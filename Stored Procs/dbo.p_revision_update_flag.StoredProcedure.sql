/****** Object:  StoredProcedure [dbo].[p_revision_update_flag]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_revision_update_flag]
GO
/****** Object:  StoredProcedure [dbo].[p_revision_update_flag]    Script Date: 12/03/2021 10:03:50 AM ******/
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
