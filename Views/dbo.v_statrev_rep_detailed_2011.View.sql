/****** Object:  View [dbo].[v_statrev_rep_detailed_2011]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statrev_rep_detailed_2011]
GO
/****** Object:  View [dbo].[v_statrev_rep_detailed_2011]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





create view [dbo].[v_statrev_rep_detailed_2011]
as
select  film_campaign.campaign_no, 
film_campaign.product_desc,  
client_group_desc, 
client_name, 
client.client_id,
agency_name, 
agency_group_name, 
buying_group_desc, 
v_statrev_rep.branch_name,
v_statrev_rep.business_unit_desc, 
v_statrev_rep.master_revenue_group_desc, 
v_statrev_rep.revenue_group_desc, 
v_statrev_rep.statrev_transaction_type_desc, 
v_statrev_rep.revenue_period,
--v_statrev_rep.screening_date,
--v_statrev_rep.delta_date,
sum(cost) as rev, 
year(v_statrev_rep.revenue_period) as cal_year, 
v_statrev_rep.country_code,
case month(revenue_period) 
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
case month(revenue_period) 
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
case month(revenue_period) 
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
when 12 then 'Q2' end as fin_qtr,
case month(revenue_period) 
when 1 then 'H1' 
when 2 then 'H1'
when 3 then 'H1'
when 4 then 'H1' 
when 5 then 'H1' 
when 6 then 'H1' 
when 7 then 'H2' 
when 8 then 'H2' 
when 9 then 'H2' 
when 10 then 'H2'
when 11 then 'H2'
when 12 then 'H2' end as cal_half,
case month(revenue_period) 
when 1 then 'H2' 
when 2 then 'H2'
when 3 then 'H2'
when 4 then 'H2' 
when 5 then 'H2' 
when 6 then 'H2' 
when 7 then 'H1' 
when 8 then 'H1' 
when 9 then 'H1' 
when 10 then 'H1'
when 11 then 'H1'
when 12 then 'H1' end as fin_half,
rep_name
from    client, client_group, v_statrev_rep, film_campaign, agency, agency_groups, agency_buying_groups
where   client.client_group_id = client_group.client_group_id
and     client.client_id = film_campaign.client_id
and     film_campaign.campaign_no = v_statrev_rep.campaign_no
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     agency.agency_id = film_campaign.reporting_agency
and		revenue_period > '1-jan-2015'
and		revenue_period <> '1-jul-2015'
and		film_campaign.business_unit_id not in (6,7,8)
group by film_campaign.campaign_no, film_campaign.product_desc, client_name,    client.client_id,client_group_desc, agency_name, agency_group_name, buying_group_desc, v_statrev_rep.revenue_group_desc,v_statrev_rep.branch_name,v_statrev_rep.business_unit_desc, v_statrev_rep.master_revenue_group_desc, v_statrev_rep.revenue_group_desc, v_statrev_rep.statrev_transaction_type_desc, v_statrev_rep.revenue_period, v_statrev_rep.country_code, client_name, rep_name
union
select  film_campaign.campaign_no, 
film_campaign.product_desc,  
client_group_desc, 
client_name, 
client.client_id,
agency_name, 
agency_group_name, 
buying_group_desc, 
v_statrev_rep.branch_name,
v_statrev_rep.business_unit_desc, 
v_statrev_rep.master_revenue_group_desc, 
v_statrev_rep.revenue_group_desc, 
v_statrev_rep.statrev_transaction_type_desc, 
v_statrev_rep.revenue_period,
--v_statrev_rep.screening_date,
--v_statrev_rep.delta_date,
sum(cost) as rev, 
year(v_statrev_rep.revenue_period) as cal_year, 
v_statrev_rep.country_code,
case month(revenue_period) 
when 1 then 'Q1' 
when 2 then 'Q1'
when 3 then 'Q1'
when 4 then 'Q2' 
when 5 then 'Q2' 
when 6 then 'Q2' 
when 7 then 'Q2' 
when 8 then 'Q3' 
when 9 then 'Q3' 
when 10 then 'Q4'
when 11 then 'Q4'
when 12 then 'Q4' end as cal_qtr,
case month(revenue_period) 
when 1 then year(revenue_period)
when 2 then year(revenue_period)
when 3 then year(revenue_period)
when 4 then year(revenue_period)
when 5 then year(revenue_period)
when 6 then year(revenue_period)
when 7 then year(revenue_period) 
when 8 then year(revenue_period) + 1
when 9 then year(revenue_period)  + 1
when 10 then year(revenue_period) + 1
when 11 then year(revenue_period) + 1
when 12 then year(revenue_period) + 1 end as fin_year,
case month(revenue_period) 
when 1 then 'Q3' 
when 2 then 'Q3'
when 3 then 'Q3'
when 4 then 'Q4' 
when 5 then 'Q4' 
when 6 then 'Q4' 
when 7 then 'Q4' 
when 8 then 'Q1' 
when 9 then 'Q1' 
when 10 then 'Q2'
when 11 then 'Q2'
when 12 then 'Q2' end as fin_qtr,
case month(revenue_period) 
when 1 then 'H1' 
when 2 then 'H1'
when 3 then 'H1'
when 4 then 'H1' 
when 5 then 'H1' 
when 6 then 'H1' 
when 7 then 'H4' 
when 8 then 'H2' 
when 9 then 'H2' 
when 10 then 'H2'
when 11 then 'H2'
when 12 then 'H2' end as cal_half,
case month(revenue_period) 
when 7 then 'H2' 
 end as fin_half,
rep_name
from    client, client_group, v_statrev_rep, film_campaign, agency, agency_groups, agency_buying_groups
where   client.client_group_id = client_group.client_group_id
and     client.client_id = film_campaign.client_id
and     film_campaign.campaign_no = v_statrev_rep.campaign_no
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     agency.agency_id = film_campaign.reporting_agency
and		revenue_period = '1-jul-2015'
and		film_campaign.business_unit_id not in (6,7,8)
group by film_campaign.campaign_no, film_campaign.product_desc, client_name,  client.client_id,  client_group_desc, agency_name, agency_group_name, buying_group_desc, v_statrev_rep.revenue_group_desc,v_statrev_rep.branch_name,v_statrev_rep.business_unit_desc, v_statrev_rep.master_revenue_group_desc, v_statrev_rep.revenue_group_desc, v_statrev_rep.statrev_transaction_type_desc, v_statrev_rep.revenue_period, v_statrev_rep.country_code, client_name, rep_name

GO
