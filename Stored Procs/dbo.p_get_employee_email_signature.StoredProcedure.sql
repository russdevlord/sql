/****** Object:  StoredProcedure [dbo].[p_get_employee_email_signature]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_get_employee_email_signature]
GO
/****** Object:  StoredProcedure [dbo].[p_get_employee_email_signature]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_get_employee_email_signature]  @user_id            varchar(40),
                                            @signature_type     varchar(5),
                                            @sign_line1         varchar(100) OUTPUT,
                                            @sign_line2         varchar(100) OUTPUT,
                                            @sign_line3         varchar(100) OUTPUT,
                                            @sign_line4         varchar(100) OUTPUT,
                                            @sign_line5         varchar(100) OUTPUT,
                                            @sign_line6         varchar(100) OUTPUT,
                                            @sign_line7         varchar(100) OUTPUT,
                                            @sign_line8         varchar(100) OUTPUT,
                                            @sign_line9         varchar(100) OUTPUT,
                                            @sign_line10        varchar(100) OUTPUT
as
/* Proc name:   p_get_employee_email_signature
 * Author:      Victoria Tyshchenko
 * Date:        23/03/2004
 * Description: Returns employee/user e-mail signature
                Signature Type = 'REP' for sales reps; 'USER' - FAST users
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date:   Mar 25 2004 11:18:14  $ 
 * $Author:   vtyshchenko  $ 
 * $Revision:   1.1  $
 * $Workfile:   get_employee_email_signature.sql  $
 *
*/ 
set nocount on 

declare @proc_name varchar(30)
select  @proc_name = 'p_get_employee_email_signature'

declare @branch_code char(1),
        @user_email_address varchar(150),
        @user_name      varchar(50)

if @signature_type = 'REP'
    begin
        select @branch_code = branch_code,
               @user_email_address = isnull(email, ''),
               @user_name = rtrim(First_Name) + ' ' + rtrim(last_name)
        from    sales_rep
        where   rep_id = convert(integer, @user_id)
    end

if @signature_type = 'USER'
    begin
        select @branch_code = branch_code,
               @user_email_address = email,
               @user_name = employee_name
        from   employee
        where  login_id = @user_id
    end

-- DYI 2012-10-12 Specific for accounting  
if @signature_type = 'GROUP'
    begin
        select @user_email_address = @user_id + '@valmorgan.com.au',
               @user_name = @user_id,
               @branch_code = 'N'
    end

select @sign_line1 = @user_name
select @sign_line2 = 'Val Morgan Cinema Network' 

select @sign_line3 = address_1 + ' ' + isnull(address_2, ''),
       @sign_line4 = rtrim(town_suburb) + ', ' + state_code + ' ' + postcode,
       @sign_line5 = 'Tel: ' + phone,
       @sign_line6 = 'Fax: ' + fax,
       @sign_line7 = @user_email_address,
       @sign_line8	= (case branch_code when 'Z' then 'http://www.valmorgan.co.nz' else 'http://www.valmorgan.com.au' end),
       @sign_line9	= '' ,
       @sign_line10	= '' 
from branch
where branch_code = @branch_code

return 0
GO
