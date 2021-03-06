/****** Object:  View [dbo].[v_statrev_agency_prod]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statrev_agency_prod]
GO
/****** Object:  View [dbo].[v_statrev_agency_prod]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view [dbo].[v_statrev_agency_prod]
as
select  film_campaign.campaign_no, 
film_campaign.product_desc,  
client_group_desc, 
client_name, 
agency_name, 
agency_group_name, 
buying_group_desc, 
v_statrev.branch_name,
v_statrev.business_unit_desc, 
v_statrev.master_revenue_group_desc, 
v_statrev.revenue_group_desc, 
v_statrev.statrev_transaction_type_desc, 
v_statrev.revenue_period,
sum(cost) as rev, 
year(v_statrev.revenue_period) as cal_year, 
accounting_period.finyear_end, 
case month(case revenue_period when '1-jul-2015' then '30-jun-2015' else revenue_period end)
when 1 then 'Q1' 
when 2 then 'Q1'
when 3 then 'Q1'
when 4 then 'Q2' 
when 5 then 'Q2' 
when 6 then 'Q2' 
when 7 then 'Q3' 
when 8 then 'Q3' 
when 9 then 'Q3' 
when 10 then 'Q4'
when 11 then 'Q4'
when 12 then 'Q4' end as cal_qtr,
case month(case revenue_period when '1-jul-2015' then '30-jun-2015' else revenue_period end)
when 1 then 'Q3' 
when 2 then 'Q3'
when 3 then 'Q3'
when 4 then 'Q4' 
when 5 then 'Q4' 
when 6 then 'Q4' 
when 7 then 'Q1' 
when 8 then 'Q1' 
when 9 then 'Q1' 
when 10 then 'Q2'
when 11 then 'Q2'
when 12 then 'Q2' end as fy_qtr,
v_statrev.country_code,client_product_desc
from    client, client_group, client_product, v_statrev, film_campaign, agency, agency_groups, agency_buying_groups, accounting_period
where   client.client_group_id = client_group.client_group_id
and     client.client_id = film_campaign.client_id
and     film_campaign.campaign_no = v_statrev.campaign_no
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     agency.agency_id = film_campaign.reporting_agency
and     film_campaign.client_product_id = client_product.client_product_id
and accounting_period.end_date = v_statrev.revenue_period
group by film_campaign.campaign_no, film_campaign.product_desc, client_name,  client_group_desc, agency_name, agency_group_name, buying_group_desc, v_statrev.revenue_group_desc,v_statrev.branch_name,v_statrev.business_unit_desc, v_statrev.master_revenue_group_desc, v_statrev.revenue_group_desc, v_statrev.statrev_transaction_type_desc, v_statrev.revenue_period, accounting_period.finyear_end, v_statrev.country_code, client_name, client_product_desc

GO
