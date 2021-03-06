/****** Object:  StoredProcedure [dbo].[p_figure_discrepancy_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_figure_discrepancy_report]
GO
/****** Object:  StoredProcedure [dbo].[p_figure_discrepancy_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_figure_discrepancy_report] 	@campaign_no		integer
as

/*
 * Declare Variables
 */

declare  @errorode		integer,
         @error         integer,
         @rowcount	integer,
	@campaign_status	char(1),
	@film_plan_id		integer,
	@maximum_value		money,
	@maximum_spend		money,
	@maximum_figure_spend	money,
	@current_value		money,
	@current_spend		money,
	@figure_spend		money,
	@plan_status		char(1),
	@scheduled_spot_figures	money,
	@standby_spot_figures	money,
	@inclusion_figures	money,
	@standby_schedule_figures	money,
	@standby_remaining_figures	money,
	@actual_figures			money,
	@adjustment_figures		money,
	@released_figures		money,
	@pending_figures		money,
	@branch_code			char(2),
	@product_desc			varchar(100),
	@comm_rate			numeric(6,4),
	@first_name			varchar(50),
	@last_name			varchar(50),
	@billing_credit			money,
	@figure_exempt			char(1)


/*
 * Initialise Variables
 */

  select @scheduled_spot_figures = 0,
			@standby_spot_figures = 0 ,
			@inclusion_figures = 0,
			@standby_schedule_figures = 0,
			@standby_remaining_figures = 0,
			@actual_figures= 0,
			@adjustment_figures = 0,
			@released_figures = 0,
			@pending_figures = 0	

/*
 * Get Campaign Status
 */

select @campaign_status = campaign_status
  from film_campaign
 where campaign_no = @campaign_no

/*
 * Get Campaign Figure Exempt
 */

select @figure_exempt = figure_exempt
  from film_campaign
 where campaign_no = @campaign_no

/*
 * Get the scheduled_spot_cost
 */

if @campaign_status = 'Z' 
begin
	select @scheduled_spot_figures = isnull(campaign_cost, 0)
	  from film_campaign
	 where campaign_no = @campaign_no
end
else
begin
	select @scheduled_spot_figures = isnull(sum(charge_rate), 0)
	  from campaign_spot 
	 where campaign_no = @campaign_no and 
			 spot_type <> 'Y' and
			 spot_type <> 'M' and
			 spot_type <> 'V'
end

/*
 * Get the inclusion figure amount
 */

select @inclusion_figures = isnull(sum(figure_value), 0)
  from film_track
 where campaign_no = @campaign_no and
		 include_value_cost = 'Y'

/*
 * Get the actual figures for this campaign
 */

select @released_figures = isnull(sum(nett_amount),0)
  from film_figures
 where campaign_no = @campaign_no and
		 figure_status = 'R'


select @pending_figures = isnull(sum(nett_amount),0)
  from film_figures
 where campaign_no = @campaign_no and
		 figure_status = 'P'

/*
 * Get the adjustment cost
 */

select @adjustment_figures = isnull(sum(nett_amount),0)
  from campaign_transaction
 where campaign_no = @campaign_no and
		 tran_type = 10 or  -- bad bebt
		 tran_type = 4      -- authorised credit

select @billing_credit = isnull(sum(nett_amount),0)
  from campaign_transaction
 where campaign_no = @campaign_no and
		 tran_type = 1 and
		 nett_amount < 0

select @adjustment_figures = @adjustment_figures + @billing_credit

/*
 * Loop the plans
 */
 declare film_plan_csr cursor static for
  select film_plan_id,
	   maximum_value,
	   maximum_spend,
	   maximum_figure_spend,
	   current_value,
	   current_spend,
	   figure_spend,
	   plan_status    
    from film_plan
	where campaign_no = @campaign_no
order by film_plan_id


open film_plan_csr
fetch film_plan_csr into @film_plan_id, @maximum_value, @maximum_spend, @maximum_figure_spend, @current_value, @current_spend, @figure_spend, @plan_status	
while(@@fetch_status = 0)
begin

	if @current_spend <= @maximum_figure_spend
		select @standby_spot_figures = @standby_spot_figures + @current_spend
	else
		select @standby_spot_figures = @standby_spot_figures + @maximum_figure_spend


	if(@plan_status = 'A')
	begin
		if ( @standby_spot_figures <= @figure_spend)
			select @standby_remaining_figures = @standby_remaining_figures - @standby_spot_figures + @figure_spend
	end
	
	/*
    * Fetch Next
    */

	fetch film_plan_csr into @film_plan_id, @maximum_value, @maximum_spend, @maximum_figure_spend, @current_value, @current_spend, @figure_spend, @plan_status

end

close film_plan_csr
deallocate film_plan_csr

/*
 * Calculate Variance
 */

if((@released_figures + @pending_figures) = (@scheduled_spot_figures + @standby_spot_figures + @inclusion_figures + @standby_remaining_figures + @adjustment_figures))
	select null,
			 null,
			 null,
			 null,
			 null,
			 null,
			 null,
			 null,
			 null,
			 null,
			 null,
			 null,
			 null

if @figure_exempt = 'Y'
	select null,
			 null,
			 null,
			 null,
			 null,
			 null,
			 null,
			 null,
			 null,
			 null,
			 null,
			 null,
			 null

/*
 * Get Campaign Information
 */

select @branch_code = fc.branch_code,
		 @product_desc = fc.product_desc,
		 @first_name = rep.first_name,
		 @last_name = rep.last_name,
		 @comm_rate = fc.commission
  from film_campaign fc,
		 sales_rep rep
 where fc.campaign_no = @campaign_no and
		 fc.rep_id = rep.rep_id

/*
 * Return Dataset
 */

select @campaign_no,
		 @product_desc,
		 @branch_code,
		 @comm_rate,
		 @first_name,
		 @last_name,
		 @released_figures,
		 @pending_figures,
		 @scheduled_spot_figures,
		 @standby_spot_figures,
		 @inclusion_figures,
		 @standby_remaining_figures,
		 @adjustment_figures

/*
 * Return Success
 */

return 0
GO
