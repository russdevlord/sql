/****** Object:  View [dbo].[v_bi_statrev_unit_report]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_bi_statrev_unit_report]
GO
/****** Object:  View [dbo].[v_bi_statrev_unit_report]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_bi_statrev_unit_report] AS
SELECT DISTINCT a.campaign_no, c.country_code, b.client_id, b.client_group_id, b.Client_Name, c.client_group_desc, e.agency_name, f.agency_group_name,
buying_group_desc, 
a.branch_name,
a.business_unit_desc, 
a.master_revenue_group_desc, 
a.revenue_group_desc, 
a.statrev_transaction_type_desc, 
e.agency_id,
e.agency_group_id,
sum(a.cost) as rev, 
case month(a.revenue_period) 
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
case month(revenue_period) 
when 1 then 'January' 
when 2 then 'February'
when 3 then 'March'
when 4 then 'April' 
when 5 then 'May' 
when 6 then 'June' 
when 7 then 'July' 
when 8 then 'August' 
when 9 then 'September' 
when 10 then 'October'
when 11 then 'November'
when 12 then 'December' end as fin_Month
FROM v_Statrev a
JOIN film_campaign d
ON d.campaign_no = a.campaign_no
JOIN Client b
ON b.client_id = d.client_id
JOIN client_group c
ON b.client_group_id = c.client_group_id
AND a.country_code = c.country_code
JOIN agency e
ON e.agency_id = d.reporting_agency
JOIN agency_groups F 
ON e.agency_group_id = f.agency_group_id
JOIN agency_buying_groups g
ON f.buying_group_id = g.buying_group_id
WHERE c.country_code = 'A'
GROUP BY 
a.campaign_no, c.country_code, b.client_id, b.client_group_id, b.Client_Name, c.client_group_desc, e.agency_name, f.agency_group_name,
buying_group_desc, 
a.branch_name,
a.business_unit_desc, 
a.master_revenue_group_desc, 
a.revenue_group_desc, 
a.statrev_transaction_type_desc, 
e.agency_id,
e.agency_group_id,
a.revenue_period
GO
