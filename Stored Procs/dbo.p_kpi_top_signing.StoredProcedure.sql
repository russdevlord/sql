/****** Object:  StoredProcedure [dbo].[p_kpi_top_signing]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_kpi_top_signing]
GO
/****** Object:  StoredProcedure [dbo].[p_kpi_top_signing]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE proc	[dbo].[p_kpi_top_signing]			@country_code				char(1),
												@start_period				datetime,
												@end_period					datetime,
												@top_var					int
																
as

set nocount on
						
create table #client_data (
		sort_order					int IDENTITY(1, 1)			not null,
		sort_add					int							null,
		branch_code					char(2)						null,
		branch_name					varchar(30)					null,
		rep_name					varchar(100)				null,
		campaign_no					int							null,
		product_desc				varchar(100)				null,
		package_type				varchar(30)					null,
		package_id					int							null,
		package_code				char(1)						null,
		package_desc				varchar(255)				null,
		client_name					varchar(100)				null,
		client_id					int							null,
		agency_name					varchar(100)				null,
		agency_id					int							null,
		agency_group				varchar(100)				null,
		agency_buying				varchar(100)				null,
		confirmed					datetime					null,
		campaign_revenue			money						null	DEFAULT 0.00,
		package_revenue				money						null	DEFAULT 0.00,
		package_rate				money						null	DEFAULT 0.00,
		package_paid_screens		int							null,
		package_bonus_screens		int							null,
		business_unit_id			int							null,
		campaign_row_number			int							null
)

/*
 * Initialse Variables
 */
 
insert into 	#client_data (
		--sort_order, SQL SERVER 2008
		campaign_no,
		product_desc,
		rep_name,
		branch_code,
		branch_name, 
		package_type,
		package_id,
		package_code,
		package_desc	,
		client_name,
		client_id,
		agency_name,
		agency_id,
		agency_group,
		agency_buying,
		confirmed,
		campaign_revenue,
		package_revenue,
		package_rate,
		package_paid_screens,
		package_bonus_screens,
		business_unit_id
		)
select 		film_campaign.campaign_no,
			product_desc,
			dbo.f_campaign_repname(film_campaign.campaign_no),
			branch.branch_code,
			branch_name, 
			'Onscreen',
			campaign_package.package_id,
			package_code,
			package_desc,
			client_name,  
			client.client_id, 
			agency_name, 
			agency.agency_id,
			agency_group_name, 
			buying_group_desc,
			film_campaign.confirmed_date,
			film_campaign.confirmed_cost,
			isnull(sum(campaign_spot.charge_rate),0),
			isnull(campaign_package.charge_rate,0),
			isnull(sum(case spot_type when 'S' then 1 else 0 end),0),
			isnull(sum(case spot_type when 'B' then 1 when 'C' then 1 when 'N' then 1 when 'W' then 1 else 0 end),0),
			film_campaign.business_unit_id
from   		client,  
			film_campaign,
			campaign_package, 
			campaign_spot,					
			branch,
			agency, 
			agency_groups, 
			agency_buying_groups
where   		client.client_id = film_campaign.client_id
and     		agency.agency_group_id = agency_groups.agency_group_id
and     		agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     		agency.agency_id = film_campaign.reporting_agency
and				film_campaign.campaign_no  = campaign_package.campaign_no
and				campaign_package.package_id = campaign_spot.package_id
and				film_campaign.branch_code = branch.branch_code
and				branch.country_code = @country_code
and				film_campaign.campaign_status <> 'P'
and				campaign_package.campaign_package_status <> 'P'
and				campaign_spot.spot_status <> 'P'
and				film_campaign.confirmed_date between @start_period and @end_period
group by 	film_campaign.confirmed_cost,
			film_campaign.campaign_no,
			product_desc,
			branch.branch_code,
			branch_name, 
			campaign_package.package_id,
			package_code,
			package_desc,
			client_name,  
			client.client_id, 
			agency_name, 
			agency.agency_id,
			agency_group_name, 
			buying_group_desc,
			campaign_package.charge_rate,
			film_campaign.confirmed_date,
			film_campaign.business_unit_id
