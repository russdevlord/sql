USE [production]
GO
/****** Object:  View [dbo].[v_statrev_detailed]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


create view [dbo].[v_statrev_detailed]
as
select  client.client_id, client_name,  client_group_desc, agency_name, agency_group_name, buying_group_desc,v_statrev.branch_name,v_statrev.business_unit_desc, v_statrev.master_revenue_group_desc, v_statrev.revenue_group_desc, v_statrev.statrev_transaction_type_desc, v_statrev.revenue_period,sum(cost) as rev, year(v_statrev.revenue_period) as cal_year, accounting_period.finyear_end, v_statrev.country_code , film_campaign.campaign_no, film_campaign.product_desc
from    client, client_group, v_statrev, film_campaign, agency, agency_groups, agency_buying_groups, accounting_period
where   client.client_group_id = client_group.client_group_id
and     client.client_id = film_campaign.client_id
and     film_campaign.campaign_no = v_statrev.campaign_no
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     agency.agency_id = film_campaign.reporting_agency
--and business_unit_desc = 'Agency Sales Dept' 
--and branch_name = 'New South Wales'
and revenue_period > '1-jan-2009'
--and agency_buying_groups.buying_group_id = 3
and accounting_period.end_date = v_statrev.revenue_period
group by client.client_id,  client_name,  client_group_desc, agency_name, agency_group_name, buying_group_desc, v_statrev.branch_name,v_statrev.business_unit_desc, v_statrev.master_revenue_group_desc, v_statrev.revenue_group_desc, v_statrev.statrev_transaction_type_desc, v_statrev.revenue_period, accounting_period.finyear_end, v_statrev.country_code, film_campaign.campaign_no, film_campaign.product_desc



--select* from agency_buying_groups




GO
