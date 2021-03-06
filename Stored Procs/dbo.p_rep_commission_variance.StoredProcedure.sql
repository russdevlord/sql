/****** Object:  StoredProcedure [dbo].[p_rep_commission_variance]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rep_commission_variance]
GO
/****** Object:  StoredProcedure [dbo].[p_rep_commission_variance]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_rep_commission_variance] @rep_id					integer,
                                      @sales_period			datetime,
                                      @nett_business			money	OUTPUT,
									  @comm_amount				money OUTPUT,
                                      @entry_level				money	OUTPUT,
                                      @percentage				money	OUTPUT,
                                      @calculated				money	OUTPUT,
                                      @paid						money	OUTPUT,
									  @billing_paid			money OUTPUT,
                                      @variance					money	OUTPUT
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare @error          		integer,
        @rowcount					integer

-- Calculate the nett commissionable business
select @nett_business = sum(slide_figures.comm_amount)
  from slide_figures,
       slide_campaign
 where slide_campaign.campaign_no = slide_figures.campaign_no and
       slide_figures.rep_id = @rep_id and
       slide_figures.origin_period = @sales_period and
       slide_campaign.campaign_release = 'Y' and
       slide_figures.figure_status <> 'X'

if @nett_business is null
   select @nett_business = 0

-- Calculate the commission released or pending
select @paid = round(sum(payroll_transaction.pay_qty * payroll_transaction.pay_amount), 2)
  from payroll_transaction
 where payroll_transaction.paytran_type = 'C' and  
       payroll_transaction.rep_id = @rep_id and  
       payroll_transaction.origin_period = @sales_period

if @paid is null
   select @paid = 0

-- Get the reps entry level and commission percentage
select @entry_level = payroll.entry_level,
       @percentage = payroll.commission_percentage
  from payroll
 where payroll.rep_id = @rep_id and
       payroll.sales_period = @sales_period

if @entry_level is null
   select @entry_level = 0

if @percentage is null
   select @percentage = 0

-- Calculate the commission that should be paid
if (@nett_business - @entry_level) > 0
begin
   -- Rep has made the entry level and entitled to commission
   select @calculated = round(((@nett_business - @entry_level) * @percentage), 2)
end
else
begin
   select @calculated = 0
end

-- Calculate the nett commissionable business
select @comm_amount = isnull(sum(commission_transaction.comm_amount),0)
  from commission_transaction
 where commission_transaction.rep_id = @rep_id and
       commission_transaction.release_period = @sales_period and
       commission_transaction.status = 'A'

-- Calculate the billing commission released or pending
select @billing_paid = isnull(round(sum(payroll_transaction.pay_qty * payroll_transaction.pay_amount), 2),0)
  from payroll_transaction
 where payroll_transaction.paytran_type = 'L' and  
       payroll_transaction.rep_id = @rep_id and  
       payroll_transaction.origin_period = @sales_period

-- Calculate the commission variance
select @variance = (@calculated - @paid) + (@comm_amount - @billing_paid)

return 0
GO
