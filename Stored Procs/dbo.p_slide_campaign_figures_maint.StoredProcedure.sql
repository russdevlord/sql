/****** Object:  StoredProcedure [dbo].[p_slide_campaign_figures_maint]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_campaign_figures_maint]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_campaign_figures_maint]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_slide_campaign_figures_maint]  @campaign_no		char(7)
as
set nocount on 
declare @error							integer,
		  @inclusion_value			money,
		  @inclusion_cost				money,
		  @inclusion_figures			money
/*
 * Get the inclusion_value
 */

select @inclusion_value = isnull(sum(track_qty * track_unit_cost), 0)
  from slide_track
 where campaign_no = @campaign_no and
		 include_value_cost = 'Y'

/*
 * Get the inclusion_cost
 */

select @inclusion_cost = isnull(sum(track_qty * track_charge), 0)
  from slide_track
 where campaign_no = @campaign_no and
		 include_value_cost = 'Y'

/*
 * Get the inclusion figure amount
 */

select @inclusion_figures = isnull(sum(figure_value), 0)
  from slide_track
 where campaign_no = @campaign_no 


/*
 * Select dataset and return
 */
 
  SELECT slide_campaign.campaign_no,   
         slide_campaign.campaign_code,   
         slide_campaign.name_on_slide,   
         slide_campaign.sort_key,   
         slide_campaign.signatory,   
         slide_campaign.contact,   
         slide_campaign.phone,   
         slide_campaign.branch_code,   
         slide_campaign.campaign_status,   
         slide_campaign.campaign_type,   
         slide_campaign.campaign_category,   
         slide_campaign.credit_status,   
         slide_campaign.credit_avail,   
         slide_campaign.cancellation_code,   
         slide_campaign.is_official,   
         slide_campaign.is_closed,   
         slide_campaign.is_archived,   
         slide_campaign.contract_rep,   
         slide_campaign.business_group,   
         slide_campaign.service_rep,   
         slide_campaign.credit_controller,   
         slide_campaign.credit_manager,   
         slide_campaign.credit_cut_off,   
         slide_campaign.agency_deal,   
         slide_campaign.agency_id,   
         slide_campaign.client_id,   
         slide_campaign.industry_category,   
         slide_campaign.billing_cycle,   
         slide_campaign.start_date,   
         slide_campaign.branch_release,   
         slide_campaign.npu_release,   
         slide_campaign.ho_release,   
         slide_campaign.campaign_release,   
         slide_campaign.gross_contract_value,   
         slide_campaign.nett_contract_value,   
         slide_campaign.comm_contract_value,   
         slide_campaign.actual_contract_value,   
         slide_campaign.orig_campaign_period,   
         slide_campaign.min_campaign_period,   
         slide_campaign.bonus_period,   
         slide_campaign.discount,   
         slide_campaign.balance_credit,   
         slide_campaign.balance_current,   
         slide_campaign.balance_30,   
         slide_campaign.balance_60,   
         slide_campaign.balance_90,   
         slide_campaign.balance_120,   
         slide_campaign.balance_outstanding,   
         slide_campaign.rent_distribution_method,   
         slide_campaign.deposit,   
         slide_campaign.gst_exempt,   
         slide_campaign.screening_offsets,   
         slide_campaign.campaign_notes,   
         slide_campaign.official_period,   
         slide_campaign.payroll_rep,   
         slide_campaign.campaign_entry,   
         slide_campaign.request_accepted,   
         slide_campaign.artwork_completed,   
         slide_campaign.artwork_approved,   
         slide_campaign.billing_commission,   
         slide_campaign.comm_rate,   
         slide_campaign.comm_threshold,   
         slide_campaign.timestamp,
			@inclusion_value,
		   @inclusion_cost,
		   @inclusion_figures,
         slide_campaign.gross_total_value,   
         slide_campaign.nett_total_value,   
         slide_campaign.comm_total_value,   
         slide_campaign.actual_total_value
    FROM slide_campaign  
   WHERE slide_campaign.campaign_no = @campaign_no


return 0
GO
