/****** Object:  StoredProcedure [dbo].[p_inclusion_generate_goodwill_targets]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_inclusion_generate_goodwill_targets]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_generate_goodwill_targets]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_inclusion_generate_goodwill_targets]	@inclusion_id				int,
															@screening_date				datetime,
															@no_weeks					int,
															@attendance_total			numeric(30,20),
															@mode						int
as	

declare			@error									int,
				@start_date								datetime,
				@end_date								datetime,
				@row_counter							int,
				@attendance								numeric(30,20),
				@cinetam_reporting_demographics_id		int,
				@spot_count								int,
				@total_market							numeric(30,20),
				@attendance_diff						numeric(30,20),
				@attendance_rolling						numeric(30,20),
				@movie_attendance						numeric(30,20),
				@movie_total_attendance					numeric(30,20),
				@attendance_stored						numeric(30,20),
				@master_weekly_records					int
					
set nocount on					

create table #movie_attendance
(
screening_date		datetime			null,
attendance			numeric(30,20)		null
)

select			@start_date	= @screening_date	

select			@end_date = dateadd(wk, @no_weeks - 1, @start_date)

select			@no_weeks = 1 + datediff(wk, @start_date, @end_date)

create table #complex_week_attendance
(
	screening_date		datetime			not null,
	complex_id			int					not null,
	attendance			numeric(12,4)		not null
)

--check spots

select			@spot_count = count(spot_id)
from			inclusion_spot
where			inclusion_id = @inclusion_id
and				screening_date between @start_date	and @end_date

if @spot_count <> @no_weeks
begin
	raiserror ('You have not entered inclusion spots for the new weeks you have requested', 16, 1)
	return -1
end

insert into		#complex_week_attendance
select			inclusion_spot.screening_date,
				inclusion_cinetam_settings.complex_id,
				sum(percent_market)
from			inclusion_spot
inner join		inclusion_cinetam_settings on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
inner join		cinetam_reporting_demographics_xref on inclusion_cinetam_settings.cinetam_reporting_demographics_id = cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id
inner join		cinetam_complex_date_settings on dbo.f_prev_attendance_screening_date(inclusion_spot.screening_date) = cinetam_complex_date_settings.screening_date 
and				inclusion_cinetam_settings.complex_id = cinetam_complex_date_settings.complex_id
and				inclusion_cinetam_settings.cinetam_reporting_demographics_id = cinetam_complex_date_settings.cinetam_reporting_demographics_id
where			inclusion_spot.inclusion_id = @inclusion_id
and				inclusion_spot.screening_date between @start_date and @end_date
group by		inclusion_spot.screening_date,
				inclusion_cinetam_settings.complex_id

select		@error = @@error
if @error <> 0
begin
	raiserror ('Error determining weekly and complex target split', 16, 1)
	return -1
end

select			@attendance = sum(attendance)
from			#complex_week_attendance

select		@error = @@error
if @error <> 0
begin
	raiserror ('Error determining weekly and complex target split - total attendance', 16, 1)
	return -1
end


begin transaction

insert into		inclusion_cinetam_targets
select			inclusion_id,
				cinetam_reporting_demographics_id,
				complex_id,
				screening_date,
				@attendance_total * (#complex_week_attendance.attendance / @attendance),
				0,
				'N',
				0
from			inclusion_cinetam_master_target
cross join		#complex_week_attendance
where			inclusion_id = @inclusion_id

select		@error = @@error
if @error <> 0
begin
	raiserror ('Error deleting old targets for this inclusion', 16, 1)
	rollback transaction
	return -1
end			

select			@attendance_stored = sum(inclusion_cinetam_targets.target_attendance)
from			inclusion_cinetam_targets
where			inclusion_id = @inclusion_id
and				screening_date between @start_date	and @end_date


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
	and				screening_date between @start_date	and @end_date

	select		@error = @@error
	if @error <> 0
	begin
		raiserror ('Error matching attendance total - targets', 16, 1)
		rollback transaction
		return -1
	end			
end

if @mode = 1 
begin
	update			inclusion_cinetam_targets
	set				original_target_attendance = target_attendance
	where			inclusion_id = @inclusion_id
	and				screening_date between @start_date	and @end_date

	select		@error = @@error
	if @error <> 0
	begin
		raiserror ('Error matching attendance total - targets', 16, 1)
		rollback transaction
		return -1
	end	

	update			inclusion_cinetam_master_target
	set				attendance = isnull(attendance, 0) + @attendance_total
	where			inclusion_id = @inclusion_id

	select		@error = @@error
	if @error <> 0
	begin
		raiserror ('Error updateing master target', 16, 1)
		rollback transaction
		return -1
	end	

	select			@master_weekly_records = count(*) 
	from			inclusion_cinetam_weekly_master_target 
	where			inclusion_id = @inclusion_id

	if @master_weekly_records > 0 
	begin
		select			@master_weekly_records = count(*) 
		from			inclusion_cinetam_weekly_master_target 
		where			inclusion_id = @inclusion_id
		and				screening_date between @start_date	and @end_date

		if @master_weekly_records = 0 
		begin
			insert into		inclusion_cinetam_weekly_master_target
			select			inclusion_id,
							cinetam_reporting_demographics_id,
							screening_date,
							sum(target_attendance)
			from			inclusion_cinetam_targets
			where			inclusion_id = @inclusion_id
			and				screening_date between @start_date	and @end_date	
			group by		inclusion_id,
							cinetam_reporting_demographics_id,
							screening_date							 

			select		@error = @@error
			if @error <> 0
			begin
				raiserror ('Error updateing weekly master target', 16, 1)
				rollback transaction
				return -1
			end	

		end
	end
end
else
begin
	update			inclusion_cinetam_targets
	set				original_target_attendance = 0
	where			inclusion_id = @inclusion_id
	and				screening_date between @start_date	and @end_date

	select		@error = @@error
	if @error <> 0
	begin
		raiserror ('Error matching attendance total - targets', 16, 1)
		rollback transaction
		return -1
	end	
end

commit transaction
return 0
GO
