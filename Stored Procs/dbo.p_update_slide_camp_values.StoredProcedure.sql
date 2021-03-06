/****** Object:  StoredProcedure [dbo].[p_update_slide_camp_values]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_update_slide_camp_values]
GO
/****** Object:  StoredProcedure [dbo].[p_update_slide_camp_values]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_update_slide_camp_values]		@campaign_no					char(7),
				@campaign_status				char(1),   
				@campaign_type					char(1),   
				@campaign_category			char(1),   
				@credit_status					char(1),   
				@credit_avail					char(1),   
				@cancellation_code			char(1),   
				@is_official					char(1),   
				@is_closed						char(1),   
				@is_archived					char(1),   
				@contract_rep					integer,   
				@business_group				smallint,   
				@service_rep					integer,   
				@credit_controller			integer,   
				@credit_manager				integer,   
				@credit_cut_off				char(1),   
				@agency_deal					char(1),   
				@agency_id						integer,   
				@client_id						integer,   
				@industry_category			integer,   
				@billing_cycle					tinyint,   
				@start_date						datetime,   
				@branch_release				char(1),   
				@npu_release					char(1),   
				@ho_release						char(1),   
				@campaign_release				char(1),   
				@gross_contract_value 		money,   
				@nett_contract_value			money,   
				@comm_contract_value			money,   
				@actual_contract_value 		money,   
				@orig_campaign_period		smallint,   
				@min_campaign_period 		smallint,   
				@bonus_period					smallint,   
				@discount						numeric(6,4),   
				@balance_credit				money,   
				@balance_current				money,   
				@balance_30						money,   
				@balance_60						money,   
				@balance_90						money,   
				@balance_120					money,   
				@balance_outstanding			money,   
				@rent_distribution_method 	tinyint,   
				@deposit							money,   
				@gst_exempt						char(1),   
				@screening_offsets  			char(1),   
				@campaign_notes				varchar(255),   
				@official_period				datetime,   
				@campaign_entry				datetime,   
				@request_accepted				datetime,   
				@artwork_completed			datetime,   
				@artwork_approved   			datetime,   
				@gross_total_value			money,   
				@nett_total_value				money,   
				@comm_total_value				money,   
				@actual_total_value  		money

as
set nocount on 
declare  @error						integer

                             

begin transaction

                                                     

update slide_campaign
   set campaign_status = @campaign_status,   
		 campaign_type = @campaign_type,   
		 campaign_category = @campaign_category,   
		 credit_status = @credit_status,   
		 credit_avail = @credit_avail,   
		 cancellation_code = @cancellation_code,   
		 is_official = @is_official,   
		 is_closed = @is_closed,   
		 is_archived = @is_archived,   
		 contract_rep = @contract_rep,   
		 business_group = @business_group,   
		 service_rep = @service_rep,   
		 credit_controller = @credit_controller,   
		 credit_manager = @credit_manager,   
		 credit_cut_off = @credit_cut_off,   
		 agency_deal = @agency_deal,   
		 agency_id = @agency_id,   
    	 client_id = @client_id,   
		 industry_category = @industry_category,   
		 billing_cycle = @billing_cycle,   
		 start_date = @start_date,   
		 branch_release = @branch_release,   
		 npu_release = @npu_release,   
		 ho_release = @ho_release,   
		 campaign_release = @campaign_release,   
		 gross_contract_value = @gross_contract_value,   
		 nett_contract_value = @nett_contract_value,   
		 comm_contract_value = @comm_contract_value,   
		 actual_contract_value = @actual_contract_value,   
		 orig_campaign_period = @orig_campaign_period,   
		 min_campaign_period = @min_campaign_period,   
		 bonus_period = @bonus_period,   
		 discount = @discount,   
		 balance_credit = @balance_credit,   
		 balance_current = @balance_current,   
		 balance_30 = @balance_30,   
		 balance_60 = @balance_60,   
		 balance_90 = @balance_90,   
		 balance_120 = @balance_120,   
		 balance_outstanding = @balance_outstanding,   
		 rent_distribution_method = @rent_distribution_method,   
		 deposit = @deposit,   
		 gst_exempt = @gst_exempt,   
		 screening_offsets = @screening_offsets,   
		 campaign_notes = @campaign_notes,   
		 official_period = @official_period,   
		 campaign_entry = @campaign_entry,   
		 request_accepted = @request_accepted,   
		 artwork_completed = @artwork_completed,   
		 artwork_approved = @artwork_approved,   
		 gross_total_value = @gross_total_value,   
		 nett_total_value = @nett_total_value,   
		 comm_total_value = @comm_total_value,   
		 actual_total_value = @actual_total_value
 where campaign_no = @campaign_no

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to update the slide campaign table.', 16, 1)
	return -1
end

commit transaction
return 0
GO
