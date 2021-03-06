/****** Object:  StoredProcedure [dbo].[p_inclusion_audience_generate_missing_targets]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_inclusion_audience_generate_missing_targets]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_audience_generate_missing_targets]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_inclusion_audience_generate_missing_targets]			@inclusion_id			int

as

declare					@error																int,
							@start_date													datetime,
							@end_date														datetime,
							@screening_date												datetime,
							@row_counter													int,
							@attendance													numeric(30,20),
							@attendance_total											numeric(30,20),
							@attendance_stored										numeric(30,20),
							@orig_attendance_total									numeric(30,20),
							@cinetam_reporting_demographics_id			int,
							@spot_count													int,
							@total_market													numeric(30,20),
							@no_weeks														int,
							@attendance_diff											numeric(30,20),
							@attendance_rolling										numeric(30,20),
							@movie_id														int,
							@movie_attendance											numeric(30,20),
							@movie_total_attendance								numeric(30,20),
							@movie_count													int,
							@estimate_count												int

set nocount on					

create table #complex_week_attendance
(
	screening_date		datetime			not null,
	complex_id				int					not null,
	attendance				numeric(12,4)	not null
)

create table #inclusion_cinetam_targets
(
	inclusion_id													int,
	cinetam_reporting_demographics_id			int,
	complex_id													int,
	screening_date											datetime,
	target_attendance										int,
	achieved_attendance									int,
	processed														char(1),
	original_target_attendance							int
)

begin transaction

insert into		#inclusion_cinetam_targets
select				inclusion_id,
						cinetam_reporting_demographics_id,
						complex_id,
						screening_date,
						target_attendance,
						achieved_attendance,
						processed,
						original_target_attendance		
from					inclusion_cinetam_targets						
where				inclusion_id = @inclusion_id
and					processed = 'N'

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('ERROR: Whoopsie - failed to back up the current targets.', 16, 1)
	return -1
end

delete				inclusion_cinetam_targets
where				inclusion_id = @inclusion_id
and					processed = 'N'

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('ERROR: Oh gosh darn - failed to delete up the current targets.', 16, 1)
	return -1
end

declare			screening_date_csr cursor for
select			screening_date
from				#inclusion_cinetam_targets
group by		screening_date
order by		screening_date
for				read only

open screening_date_csr
fetch screening_date_csr into @screening_date
while(@@fetch_status = 0)
begin
	
	select				@attendance_total = 0,
							@orig_attendance_total = 0

	select				@attendance_total = isnull(sum(target_attendance),0),
							@orig_attendance_total = isnull(sum(original_target_attendance),0)
	from					#inclusion_cinetam_targets
	where				inclusion_id = @inclusion_id
	and					screening_date = @screening_date
	and					processed = 'N' 	
	
	insert into		#complex_week_attendance
	select				inclusion_spot.screening_date,
							inclusion_cinetam_settings.complex_id,
							sum(percent_market)
	from					inclusion_spot
	inner join			inclusion_cinetam_settings on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
	inner join			cinetam_complex_date_settings on inclusion_spot.screening_date = cinetam_complex_date_settings.screening_date 
																				and inclusion_cinetam_settings.complex_id = cinetam_complex_date_settings.complex_id
																				and inclusion_cinetam_settings.cinetam_reporting_demographics_id = cinetam_complex_date_settings.cinetam_reporting_demographics_id
	where				inclusion_spot.inclusion_id = @inclusion_id
	and					inclusion_spot.screening_date = @screening_date
	and					inclusion_cinetam_settings.complex_id not in (select complex_id from inclusion_cinetam_targets where inclusion_id = @inclusion_id and screening_date = @screening_date and processed = 'Y')
	group by			inclusion_spot.screening_date,
							inclusion_cinetam_settings.complex_id

	select		@error = @@error
	if @error <> 0
	begin
		raiserror ('Error determining weekly and complex target split', 16, 1)
		return -1
	end

	select				@movie_total_attendance = sum(attendance)
	from					#complex_week_attendance
	where				screening_date = @screening_date

	select		@error = @@error
	if @error <> 0
	begin
		raiserror ('Error determining weekly and complex target split - total attendance', 16, 1)
		return -1
	end

	insert into		inclusion_cinetam_targets
	select				inclusion_id,
							cinetam_reporting_demographics_id,
							complex_id,
							screening_date,
							isnull(@attendance_total * (#complex_week_attendance.attendance / @movie_total_attendance),0),
							0,
							'N',
							isnull(@orig_attendance_total * (#complex_week_attendance.attendance / @movie_total_attendance),0)
	from					inclusion_cinetam_master_target
	cross join			#complex_week_attendance
	where				inclusion_id = @inclusion_id
	and					screening_date = @screening_date

	select		@error = @@error
	if @error <> 0
	begin
		raiserror ('Error deleting old targets for this inclusion', 16, 1)
		rollback transaction
		return -1
	end			

	select			@attendance_stored = isnull(sum(inclusion_cinetam_targets.target_attendance),0)
	from				inclusion_cinetam_targets
	where			inclusion_id = @inclusion_id
	and				screening_date = @screening_date
	and				processed = 'N'

	select		@error = @@error
	if @error <> 0
	begin
		raiserror ('Error matching attendance total - targets', 16, 1)
		rollback transaction
		return -1
	end			

	select			@attendance_rolling = @attendance_total - @attendance_stored

	update			top (convert(int, @attendance_rolling)) inclusion_cinetam_targets
	set				target_attendance = target_attendance + 1
	where			inclusion_id = @inclusion_id
	and				screening_date = @screening_date
	and				processed = 'N'

	select		@error = @@error
	if @error <> 0
	begin
		raiserror ('Error matching attendance total - targets', 16, 1)
		rollback transaction
		return -1
	end			

	select			@attendance_stored = isnull(sum(inclusion_cinetam_targets.original_target_attendance),0)
	from				inclusion_cinetam_targets
	where			inclusion_id = @inclusion_id
	and				screening_date = @screening_date
	and				processed = 'N'

	select			@error = @@error
	if @error <> 0
	begin
		raiserror ('Error matching attendance total - targets', 16, 1)
		rollback transaction
		return -1
	end			

	select			@attendance_rolling = @orig_attendance_total - @attendance_stored

	update			top (convert(int, @attendance_rolling)) inclusion_cinetam_targets
	set				original_target_attendance = original_target_attendance + 1
	where			inclusion_id = @inclusion_id
	and				screening_date = @screening_date
	and				processed = 'N'

	select		@error = @@error
	if @error <> 0
	begin
		raiserror ('Error matching attendance total - targets', 16, 1)
		rollback transaction
		return -1
	end			

	fetch screening_date_csr into @screening_date
end

commit transaction
return 0
GO
