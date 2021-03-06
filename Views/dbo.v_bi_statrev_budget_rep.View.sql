/****** Object:  View [dbo].[v_bi_statrev_budget_rep]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_bi_statrev_budget_rep]
GO
/****** Object:  View [dbo].[v_bi_statrev_budget_rep]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create View [dbo].[v_bi_statrev_budget_rep] AS
Select case month(revenue_period) 
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
when 12 then 'December' end as fin_Month,
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
rep_id, team_ID, Budget, revenue_period
From dbo.statrev_budgets_rep
GO
