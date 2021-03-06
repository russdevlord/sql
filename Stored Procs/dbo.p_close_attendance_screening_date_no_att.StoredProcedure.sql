/****** Object:  StoredProcedure [dbo].[p_close_attendance_screening_date_no_att]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_close_attendance_screening_date_no_att]
GO
/****** Object:  StoredProcedure [dbo].[p_close_attendance_screening_date_no_att]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create proc [dbo].[p_close_attendance_screening_date_no_att] 	@screening_date		datetime,
																@employee_id		int

as

declare		@error								int,
			@attendance_contributors			int,
			@attendance_processed				int,
			@attendance_status					char(1),
			@regional_indicator					char(1),
			@country_code						char(1),
			@average							numeric(18,6),
			@programmed_average					numeric(18,6),
			@movie_id							int,
			@campaign_no						int,
			@complex_id							int,
			@attendance							int,
			@records							int,
			@cinelight_id						int,
			@showings							int,
			@package_id							int,
			@cinelight_count					int,
			@player_name						varchar(40),
			@days								int,
			@premium_movie_count				numeric(18,6),
			@normal_movie_count					numeric(18,6),			
			@premium_movie_avg					numeric(18,6),
			@normal_movie_avg					numeric(18,6)		


set nocount on

/*
 * Obtain info from screening_dates table
 */



/*
 * Begin Transaction
 */

begin transaction


update 	film_screening_dates 
set		attendance_processed = attendance_contributors,
		attendance_status = 'X'
where 	screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not set close status. Close denied.', 16, 1)
	rollback transaction
	return -1
end

/*
 * Delete existing attendance averages
 */

delete 	attendance_screening_date_averages
where	screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete attendance_screening_date_averages. Close denied.', 16, 1)
	rollback transaction
	return -1
end

delete 	attendance_movie_averages
where	screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete attendance_movie_averages. Close denied.', 16, 1)
	rollback transaction
	return -1
end



/*
 * Update Movie History with appropriate averages where actual information is not already stored.
 */

update 		movie_history
set			attendance = 0,
			attendance_type = null
where 		(attendance_type != 'A'
or			attendance_type is null)
and 		screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Update Movie History information. Close denied.', 16, 1)
	rollback transaction
	return -1
end

/*
 * Delete Existing Actuals For Campaigns
 */

delete	attendance_campaign_actuals
where	screening_date = @screening_date


select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete attendance_campaign_actuals. Close denied.', 16, 1)
	rollback transaction
	return -1
end


--print 8

delete	attendance_campaign_complex_actuals
where	screening_date = @screening_date


select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete attendance_campaign_complex_actuals. Close denied.', 16, 1)
	rollback transaction
	return -1
end

--print 9



/*
 * Create Cinelight Attendance
 */

delete		cinelight_attendance_history
where		screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Generate Cinelight Actuals. Close denied.', 16, 1)
	rollback transaction
	return -1
end

delete		cinelight_attendance_actuals
where		screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Generate Cinelight Actuals. Close denied.', 16, 1)
	rollback transaction
	return -1
end

delete		cinelight_attendance_digilite_actuals
where		screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Generate Cinelight Actuals. Close denied.', 16, 1)
	rollback transaction
	return -1
end

delete		cinelight_shell_attendance
where		screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Generate Cinelight Actuals. Close denied.', 16, 1)
	rollback transaction
	return -1
end


/*
 * Summarise Tracking Data
 */

 delete			attendance_campaign_tracking
 where				screening_date = @screening_date

 select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not delete  attendance_campaign_tracking Information. Close denied.', 16, 1)
	rollback transaction
	return -1
end


--print 20

update		movie_history 
set			attendance = 0 
where		movie_id = 102

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not remove attendance . Close denied.', 16, 1)
	rollback transaction
	return -1
end

--print 21

/*
 * Close Transaction & Return
 */

commit transaction

return 0
GO
