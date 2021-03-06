/****** Object:  StoredProcedure [dbo].[p_change_film_campaign_no]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_change_film_campaign_no]
GO
/****** Object:  StoredProcedure [dbo].[p_change_film_campaign_no]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_change_film_campaign_no] @old				integer,
                                 			  @new_branch		char(2),
                                 			  @new				integer OUTPUT
as

/*
 * Declare Variables
 */
 
declare @error							integer,
        @errorode							integer,
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
    reporting_client,
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
    reporting_client,
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
 * Redirect Campaign Package
 */

update campaign_package
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update campaign package', 16, 1)
	return -1
end	

/*
 * Redirect Campaign Package
 */

update film_campaign_standalone_invoice
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update campaign package', 16, 1)
	return -1
end	


/*
 * Redirect Statutory Revenue Camapign Avg Rates
 */

update statrev_campaign_rates
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update statrev_campaign_rates ', 16, 1)
	return -1
end	


/*
 * Redirect Statutory Revenue Camapign Avg Rates
 */

update statrev_spot_rates
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update statrev_campaign_rates', 16, 1)
	return -1
end	


/*
 * Redirect Statutory Revenue Camapign Avg Rates
 */

update statrev_campaign_periods
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update statrev_campaign_rates ', 16, 1)
	return -1
end	


/*
 * Redirect Statutory Revenue Camapign Avg Rates
 */

update statrev_campaign_revision
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update statrev_campaign_revision ', 16, 1)
	return -1
end	

/*
 * Redirect Campaign Spots
 */

update campaign_spot
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update campaign spot', 16, 1)
	return -1
end	

/*
 * Redirect Campaign Transactions
 */

update campaign_transaction
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update campaign transaction', 16, 1)
	return -1
end	

/*
 * Redirect Film Campaign Complex
 */

update film_campaign_complex
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_campaign_complex', 16, 1)
	return -1
end	

/*
 * Redirect Film Campaign Events
 */

update film_campaign_event
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_campaign_event', 16, 1)
	return -1
end	

/*
 * Redirect Film Campaign Movie Archive
 */

update film_campaign_movie_archive
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_campaign_movie_archive', 16, 1)
	return -1
end	

/*
 * Redirect Film Campaign Partition
 */

update film_campaign_partition
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_campaign_partition', 16, 1)
	return -1
end	

/*
 * Redirect Film Campaign Pattern
 */

update film_campaign_pattern
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_campaign_pattern', 16, 1)
	return -1
end	

/*
 * Redirect Film Campaign Prints
 */

update film_campaign_print_complex
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_campaign_prints', 16, 1)
	return -1
end	

/*
 * Redirect Film Campaign Prints
 */

update film_campaign_prints
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_campaign_prints', 16, 1)
	return -1
end	

/*
 * Redirect Film Campaign Program
 */

update film_campaign_program
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_campaign_program', 16, 1)
	return -1
end	

/*
 * Redirect smi_report_group_fc_xref
 */

select @smi_report_group_id = smi_report_group_id
from smi_report_group_fc_xref 
 where campaign_no = @old


select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update smi_report_group_fc_xref', 16, 1)
	return -1
end	

update smi_report_group_fc_xref
   set smi_report_group_fc_xref.smi_report_group_id = @smi_report_group_id
 where campaign_no = @new

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update smi_report_group_fc_xref', 16, 1)
	return -1
end	

/*
 * Redirect smi_report_group_fc_xref
 */

delete smi_report_group_fc_xref
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update smi_report_group_fc_xref', 16, 1)
	return -1
end	

/*
 * Redirect Film Campaign Revision
 */

update film_campaign_revision
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_campaign_revision', 16, 1)
	return -1
end	

/*
 * Redirect Film Campaign Spot Archive
 */

update film_campaign_spot_archive
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_campaign_spot_archive', 16, 1)
	return -1
end	

/*
 * Redirect Film Delete Charge
 */

update film_delete_charge
   set parent_campaign = @new
 where parent_campaign = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_delete_charge', 16, 1)
	return -1
end	

/*
 * Redirect Delete Charge
 */

update delete_charge
   set source_campaign = @new
 where source_campaign = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update source delete_charge campaign', 16, 1)
	return -1
end	

update delete_charge
   set destination_campaign = @new
 where destination_campaign = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update destination delete_charge campaign', 16, 1)
	return -1
end	

