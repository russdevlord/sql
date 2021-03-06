/****** Object:  StoredProcedure [dbo].[p_run_close_weekend]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_run_close_weekend]
GO
/****** Object:  StoredProcedure [dbo].[p_run_close_weekend]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc	[dbo].[p_run_close_weekend]			@screening_date			datetime,
																		@employee_id				int

as

set nocount on

declare			@error				int

/*
 * Begin Transaction
  */

begin transaction

/*
 * Close Weekend
 */

exec @error = p_close_attendance_weekend @screening_date, @employee_id

if @error <> 0
begin
	raiserror ('Error Closing Weekend - Close Weekend Step', 16, 1)
	rollback transaction
	return -1
end

/*
 * Run CineTAM Weekend Australia
 */

exec @error = p_run_cinetam_movio_pop_weekend 2, @screening_date, 'A'

if @error <> 0
begin
	raiserror ('Error Closing Weekend - Run CineTAM Australia Step', 16, 1)
	rollback transaction
	return -1
end

/*
 * Run CineTAM Weekend New Zealand
 */

exec @error = p_run_cinetam_movio_pop_weekend 2, @screening_date, 'Z'

if @error <> 0
begin
	raiserror ('Error Closing Weekend - Run CineTAM New Zealand Step', 16, 1)
	rollback transaction
	return -1
end

/*
 * Run CineTAM Close Campaigns
 */

exec @error = p_cinetam_close_campaigns_weekend 2, @screening_date

if @error <> 0
begin
	raiserror ('Error Closing Weekend - Run CineTAM Close Campaigns Step', 16, 1)
	rollback transaction
	return -1
end

/*
 * Run CineTAM Adjustments
 */

exec @error = p_cinetam_adjust_estimates_weekend @screening_date

if @error <> 0
begin
	raiserror ('Error Closing Weekend - Run CineTAM Adjustments Step', 16, 1)
	rollback transaction
	return -1
end

/*
 * Commit & Return 
 */

commit transaction
return 0
GO
