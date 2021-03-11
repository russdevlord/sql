USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_vm_br_get_previous_acc_per]    Script Date: 11/03/2021 2:30:35 PM ******/
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
