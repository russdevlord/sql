/****** Object:  StoredProcedure [dbo].[p_follow_film_generate_targets]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_follow_film_generate_targets]
GO
/****** Object:  StoredProcedure [dbo].[p_follow_film_generate_targets]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create proc [dbo].[p_follow_film_generate_targets]			@inclusion_id			int

as

declare				@error															int,
						@start_date												datetime,
						@end_date													datetime,
						@screening_date											datetime,
						@row_counter												int,
						@attendance												numeric(30,20),
						@attendance_total										numeric(30,20),
						@cinetam_reporting_demographics_id		int,
						@spot_count												int,
						@total_market												numeric(30,20),
						@no_weeks													int,
						@attendance_diff										numeric(30,20),
						@attendance_rolling									numeric(30,20),
						@movie_id													int,
						@movie_attendance										numeric(30,20),
						@movie_total_attendance							numeric(30,20),
						@attendance_stored									numeric(30,20),
						@movie_count												int,
						@estimate_count											int
					
set nocount on					

create table #movie_attendance
(
movie_id					int						null,
complex_id				int						null,
screening_date		datetime				null,
attendance				numeric(30,20)		null
)

select		@attendance_total = attendance,
			@cinetam_reporting_demographics_id = cinetam_reporting_demographics_id
from		inclusion_cinetam_master_target
where		inclusion_id = @inclusion_id

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting targets for this inclusion', 16, 1)
	return -1
end

if @attendance_total = 0
begin
	raiserror ('Error: master target set to zero', 16, 1)
	return -1
end

select			@movie_count = count(distinct movie_screening_instructions.movie_id)
from			inclusion_cinetam_package,
				movie_screening_instructions,
				inclusion_cinetam_settings
where			inclusion_cinetam_package.package_id = movie_screening_instructions.package_id
and				inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
and				inclusion_cinetam_settings.inclusion_id = @inclusion_id 
and				instruction_type = 1

select			@estimate_count = count(distinct cinetam_movie_complex_estimates.movie_id)
from			inclusion_cinetam_package,
				movie_screening_instructions,
				inclusion_cinetam_settings,
				cinetam_movie_complex_estimates
where			inclusion_cinetam_package.package_id = movie_screening_instructions.package_id
and				inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
and				cinetam_movie_complex_estimates.complex_id = inclusion_cinetam_settings.complex_id
and				cinetam_movie_complex_estimates.cinetam_reporting_demographics_id = inclusion_cinetam_settings.cinetam_reporting_demographics_id
and				cinetam_movie_complex_estimates.movie_id = movie_screening_instructions.movie_id
and				inclusion_cinetam_settings.inclusion_id = @inclusion_id 
and				instruction_type = 1


select	@movie_count = isnull(@movie_count,0),
			@estimate_count = isnull(@estimate_count,0)

if @movie_count <> @estimate_count
begin
	raiserror ('Error: Some of the movies on this inclusion have not had their estimates generated.', 16, 1)
	return -1
end

insert into		#movie_attendance
select				movie_screening_instructions.movie_id,
						cinetam_movie_complex_estimates.complex_id,
						cinetam_movie_complex_estimates.screening_date,
						convert(numeric(30,20), sum(attendance))
from					inclusion_cinetam_package,
						movie_screening_instructions,
						inclusion_cinetam_settings,
						cinetam_movie_complex_estimates,
						inclusion_spot
where				inclusion_cinetam_package.package_id = movie_screening_instructions.package_id
and					inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
and					cinetam_movie_complex_estimates.complex_id = inclusion_cinetam_settings.complex_id
and					cinetam_movie_complex_estimates.cinetam_reporting_demographics_id = inclusion_cinetam_settings.cinetam_reporting_demographics_id
and					cinetam_movie_complex_estimates.movie_id = movie_screening_instructions.movie_id
and					inclusion_cinetam_settings.inclusion_id = @inclusion_id 
and					inclusion_spot.inclusion_id = inclusion_cinetam_package.inclusion_id
and					inclusion_spot.screening_date = cinetam_movie_complex_estimates.screening_date
and					instruction_type = 1
group by			movie_screening_instructions.movie_id,
						cinetam_movie_complex_estimates.complex_id,
						cinetam_movie_complex_estimates.screening_date

select		@error = @@error
if @error <> 0
begin
	raiserror ('Error determining weekly and complex target split - temp table insert', 16, 1)
	return -1
end

select				@attendance_total = sum(attendance)
from					#movie_attendance

select		@error = @@error
if @error <> 0
begin
	raiserror ('Error determining weekly and complex target split - total attendance', 16, 1)
	return -1
end


begin transaction

delete				inclusion_follow_film_targets
where				inclusion_id = @inclusion_id
	
select		@error = @@error
if @error <> 0
begin
	raiserror ('Error deleting old targets for this inclusion', 16, 1)
	rollback transaction
	return -1
end

insert into		inclusion_follow_film_targets
select				inclusion_id,
						cinetam_reporting_demographics_id,
						complex_id,
						movie_id,
						screening_date,
						isnull(inclusion_cinetam_master_target.attendance * (#movie_attendance.attendance / @attendance_total),0),
						0,
						'N',
						0
from					inclusion_cinetam_master_target
cross join			#movie_attendance
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

select		@attendance_stored = isnull(sum(inclusion_follow_film_targets.target_attendance),0)
from			inclusion_follow_film_targets
where		inclusion_id = @inclusion_id

select		@error = @@error
if @error <> 0
begin
	raiserror ('Error matching attendance total - targets', 16, 1)
	rollback transaction
	return -1
end			

select			@attendance_rolling = @attendance_total - @attendance_stored

update			top (convert(int, @attendance_rolling)) inclusion_follow_film_targets
set				target_attendance = target_attendance + 1
where			inclusion_id = @inclusion_id

select		@error = @@error
if @error <> 0
begin
	raiserror ('Error matching attendance total - targets', 16, 1)
	rollback transaction
	return -1
end			

update			inclusion_follow_film_targets
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
