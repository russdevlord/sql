/****** Object:  StoredProcedure [dbo].[p_system_clean]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_system_clean]
GO
/****** Object:  StoredProcedure [dbo].[p_system_clean]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_system_clean]
as
set nocount on 
/*
 * Declare Variables
 */

declare @error     int

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Users from Security Access Table
 */

-- delete security_access
--  where not exists
--        ( select name from sysusers where name = security_access.user_id and uid <> gid )
-- 
-- select @error = @@error
-- if ( @error !=0 )
-- begin
-- 	rollback transaction
-- 	raiserror ('p_system_clean : Delete Error', 16, 1)
--         return -1
-- end	
-- 
-- /*
--  * Delete Users from Branch Security Table
--  */
-- 
-- delete branch_access
--  where not exists
--        ( select name from sysusers where name = branch_access.user_id and uid <> gid )
-- 
-- select @error = @@error
-- if ( @error !=0 )
-- begin
-- 	rollback transaction
-- 	raiserror ('p_system_clean : Delete Error(2)', 16, 1)
-- 	 return -1
-- end	
-- 
-- /*
--  * Delete Users Password History
--  */
-- 
-- delete password_history
--  where not exists
--        ( select name from sysusers where name = password_history.user_id and uid <> gid )
-- 
-- select @error = @@error
-- if ( @error !=0 )
-- begin
-- 	rollback transaction
-- 	raiserror ('p_system_clean : Delete Error(3)', 16, 1)
--    return -1
-- end	

/*
 * Clean working tables
 */

delete work_spot_list

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('p_system_clean : Delete Error(4)', 16, 1)
   return -1
end	

delete work_pack_totals

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('p_system_clean : Delete Error(5)', 16, 1)
   return -1
end	

delete work_spot_allocation

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('p_system_clean : Delete Error(6)', 16, 1)
   return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