update delete_charge_spots
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update delete_charge spots', 16, 1)
	return -1
end	

/*
 * Redirect Film Figures
 */

update film_figures
   set campaign_no = @new,
		branch_code = @new_branch
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_figures', 16, 1)
	return -1
end	

/*
 * Redirect Film Plans
 */

update film_plan
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_plan', 16, 1)
	return -1
end	

/*
 * Redirect Film Spot Summary
 */

update film_spot_summary
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_spot_summary', 16, 1)
	return -1
end	

/*
 * Declare Wriateback LIability Cursor
 */

 declare film_wb_liability_csr cursor static for 
  select wb_liability_id,
			origin_campaign,
			parent_campaign,
			original_figure_id,
			source_figure_id, 
			liability_amount,
			entry_date
	 from film_writeback_liability
	where origin_campaign = @old or
			parent_campaign = @old
order by wb_liability_id
     for read only

/*
 * Redirect Film Writeback Liability
 */

open film_wb_liability_csr
fetch film_wb_liability_csr into @wb_liability_id, @origin_campaign, @parent_campaign, @original_figure_id, @source_figure_id, @liability_amount, @entry_date
while(@@fetch_status=0)
begin
	
	delete film_writeback_liability
	 where wb_liability_id = @wb_liability_id

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ('Unable to update film_writeback_liability', 16, 1)
		return -1
	end	

	if @origin_campaign = @old
		select @origin_campaign = @new

	if @parent_campaign = @old
		select @parent_campaign = @new

	
	execute @errorode = p_get_sequence_number 'film_writeback_liability', 5, @wb_liability_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		raiserror ('Unable to update film_writeback_liability', 16, 1)
		return -1
	end

	insert into film_writeback_liability
	(wb_liability_id,
	 origin_campaign,
	 parent_campaign,
	 original_figure_id,
	 source_figure_id,
	 liability_amount,
	 entry_date) values
	(@wb_liability_id,
	 @origin_campaign,
	 @parent_campaign,
	 @original_figure_id,
	 @source_figure_id,
	 @liability_amount,
	 @entry_date)
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ('Unable to update film_writeback_liability', 16, 1)
		return -1
	end	

	fetch film_wb_liability_csr into @wb_liability_id, @origin_campaign, @parent_campaign, @original_figure_id, @source_figure_id, @liability_amount, @entry_date
end
close film_wb_liability_csr
deallocate film_wb_liability_csr

/*
 * Redirect Print Transactions
 */

update print_transactions
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update print_transactions', 16, 1)
	return -1
end	

/*
 * Redirect Statements
 */

update statement
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update statement', 16, 1)
	return -1
end	

/*
 * Redirect Film Track
 */

update film_track
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_track', 16, 1)
	return -1
end	

/*
 * Redirect Film Diary
 */

update film_diary
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_diary', 16, 1)
	return -1
end	

/*
 * Create New Reach Frequency Record
 */

insert into film_reach_frequency ( 
       campaign_no,
       demographic_code,
       reach,
       frequency,
       duration )
select @new,
       demographic_code,
       reach,
       frequency,
       duration
  from film_reach_frequency
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to create new film_reach_frequency', 16, 1)
	return -1
end	

delete film_reach_frequency
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to delete film_reach_frequency', 16, 1)
	return -1
end	

/*
 * Create New Film Revenue Records
 */
 
insert into film_revenue ( 
       campaign_no,
       complex_id,
       country_code,
       product_desc,
       accounting_period,
       origin_period,
       liability_type_id,
       business_unit_id,
       media_product_id,
       currency_code,
       revenue_source,
       spot_amount,
       cinema_amount )
select @new,
       complex_id,
       country_code,
       product_desc,
       accounting_period,
       origin_period,
       liability_type_id,
       business_unit_id,
       media_product_id,
       currency_code,
       revenue_source,
       spot_amount,
       cinema_amount
  from film_revenue
 where campaign_no = @old
      
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to create new film_revenue', 16, 1)
	return -1
end	

delete film_revenue
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to delete film_revenue', 16, 1)
	return -1
end	

/*
 * Create New Actual Cinema Attendance Records
 */
 
insert into film_cinatt_actuals ( 
       campaign_no,
       screening_date,
       attendance,
       data_valid )
select @new,
       screening_date,
       attendance,
       data_valid
  from film_cinatt_actuals
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to create new film_cinatt_actuals', 16, 1)
	return -1
