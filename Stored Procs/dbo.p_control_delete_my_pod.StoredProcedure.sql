/****** Object:  StoredProcedure [dbo].[p_control_delete_my_pod]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_control_delete_my_pod]
GO
/****** Object:  StoredProcedure [dbo].[p_control_delete_my_pod]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_control_delete_my_pod] @control_group_item                 int,
                                       @login_name                   varchar(30)
                                       
as

declare     @error                          int,
            @err_msg                        varchar(255),
            @security_user_count            int,
            @security_group_count           int,
            @my_pod_count                int

/*
 * Verify that this control_group_item is a my_pod - interface should check this but ensure here
 */
 
select  @my_pod_count = count(control_group_item)
from    control_group_item
where   control_group_item = @control_group_item
and     control_group = 34 -- my_pods group

select @error = @@error
if @error != 0 or @my_pod_count != 1
begin
    select  @error = 50000
    select  @err_msg = 'Error:  Cannot delete this item as it is not a my_pod.'
    goto error            
end

/*
 * Begin Transaction
 */
 
begin transaction

/*
 * Delete Control Security Users Record
 */
 
delete  control_security_users
where   control_group_item = @control_group_item
and     login_id = @login_name
   
select  @error = @@error
if @error != 0
    goto rollbackerror
    
/*
 * If there are no control_security_users/control_security_groups 
 * remaining for this control_group_item then delete the item
 */    
    
select  @security_user_count = count(login_id)
from    control_security_users
where   control_group_item = @control_group_item

select  @error = @@error
if @error != 0
    goto rollbackerror

select  @security_group_count = count(security_access_group_id)
from    control_security_groups
where   control_group_item = @control_group_item

select @error = @@error
if @error != 0
    goto rollbackerror


if @security_group_count = 0 and @security_user_count = 0
begin
    delete  control_group_item
    where   control_group_item = @control_group_item
    
    select  @error = @@error
    if @error != 0
        goto rollbackerror
end

/*
 * Commit Transaction and Return
 */
 
commit transaction
return 0

/*
 * Error handlers
 */
 
rollbackerror:
    rollback transaction
error:
    if @error >= 50000
        raiserror (@err_msg, 16, 1)

    return -1
GO
