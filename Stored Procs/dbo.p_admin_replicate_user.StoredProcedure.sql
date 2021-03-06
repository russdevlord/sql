/****** Object:  StoredProcedure [dbo].[p_admin_replicate_user]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_admin_replicate_user]
GO
/****** Object:  StoredProcedure [dbo].[p_admin_replicate_user]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_admin_replicate_user] @source_name		varchar(15),
                                   @target_name		varchar(15),
                                   @branch_access	varchar(30),
                                   @database			char(1)

as

/*
 * Declare Valiables
 */ 

declare @error							integer,
        @current_name				varchar(30)

/*
 * Check Source Login Exists
 */

select @current_name = null

select @current_name = name
  from master..syslogins
 where name = @source_name

if(@current_name is null)
begin
	raiserror ('Cannot find source user in master table.', 16, 1)
	return -1
end

/*
 * Check new login does not exist
 */

select @current_name = null

select @current_name = name
  from master..syslogins
 where name = @target_name

if(@current_name is null)
begin
	raiserror ('Cannot find target user in master table.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Insert Security Access
 */

if(@database = 'P')
begin

	insert into production..security_access
	select @target_name,
			 security_access_group_id
	  from production..security_access
	 where user_id = @source_name
	
	select @error = @@error
	if(@error !=0)
	begin
		raiserror ( 'Error copying security access: security_access', 16, 1) 
		rollback transaction
		return -1
	end
	
	/*
	 * Insert Branch Access
	 */
	
	insert into production..branch_access
	select @target_name,
			 branch_code
	  from production..branch
	 where branch_code in (@branch_access)
	
	select @error = @@error
	if(@error !=0)
	begin
		raiserror ( 'Error copying branch access: branch_access', 16, 1) 
		rollback transaction
		return -1
	end

end

if(@database = 'A')
begin

	insert into acceptance..security_access
	select @target_name,
			 security_access_group_id
	  from acceptance..security_access
	 where user_id = @source_name
	
	select @error = @@error
	if(@error !=0)
	begin
		raiserror ( 'Error copying security access: security_access', 16, 1) 
		rollback transaction
		return -1
	end
	
	/*
	 * Insert Branch Access
	 */
	
	insert into acceptance..branch_access
	select @target_name,
			 branch_code
	  from acceptance..branch
	 where branch_code in (@branch_access)
	
	select @error = @@error
	if(@error !=0)
	begin
		raiserror ( 'Error copying branch access: branch_access', 16, 1) 
		rollback transaction
		return -1
	end

end

if(@database = 'D')
begin

	insert into development..security_access
	select @target_name,
			 security_access_group_id
	  from development..security_access
	 where user_id = @source_name
	
	select @error = @@error
	if(@error !=0)
	begin
		raiserror ( 'Error copying security access: security_access', 16, 1) 
		rollback transaction
		return -1
	end
	
	/*
	 * Insert Branch Access
	 */
	
	insert into development..branch_access
	select @target_name,
			 branch_code
	  from development..branch
	 where branch_code in (@branch_access)
	
	select @error = @@error
	if(@error !=0)
	begin
		raiserror ( 'Error copying branch access: branch_access', 16, 1) 
		rollback transaction
		return -1
	end

end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
