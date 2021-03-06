/****** Object:  StoredProcedure [dbo].[p_change_slide_campaign_no]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_change_slide_campaign_no]
GO
/****** Object:  StoredProcedure [dbo].[p_change_slide_campaign_no]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  PROC [dbo].[p_change_slide_campaign_no] @old				char(7),
                                 	   @new     		char(7)
as

declare @error		int,
        @errorode		int

/*
 * Begin Transaction
 */

begin transaction

/*
 * Create New CAmpaign
 */

insert into slide_campaign ( 
       campaign_no,   
       campaign_code,   
       name_on_slide,   
       sort_key,   
       signatory,   
       contact,   
       phone,   
       branch_code,   
       campaign_status,   
       campaign_type,   
       campaign_category,   
       credit_status,   
       credit_avail,   
       cancellation_code,   
       is_official,   
       is_closed,   
       is_archived,   
       contract_rep,   
       business_group,   
       service_rep,   
       credit_controller,   
       agency_deal,   
       agency_id,   
       client_id,   
       industry_category,   
       billing_cycle,   
       start_date,   
       branch_release,   
       npu_release,   
       ho_release,   
       campaign_release,   
       gross_contract_value,   
       nett_contract_value,   
       comm_contract_value,   
       actual_contract_value,   
       orig_campaign_period,   
       min_campaign_period,   
       bonus_period,   
       discount,   
       balance_credit,   
       balance_current,   
       balance_30,   
       balance_60,   
       balance_90,   
       balance_120,   
       balance_outstanding,   
       rent_distribution_method,   
       deposit,   
       gst_exempt,   
       screening_offsets,   
       campaign_notes,   
       official_period,   
       campaign_entry,
billing_commission,
payroll_rep,
actual_total_value,
comm_total_value,
nett_total_value,
gross_total_value,
credit_cut_off,
credit_manager )
select @new,   
       stuff(@new, 2, 2, null),
       name_on_slide,   
       sort_key,   
       signatory,   
       contact,   
       phone,   
       branch_code,   
       campaign_status,   
       campaign_type,   
       campaign_category,   
       credit_status,   
       credit_avail,   
       cancellation_code,   
       is_official,   
       is_closed,   
       is_archived,   
       contract_rep,   
       business_group,   
       service_rep,   
       credit_controller,   
       agency_deal,   
       agency_id,   
       client_id,   
       industry_category,   
       billing_cycle,   
       start_date,   
       branch_release,   
       npu_release,   
       ho_release,   
       campaign_release,   
       gross_contract_value,   
       nett_contract_value,   
       comm_contract_value,   
       actual_contract_value,   
       orig_campaign_period,   
       min_campaign_period,   
       bonus_period,   
       discount,   
       balance_credit,   
       balance_current,   
       balance_30,   
       balance_60,   
       balance_90,   
       balance_120,   
       balance_outstanding,   
       rent_distribution_method,   
       deposit,   
       gst_exempt,   
       screening_offsets,   
       campaign_notes,   
       official_period,   
       campaign_entry,
	billing_commission,
payroll_rep,
actual_total_value,
comm_total_value,
nett_total_value,
gross_total_value,
credit_cut_off,
credit_manager
  from slide_campaign sc
 where sc.campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Sales Territory Diary
 */

update slide_campaign_sales_territory
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Admin Diary
 */

update admin_diary
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Batch Item
 */

update batch_item
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	


/*
 * Redirect Service Diary
 */

update service_diary
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Credit Diary
 */

update credit_diary
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect DSP Diary
 */

update dsp_diary
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Credit Arrangements
 */

update credit_arrangement
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Campaign Letters
 */

update campaign_letter
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Campaign Letters
 */

update campaign_letter
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect NPU Requests
 */

update npu_request
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Competition Entries
 */

update competition_entry
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Slide Campaign Artworks
 */

update slide_campaign_artwork
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Slide Proposal
 */

update slide_proposal
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Slide Figures
 */

update slide_figures
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Parent Writeback Liability
 */

update writeback_liability
   set parent_campaign = @new
 where parent_campaign = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Origin Writeback Liability
 */

update writeback_liability
   set origin_campaign = @new
 where origin_campaign = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Slide Profiles
 */

update slide_profile_xref
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Campaign Spots
 */

update slide_campaign_spot
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Campaign Lines
 */

update campaign_line
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Campaign Lines
 */

update campaign_line
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Campaign Complexes
 */

update slide_campaign_complex
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Statements
 */

update slide_statement
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Voiceovers
 */

update slide_campaign_voiceover
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Campaign Events
 */

update campaign_event
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Campaign Distribution
 */

update slide_distribution
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Parent Slide Family
 */

update slide_family
   set parent_campaign = @new
 where parent_campaign = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Redirect Child Slide Family
 */

update slide_family
   set child_campaign = @new
 where child_campaign = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Slide Transactions
 */

update slide_transaction
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Non Trading
 */

update non_trading
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Rent Distribution
 */

update rent_distribution
   set campaign_no = @new
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	


/*
 * Delete Old Campaign
 */

delete slide_campaign
 where campaign_no = @old

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
