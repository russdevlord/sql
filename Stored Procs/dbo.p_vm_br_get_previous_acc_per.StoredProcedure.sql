/****** Object:  StoredProcedure [dbo].[p_vm_br_get_previous_acc_per]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_vm_br_get_previous_acc_per]
GO
/****** Object:  StoredProcedure [dbo].[p_vm_br_get_previous_acc_per]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_vm_br_get_previous_acc_per]    @end_date       datetime

as

select  max(end_date)
from    accounting_period
where   end_date < @end_date


return 0
GO
