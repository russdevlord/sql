/****** Object:  View [dbo].[v_statrev_detailed_week]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statrev_detailed_week]
GO
/****** Object:  View [dbo].[v_statrev_detailed_week]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



create view [dbo].[v_statrev_detailed_week]
as
select  client_name,  client_group_desc, agency_name, agency_group_name, buying_group_desc,v_statrev_no_deferred.branch_name,v_statrev_no_deferred.business_unit_desc, v_statrev_no_deferred.master_revenue_group_desc, v_statrev_no_deferred.revenue_group_desc, v_statrev_no_deferred.statrev_transaction_type_desc, v_statrev_no_deferred.revenue_period,v_statrev_no_deferred.screening_date,sum(cost) as rev, year(v_statrev_no_deferred.revenue_period) as cal_year, accounting_period.finyear_end, v_statrev_no_deferred.country_code , film_campaign.campaign_no, film_campaign.product_desc
from    client, client_group, v_statrev_no_deferred, film_campaign, agency, agency_groups, agency_buying_groups, accounting_period
where   client.client_group_id = client_group.client_group_id
and     client.client_id = film_campaign.client_id
and     film_campaign.campaign_no = v_statrev_no_deferred.campaign_no
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     agency.agency_id = film_campaign.reporting_agency
--and business_unit_desc = 'Agency Sales Dept' 
--and branch_name = 'New South Wales'
and revenue_period > '1-jan-2013'
--and agency_buying_groups.buying_group_id = 3
and accounting_period.end_date = v_statrev_no_deferred.revenue_period
group by client_name,  client_group_desc, agency_name, agency_group_name, buying_group_desc, v_statrev_no_deferred.branch_name,v_statrev_no_deferred.business_unit_desc, v_statrev_no_deferred.master_revenue_group_desc, v_statrev_no_deferred.revenue_group_desc, v_statrev_no_deferred.statrev_transaction_type_desc, v_statrev_no_deferred.revenue_period, accounting_period.finyear_end, v_statrev_no_deferred.country_code, film_campaign.campaign_no, film_campaign.product_desc,v_statrev_no_deferred.screening_date



--select* from agency_buying_groups





GO
