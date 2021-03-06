/****** Object:  StoredProcedure [dbo].[p_cinetam_setup_new_complex]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_setup_new_complex]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_setup_new_complex]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc	[dbo].[p_cinetam_setup_new_complex]		@old_complex_id			int,
							@new_Complex_id		int

as

declare			@error		int

begin transaction

delete cinetam_complex_date_settings where complex_id = @new_complex_id

select @error = @@error
if @error <> 0
begin
	select 'error deleting cinetam_complex_date_settings' as setup_result
	rollback transaction
	return -1
end

insert into cinetam_complex_date_settings select  @new_complex_id, screening_date, cinetam_reporting_demographics_id, percent_market, priority_level, spot_min_no, spot_max_no 
from cinetam_complex_date_settings where complex_id = @old_complex_id and screening_date not in (select screening_date from cinetam_complex_date_settings where complex_id = @new_complex_id)

select @error = @@error
if @error <> 0
begin
	select 'error inserting cinetam_complex_date_settings' as setup_result
	rollback transaction
	return -1
end


delete cinetam_movie_complex_estimates where complex_id = @new_complex_id

select @error = @@error
if @error <> 0
begin
	select 'error deleting cinetam_movie_complex_estimates' as setup_result
	rollback transaction
	return -1
end

insert into cinetam_movie_complex_estimates 
select movie_id, cinetam_reporting_demographics_id, screening_date, @new_complex_id, attendance, original_estimate
from cinetam_movie_complex_estimates 
where complex_id = @old_complex_id and screening_date >= '14-sep-2017'

select @error = @@error
if @error <> 0
begin
	select 'error inserting cinetam_movie_complex_estimates' as setup_result
	rollback transaction
	return -1
end

delete availability_demo_matching where complex_id = @new_Complex_id

select @error = @@error
if @error <> 0
begin
	select 'error deleting availability_demo_matching' as setup_result
	rollback transaction
	return -1
end

insert into availability_demo_matching 
select			@new_Complex_id,
				availability_demo_matching.screening_date,
				availability_demo_matching.cinetam_reporting_demographics_id,
				availability_demo_matching.attendance_share 
from			availability_demo_matching 
where			complex_id = @old_complex_id

select @error = @@error
if @error <> 0
begin
	select 'error inserting availability_demo_matching' as setup_result
	rollback transaction
	return -1
end
commit transaction
select 'complex setup' as setup_result
return 0
GO
