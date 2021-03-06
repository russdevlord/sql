/****** Object:  StoredProcedure [dbo].[p_kpi_client_revenue_share]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_kpi_client_revenue_share]
GO
/****** Object:  StoredProcedure [dbo].[p_kpi_client_revenue_share]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE proc	[dbo].[p_kpi_client_revenue_share]		@country_code				char(1),
																					@start_period				datetime,
																					@end_period					datetime,
																					@delta_date					datetime,
																					@top_var							int
																
as

declare			@prev_start_period			datetime,
						@prev_end_period				datetime,
						@start_period_no				int,
						@end_period_no				int


set nocount on
						
create table #client_data (
			sort_order						int IDENTITY(1, 1)				not null,
			client_name						varchar(100)					null,
			client_id						int								null,
			agency_name						Varchar(100)					null,
			agency_id						int								null,
			agency_group					varchar(100)					null,
			agency_buying					varchar(100)					null,
			onscreen_fy_ytd					money							null	DEFAULT 0.00,
			onscreen_fy_totmkt				money							null	DEFAULT 0.00,
			onscreen_fy_prev_ytd			money							null	DEFAULT 0.00,
			onscreen_fy_prev_totmkt			money							null	DEFAULT 0.00,
			retail_fy_ytd					money							null	DEFAULT 0.00,
			retail_fy_totmkt				money							null	DEFAULT 0.00,
			retail_fy_prev_ytd				money							null	DEFAULT 0.00,
			retail_fy_prev_totmkt			money							null	DEFAULT 0.00,
			digilite_fy_ytd					money							null	DEFAULT 0.00,
			digilite_fy_totmkt				money							null	DEFAULT 0.00,
			digilite_fy_prev_ytd			money							null	DEFAULT 0.00,
			digilite_fy_prev_totmkt			money							null	DEFAULT 0.00,
			cinemarketing_fy_ytd			money							null	DEFAULT 0.00,
			cinemarketing_fy_totmkt			money							null	DEFAULT 0.00,
			cinemarketing_fy_prev_ytd		money							null	DEFAULT 0.00,
			cinemarketing_fy_prev_totmkt	money							null	DEFAULT 0.00,
			adex_fy_ytd						money							null	DEFAULT 0.00,
			adex_fy_totmkt					money							null	DEFAULT 0.00,
			adex_fy_prev_ytd				money							null	DEFAULT 0.00,
			adex_fy_prev_totmkt				money							null	DEFAULT 0.00,
			total_fy_ytd 					as isnull(onscreen_fy_ytd,0) + isnull(retail_fy_ytd,0) + isnull(digilite_fy_ytd,0) + isnull(cinemarketing_fy_ytd,0),
			total_fy_totmkt					as isnull(onscreen_fy_totmkt,0) + isnull(retail_fy_totmkt,0) + isnull(digilite_fy_totmkt,0) + isnull(cinemarketing_fy_totmkt,0),
			total_fy_prev_ytd 				as isnull(onscreen_fy_prev_ytd,0) + isnull(retail_fy_prev_ytd,0) + isnull(digilite_fy_prev_ytd,0) + isnull(cinemarketing_fy_prev_ytd,0),
			total_fy_prev_totmkt			as isnull(onscreen_fy_prev_totmkt,0) + isnull(retail_fy_prev_totmkt,0) + isnull(digilite_fy_prev_totmkt,0) + isnull(cinemarketing_fy_prev_totmkt,0)
)

/*
 * Initialse Variables
 */
 
select 	@start_period_no = period_no
from	accounting_period 
where	end_date = @start_period 

select 	@end_period_no = period_no
from	accounting_period 
where	end_date = @end_period 

select 	@prev_start_period = max(end_date)
from	accounting_period
where	period_no = @start_period_no
and		end_date < @start_period

select 	@prev_end_period = max(end_date)
from	accounting_period
where	period_no = @end_period_no
and		end_date < @end_period

insert into 	#client_data
					(
					--sort_order, SQL SERVER 2008
					client_name,
					client_id,
					agency_name,
					agency_id,
					agency_group,
					agency_buying
					)
select 		--ROW_NUMBER() over (order by 	isnull(sum(cost),0) desc), SQL SERVER 2008
					client_name,  
					client.client_id, 
					agency_name, 
					agency.agency_id,
					agency_group_name, 
					buying_group_desc
