USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_audit_proc_on]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_audit_proc_on]      @proc_name     varchar(30)
as
/* Proc name:   p_audit_proc_on
 * Author:      Grant Carlson
 * Date:        24/9/2003
 * Description: Used as a flag for audit code in procs
 *
 * Changes:
*/ 


return 1
GO