end	

delete film_cinatt_actuals
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to delete film_cinatt_actuals', 16, 1)
	return -1
end	

insert into film_cinatt_actuals_cplx ( 
       campaign_no,
       screening_date,
       complex_id,
       movie_id,
       data_valid,
       attendance )   
select @new,
       screening_date,
       complex_id,
       movie_id,
       data_valid,
       attendance
  from film_cinatt_actuals_cplx
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to create new film_cinatt_actuals_cplx', 16, 1)
	return -1
end	

delete film_cinatt_actuals_cplx
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to delete film_cinatt_actuals_cplx', 16, 1)
	return -1
end	

/*
 * Create New Estimated Cinema Attendance Records
 */

insert into film_cinatt_estimates ( 
       campaign_no,
       screening_date,
       attendance,
       data_valid )
select @new,
       screening_date,
       attendance,
       data_valid
  from film_cinatt_estimates
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to create new film_cinatt_estimates', 16, 1)
	return -1
end	

delete film_cinatt_estimates
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to delete film_cinatt_estimates', 16, 1)
	return -1
end	

insert into film_cinatt_estimates_cplx ( 
       campaign_no,
       screening_date,
       complex_id,
       attendance,
       data_valid )   
select @new,
       screening_date,
       complex_id,
       attendance,
       data_valid
  from film_cinatt_estimates_cplx
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to create new film_cinatt_estimates_cplx', 16, 1)
	return -1
end	

delete film_cinatt_estimates_cplx
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to delete film_cinatt_estimates_cplx', 16, 1)
	return -1
end	

/*
 * Create New Cinema Attendance Log Records
 */

insert into film_cinatt_generate_log ( 
       campaign_no,
       log_datetime,
       log_user,
       cinatt_type,
       total_spots,
       attendance )
select @new,
       log_datetime,
       log_user,
       cinatt_type,
       total_spots,
       attendance
  from film_cinatt_generate_log
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to create new film_cinatt_generate_log', 16, 1)
	return -1
end	

delete film_cinatt_generate_log
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to delete film_cinatt_generate_log', 16, 1)
	return -1
end	

/*
 * Redirect cinelight_campaign_complex
 */

update cinelight_campaign_complex
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update cinecinelight_campaign_complexlight_campaigns', 16, 1)
	return -1
end	

/*
 * Redirect cinelight_campaign_print
 */

update cinelight_campaign_print
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update cinelight_campaign_print', 16, 1)
	return -1
end	

/*
 * Redirect cinelight_print_transaction
 */

update cinelight_print_transaction
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update cinelight_print_transaction', 16, 1)
	return -1
end	

/*
 * Redirect cinelight_pattern
 */

update cinelight_pattern
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update cinelight_pattern', 16, 1)
	return -1
end	

/*
 * Redirect cinelight_package
 */

update cinelight_package
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update cinelight_package', 16, 1)
	return -1
end	

/*
 * Redirect cinelight_spots
 */

update cinelight_spot
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update cinelight_spots', 16, 1)
	return -1
end	

update campaign_revision
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update campaign_revision', 16, 1)
	return -1
end	

update inclusion
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update inclusion', 16, 1)
	return -1
end	

update inclusion_spot
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update inclusion_spot', 16, 1)
	return -1
end	

update inclusion_pattern
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update inclusion_pattern', 16, 1)
	return -1
end	

update film_campaign_prop_notes
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_campaign_prop_notes', 16, 1)
	return -1
end	

update film_campaign_reps
   set campaign_no = @new,
	   branch_code = @new_branch	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update film_campaign_reps', 16, 1)
	return -1
end	

update booking_figures
   set campaign_no = @new,
	   branch_code = @new_branch	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update booking_figures', 16, 1)
	return -1
end	

update attendance_campaign_estimates
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update attendance_campaign_estimates', 16, 1)
	return -1
end	

update attendance_campaign_complex_estimates
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update attendance_campaign_complex_estimates', 16, 1)
	return -1
end	

update attendance_campaign_actuals
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update attendance_campaign_actuals', 16, 1)
	return -1
end	

update attendance_campaign_complex_actuals
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update attendance_campaign_complex_actuals', 16, 1)
	return -1
end	

update dbo.outpost_attendance_actuals
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.outpost_attendance_actuals', 16, 1)
	return -1
end	

