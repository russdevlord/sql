/****** Object:  StoredProcedure [dbo].[p_complex_date_deactivation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_complex_date_deactivation]
GO
/****** Object:  StoredProcedure [dbo].[p_complex_date_deactivation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_complex_date_deactivation] @screening_date		datetime
as

/*
 * Declare Variables
 */

declare @error        		int,
        @rowcount     		int,
        @errorode					int,
        @errno					int,
        @status				char(1)

/*
 * Check Screening Date Status
 */

select @status = screening_date_status
  from film_screening_dates
 where screening_date = @screening_date

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Complex Date Deactivate: Error Reading Screening Date Status.', 16, 1)
	return -1
end

if(@status <> 'X')
begin
	raiserror ('Complex Date Deactivate: Screening Date must be Closed. Deactivation Request Denied.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Complex Dates
 */

delete complex_date
 where screening_date = @screening_date

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Delete Cinelight Dates
 */

delete cinelight_date
 where screening_date = @screening_date

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Update Screening Date
 */

update film_screening_dates
   set complex_date_removed = 'Y'
 where screening_date = @screening_date

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