from   		client,  
					v_statrev, 
					film_campaign, 
					agency, 
					agency_groups, 
					agency_buying_groups
where   		client.client_id = film_campaign.client_id
and     		film_campaign.campaign_no = v_statrev.campaign_no
and     		agency.agency_group_id = agency_groups.agency_group_id
and     		agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     		agency.agency_id = film_campaign.reporting_agency
and     		v_statrev.revenue_period between @start_period and @end_period
and				v_statrev.delta_date <= @delta_date
and				v_statrev.country_code = @country_code
group by 	client_name,  
					client.client_id, 
					agency.agency_id,
					agency_name, 
					agency_group_name, 
					buying_group_desc
order by 	isnull(sum(cost),0) desc					

delete 		#client_data 
where		sort_order > @top_var

update 		#client_data 
set 				onscreen_fy_ytd = revenue
from   		(select 		isnull(sum(cost),0) as revenue,
										client_id,
										reporting_agency
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @start_period and @end_period
					and				v_statrev.delta_date <= @delta_date
					and				v_statrev.master_revenue_group = 1
					and				v_statrev.country_code = @country_code
					group by 	client_id, 
										reporting_agency) as revenue_data
where		revenue_data.client_id = #client_data.client_id
and				revenue_data.reporting_agency  = #client_data.agency_id
	
update 		#client_data 
set 				onscreen_fy_prev_ytd = revenue
from   		(select 		isnull(sum(cost),0) as revenue,
										client_id,
										reporting_agency
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @prev_start_period and @prev_end_period
					and				v_statrev.delta_date <= dateadd(yy, -1, @delta_date)
					and				v_statrev.master_revenue_group = 1
					and				v_statrev.country_code = @country_code
					group by 	client_id, 
										reporting_agency) as revenue_data
where		revenue_data.client_id = #client_data.client_id
and				revenue_data.reporting_agency  = #client_data.agency_id
	
update 		#client_data 
set 				digilite_fy_ytd = revenue
from   		(select 		isnull(sum(cost),0) as revenue,
										client_id,
										reporting_agency
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @start_period and @end_period
					and				v_statrev.delta_date <= @delta_date
					and				v_statrev.master_revenue_group = 2
					and				v_statrev.country_code = @country_code
					group by 	client_id, 
										reporting_agency) as revenue_data
where		revenue_data.client_id = #client_data.client_id
and				revenue_data.reporting_agency  = #client_data.agency_id
	
update 		#client_data 
set 				digilite_fy_prev_ytd = revenue
from   		(select 		isnull(sum(cost),0) as revenue,
										client_id,
										reporting_agency
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @prev_start_period and @prev_end_period
					and				v_statrev.delta_date <= dateadd(yy, -1, @delta_date)
					and				v_statrev.master_revenue_group = 2
					and				v_statrev.country_code = @country_code
					group by 	client_id, 
										reporting_agency) as revenue_data
where		revenue_data.client_id = #client_data.client_id
and				revenue_data.reporting_agency  = #client_data.agency_id

update 		#client_data 
set 				cinemarketing_fy_ytd = revenue
from   		(select 		isnull(sum(cost),0) as revenue,
										client_id,
										reporting_agency
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @start_period and @end_period
					and				v_statrev.delta_date <= @delta_date
					and				v_statrev.master_revenue_group = 3
					and				v_statrev.country_code = @country_code
					group by 	client_id, 
										reporting_agency) as revenue_data
where		revenue_data.client_id = #client_data.client_id
and				revenue_data.reporting_agency  = #client_data.agency_id
	
update 		#client_data 
set 				cinemarketing_fy_prev_ytd = revenue
from   		(select 		isnull(sum(cost),0) as revenue,
										client_id,
										reporting_agency
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @prev_start_period and @prev_end_period
					and				v_statrev.delta_date <= dateadd(yy, -1, @delta_date)
					and				v_statrev.master_revenue_group = 3
					and				v_statrev.country_code = @country_code
					group by 	client_id, 
										reporting_agency) as revenue_data
where		revenue_data.client_id = #client_data.client_id
and				revenue_data.reporting_agency  = #client_data.agency_id

