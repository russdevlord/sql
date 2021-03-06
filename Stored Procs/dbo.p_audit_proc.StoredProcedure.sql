/****** Object:  StoredProcedure [dbo].[p_audit_proc]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_audit_proc]
GO
/****** Object:  StoredProcedure [dbo].[p_audit_proc]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_audit_proc]      @proc_name     varchar(30),
                              @event         varchar(30)
as
/* Proc name:   p_audit_proc
 * Author:      Grant Carlson
 * Date:        24/9/2003
 * Description: Used as a flag for audit code in procs
 *
 * Changes:
*/ 

return 1

select  case @event
        when 'start' then 'START: ' + @proc_name + ', ' + convert(varchar(30),getdate(),109)
        when 'end' then 'END: ' + @proc_name + ', ' + convert(varchar(30),getdate(),109)
        end

return 1
GO
