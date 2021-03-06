/****** Object:  StoredProcedure [dbo].[p_attendance_weekend_setup]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_attendance_weekend_setup]
GO
/****** Object:  StoredProcedure [dbo].[p_attendance_weekend_setup]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_attendance_weekend_setup]		@screening_date				datetime
																			
as

declare			@error					int,
						@date_check		char(1)

set nocount on

select		@date_check = weekend_attendance_status
from		film_screening_dates
where		screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Could Not determine status of screening week', 16, 1)
	return -1
end

--Unless week is open - do not process logic in this proc - ensures this will only be run once per week
if @date_check <> 'O'
begin
	return 0
end
	
/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Attendance Source records
 */

delete		attendance_source_weekend
where		screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: could not delete attendance source records for this provider', 16, 1)
	return -1
end

/*
 * Delete Attendance Raw records
 */

delete		attendance_raw_weekend
where		screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: could not delete attendance raw records for this provider', 16, 1)
	return -1
end

/*
 * Setup attendance_movie_weekend records
 */

delete		movie_history_weekend  
where		screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: could not delete movie_history_weekend records for this provider', 16, 1)
	return -1
end									

delete		cinetam_movie_history_weekend
where		screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: could not delete cinetam_movie_history_weekend records for this provider', 16, 1)
	return -1
end					

delete		cinetam_movio_data_weekend
where		screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: could not delete cinetam_movio_data_weekend records for this provider', 16, 1)
	return -1
end					



insert into		movie_history_weekend
						(movie_id,
						complex_id,
						screening_date,
						occurence,
						print_medium,
						three_d_type,
						altered,
						advertising_open,
						source,
						start_date,
						premium_cinema,
						show_category,
						certificate_group,
						movie_print_medium, 
						confirmed,
						sessions_scheduled,
						sessions_held,
						attendance,
						full_attendance,
						attendance_type,
						country,
						status)
select				movie_id,
						complex_id,
						screening_date,
						occurence,
						print_medium,
						three_d_type,
						altered,
						advertising_open,
						source,
						start_date,
						premium_cinema,
						show_category,
						certificate_group,
						movie_print_medium, 
						confirmed,
						sessions_scheduled,
						sessions_held,
						0 as attendance,
						0 as full_attendance,
						attendance_type,
						country,
						status
from				movie_history
where				screening_date = @screening_date

													
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: could not delete attendance_movie_weekend records for this provider', 16, 1)
	return -1
end						


/* 
 * set week to in processing
 */
  
update	film_screening_dates
set			weekend_attendance_status = 'P'
where		screening_date = @screening_date
  
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: could not update film screening dates to In Processing', 16, 1)
	return -1
end				

/*
 * Commit Transaction & Return
 */ 							

commit transaction
return 0
GO
