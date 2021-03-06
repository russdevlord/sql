/****** Object:  StoredProcedure [dbo].[p_delete_account]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_account]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_account]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_delete_account]		@account_id		integer

as

/*==============================================================*
 * DESC:- deletes an account                                    *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1   5-Mar-2008 DH  Initial Build                            *
 *                                                              *
 *==============================================================*/

declare @error          int,
        @rowcount			int

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete account
 */
delete account
 where account_id = @account_id
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
