/****** Object:  View [dbo].[v_statrev_detailed_week_delta]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statrev_detailed_week_delta]
GO
/****** Object:  View [dbo].[v_statrev_detailed_week_delta]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO




create view [dbo].[v_statrev_detailed_week_delta]
as
select  client_name,  client_group_desc, agency_name, agency_group_name, buying_group_desc,v_statrev_no_deferred_post2015.branch_name,v_statrev_no_deferred_post2015.business_unit_desc, v_statrev_no_deferred_post2015.master_revenue_group_desc, v_statrev_no_deferred_post2015.revenue_group_desc, v_statrev_no_deferred_post2015.statrev_transaction_type_desc, v_statrev_no_deferred_post2015.revenue_period,v_statrev_no_deferred_post2015.screening_date,sum(cost) as rev, year(v_statrev_no_deferred_post2015.revenue_period) as cal_year, accounting_period.finyear_end, v_statrev_no_deferred_post2015.country_code , film_campaign.campaign_no, film_campaign.product_desc, delta_date
from    client, client_group, v_statrev_no_deferred_post2015, film_campaign, agency, agency_groups, agency_buying_groups, accounting_period
where   client.client_group_id = client_group.client_group_id
and     client.client_id = film_campaign.client_id
and     film_campaign.campaign_no = v_statrev_no_deferred_post2015.campaign_no
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     agency.agency_id = film_campaign.reporting_agency
and		business_unit_desc in ('Retail', 'Petro', 'Tower TV')
--and branch_name = 'New South Wales'
and revenue_period > '1-jan-2015'
--and agency_buying_groups.buying_group_id = 3
and accounting_period.end_date = v_statrev_no_deferred_post2015.revenue_period
group by client_name,  client_group_desc, agency_name, agency_group_name, buying_group_desc, v_statrev_no_deferred_post2015.branch_name,v_statrev_no_deferred_post2015.business_unit_desc, v_statrev_no_deferred_post2015.master_revenue_group_desc, v_statrev_no_deferred_post2015.revenue_group_desc, v_statrev_no_deferred_post2015.statrev_transaction_type_desc, v_statrev_no_deferred_post2015.revenue_period, accounting_period.finyear_end, v_statrev_no_deferred_post2015.country_code, film_campaign.campaign_no, film_campaign.product_desc,v_statrev_no_deferred_post2015.screening_date, delta_date





--select* from agency_buying_groups

--select distinct business_unit_desc from v_statrev_no_deferred_post2015

/*Agency Sales Dept
CINEads
Direct Sales Dept
Petro
Retail
Showcase
Tower TV*/




GO
