/****** Object:  StoredProcedure [dbo].[p_get_employee_email_address]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_get_employee_email_address]
GO
/****** Object:  StoredProcedure [dbo].[p_get_employee_email_address]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_get_employee_email_address]  @user_id          varchar(40),
                                          @address_type     varchar(5),
                                          @email_address    varchar(100) OUTPUT
as
/* Proc name:   p_get_employee_email_address
 * Author:      Victoria Tyshchenko
 * Date:        23/03/2004
 * Description: Returns employee/user e-mail address
                E Address Type = 'REP' for sales reps; 'USER' - FAST users
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date:   Apr 07 2004 17:18:14  $ 
 * $Author:   vtyshchenko  $ 
 * $Revision:   1.1  $
 * $Workfile:   get_employee_email_address.sql  $
 *
*/ 

set nocount on 

declare @proc_name varchar(30)
select  @proc_name = 'p_get_employee_email_address'

declare @branch_code char(1),
        @user_name      varchar(50)

if @address_type = 'REP'
    begin
        select @email_address = isnull(email, '')
        from    sales_rep
        where   rep_id = convert(integer, @user_id)
    end

if @address_type = 'USER'
    begin
        select @email_address = @user_id + '@valmorgan.com.au'
        from   employee
        where  login_id = @user_id
    end

if @address_type = 'GROUP'
    begin
        select @email_address = @user_id + '@valmorgan.com.au'
    end

return 0
GO