update 		#client_data 
set 				retail_fy_ytd = revenue
from   		(select 		isnull(sum(cost),0) as revenue,
										client_id,
										reporting_agency
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @start_period and @end_period
					and				v_statrev.delta_date <= @delta_date
					and				v_statrev.transaction_type >= 100
					and				v_statrev.country_code = @country_code
					group by 	client_id, 
										reporting_agency) as revenue_data
where		revenue_data.client_id = #client_data.client_id
and				revenue_data.reporting_agency  = #client_data.agency_id
	
update 		#client_data 
set 				retail_fy_prev_ytd = revenue
from   		(select 		isnull(sum(cost),0) as revenue,
										client_id,
										reporting_agency
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @prev_start_period and @prev_end_period
					and				v_statrev.delta_date <= dateadd(yy, -1, @delta_date)
					and				v_statrev.transaction_type >= 100
					and				v_statrev.country_code = @country_code
					group by 	client_id, 
										reporting_agency) as revenue_data
where		revenue_data.client_id = #client_data.client_id
and				revenue_data.reporting_agency  = #client_data.agency_id

update 		#client_data 
set 				onscreen_fy_totmkt = revenue
from   		(select 		isnull(sum(cost),0) as revenue
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @start_period and @end_period
					and				v_statrev.delta_date <= @delta_date
					and				v_statrev.country_code = @country_code
					and				v_statrev.master_revenue_group = 1) as revenue_data
	
update 		#client_data 
set 				onscreen_fy_prev_totmkt = revenue
from   		(select 		isnull(sum(cost),0) as revenue
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @prev_start_period and @prev_end_period
					and				v_statrev.delta_date <= dateadd(yy, -1, @delta_date)
					and				v_statrev.country_code = @country_code
					and				v_statrev.master_revenue_group = 1) as revenue_data
	
update 		#client_data 
set 				digilite_fy_totmkt = revenue
from   		(select 		isnull(sum(cost),0) as revenue
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @start_period and @end_period
					and				v_statrev.delta_date <= @delta_date
					and				v_statrev.country_code = @country_code
					and				v_statrev.master_revenue_group = 2) as revenue_data
	
update 		#client_data 
set 				digilite_fy_prev_totmkt = revenue
from   		(select 		isnull(sum(cost),0) as revenue
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @prev_start_period and @prev_end_period
					and				v_statrev.delta_date <= dateadd(yy, -1, @delta_date)
					and				v_statrev.country_code = @country_code
					and				v_statrev.master_revenue_group = 2) as revenue_data

update 		#client_data 
set 				cinemarketing_fy_totmkt = revenue
from   		(select 		isnull(sum(cost),0) as revenue
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @start_period and @end_period
					and				v_statrev.delta_date <= @delta_date
					and				v_statrev.country_code = @country_code
					and				v_statrev.master_revenue_group = 3) as revenue_data
	
update 		#client_data 
set 				cinemarketing_fy_prev_totmkt = revenue
from   		(select 		isnull(sum(cost),0) as revenue
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @prev_start_period and @prev_end_period
					and				v_statrev.delta_date <= dateadd(yy, -1, @delta_date)
					and				v_statrev.country_code = @country_code
					and				v_statrev.master_revenue_group = 3) as revenue_data

update 		#client_data 
set 				retail_fy_totmkt = revenue
from   		(select 		isnull(sum(cost),0) as revenue
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @start_period and @end_period
					and				v_statrev.delta_date <= @delta_date
					and				v_statrev.country_code = @country_code
					and				v_statrev.transaction_type >= 100) as revenue_data
	
update 		#client_data 
set 				retail_fy_prev_totmkt = revenue
from   		(select 		isnull(sum(cost),0) as revenue
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @prev_start_period and @prev_end_period
					and				v_statrev.delta_date <= dateadd(yy, -1, @delta_date)
					and				v_statrev.country_code = @country_code
					and				v_statrev.transaction_type >= 100) as revenue_data

-- adex this year
-- adex last year
-- adex this year whole market
--	adex last year whole market

select *, 		
		@country_code AS country_code,
		@start_period AS start_period, 
		@end_period AS end_period, 
		@delta_date AS delta_date,
		@top_var AS top_var 
from #client_data 
order by sort_order

return 0
GO
