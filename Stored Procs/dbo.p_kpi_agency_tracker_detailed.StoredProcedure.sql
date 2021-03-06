/****** Object:  StoredProcedure [dbo].[p_kpi_agency_tracker_detailed]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_kpi_agency_tracker_detailed]
GO
/****** Object:  StoredProcedure [dbo].[p_kpi_agency_tracker_detailed]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE proc	[dbo].[p_kpi_agency_tracker_detailed]		@country_code				char(1),
														@start_period				datetime,
														@end_period					datetime,
														@delta_date					datetime,
														@top_var					int
																
as

declare					@prev_start_period			datetime,
						@prev_end_period			datetime,
						@start_period_no			int,
						@end_period_no				int


create table #agency_data
(
		sort_order				int IDENTITY(1, 1)	not null,	
		agency_id				int					null,
		agency_name				varchar(100)		null,
		agency_group_id			int					null,
		agency_group			varchar(100)		null,
		agency_buying			varchar(100)		null,
		fy_ytd 					money				NULL DEFAULT 0.00,
		fy_ytd_totmkt			money				NULL DEFAULT 0.00,
		fy_prev_ytd 			money				NULL DEFAULT 0.00,
		fy_prev_ytd_totmkt		money				NULL DEFAULT 0.00,
		fy_prev_final			money				NULL DEFAULT 0.00,
		fy_prev_final_totmkt	money				NULL DEFAULT 0.00
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

insert into 	#agency_data (
		--sort_order, SQL SERVER 2008
		agency_id,
		agency_name,
		agency_group_id,
		agency_group,
		agency_buying
		)
select	--ROW_NUMBER() over (order by 	isnull(sum(cost),0) desc), SQL SERVER 2008
		agency.agency_id,
		agency.agency_name,
		agency.agency_group_id,
		agency_group_name, 
		buying_group_desc
from	client,  
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
and				agency_buying_groups.buying_group_id = agency_groups.buying_group_id
and				v_statrev.country_code = @country_code
group by 	agency.agency_id,
			agency.agency_name,
			agency.agency_group_id,
			agency_group_name, 
			buying_group_desc
order by 	isnull(sum(cost),0) desc					

delete 		#agency_data 
where		sort_order > @top_var

update 		#agency_data 
set 				fy_ytd = revenue
from   		(select 		isnull(sum(cost),0) as revenue,
										agency.agency_group_id,
										agency.agency_id
					from			v_statrev, 
										film_campaign,
										agency
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @start_period and @end_period
					and				v_statrev.delta_date <= @delta_date
					and				film_campaign.reporting_agency = agency.agency_id
					and				v_statrev.country_code = @country_code
					group by 	agency.agency_group_id,
										agency.agency_id) as revenue_data
where		revenue_data.agency_group_id  = #agency_data.agency_group_id
and				revenue_data.agency_id  = #agency_data.agency_id
	
update 		#agency_data 
set 				fy_ytd_totmkt = revenue
from   		(select 		isnull(sum(cost),0) as revenue
					from			v_statrev, 
										film_campaign,
										agency
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @start_period and @end_period
					and				v_statrev.delta_date <= @delta_date
					and				film_campaign.reporting_agency = agency.agency_id
					and				v_statrev.country_code = @country_code) as revenue_data
	
update 		#agency_data 
set 				fy_prev_ytd = revenue
from   		(select 		isnull(sum(cost),0) as revenue,
										agency.agency_group_id,
										agency.agency_id
					from			v_statrev, 
										film_campaign,
										agency
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @prev_start_period and @prev_end_period
					and				v_statrev.delta_date <= dateadd(yy, -1, @delta_date)
					and				film_campaign.reporting_agency = agency.agency_id
					and				v_statrev.country_code = @country_code
					group by 	agency.agency_group_id,
										agency.agency_id) as revenue_data
where		revenue_data.agency_group_id  = #agency_data.agency_group_id
and				revenue_data.agency_id  = #agency_data.agency_id
	
update 		#agency_data 
set 				fy_prev_ytd_totmkt = revenue
from   		(select 		isnull(sum(cost),0) as revenue
					from			v_statrev, 
										film_campaign,
										agency
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @prev_start_period and @prev_end_period
					and				v_statrev.delta_date <= dateadd(yy, -1, @delta_date)
					and				v_statrev.country_code = @country_code
					and				film_campaign.reporting_agency = agency.agency_id) as revenue_data

update 		#agency_data 
set 				fy_prev_final	= revenue
from   		(select 		isnull(sum(cost),0) as revenue,
										agency.agency_group_id,
										agency.agency_id
					from			v_statrev, 
										film_campaign,
										agency
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @prev_start_period and @prev_end_period
					and				v_statrev.delta_date <= @delta_date
					and				film_campaign.reporting_agency = agency.agency_id
					and				v_statrev.country_code = @country_code
					group by 	agency.agency_group_id,
										agency.agency_id) as revenue_data
where		revenue_data.agency_group_id  = #agency_data.agency_group_id
and				revenue_data.agency_id  = #agency_data.agency_id
	
update 		#agency_data 
set 				fy_prev_final_totmkt = revenue
from   		(select 		isnull(sum(cost),0) as revenue
					from			v_statrev, 
										film_campaign,
										agency
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @prev_start_period and @prev_end_period
					and				v_statrev.delta_date <= @delta_date
					and				v_statrev.country_code = @country_code
					and				film_campaign.reporting_agency = agency.agency_id) as revenue_data

select *, 
		@country_code as country_code,
		@start_period as start_period, 
		@end_period	as end_period, 
		@delta_date as delta_date,
		@top_var as top_var 
from #agency_data 
order by sort_order

return 0
GO