update dbo.outpost_spot
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to dbo.outpost_spot', 16, 1)
	return -1
end	

update dbo.outpost_revenue
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.outpost_revenue', 16, 1)
	return -1
end	

update dbo.outpost_pattern
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.outpost_pattern', 16, 1)
	return -1
end	

update dbo.outpost_package
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.outpost_package', 16, 1)
	return -1
end	
	
update dbo.outpost_delete_charge_spots
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.outpost_delete_charge_spots', 16, 1)
	return -1
end	

update dbo.outpost_delete_charge
   set source_Campaign = @new	
 where source_Campaign = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.outpost_delete_charge', 16, 1)
	return -1
end	

update dbo.outpost_delete_charge
   set destination_campaign = @new	
 where destination_campaign = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.outpost_delete_charge', 16, 1)
	return -1
end	

update dbo.outpost_campaign_revision
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.outpost_campaign_revision', 16, 1)
	return -1
end	
update dbo.outpost_campaign_panel
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.outpost_campaign_panel', 16, 1)
	return -1
end	
update dbo.outpost_attendance_panel_estimates
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.outpost_attendance_panel_estimates', 16, 1)
	return -1
end	

update dbo.outpost_attendance_panel_actuals
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.outpost_attendance_panel_actuals', 16, 1)
	return -1
end	

update dbo.outpost_campaign_print
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.outpost_campaign_print', 16, 1)
	return -1
end	

update dbo.outpost_attendance_estimates
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.outpost_attendance_estimates', 16, 1)
	return -1
end	
	

update dbo.film_campaign_reporting_client
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.film_campaign_reporting_client', 16, 1)
	return -1
end	


	
update dbo.cinetam_campaign_settings
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.cinetam_campaign_settings', 16, 1)
	return -1
end	


update dbo.cinetam_campaign_targets
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.cinetam_campaign_targets', 16, 1)
	return -1
end	

update dbo.cinetam_campaign_actuals
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.cinetam_campaign_actuals', 16, 1)
	return -1
end	

update dbo.cinetam_campaign_complex_actuals
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.cinetam_campaign_actuals', 16, 1)
	return -1
end	

update dbo.film_campaign_manual_attendance
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.film_campaign_manual_attendance', 16, 1)
	return -1
end	

update dbo.attendance_campaign_actuals_weekend
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.attendance_campaign_actuals_weekend', 16, 1)
	return -1
end	

update dbo.attendance_campaign_complex_actuals_weekend
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.attendance_campaign_complex_actuals_weekend', 16, 1)
	return -1
end	

update dbo.attendance_campaign_tracking
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.attendance_campaign_tracking', 16, 1)
	return -1
end	


update dbo.attendance_campaign_tracking_weekend
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.attendance_campaign_tracking_weekend', 16, 1)
	return -1
end	

update dbo.cinetam_attendance_campaign_tracking_weekend
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.cinetam_attendance_campaign_tracking_weekend', 16, 1)
	return -1
end	

update dbo.cinetam_campaign_actuals_weekend
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.cinetam_campaign_actuals_weekend', 16, 1)
	return -1
end	

update dbo.cinetam_campaign_complex_actuals_weekend
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.cinetam_campaign_complex_actuals_weekend', 16, 1)
	return -1
end	

update dbo.film_revenue_creation
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.film_revenue_creation', 16, 1)
	return -1
end	

update dbo.cinetam_attendance_campaign_tracking
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.cinetam_attendance_campaign_tracking', 16, 1)
	return -1
end	

update dbo.cinelight_attendance_digilite_actuals
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.cinelight_attendance_digilite_actuals', 16, 1)
	return -1
end	

update dbo.cinelight_attendance_actuals
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.cinelight_attendance_actuals', 16, 1)
	return -1
end	

update dbo.inclusion_cinetam_attendance
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.inclusion_cinetam_attendance', 16, 1)
	return -1
end	


update dbo.inclusion_cinetam_attendance_weekend
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.inclusion_cinetam_attendance_weekend', 16, 1)
	return -1
end	


update dbo.inclusion_cinetam_complex_attendance
   set campaign_no = @new	
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to update dbo.inclusion_cinetam_complex_attendance', 16, 1)
	return -1
end	
/*
 * Delete Campaign
 */

delete film_campaign
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Unable to delete old film_campaign', 16, 1)
	return -1
end	
   

/*
 * Commit and Return
 */

commit transaction
return 0
GO
