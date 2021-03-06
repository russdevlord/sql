/****** Object:  StoredProcedure [dbo].[p_kpi_business_development_list]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_kpi_business_development_list]
GO
/****** Object:  StoredProcedure [dbo].[p_kpi_business_development_list]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE proc	[dbo].[p_kpi_business_development_list]		@country_code				char(1),
																							@start_period					datetime,
																							@end_period					datetime,
																							@delta_date					datetime
																
as

declare			@prev_start_period			datetime,
						@prev_end_period				datetime,
						@start_period_no				int,
						@end_period_no				int


set nocount on
						
create table #client_data
(
sort_order										int IDENTITY(1, 1)		not null,
client_name									varchar(100)					null,
client_id										int									null,
agency_name								varchar(100)					null,
agency_id										int									null,
agency_group								varchar(100)					null,
agency_buying							varchar(100)					null,
target												money							null,
adex_fy_ytd									money							null,
adex_fy_prev_ytd						money							null,
total_fy_ytd 									money							null,
total_fy_prev_ytd 							money							null,
total_fy_prev_final 						money							null
)

/*
 * Initialse Variables
 */
 
select 	@start_period_no = period_no
from		accounting_period 
where	end_date = @start_period 

select 	@end_period_no = period_no
from		accounting_period 
where	end_date = @end_period 

select 	@prev_start_period = max(end_date)
from		accounting_period
where	period_no = @start_period_no
and			end_date < @start_period

select 	@prev_end_period = max(end_date)
from		accounting_period
where	period_no = @end_period_no
and			end_date < @end_period

insert into 	#client_data
					(
					--sort_order, SQL SERVER 2008
					client_name,
					client_id,
					agency_name,
					agency_id,
					agency_group,
					agency_buying,
					target
					)
select 		--ROW_NUMBER() over (order by 	isnull(sum(cost),0) desc), SQL SERVER 2008
					client_name,  
					client.client_id, 
					agency_name, 
					agency.agency_id,
					agency_group_name, 
					buying_group_desc,
					client_prospects.revenue
from   		client,  
					film_campaign, 
					agency, 
					agency_groups, 
					agency_buying_groups,
					client_prospects
where   		client.client_id = film_campaign.client_id
and     		agency.agency_group_id = agency_groups.agency_group_id
and     		agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     		agency.agency_id = film_campaign.reporting_agency
and				client_prospects.client_id = client.client_id
and				client_prospects.country_code = @country_code
group by 	client_name,  
					client.client_id, 
					agency_name, 
					agency.agency_id,
					agency_group_name, 
					buying_group_desc,
					client_prospects.revenue
order by 	client_name				

update 		#client_data 
set 				total_fy_ytd = revenue
from   		(select 		isnull(sum(cost),0) as revenue,
										client_id,
										reporting_agency
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @start_period and @end_period
					and				v_statrev.delta_date <= @delta_date
					and				v_statrev.country_code = @country_code
					group by 	client_id, 
										reporting_agency) as revenue_data
where		revenue_data.client_id = #client_data.client_id
and				revenue_data.reporting_agency  = #client_data.agency_id
	
update 		#client_data 
set 				total_fy_prev_ytd = revenue
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
set 				total_fy_prev_final = revenue
from   		(select 		isnull(sum(cost),0) as revenue,
										client_id,
										reporting_agency
					from			v_statrev, 
										film_campaign
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @prev_start_period and @prev_end_period
					and				v_statrev.delta_date <= @delta_date
					and				v_statrev.master_revenue_group = 1
					and				v_statrev.country_code = @country_code
					group by 	client_id, 
										reporting_agency) as revenue_data
where		revenue_data.client_id = #client_data.client_id
and				revenue_data.reporting_agency  = #client_data.agency_id

-- adex this year
-- adex last year
-- adex this year whole market
--	adex last year whole market


select sort_order,
		client_name,
		client_id,
		agency_name,
		agency_id,
		agency_group,
		agency_buying,
		target,
		adex_fy_ytd,
		adex_fy_prev_ytd,
		total_fy_ytd,
		total_fy_prev_ytd,
		total_fy_prev_final,
		@country_code AS country_code,
		@start_period AS start_period, 
		@end_period AS end_period, 
		@delta_date AS delta_date
from #client_data 
order by sort_order

return 0
GO
