/****** Object:  StoredProcedure [dbo].[p_duplicate_film_campaign]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_duplicate_film_campaign]
GO
/****** Object:  StoredProcedure [dbo].[p_duplicate_film_campaign]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_duplicate_film_campaign] @old				integer,
                                 	  @new_branch		char(2)
as

/*
 * Declare Variables
 */
 
declare @error							integer,
        @errorode							integer,
        @new							integer,
		@wb_liability_id			    integer,
		@origin_campaign		    	integer,
		@parent_campaign			    integer,
		@original_figure_id		        integer,
		@source_figure_id			    integer, 
		@liability_amount			    money,
  		@entry_date 					datetime,
		@smi_report_group_id			int

/*
 * Begin Transaction
 */

set nocount on

begin transaction

/*
 * Get Transaction Allocation Id
 */

execute @errorode = p_film_campaign_number @new_branch, 1, @new OUTPUT
if (@errorode !=0)
begin
	rollback transaction
	raiserror ('Unable to get campaign_no', 16, 1)
	return -1
end

/*
 * Copy Campaign
 */

insert into film_campaign ( 
	campaign_no,
    product_desc,
    revision_no,
    branch_code,
    business_unit_id,
    rep_id,
    delivery_branch,
    campaign_status,
    cinelight_status,
    inclusion_status,
    outpost_status,
    campaign_type,
    campaign_category,
    includes_media,
    includes_cinelights,
    includes_infoyer,
    includes_miscellaneous,
    includes_follow_film,
    includes_premium_position,
    includes_gold_class,
    includes_retail,
    agency_deal,
    commission,
    gst_exempt,
    agency_id,
    billing_agency,
    reporting_agency,
    client_id,
    client_product_id,
    onscreen_account_id,
    cinelight_account_id,
    outpost_account_id,
    contact,
    phone,
    fax,
    email,
    prop_status,
    commments,
    display_value,
    confirmed_date,
    billing_start_date,
    start_date,
    end_date,
    makeup_deadline,
    expired_date,
    closed_date,
    campaign_expiry_idc,
    figure_exempt,
    contract_received,
    cinelight_contract_received,
    attendance_analysis,
    allow_market_makeups,
    allow_pack_clashing,
    entry_date,
    campaign_budget,
    exclude_system_revision,
    test_campaign,
    standby_value,
    confirmed_cost,
    confirmed_value,
    campaign_cost,
    campaign_value,
    closing_cost,
    our_share,
    balance_credit,
    balance_outstanding,
    balance_current,
    balance_30,
    balance_60,
    balance_90,
    balance_120,
    outpost_contract_received  )
select     @new,
    product_desc,
    revision_no,
    @new_branch,
    business_unit_id,
    rep_id,
    delivery_branch,
    'P',
    'P',
    'P',
    'P',
    campaign_type,
    campaign_category,
    includes_media,
    includes_cinelights,
    includes_infoyer,
    includes_miscellaneous,
    includes_follow_film,
    includes_premium_position,
    includes_gold_class,
    includes_retail,
    agency_deal,
    commission,
    gst_exempt,
    agency_id,
    billing_agency,
    reporting_agency,
    client_id,
    client_product_id,
    onscreen_account_id,
    cinelight_account_id,
    outpost_account_id,
    contact,
    phone,
    fax,
    email,
    prop_status,
    commments,
    display_value,
    confirmed_date,
    billing_start_date,
    start_date,
    end_date,
    makeup_deadline,
    expired_date,
    closed_date,
    campaign_expiry_idc,
    figure_exempt,
    contract_received,
    cinelight_contract_received,
    attendance_analysis,
    allow_market_makeups,
    allow_pack_clashing,
    entry_date,
    campaign_budget,
    exclude_system_revision,
    test_campaign,
    standby_value,
    confirmed_cost,
    confirmed_value,
    campaign_cost,
    campaign_value,
    closing_cost,
    our_share,
    balance_credit,
    balance_outstanding,
    balance_current,
    balance_30,
    balance_60,
    balance_90,
    balance_120,
    outpost_contract_received  
  from film_campaign
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to insert new campaign record', 16, 1)
	return -1
end	



	
/*
 * Return New Campaign No
 */

select @old, @new

/*
 * Commit and Return
 */

commit transaction
return 0
GO
