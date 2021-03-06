/****** Object:  View [dbo].[v_Tableau_statrev_product_cateogry_Reps]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_Tableau_statrev_product_cateogry_Reps]
GO
/****** Object:  View [dbo].[v_Tableau_statrev_product_cateogry_Reps]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


create view [dbo].[v_Tableau_statrev_product_cateogry_Reps] as
select  client_name,  client_group_desc, agency_name, agency_group_name, buying_group_desc, v_statrev.branch_name,
v_statrev.business_unit_desc, v_statrev.master_revenue_group_desc, v_statrev.revenue_group_desc, v_statrev.statrev_transaction_type_desc, 
product_category.product_category_desc,product_group.product_group_desc, v_statrev.revenue_period, year(revenue_period) as cal_year, 
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
when 1 then year(revenue_period)
when 2 then year(revenue_period)
when 3 then year(revenue_period)
when 4 then year(revenue_period)
when 5 then year(revenue_period)
when 6 then year(revenue_period)
when 7 then year(revenue_period) + 1 
when 8 then year(revenue_period) + 1
when 9 then year(revenue_period)  + 1
when 10 then year(revenue_period) + 1
when 11 then year(revenue_period) + 1
when 12 then year(revenue_period) + 1 end as fin_year,
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
sum(cost) as revenue,
			sales_rep.rep_id,
			sales_rep.first_name + ' ' + sales_rep.last_name as rep_name,
v_statrev.country_code AS Country			
from    
client WITH (NOLOCK), 
client_group WITH (NOLOCK), 
v_statrev WITH (NOLOCK), 
film_campaign WITH (NOLOCK), 
agency WITH (NOLOCK), 
agency_groups WITH (NOLOCK), 
agency_buying_groups WITH (NOLOCK), 
v_campaign_product_category WITH (NOLOCK), 
product_category WITH (NOLOCK), 
product_group WITH (NOLOCK),
sales_rep WITH (NOLOCK)
where   client.client_group_id = client_group.client_group_id
and     client.client_id = film_campaign.client_id
and     film_campaign.campaign_no = v_statrev.campaign_no
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     agency.agency_id = film_campaign.reporting_agency
and     v_campaign_product_category.product_category = product_category.product_category_id
and     v_campaign_product_category.campaign_no = film_campaign.campaign_no
and		film_campaign.rep_id = sales_rep.rep_id
and     revenue_period > '1-jan-2009'
--and 	revenue_period between '1-jan-2011' and '31-dec-2014'
and product_group.product_group_id = product_category.product_group
group by client_name,  
client_group_desc, 
agency_name, 
agency_group_name, 
buying_group_desc, 
v_statrev.branch_name,
v_statrev.business_unit_desc, 
v_statrev.master_revenue_group_desc, 
v_statrev.revenue_group_desc, 
v_statrev.statrev_transaction_type_desc, 
v_statrev.revenue_period, 
product_category.product_category_desc,
product_group.product_group_desc, 
sales_rep.rep_id, 
sales_rep.first_name, 
Sales_rep.last_name,
v_statrev.country_code


GO
