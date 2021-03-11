USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_screening_cert_removal]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_screening_cert_removal] @screening_date		datetime
as
set nocount on 

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
	raiserror ('Screening Certificate Removal: Error Reading Screening Date Status.', 16, 1)
	return -1
end

if(@status <> 'X')
begin
	raiserror ('Screening Certificate Removal: Screening Date must be Closed. Request Denied.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Complex Dates
 */

delete certificate_group --Cascades delete to Certificate Item
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
