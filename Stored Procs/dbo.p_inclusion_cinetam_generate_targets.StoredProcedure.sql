/****** Object:  StoredProcedure [dbo].[p_inclusion_cinetam_generate_targets]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_inclusion_cinetam_generate_targets]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_cinetam_generate_targets]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create	proc [dbo].[p_inclusion_cinetam_generate_targets]			@inclusion_id		int

as

declare			@error										int,
				@start_date									datetime,
				@end_date									datetime,
				@screening_date								datetime,
				@row_counter								int,
				@attendance									numeric(30,20),
				@attendance_total							numeric(30,20),
				@attendance_master_total					numeric(30,20),
				@cinetam_reporting_demographics_id			int,
				@spot_count									int,
				@total_market								numeric(30,20),
				@no_weeks									int,
				@attendance_stored							numeric(30,20),
				@attendance_rolling							numeric(30,20),
				@inclusion_type								int,
				@weekly_master_records						int


create table #complex_week_attendance
(
	screening_date		datetime			not null,
	complex_id				int					not null,
	attendance				numeric(12,4)	not null
)

--print @inclusion_id

insert into		#complex_week_attendance
select				inclusion_spot.screening_date,
						inclusion_cinetam_settings.complex_id,
						sum(percent_market)
from					inclusion_spot
inner join			inclusion_cinetam_settings on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
inner join			cinetam_complex_date_settings on dbo.f_prev_attendance_screening_date(inclusion_spot.screening_date) = cinetam_complex_date_settings.screening_date 
																			and inclusion_cinetam_settings.complex_id = cinetam_complex_date_settings.complex_id
																			and inclusion_cinetam_settings.cinetam_reporting_demographics_id = cinetam_complex_date_settings.cinetam_reporting_demographics_id
where				inclusion_spot.inclusion_id = @inclusion_id
group by			inclusion_spot.screening_date,
						inclusion_cinetam_settings.complex_id

select		@error = @@error
if @error <> 0
begin
	raiserror ('Error determining weekly and complex target split', 16, 1)
	return -1
end


--select * from  #complex_week_attendance

select			@attendance_total = sum(attendance)
from			#complex_week_attendance

select		@error = @@error
if @error <> 0 or @attendance_total = 0
begin
	raiserror ('Error determining weekly and complex target split - total attendance', 16, 1)
	return -1
end

select			@weekly_master_records = count(*)
from			inclusion_cinetam_weekly_master_target
where			inclusion_id = @inclusion_id

select		@error = @@error
if @error <> 0 or @weekly_master_records < 0
begin
	raiserror ('Error determining master or weekly master target source', 16, 1)
	return -1
end

if @weekly_master_records = 0
begin
	select			@attendance_master_total = sum(attendance)
	from			inclusion_cinetam_master_target
	where			inclusion_id = @inclusion_id	
	
	select			@error = @@error
end
else
begin
	select			@attendance_master_total = sum(attendance)
	from			inclusion_cinetam_weekly_master_target
	where			inclusion_id = @inclusion_id	

	select			@error = @@error
end

if @error <> 0
begin
	raiserror ('Error determining master or weekly master target amount', 16, 1)
	return -1
end

if @attendance_master_total = 0
begin
	raiserror ('Error: master target set to zero', 16, 1)
	return -1
end

select			@no_weeks = count(*)
from			inclusion_spot
where			inclusion_id = @inclusion_id

select		@error = @@error
if @error <> 0
begin
	raiserror ('Error determining master or weekly master target source', 16, 1)
	return -1
end

if @no_weeks < 1
begin
	raiserror ('Error: not spots setup for this inclusion', 16, 1)
	return -1
end


begin transaction

delete				inclusion_cinetam_targets
where				inclusion_id = @inclusion_id
	
select		@error = @@error
if @error <> 0
begin
	raiserror ('Error deleting old targets for this inclusion', 16, 1)
	rollback transaction
	return -1
end

update				inclusion_cinetam_weekly_master_target
set					cinetam_reporting_demographics_id = inclusion_cinetam_master_target.cinetam_reporting_demographics_id
from					inclusion_cinetam_master_target
where				inclusion_cinetam_weekly_master_target.inclusion_id = @inclusion_id
and					inclusion_cinetam_weekly_master_target.inclusion_id = inclusion_cinetam_master_target.inclusion_id

select		@error = @@error
if @error <> 0
begin
	raiserror ('Error synchronising weekly masters deoms with actual master', 16, 1)
	rollback transaction
	return -1
end

if @weekly_master_records = 0
begin
	insert into		inclusion_cinetam_targets
	select				inclusion_id,
							cinetam_reporting_demographics_id,
							complex_id,
							screening_date,
							inclusion_cinetam_master_target.attendance * (#complex_week_attendance.attendance / @attendance_total),
							0,
							'N',
							0
	from					inclusion_cinetam_master_target
	cross join			#complex_week_attendance
	where				inclusion_id = @inclusion_id

	select		@error = @@error
	if @error <> 0
	begin
		raiserror ('Error deleting old targets for this inclusion', 16, 1)
		rollback transaction
		return -1
	end		
	
	select		@attendance_total = inclusion_cinetam_master_target.attendance
	from			inclusion_cinetam_master_target
	where		inclusion_id = @inclusion_id

	select		@error = @@error
	if @error <> 0
	begin
		raiserror ('Error matching attendance total - master', 16, 1)
		rollback transaction
		return -1
	end			

	select		@attendance_stored = sum(inclusion_cinetam_targets.target_attendance)
	from			inclusion_cinetam_targets
	where		inclusion_id = @inclusion_id

	select		@error = @@error
	if @error <> 0
	begin
		raiserror ('Error matching attendance total - targets', 16, 1)
		rollback transaction
		return -1
	end			

	select			@attendance_rolling = @attendance_total - @attendance_stored

	if @attendance_rolling > 0 
	begin
		update				top (convert(int, @attendance_rolling)) inclusion_cinetam_targets
		set				target_attendance = target_attendance + 1
		where			inclusion_id = @inclusion_id

		select		@error = @@error
		if @error <> 0
		begin
			raiserror ('Error matching attendance total - targets', 16, 1)
			rollback transaction
			return -1
		end			
	end		
end
else
begin
	if @weekly_master_records <> @no_weeks
	begin
		raiserror ('Error: Differing number of master target weeks to actual inclusion spots', 16, 1)
		rollback transaction
		return -1
	end			

	insert into		inclusion_cinetam_targets
	select				inclusion_id,
							cinetam_reporting_demographics_id,
							complex_id,
							#complex_week_attendance.screening_date,
							inclusion_cinetam_weekly_master_target.attendance * (#complex_week_attendance.attendance / weekly_splitter.weekly_attendance_total),
							0,
							'N',
							0
	from					inclusion_cinetam_weekly_master_target
	inner join			#complex_week_attendance on inclusion_cinetam_weekly_master_target.screening_date = #complex_week_attendance.screening_date
	inner join			(select			screening_date,
												sum(attendance) as weekly_attendance_total
							from				#complex_week_attendance
							group by		screening_date) as weekly_splitter on inclusion_cinetam_weekly_master_target.screening_date = weekly_splitter.screening_date
	where				inclusion_cinetam_weekly_master_target.inclusion_id = @inclusion_id

	select		@error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting old targets for this inclusion', 16, 1)
		rollback transaction
		return -1
	end		

	declare		weekly_master_csr cursor for 
	select		screening_date,
					attendance
	from			inclusion_cinetam_weekly_master_target
	where		inclusion_id = @inclusion_id
	for read only

	open weekly_master_csr
	fetch weekly_master_csr into @screening_date, @attendance_total
	while(@@FETCH_STATUS=0)
	begin

		select			@attendance_stored = sum(inclusion_cinetam_targets.target_attendance)
		from				inclusion_cinetam_targets
		where			inclusion_id = @inclusion_id
		and				screening_date = @screening_date

		select		@error = @@error
		if @error <> 0
		begin
			raiserror ('Error matching attendance total - targets', 16, 1)
			rollback transaction
			return -1
		end			

		select			@attendance_rolling = @attendance_total - @attendance_stored

		if @attendance_rolling > 0
		begin
			update			top (convert(int, @attendance_rolling)) inclusion_cinetam_targets
			set				target_attendance = target_attendance + 1
			where			inclusion_id = @inclusion_id
			and				screening_date = @screening_date

			select		@error = @@error
			if @error <> 0
			begin
				raiserror ('Error matching attendance total - targets', 16, 1)
				rollback transaction
				return -1
			end			
		end

		fetch weekly_master_csr into @screening_date, @attendance_total
	end
end

update			inclusion_cinetam_targets
set				original_target_attendance = target_attendance
where			inclusion_id = @inclusion_id

select		@error = @@error
if @error <> 0
begin
	raiserror ('Error matching attendance total - targets', 16, 1)
	rollback transaction
	return -1
end	


commit transaction
return 0
GO
