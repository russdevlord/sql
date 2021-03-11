USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_address_detach_from_xref]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_address_detach_from_xref]  @address_xref_id integer
as
/* Proc name:   p_address_detach_from_xref
 * Author:      Victoria Tyshchenko
 * Date:        17/7/2004
 * Description: SP deletes address_xref records
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date:   Aug 17 2004 16:53:58  $ 
 * $Author:   vtyshchenko  $ 
 * $Revision:   1.0  $
 * $Workfile:   address_detach_from_xref.sql  $
 *
*/ 

declare @proc_name  varchar(30),
        @err_msg    varchar(250),
        @error      integer
        
select  @proc_name = 'p_address_detach_from_xref'

begin transaction

delete from address_xref
where address_xref_id = @address_xref_id

select @error = @@error
if @error != 0
     goto error

commit transaction

return 0

error:
    if @error >= 50000 -- developer generated errors
    begin
        select @err_msg = @proc_name + ': ' + IsNull(@err_msg, 'Error ocurred')
        raiserror (@err_msg, 16, 1)
    end
--    else
--        raiserror ( @error, 16, 1)

    return -100
GO
