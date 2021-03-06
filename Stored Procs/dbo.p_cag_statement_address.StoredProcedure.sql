/****** Object:  StoredProcedure [dbo].[p_cag_statement_address]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_statement_address]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_statement_address]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_statement_address]  @mode int                            
as
/* Proc name:   p_cag_statement_address
 * Author:      Victoria Tyshchenko
 * Date:        22 March, 2004
 * Description: Retrievs address line for cinema agreement rent statements
 *
 * @MODE is CINEMA AGREEMENT #
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date:   Jul 08 2004 11:23:38  $ 
 * $Author:   vtyshchenko  $ 
 * $Revision:   1.2  $
 * $Workfile:   cag_statement_address.sql  $
 *
*/ 

declare @proc_name varchar(30)
select  @proc_name = 'p_cag_statement_address'
--exec    p_audit_proc @proc_name,'start' 

declare @country        varchar(20),      
        @address_1      varchar(50),   
        @address_2      varchar(50),   
        @address_3      varchar(50),   
        @address_4      varchar(50),   
        @address_5      varchar(50),   
        @error          int,
        @err_msg        varchar(100),
        @currency_code  varchar(3),
        @line1          varchar(70),
        @line2          varchar(70),
        @line3          varchar(70),
        @line4          varchar(70)


select  @currency_code = currency_code
from    cinema_agreement
where   cinema_Agreement_id = @mode

select @error = @@error
  if @error != 0
        goto error

          
if @currency_code = 'NZD'
      SELECT @address_1 = branch_address.address_1,   
             @address_2 = branch_address.address_2,   
             @address_3 = branch_address.address_3,
             @address_4 = branch_address.address_4,
             @address_5 = branch_address.address_5,
             @country   = country_name
        FROM branch_address, country, branch  
    where branch.branch_code = branch_address.branch_code    
          and branch.country_code = country.country_code 
          and branch_address.branch_code = 'Z'
          and branch_address.address_category = 'SRA'
 else
      SELECT @address_1 = branch_address.address_1,   
             @address_2 = branch_address.address_2,   
             @address_3 = branch_address.address_3,
             @address_4 = branch_address.address_4,
             @address_5 = branch_address.address_5,
             @country   = country_name
        FROM branch_address, country, branch  
    where branch.branch_code = branch_address.branch_code    
          and branch.country_code = country.country_code 
          and branch_address.branch_code = 'N'
          and branch_address.address_category = 'SRA'
 
select @error = @@error
  if @error != 0
        goto error

select @address_1 = @address_2

if @currency_code = 'NZD'
    select @address_2 = @address_3 
else
    select @address_2 = @address_3 + ' ' + @country    
    
select @address_3 = 'Telephone:' + ' ' + @address_4

select @address_4 = 'Facsimile:' + ' ' + @address_5

if @currency_code = 'NZD'
    begin
        select @line1 = 'Val Morgan Cinema Advertising (NZ) Limited'
        select @line2 = 'A Division of Val Morgan Holdings Pty Ltd'
        select @line3 = ''
        select @line4 = 'www.valmorgan.co.nz'
    end
else
    begin
        select @line1 = 'Val Morgan & Co (Aust) Pty Ltd'
        select @line2 = 'ABN 28 004 806 857'
        select @line3 = 'A Division of Val Morgan Holdings Pty Ltd'
        select @line4 = 'www.valmorgan.com.au'
    end



select @address_1 'address_1', @address_2 'address_2', @address_3 'address_3', @address_4 'address_4',
       @line1 'line1', @line2 'line2', @line3 'line3', @line4 'line4' 

--exec p_audit_proc @proc_name,'end'
return 0

error:
if @error >= 50000 -- developer generated errors
    begin
        select @err_msg = @proc_name + ': ' + @err_msg
        raiserror (@err_msg, 16, 1)
    end
--else
--    raiserror ( 'Error', 16, 1) 
    

return -100
GO
