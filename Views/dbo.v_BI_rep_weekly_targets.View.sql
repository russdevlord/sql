/****** Object:  View [dbo].[v_BI_rep_weekly_targets]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_BI_rep_weekly_targets]
GO
/****** Object:  View [dbo].[v_BI_rep_weekly_targets]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create View [dbo].[v_BI_rep_weekly_targets] AS
SELECT DISTINCT Team_ID, Delta_Week_no, Delta_week, rep_id, Rep_name, branch_name, ISNULL(revenue,0) AS Revenue, ISNULL(budget,0) AS Budget, fin_qtr, business_unit_desc, master_revenue_group_desc, team_name
FROM
(
Select DISTINCT a.Team_ID, DATEPART(WEEK,a.Delta_date) Delta_Week_no, DATEADD(WW, DATEDIFF(ww, 0, a.Delta_date),-1) AS Delta_week, a.rep_id, a.rep_name, a.Branch_name, SUM(a.rev) AS revenue, 
b.budget, a.fin_qtr, a.business_unit_desc, a.master_revenue_group_desc, c.team_name
FROM v_bi_statrev_agency_week_rep a
LEFT JOIN statrev_budgets_rep b
ON a.revenue_period = b.revenue_period
and a.rep_ID = b.Rep_Id
and a.branch_name NOT IN ('New Zealand')
LEFT JOIN sales_team c
ON a.team_ID = c.team_id
Group BY a.Team_ID, a.delta_date, a.rep_id, a.rep_name, a.branch_name,  b.budget, a.fin_qtr, a.business_unit_desc, a.master_revenue_group_desc, c.team_name 
)a
Where revenue <> '0.00000000'
AND Delta_Week > = '2013-06-30'
ANd Delta_week <=  '2014-06-01'


GO
