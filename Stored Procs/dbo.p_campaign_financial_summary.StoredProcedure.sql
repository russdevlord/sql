/****** Object:  StoredProcedure [dbo].[p_campaign_financial_summary]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_financial_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_financial_summary]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_campaign_financial_summary] @campaign_no		char(7),
                                         @run_date			datetime,
                                         @mode				char(1)
as
set nocount on 
/*
 * Declare Variables
 */

declare  @start_date				datetime,
			@end_date				datetime,
			@gross_value			money,
			@nett_value				money,    
			@weekly_rate			money,    
			@current_due_date		datetime,
			@balance_forward		money,
			@total_payment			money,
			@month_payment			money,
			@nett_billed			money,
			@nett_unbilled			money,
			@gross_billed			money,
			@gross_unbilled		money,
			@original_period		integer,
			@minimum_period		integer,
			@bonus_weeks			integer,
			@suspended_weeks		integer,
			@weeks_to_suspend		integer,
			@billing_credits		integer,
			@suspension_credits	integer,
			@weeks_billed			integer,
			@weeks_to_bill			integer,
			@weeks_cancelled		integer,
			@billed_to_date		datetime,
			@balance_credit		money,
			@balance_current		money,
			@balance_30				money,
			@balance_60				money,
			@balance_90				money,
			@balance_120			money,
			@authorised_credits	money,
			@billing_cred_amnt	money,
         @branch_code			char(2),
         @gst_rate				decimal(6,4)

/*
 *	Select campaign details
 */

select @start_date      = start_date,
		 @end_date        = dateadd(dd, ((min_campaign_period + bonus_period) * 7) - 1, start_date),
		 @gross_value     = isnull(gross_contract_value,0),
		 @nett_value      = isnull(nett_contract_value,0),
		 @original_period = orig_campaign_period,
		 @minimum_period  = min_campaign_period,
       @balance_credit  = isnull(balance_credit,0),
       @balance_current = isnull(balance_current,0),
       @balance_30      = isnull(balance_30,0),
       @balance_60      = isnull(balance_60,0),
       @balance_90      = isnull(balance_90,0),
       @balance_120     = isnull(balance_120,0),
       @bonus_weeks     = bonus_period,
       @branch_code		= branch_code
  from slide_campaign
 where campaign_no = @campaign_no

if @end_date < @start_date
begin
	select @end_date = @start_date
end

if @mode = 'F'
begin

	/*
    * Get GST Rate
    */

	select @gst_rate = c.gst_rate
     from branch b,
          country c
    where b.branch_code = @branch_code and
          b.country_code = c.country_code

	/*
    * Calculate Weekly Rate
    */

	if @original_period = 0
		select @weekly_rate = 0
	else
		select @weekly_rate = @nett_value / @original_period

	/*
	 *	Select Details from Statement Records
	 */
	
	select @current_due_date = due_date,
			 @balance_forward = balance_forward
	  from slide_statement 
	 where campaign_no = @campaign_no and
			 screening_date = (select max(screening_date) 
										from slide_statement
									  where campaign_no = @campaign_no)

	/*
	 *	Select details from transaction records
	 */
	
	select @total_payment = isnull(sum(gross_amount),0)
	  from slide_transaction
	 where campaign_no = @campaign_no and
			 tran_category = 'C'
	
	select @month_payment = isnull(sum(gross_amount),0)
	  from slide_transaction
	 where campaign_no = @campaign_no and
			 tran_category = 'C' and
			 statement_id is null

	select @nett_billed = isnull(sum(nett_rate),0),
			 @gross_billed = isnull(sum(gross_rate),0)
	  from slide_campaign_spot
	 where campaign_no = @campaign_no and
			 billing_status = 'B' 

	select @weeks_cancelled = count(*)
	  from slide_campaign_spot
	 where campaign_no = @campaign_no and
			 billing_status = 'X'

	select @billed_to_date = dateadd(dd,6,screening_date)
	  from slide_campaign_spot
	 where campaign_no = @campaign_no and
			 spot_no = (select max(spot_no)
							  from slide_campaign_spot
							 where campaign_no = @campaign_no and
									 ( billing_status = 'B' or
									   billing_status = 'C') )
end

/*
 * Calculate Suspensions
 */

select @suspended_weeks = count(*)
  from slide_campaign_spot
 where campaign_no = @campaign_no and
       spot_status = 'S' and 
		 screening_date <= @run_date

select @weeks_to_suspend = count(*)
  from slide_campaign_spot
 where campaign_no = @campaign_no and
       spot_status = 'S' and 
		 screening_date > @run_date

/*
 * Calculate Billing Credits
 */

select @billing_credits = count(*)
  from slide_campaign_spot
 where campaign_no = @campaign_no and
		 spot_status <> 'S' and
		 billing_status = 'C'	 	 

select @suspension_credits = count(*)
  from slide_campaign_spot
 where campaign_no = @campaign_no and
		 spot_status = 'S' and
		 billing_status = 'C'

/*
 * Calculate Weeks to Bill
 */

select @weeks_to_bill = count(*),
       @nett_unbilled = isnull(sum(nett_rate),0),
       @gross_unbilled = isnull(sum(gross_rate),0)
  from slide_campaign_spot
 where campaign_no = @campaign_no and
	  ( billing_status = 'L' or
       billing_status = 'U' ) and
       spot_type <> 'B'

select @weeks_billed = @minimum_period - @weeks_to_bill

/*
 * Calculate Authorised Credits
 */
	
select @authorised_credits = isnull(sum(credit_value),0)
  from slide_campaign_spot
 where campaign_no = @campaign_no and 
		 billing_status <> 'C' and 
		 credit_value > 0 

select @billing_cred_amnt = isnull(sum(credit_value),0)
  from slide_campaign_spot
 where campaign_no = @campaign_no and 
		 billing_status = 'C' and 
		 credit_value > 0 

/*
 * Return Dataset
 */

select   @start_date 			as start_date,
			@end_date 				as end_date,
			@gross_value 			as gross_value,
			@nett_value 			as nett_value,
			@weekly_rate 			as weekly_rate,
			@current_due_date 	as current_due_date,
			@month_payment 		as month_payment,
			isnull(@balance_forward,0)	as balance_forward,
			@nett_billed			as nett_billed,
			@nett_unbilled			as nett_unbilled,
			@gross_billed			as gross_billed,
			@gross_unbilled		as gross_unbilled,
			@original_period 		as original_period,
			@minimum_period 		as minimum_period,
			@bonus_weeks 			as bonus_weeks,
			@suspended_weeks 		as suspended_weeks,
			@weeks_to_suspend 	as weeks_to_suspend,
			@suspension_credits 	as suspension_credits,
			@billing_credits 		as billing_credits,
			@weeks_billed 			as weeks_billed,
			@weeks_to_bill 		as weeks_to_bill,
			@billed_to_date		as billed_to_date,
  			@balance_credit		as balance_credit,
			@balance_current		as balance_current,
			@balance_30				as balance_30,
			@balance_60				as balance_60,
			@balance_90				as balance_90,
			@balance_120			as balance_120,
			@authorised_credits  as authorised_credits,
			@billing_cred_amnt	as billing_credit_amnt,
         @total_payment			as total_payments,
         @gst_rate				as gst_rate

return 0
GO
