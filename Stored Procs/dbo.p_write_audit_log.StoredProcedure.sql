/****** Object:  StoredProcedure [dbo].[p_write_audit_log]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_write_audit_log]
GO
/****** Object:  StoredProcedure [dbo].[p_write_audit_log]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_write_audit_log]  @action_type varchar(10), 
                               @table_name varchar(40),
                               @column_name varchar(30),
                               @old_data    varchar(50),
                               @new_data    varchar(50),
                               @comments    varchar(255)
                               as                              
 
/* Proc name:   p_write_audit_log
 * Author:      Victoria tyshchenko
 * Date:        09/03/2004
 * Description: Writes into audit_log table
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date:   Mar 09 2004 17:03:22  $ 
 * $Author:   vtyshchenko  $ 
 * $Revision:   1.0  $
 * $Workfile:   write_audit_log.sql  $
 *
*/ 
 set nocount on 

declare @error                  int,
        @err_msg                varchar(150)
 
select @error = 0 


 
insert into audit_log ( employee_id, action_type, action_date, table_name, column_name, old_data, new_data, comments)
values ( substring(suser_sname(),1, 20), @action_type, getdate() , @table_name, @column_name, @old_data, @new_data, substring(@comments, 1, 255))

select @error = @@error
        
if @error >= 50000
    begin
       raiserror (@err_msg, 16, 1)        
       return -1
    end
        
if @error <> 0
    return -100
    
return 0
GO
