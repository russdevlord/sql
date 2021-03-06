/****** Object:  StoredProcedure [dbo].[p_film_campaign_figure_status]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_figure_status]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_figure_status]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_film_campaign_figure_status] @campaign_no			integer,
                                          @return_mode			char(1),
                                          @released_figs			money 		OUTPUT,
                                          @pending_figs			money			OUTPUT,
                                          @scheduled_cost		money			OUTPUT,
                                          @standby_cost			money			OUTPUT,
                                          @standby_spent			money			OUTPUT
as

/*
 * Declare Variables
 */

declare @error						integer,
        @rowcount					integer,
        @errorode						integer,
        @plan_id					integer,
        @released					money,
        @pending					money,
        @billed 					money,
        @commission				money,
        @tobill 					money,
        @baddebts					money,
        @bill_tot					money,
        @figure_spend			money,
        @maximum_figure_spend	money,
        @current_spend			money,
        @actual_spend			money,
        @plan_amount				money,
        @plan_tot					money,
        @spend_tot				money,
        @plan_status				char(1)



/*
 * Initialise Variables
 */

select @released = 0,
       @pending = 0,
       @billed = 0,
       @tobill = 0,
       @baddebts = 0,
       @plan_amount = 0,
       @spend_tot = 0,
       @plan_tot = 0

/*
 * Calculate Currently Released Figures
 */

select @released = sum(nett_amount)
  from film_figures
 where campaign_no = @campaign_no and
       figure_status = 'R'

select @released = isnull(@released,0)

/*
 * Calculate Currently Pending Figures
 */

select @pending = sum(nett_amount)
  from film_figures
 where campaign_no = @campaign_no and
       figure_status = 'P'

select @pending = isnull(@pending,0)

/*
 * Calculate Transaction Totals
 */

select @billed = sum(nett_amount)
  from campaign_transaction
 where campaign_no = @campaign_no and
       tran_category = 'B'

select @billed = isnull(@billed,0)

select @commission = 0

select @baddebts = sum(ta.alloc_amount)
  from campaign_transaction ct,
       transaction_allocation ta
 where ct.campaign_no = @campaign_no and
       ct.tran_category = 'D' and
       ct.tran_id = ta.from_tran_id and
       ta.alloc_amount <> 0
       
select @baddebts = isnull(@baddebts,0)

/***************************
 * Calculate Billing Total *
 ***************************/

select @bill_tot = @billed + @commission + @baddebts

/*************************
 * Calculate Spot Totals *
 *************************/

select @tobill = sum(charge_rate)
  from campaign_spot
 where campaign_no = @campaign_no and
       tran_id is null

select @tobill = isnull(@tobill,0)

/*
 * Cursor - Film Plans
 */

 declare plan_csr cursor static for 
  select film_plan_id,
         plan_status,
         figure_spend,
			current_spend,
			maximum_figure_spend
	 from film_plan
   where campaign_no = @campaign_no
order by film_plan_id
     for read only
/*
 * Calculate Plan Values
 */

open plan_csr
fetch plan_csr into @plan_id, @plan_status, @figure_spend, @current_spend, @maximum_figure_spend
while (@@fetch_status=0)
begin

	select @spend_tot = @spend_tot + @current_spend

	if(@current_spend <= @maximum_figure_spend)
		select @plan_amount = @current_spend
	else
		select @plan_amount = @maximum_figure_spend

	if(@plan_amount <= @figure_spend)
		select @plan_amount = @figure_spend

	select @plan_tot = @plan_tot + @plan_amount

	/*
    * Fetch Next
    */

	fetch plan_csr into @plan_id, @plan_status, @figure_spend, @current_spend, @maximum_figure_spend

end
close plan_csr
deallocate plan_csr

/******************************
 * Finalise Calculated Values *
 ******************************/

select @released_figs = @released,
       @pending_figs = @pending,
       @scheduled_cost = @bill_tot + @tobill - @spend_tot,
       @standby_cost = @plan_tot,
       @standby_spent = @spend_tot

/*
 * Return Dataset
 */

if(@return_mode = 'D')
	select @released_figs,
          @pending_figs,
          @scheduled_cost,
          @standby_cost,
          @standby_spent

/*
 * Return Success
 */

return 0
GO
