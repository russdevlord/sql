USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_account]    Script Date: 11/03/2021 2:30:34 PM ******/
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