union all
select 		film_campaign.campaign_no,
			product_desc,
			dbo.f_campaign_repname(film_campaign.campaign_no),
			branch.branch_code,
			branch_name, 
			'Digilite',
			cinelight_package.package_id,
			package_code,
			package_desc,
			client_name,  
			client.client_id, 
			agency_name, 
			agency.agency_id,
			agency_group_name, 
			buying_group_desc,
			film_campaign.confirmed_date,
			film_campaign.confirmed_cost,
			isnull(sum(cinelight_spot.charge_rate),0),
			isnull(cinelight_package.charge_rate,0),
			isnull(sum(case spot_type when 'S' then 1 else 0 end),0),
			isnull(sum(case spot_type when 'B' then 1 when 'C' then 1 when 'N' then 1 when 'W' then 1 else 0 end),0),
			film_campaign.business_unit_id
from   		client,  
			film_campaign,
			cinelight_package, 
			cinelight_spot,					
			branch,
			agency, 
			agency_groups, 
			agency_buying_groups
where   		client.client_id = film_campaign.client_id
and     		agency.agency_group_id = agency_groups.agency_group_id
and     		agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     		agency.agency_id = film_campaign.reporting_agency
and				film_campaign.campaign_no  = cinelight_package.campaign_no
and				cinelight_package.package_id = cinelight_spot.package_id
and				film_campaign.branch_code = branch.branch_code
and				branch.country_code = @country_code
and				film_campaign.campaign_status <> 'P'
and				cinelight_package.cinelight_package_status <> 'P'
and				cinelight_spot.spot_status <> 'P'
and				film_campaign.confirmed_date between @start_period and @end_period
group by 	film_campaign.confirmed_cost,
			film_campaign.campaign_no,
			product_desc,
			branch.branch_code,
			branch_name, 
			cinelight_package.package_id,
			package_code,
			package_desc,
			client_name,  
			client.client_id, 
			agency_name, 
			agency.agency_id,
			agency_group_name, 
			buying_group_desc,
			cinelight_package.charge_rate,
			film_campaign.confirmed_date,
			film_campaign.business_unit_id
union all
select 		film_campaign.campaign_no,
			product_desc,
			dbo.f_campaign_repname(film_campaign.campaign_no),
			branch.branch_code,
			branch_name, 
			'Retail',
			outpost_package.package_id,
			package_code,
			package_desc,
			client_name,  
			client.client_id, 
			agency_name, 
			agency.agency_id,
			agency_group_name, 
			buying_group_desc,
			film_campaign.confirmed_date,
			film_campaign.confirmed_cost,
			isnull(sum(outpost_spot.charge_rate),0),
			isnull(outpost_package.charge_rate,0),
			isnull(sum(case spot_type when 'S' then 1 else 0 end),0),
			isnull(sum(case spot_type when 'B' then 1 when 'C' then 1 when 'N' then 1 when 'W' then 1 else 0 end),0),
			film_campaign.business_unit_id
from   		client,  
			film_campaign,
			outpost_package, 
			outpost_spot,					
			branch,
			agency, 
			agency_groups, 
			agency_buying_groups
where   		client.client_id = film_campaign.client_id
and     		agency.agency_group_id = agency_groups.agency_group_id
and     		agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     		agency.agency_id = film_campaign.reporting_agency
and				film_campaign.campaign_no  = outpost_package.campaign_no
and				outpost_package.package_id = outpost_spot.package_id
and				film_campaign.branch_code = branch.branch_code
and				branch.country_code = @country_code
and				film_campaign.campaign_status <> 'P'
and				outpost_package.package_status <> 'P'
and				outpost_spot.spot_status <> 'P'
and				outpost_panel_id in (select outpost_panel_id from outpost_player_xref, outpost_player where outpost_player.media_product_id = 9 and outpost_player.player_name = outpost_player_xref.player_name)
and				film_campaign.confirmed_date between @start_period and @end_period
group by 	film_campaign.confirmed_cost,
			film_campaign.campaign_no,
			product_desc,
			branch.branch_code,
			branch_name, 
			outpost_package.package_id,
			package_code,
			package_desc,
			client_name,  
			client.client_id, 
			agency_name, 
			agency.agency_id,
			agency_group_name, 
			buying_group_desc,
			outpost_package.charge_rate,
			film_campaign.confirmed_date,
			film_campaign.business_unit_id
