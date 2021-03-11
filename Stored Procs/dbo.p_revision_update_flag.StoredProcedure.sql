USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_revision_update_flag]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_revision_update_flag]

as

declare		@error			int

set nocount on

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Campaigns with flag set to exclude
 */

update 	film_campaign
set 	exclude_system_revision = 'N'
where	exclude_system_revision = 'Y'

select @error = @@error
if @error <> 0 
begin
	rollback transaction
	raiserror ('Error updating nightly revision exclude flag', 16, 1)
	return -1
end

/*
 * Commit Transaction & Return
 */

commit transaction
return 0
GO
