/****** Object:  StoredProcedure [dbo].[p_kpi_digital_only_campaigns]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_kpi_digital_only_campaigns]
GO
/****** Object:  StoredProcedure [dbo].[p_kpi_digital_only_campaigns]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE proc	[dbo].[p_kpi_digital_only_campaigns]		@country_code				char(1),
														@start_period				datetime,
														@end_period					datetime,
														@delta_date					datetime,
														@top_var					int
																
as

declare			@prev_start_period			datetime,
				@prev_end_period				datetime,
				@start_period_no				int,
				@end_period_no				int


set nocount on
						
create table #digital_only_data (
			sort_order					int IDENTITY(1, 1)		not null,
			campaign_no					int							null,
			product_desc				varchar(100)				null,
			client_id					int							null,
			client_name					varchar(100)				null,
			agency_group_id				int							null,
			agency_group				varchar(100)				null,
			agency_buying				varchar(100)				null,
			fy_ytd 						money						null	DEFAULT 0.00,
			fy_ytd_totmkt				money						null	DEFAULT 0.00
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

insert into 	#digital_only_data
					(
					--sort_order, SQL SERVER 2008
					campaign_no,
					product_desc,
					client_id,
					client_name,
					agency_group_id,
					agency_group,
					agency_buying,
					fy_ytd
					)
select 		--ROW_NUMBER() over (order by 	isnull(sum(cost),0) desc), SQL SERVER 2008
					film_campaign.campaign_no,
					film_campaign.product_desc,
					client.client_id, 
					client.client_name,
					agency.agency_group_id,
					agency_group_name, 
					buying_group_desc,
					isnull(sum(cost),0)
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
and				agency_buying_groups.buying_group_id = agency_groups.buying_group_id
and				v_statrev.country_code = @country_code
and				film_campaign.campaign_no not in (select campaign_no from campaign_package where package_id in (select package_id from print_package where print_package_id in (select print_package_id from print_package_medium where print_medium = 'F')))
and				film_campaign.campaign_no  in (select campaign_no from campaign_package where package_id in (select package_id from print_package where print_package_id in (select print_package_id from print_package_medium where print_medium = 'D')))
group by 	film_campaign.campaign_no,
					film_campaign.product_desc,
					client.client_id, 
					client.client_name,
					agency.agency_group_id,
					agency_group_name, 
					buying_group_desc
order by 	isnull(sum(cost),0) desc					

delete 		#digital_only_data 
where		sort_order > @top_var

	
update 		#digital_only_data 
set 				fy_ytd_totmkt = revenue
from   		(select 		isnull(sum(cost),0) as revenue
					from			v_statrev, 
										film_campaign,
										agency
					where   		film_campaign.campaign_no = v_statrev.campaign_no
					and     		v_statrev.revenue_period between @start_period and @end_period
					and				v_statrev.delta_date <= @delta_date
					and				film_campaign.campaign_no not in (select campaign_no from campaign_package where package_id in (select package_id from print_package where print_package_id in (select print_package_id from print_package_medium where print_medium = 'F')))
					and				film_campaign.campaign_no  in (select campaign_no from campaign_package where package_id in (select package_id from print_package where print_package_id in (select print_package_id from print_package_medium where print_medium = 'D')))
					and				v_statrev.country_code = @country_code
					and				film_campaign.reporting_agency = agency.agency_id) as revenue_data
	

select *, 
		@country_code AS country_code,
		@start_period AS start_period, 
		@end_period AS end_period, 
		@delta_date AS delta_date,
		@top_var AS top_var
from #digital_only_data order by sort_order

return 0
GO
