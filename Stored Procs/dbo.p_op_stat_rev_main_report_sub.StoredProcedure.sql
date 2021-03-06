/****** Object:  StoredProcedure [dbo].[p_op_stat_rev_main_report_sub]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_stat_rev_main_report_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_op_stat_rev_main_report_sub]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
mode = 1 = normal revenue
mode = 2 = deferred revenue
mode = 3 = budgets
mode = 4 = forecast
*/

Create     proc [dbo].[p_op_stat_rev_main_report_sub]	@report_date				datetime,
										@report_start_date			datetime,
										@start_date					datetime,
										@end_date					datetime,
										@revenue_company			int,
										@revenue_group				int,
										@master_revenue_group		int,
										@business_unit_id			int,
										@country_code				char(1),
										@branch_code				char(1),	
									    @mode						int--,
									--@revenue					money out
						
									
as

declare		@error 			int,
@revenue					money 

set nocount on

if @mode = 1
begin
	select 		@revenue = isnull( sum ( cost ),0)
	from 		statrev_campaign_revision scr,   
				film_campaign fc,   
				statrev_outpost_normal_transaction scnt,   
				statrev_transaction_type stt,
				statrev_revenue_group srg,
				statrev_revenue_master_group srmg,
				branch b
	where		fc.campaign_no = scr.campaign_no
	and			scr.revision_id = scnt.revision_id
	and			scnt.transaction_type = stt.statrev_transaction_type
	and			stt.revenue_group = srg.revenue_group
	and			srg.master_revenue_group = srmg.master_revenue_group
	and			fc.branch_code = b.branch_code
	and			(fc.branch_code = @branch_code
	or			@branch_code = '')
	and			(b.country_code = @country_code
	or			@country_code = '')
	and			(fc.business_unit_id = @business_unit_id
	or  		@business_unit_id = 0 ) 
	and			((srg.revenue_group = @revenue_group
	or			@revenue_group = 0)
	and			srg.revenue_company = @revenue_company)
	and			((srmg.master_revenue_group = @master_revenue_group
	or			@master_revenue_group = 0)
	and			srmg.revenue_company = @revenue_company)
	and			scnt.delta_date <= @report_date 
	and			(scnt.delta_date >= @report_start_date
	or			@report_start_date is null)
	and			scnt.revenue_period between @start_date and @end_date

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error: retrieving revenue information.', 16, 1)
		return 0
	end
end
else if @mode = 2
begin
	select 		@revenue = isnull(  sum ( cost ),0)
	from 		statrev_campaign_revision scr,   
				film_campaign fc,   
				statrev_outpost_deferred_transaction scnt,   
				statrev_transaction_type stt,
				statrev_revenue_group srg,
				statrev_revenue_master_group srmg,
				branch b
	where		fc.campaign_no = scr.campaign_no
	and			scr.revision_id = scnt.revision_id
	and			scnt.transaction_type = stt.statrev_transaction_type
	and			stt.revenue_group = srg.revenue_group
	and			srg.master_revenue_group = srmg.master_revenue_group
	and			fc.branch_code = b.branch_code
	and			(fc.branch_code = @branch_code
	or			@branch_code = '')
	and			(b.country_code = @country_code
	or			@country_code = '')
	and			(fc.business_unit_id = @business_unit_id
	or  		@business_unit_id = 0 ) 
	and			((srg.revenue_group = @revenue_group
	or			@revenue_group = 0)
	and			srg.revenue_company = @revenue_company)
	and			((srmg.master_revenue_group = @master_revenue_group
	or			@master_revenue_group = 0)
	and			srmg.revenue_company = @revenue_company)
	and			scnt.delta_date <= @report_date 
	and			(scnt.delta_date >= @report_start_date
	or			@report_start_date is null)

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error: retrieving deferred revenue information.', 16, 1)
		return 0
	end
end
else if @mode = 3
begin	
	select 		@revenue = isnull( sum ( budget ),0)
	from 		statrev_budgets sb,
				statrev_revenue_group srg,
				statrev_revenue_master_group srmg,
				branch b
	where		sb.revenue_group = srg.revenue_group
	and			srg.master_revenue_group = srmg.master_revenue_group
	and			sb.branch_code = b.branch_code
	and			(sb.branch_code = @branch_code
	or			@branch_code = '')
	and			(b.country_code = @country_code
	or			@country_code = '')
	and			(sb.business_unit_id = @business_unit_id
	or  		@business_unit_id = 0 ) 
	and			((sb.revenue_group = @revenue_group

	or			@revenue_group = 0)
	and			srg.revenue_company = @revenue_company)
	and			((srmg.master_revenue_group = @master_revenue_group
	or			@master_revenue_group = 0)
	and			srmg.revenue_company = @revenue_company)
	and			sb.revenue_period between @start_date and @end_date

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error: retrieving budget information.', 16, 1)
		return 0
	end
end
else if @mode = 4
begin	
	select 		@revenue = isnull(sum ( forecast ),0)
	from 		statrev_budgets sb,
				statrev_revenue_group srg,
				statrev_revenue_master_group srmg,
				branch b
	where		sb.revenue_group = srg.revenue_group
	and			srg.master_revenue_group = srmg.master_revenue_group
	and			sb.branch_code = b.branch_code
	and			(sb.branch_code = @branch_code
	or			@branch_code = '')
	and			(b.country_code = @country_code
	or			@country_code = '')
	and			(sb.business_unit_id = @business_unit_id
	or  		@business_unit_id = 0 ) 
	and			((sb.revenue_group = @revenue_group
	or			@revenue_group = 0)
	and			srg.revenue_company = @revenue_company)
	and			((srmg.master_revenue_group = @master_revenue_group
	or			@master_revenue_group = 0)
	and			srmg.revenue_company = @revenue_company)
	and			sb.revenue_period between @start_date and @end_date

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error: retrieving forecast information.', 16, 1)
		return 0
	end
end

select Isnull(@revenue, 0)
--return 0
GO
