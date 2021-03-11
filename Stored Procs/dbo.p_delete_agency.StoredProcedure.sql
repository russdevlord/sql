USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_agency]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_delete_agency]		@agency_id		integer

as

declare @error          int,
        @rowcount			int


--Check if the agency has been used anywhere.
if exists (select 1
             from slide_campaign
            where agency_id = @agency_id)
begin
	raiserror ('Agency is assigned to a slide campaign and cannot be deleted.', 16, 1)
	return -1
end

if exists (select 1
             from film_campaign
            where agency_id = @agency_id or
                  billing_agency = @agency_id)
begin
	raiserror ('Agency is assigned to a film campaign and cannot be deleted.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete agency
 */
delete agency
 where agency_id = @agency_id
select @error = @@error
if ( @error !=0 )
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