union all
select 		film_campaign.campaign_no,
			product_desc,
			dbo.f_campaign_repname(film_campaign.campaign_no),
			branch.branch_code,
			branch_name, 
			'Retail Super Wall',
			outpost_package.package_id,
			package_code,
			package_desc,
			client_name,  
			client.client_id, 
			agency_name, 
			agency.agency_id,
			agency_group_name, 
			buying_group_desc,
			film_campaign.confirmed_date,
			film_campaign.confirmed_cost,
			isnull(sum(outpost_spot.charge_rate),0),
			isnull(outpost_package.charge_rate,0),
			isnull(sum(case spot_type when 'S' then 1 else 0 end),0),
			isnull(sum(case spot_type when 'B' then 1 when 'C' then 1 when 'N' then 1 when 'W' then 1 else 0 end),0),
			film_campaign.business_unit_id
from   		client,  
				film_campaign,
				outpost_package, 
				outpost_spot,					
				branch,
				agency, 
				agency_groups, 
				agency_buying_groups
where   		client.client_id = film_campaign.client_id
and     		agency.agency_group_id = agency_groups.agency_group_id
and     		agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     		agency.agency_id = film_campaign.reporting_agency
and				film_campaign.campaign_no  = outpost_package.campaign_no
and				outpost_package.package_id = outpost_spot.package_id
and				film_campaign.branch_code = branch.branch_code
and				branch.country_code = @country_code
and				film_campaign.campaign_status <> 'P'
and				outpost_package.package_status <> 'P'
and				outpost_spot.spot_status <> 'P'
and				outpost_panel_id in (select outpost_panel_id from outpost_player_xref, outpost_player where outpost_player.media_product_id = 11 and outpost_player.player_name = outpost_player_xref.player_name)
and				film_campaign.confirmed_date between @start_period and @end_period
group by 	film_campaign.confirmed_cost,
			film_campaign.campaign_no,
			product_desc,
			branch.branch_code,
			branch_name, 
			outpost_package.package_id,
			package_code,
			package_desc,
			client_name,  
			client.client_id, 
			agency_name, 
			agency.agency_id,
			agency_group_name, 
			buying_group_desc,
			outpost_package.charge_rate,
			film_campaign.confirmed_date,
			film_campaign.business_unit_id
union all
select 		film_campaign.campaign_no,
			product_desc,
			dbo.f_campaign_repname(film_campaign.campaign_no),
			branch.branch_code,
			branch_name, 
			'Cinemarketing',
			inclusion.inclusion_id,
			'',
			inclusion_desc,
			client_name,  
			client.client_id, 
			agency_name, 
			agency.agency_id,
			agency_group_name, 
			buying_group_desc,
			film_campaign.confirmed_date,
			film_campaign.confirmed_cost,
			isnull(sum(inclusion_spot.charge_rate),0),
			isnull(inclusion.inclusion_charge,0),
			isnull(sum(case spot_type when 'S' then 1 else 0 end),0),
			isnull(sum(case spot_type when 'B' then 1 when 'C' then 1 when 'N' then 1 when 'W' then 1 else 0 end),0),
			film_campaign.business_unit_id
from   		client,  
			film_campaign,
			inclusion, 
			inclusion_spot,					
			branch,
			agency, 
			agency_groups, 
			agency_buying_groups
