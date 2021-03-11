/****** Object:  StoredProcedure [dbo].[p_audit_proc_on]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_audit_proc_on]
GO
/****** Object:  StoredProcedure [dbo].[p_audit_proc_on]    Script Date: 12/03/2021 10:03:49 AM ******/
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
