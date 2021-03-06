/****** Object:  StoredProcedure [dbo].[p_control_add_my_pod]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_control_add_my_pod]
GO
/****** Object:  StoredProcedure [dbo].[p_control_add_my_pod]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_control_add_my_pod] @control_item                 int,
                                    @login_name                   varchar(30),
                                    @application_name             varchar(255)
                                       
as

declare     @error                          int,
            @err_msg                        varchar(255),
            @security_user_count            int,
            @security_group_count           int,
            @control_group_item_id          int,
            @control_group_item_desc        varchar(255),
            @employee_name                  varchar(255)

/*
 * Check to see if there is an existing control_group_item for the specififed control_item linked to the my_pods group
 */
 
select  @control_group_item_id = isnull(control_group_item,0)
from    control_group_item
where   control_item = @control_item
and     control_group = 34 -- my_pods group
and     application_name = @application_name

select @error = @@error
if @error != 0
begin
    select  @error = 50000
    select  @err_msg = 'Error:  Cannot determine if my_pod already exists.'
    goto error            
end

select  @security_user_count = count(login_id)
from    control_security_users
where   control_group_item = @control_group_item_id
and     login_id = @login_name

select @error = @@error
if @error != 0
begin
    select  @error = 50000
    select  @err_msg = 'Error:  Cannot determine if my_pod already exists.'
    goto error            
end

/*
 * Begin Transaction
 */
 
begin transaction

/*
 * Insert Control Group Item if needed
 */
 
if @control_group_item_id = 0 or @control_group_item_id is null
begin

    /*
     * Get Desc
     */
     
    select  @control_group_item_desc = isnull(@application_name + ' - ' + convert(varchar(8000),control_item_desc), '')
    from    control_items
    where   control_item = @control_item
    
    select  @error = @@error
    if @error != 0
    begin
        select  @error = 50000
        select  @err_msg = 'Error:  Cannot determine if my_pod already exists.'
        goto rollbackerror
    end

    /*
     * Get new sequence number
     */
     
    execute @error = p_get_sequence_number 'control_group_item', 5, @control_group_item_id OUTPUT
    if (@error !=0)
        goto rollbackerror
       

    /*
     * Insert Record
     */
     
    insert into control_group_item
    (control_item,
     control_group,
     control_group_item,
     application_name,
     control_group_item_desc) values
    (@control_item,
     34, -- my_pods group
     @control_group_item_id,
     @application_name,
     @control_group_item_desc)       
       
    select  @error = @@error
    if @error != 0
        goto rollbackerror
end
    
    
/*
 * If there are no control_security_users/control_security_groups 
 * for this control_group_item then insert them
 */    
    
if @security_user_count = 0
begin

    select  @employee_name = employee_name
    from    employee
    where   login_id = @login_name
    
    select  @error = @@error
    if @error != 0
        goto rollbackerror

    insert into control_security_users
    (login_id,
     full_name,
     access_allowed,
     control_group_item
    ) values
    (@login_name,
     @employee_name,
     'Y',
     @control_group_item_id
    )
    
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
