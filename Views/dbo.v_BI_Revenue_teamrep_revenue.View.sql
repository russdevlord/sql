/****** Object:  View [dbo].[v_BI_Revenue_teamrep_revenue]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_BI_Revenue_teamrep_revenue]
GO
/****** Object:  View [dbo].[v_BI_Revenue_teamrep_revenue]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--DROP VIEW v_BI_Revenue_teamrep_revenue
--Go

Create View [dbo].[v_BI_Revenue_teamrep_revenue] As	
--Create the Agency Budgets First
Select team_name, fin_year, fin_qtr, fin_month,  Current_Revenue, Last_year, rep_ID, team_ID, CASE WHEN rep_budget = 0 THEN Team_budget ELSE rep_budget END Budget
FROM
(
    Select DISTINCT a.team_name, a.fin_year, a.fin_qtr, a.fin_month, Sum(a.revcurr) Current_Revenue, Sum(a.prev_rev) Last_year, NULL rep_ID, b.team_ID, 0 rep_budget, b.budget Team_budget
    FROM BI_Rep_Revenue_Team_Final a
    FULL OUTER JOIN v_bi_statrev_budget_rep b
    ON a.fin_qtr = b.fin_qtr
	AND a.fin_year = b.fin_year
	AND a.fin_month = b.fin_month
	and a.team_ID = b.team_ID
	Where  b.team_ID NOT IN (24)
	Group BY a.team_name,a.team_ID, a.fin_year, a.fin_qtr, a.fin_month, b.Budget, b.team_ID	
--Now Union Direct Sales
	UNION ALL
	Select DISTINCT a.team_name, a.fin_year, a.fin_qtr, a.fin_month, Sum(a.revcurr) Current_Revenue, Sum(a.prev_rev) Last_year, NULL rep_ID, a.team_ID, 0 rep_budget, 0 Team_budget
    FROM BI_Rep_Revenue_Team_Final a
    Where a.team_ID IN (select Distinct team_ID from v_bi_statrev_budget_rep where budget = '0.00')
	And a.team_ID NOT IN (24)
	Group BY a.team_name,a.team_ID, a.fin_year, a.fin_qtr, a.fin_month
--Now Insert The Reps
	UNION ALL
    Select DISTINCT a.rep_name, a.fin_year, a.fin_qtr, a.fin_month, Sum(a.revcurr) Current_Revenue, Sum(a.prev_rev) Last_year, b.rep_ID, c.Team_ID, b.budget rep_Budget, 0 Team_Budget
    FROM bi_rep_revenue_final a
    LEFT JOIN v_bi_statrev_budget_rep b
    ON a.Rep_ID = b.Rep_ID
	AND a.fin_qtr = b.fin_qtr
	AND a.fin_year = b.fin_year
	AND a.fin_month = b.fin_month
	LEFT JOIN sales_team_members c
	on b.Rep_ID = c.rep_ID
	Where a.branch_name <> 'New Zealand'
    and b.rep_ID IS NOT NULL
	Group BY a.rep_name, a.fin_year, a.fin_qtr, a.fin_month, b.rep_ID, c.Team_ID, b.Budget 
--Now Insert The Reps who aren't Agency
	UNION ALL
    Select DISTINCT a.rep_name, a.fin_year, a.fin_qtr, a.fin_month,  Sum(a.revcurr) Current_Revenue, Sum(a.prev_rev) Last_year, a.rep_ID, c.Team_ID, 0 rep_Budget, 0 Team_Budget
    FROM bi_rep_revenue_final a
	LEFT JOIN sales_team_members c
	on a.Rep_ID = c.rep_ID
	Where a.branch_name <> 'New Zealand'
    AND a.Rep_ID IN (select Distinct rep_ID from v_bi_statrev_budget_rep where budget = '0.00')
	Group BY a.rep_name, a.fin_year, a.fin_qtr, a.fin_month, a.Rep_ID, c.Team_ID) a
GO
