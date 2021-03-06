/****** Object:  StoredProcedure [dbo].[p_eom_statrev_periods]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_statrev_periods]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_statrev_periods]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_eom_statrev_periods]		@accounting_period		datetime

as

declare			@error		int

set nocount on

begin transaction

delete statrev_campaign_periods where datepart(mm,end_date) <> 6 and datepart(mm, end_date) <> 12 
and campaign_no in (select campaign_no from film_campaign where start_date <= @accounting_period and end_date > @accounting_period
)

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting interim non 6 monthly statutory revenue cutoff periods', 16, 1)
	rollback transaction
	return -1
end


insert into statrev_campaign_periods select campaign_no, @accounting_period from film_campaign where start_date <= @accounting_period and end_date > @accounting_period
and campaign_no not in (select campaign_no from statrev_campaign_periods where end_date = @accounting_period)

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting statutory revenue cutoff periods', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
