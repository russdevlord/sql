/****** Object:  View [dbo].[v_statrev_details_cinema_no_def]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statrev_details_cinema_no_def]
GO
/****** Object:  View [dbo].[v_statrev_details_cinema_no_def]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


create view [dbo].[v_statrev_details_cinema_no_def] as
select  client_name,  client_group_desc, agency_name, agency_group_name, buying_group_desc,v_statrev_cinema_no_def.branch_name,v_statrev_cinema_no_def.business_unit_desc, v_statrev_cinema_no_def.master_revenue_group_desc, v_statrev_cinema_no_def.revenue_group_desc, v_statrev_cinema_no_def.statrev_transaction_type_desc, v_statrev_cinema_no_def.revenue_period,sum(cost) as rev, year(v_statrev_cinema_no_def.revenue_period) as cal_year, accounting_period.finyear_end, v_statrev_cinema_no_def.country_code, v_statrev_cinema_no_def.branch_code , v_statrev_cinema_no_def.master_revenue_group, v_statrev_cinema_no_def.revenue_group, v_statrev_cinema_no_def.business_unit_id
from    client, client_group, v_statrev_cinema_no_def, film_campaign, agency, agency_groups, agency_buying_groups, accounting_period
where   client.client_group_id = client_group.client_group_id
and     client.client_id = film_campaign.client_id
and     film_campaign.campaign_no = v_statrev_cinema_no_def.campaign_no
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     agency.agency_id = film_campaign.reporting_agency
and revenue_period > '1-jan-2009'
and accounting_period.end_date = v_statrev_cinema_no_def.revenue_period
group by client_name,  client_group_desc, agency_name, agency_group_name, buying_group_desc, v_statrev_cinema_no_def.branch_name,v_statrev_cinema_no_def.business_unit_desc, v_statrev_cinema_no_def.master_revenue_group_desc, v_statrev_cinema_no_def.revenue_group_desc, v_statrev_cinema_no_def.statrev_transaction_type_desc, v_statrev_cinema_no_def.revenue_period, accounting_period.finyear_end, v_statrev_cinema_no_def.country_code ,v_statrev_cinema_no_def.branch_code, v_statrev_cinema_no_def.master_revenue_group,v_statrev_cinema_no_def.revenue_group,v_statrev_cinema_no_def.business_unit_id


GO
