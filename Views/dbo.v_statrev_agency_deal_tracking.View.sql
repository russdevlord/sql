/****** Object:  View [dbo].[v_statrev_agency_deal_tracking]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statrev_agency_deal_tracking]
GO
/****** Object:  View [dbo].[v_statrev_agency_deal_tracking]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO




create view [dbo].[v_statrev_agency_deal_tracking] as
select			client_name,  
				client_group_desc, 
				agency_name, 
				agency_group_name, 
				buying_group_desc,
				v_statrev.branch_name,
				v_statrev.business_unit_desc, 
				v_statrev.revenue_period,
				sum(cost) as rev, 
				year(v_statrev.revenue_period) as cal_year, 
				accounting_period.finyear_end, 
				v_statrev.country_code 
from			client with (nolock), 
				client_group with (nolock), 
				v_statrev with (nolock), 
				film_campaign with (nolock), 
				agency with (nolock), 
				agency_groups with (nolock), 
				agency_buying_groups with (nolock), 
				accounting_period with (nolock)
where			client.client_group_id = client_group.client_group_id
and				client.client_id = film_campaign.client_id
and				film_campaign.campaign_no = v_statrev.campaign_no
and				agency.agency_group_id = agency_groups.agency_group_id
and				agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and				agency.agency_id = film_campaign.reporting_agency
and				revenue_period > '1-jan-2016'
and				accounting_period.end_date = v_statrev.revenue_period
group by		client_name,  
				client_group_desc, 
				agency_name, 
				agency_group_name, 
				buying_group_desc,
				v_statrev.branch_name,
				v_statrev.business_unit_desc, 
				v_statrev.revenue_period,
				year(v_statrev.revenue_period), 
				accounting_period.finyear_end, 
				v_statrev.country_code 



--select* from agency_buying_groups




GO