where   		client.client_id = film_campaign.client_id
and     		agency.agency_group_id = agency_groups.agency_group_id
and     		agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     		agency.agency_id = film_campaign.reporting_agency
and				film_campaign.campaign_no  = inclusion.campaign_no
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				film_campaign.branch_code = branch.branch_code
and				branch.country_code = @country_code
and				film_campaign.campaign_status <> 'P'
and				inclusion.inclusion_status <> 'P'
and				inclusion_spot.spot_status <> 'P'
and				inclusion_type = 5
and				film_campaign.confirmed_date between @start_period and @end_period
group by 	film_campaign.confirmed_cost,
			film_campaign.campaign_no,
			product_desc,
			branch.branch_code,
			branch_name, 
			inclusion.inclusion_id,
			inclusion_desc,
			client_name,  
			client.client_id, 
			agency_name, 
			agency.agency_id,
			agency_group_name, 
			buying_group_desc,
			inclusion.inclusion_charge,
			film_campaign.confirmed_date,
			film_campaign.business_unit_id
union all
select 		film_campaign.campaign_no,
			product_desc,
			dbo.f_campaign_repname(film_campaign.campaign_no),
			branch.branch_code,
			branch_name, 
			'Retail Moving Wall',
			inclusion.inclusion_id,
			'',
			inclusion_desc,
			client_name,  
			client.client_id, 
			agency_name, 
			agency.agency_id,
			agency_group_name, 
			buying_group_desc,
			film_campaign.confirmed_date,
			film_campaign.confirmed_cost,
			isnull(sum(inclusion_spot.charge_rate),0),
			isnull(inclusion.inclusion_charge,0),
			isnull(sum(case spot_type when 'S' then 1 else 0 end),0),
			isnull(sum(case spot_type when 'B' then 1 when 'C' then 1 when 'N' then 1 when 'W' then 1 else 0 end),0),
			film_campaign.business_unit_id
from   		client,  
			film_campaign,
			inclusion, 
			inclusion_spot,
			branch,
			agency, 
			agency_groups, 
			agency_buying_groups
where   		client.client_id = film_campaign.client_id
and     		agency.agency_group_id = agency_groups.agency_group_id
and     		agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     		agency.agency_id = film_campaign.reporting_agency
and				film_campaign.campaign_no  = inclusion.campaign_no
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				film_campaign.branch_code = branch.branch_code
and				branch.country_code = @country_code
and				film_campaign.campaign_status <> 'P'
and				inclusion.inclusion_status <> 'P'
and				inclusion_spot.spot_status <> 'P'
and				inclusion_type = 18
and				film_campaign.confirmed_date between @start_period and @end_period
group by 	film_campaign.confirmed_cost,
			film_campaign.campaign_no,
			product_desc,
			branch.branch_code,
			branch_name, 
			inclusion.inclusion_id,
			inclusion_desc,
			client_name,  
			client.client_id, 
			agency_name, 
			agency.agency_id,
			agency_group_name, 
			buying_group_desc,
			inclusion.inclusion_charge,
			film_campaign.confirmed_date,
			film_campaign.business_unit_id

--DYI 2012-05-03 Additional sort
update 	#client_data
set sort_add = temp.sort_add
from ( SELECT ROW_NUMBER() OVER(PARTITION BY sort_add ORDER BY campaign_revenue desc) AS sort_add,
			sort_order  = sort_order
		from #client_data) as temp
where #client_data.sort_order  = temp.sort_order

update 	#client_data
set campaign_row_number = temp.campaign_row_number
from ( SELECT ROW_NUMBER() OVER(PARTITION BY campaign_no ORDER BY package_code desc) AS campaign_row_number,
			sort_order  = sort_order
		from #client_data) as temp
where #client_data.sort_order  = temp.sort_order

delete 	#client_data 
where	sort_add > @top_var

SELECT	sort_order,
		sort_add,
		branch_code,
		branch_name,
		rep_name,
		campaign_no,
		product_desc,
		package_type,
		package_id,
		package_code,
		package_desc,
		client_name,
		client_id,
		agency_name,
		agency_id,
		agency_group,
		agency_buying,
		confirmed,
		campaign_revenue,
		package_revenue,
		package_rate,
		package_paid_screens,
		package_bonus_screens,
		@country_code AS country_code, 
		@start_period AS start_period,
		@end_period AS end_period,
		business_unit_id,
		campaign_row_number
from #client_data 
--order by campaign_revenue desc
order by business_unit_id, branch_name, rep_name, agency_name, campaign_no
--order by campaign_no, package_id, package_code

return 0
GO
