/****** Object:  View [dbo].[v_projrev_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_projrev_report]
GO
/****** Object:  View [dbo].[v_projrev_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[v_projrev_report] (
		revision_group, 
		country_code, 
		branch_code, 
		business_unit_id, 
		revenue_period, 
		delta_date, 
		reporting_year, 
		cost, 
		budget, 
		forecast, 
		report_type)
AS 

SELECT	revision_group.revision_group,
		branch.country_code,
		film_campaign.branch_code,
		film_campaign.business_unit_id,
		xtran.revenue_period,
		xtran.delta_date,
		DATEPART(YEAR, GETDATE()), --calendar_week.reporting_year,
		SUM(COST),
		CONVERT(MONEY, NULL),
		CONVERT(MONEY, NULL),
		CONVERT(VARCHAR(1), 'C')
FROM	campaign_revision,
		film_campaign,
		revision_transaction xtran,
		--revenue_calendar_week calendar_week,
		revision_transaction_type,
		revision_group,
		branch
WHERE	( film_campaign.campaign_no = campaign_revision.campaign_no )
AND		( campaign_revision.revision_id = xtran.revision_id )
AND		( xtran.revision_transaction_type = revision_transaction_type.revision_transaction_type )
AND		( revision_transaction_type.revision_group = revision_group.revision_group )
--AND		( calendar_week.screening_date = xtran.billing_date )
--AND		( calendar_week.benchmark_end = xtran.revenue_period )
--AND		( calendar_week.reporting_year = DATEPART(YEAR, GETDATE()))
--AND		( calendar_week.calendar = 'CY')
AND		( film_campaign.branch_code = branch.branch_code )
GROUP BY revision_group.revision_group,
		branch.country_code,
		film_campaign.branch_code,
		film_campaign.business_unit_id,
		--calendar_week.reporting_year,
		xtran.revenue_period,
		xtran.delta_date
UNION
SELECT	revision_group.revision_group,
		branch.country_code,
		film_campaign.branch_code,
		film_campaign.business_unit_id,
		xtran.revenue_period,
		xtran.delta_date,
		DATEPART(YEAR, GETDATE()), --calendar_week.reporting_year,
		SUM(COST),
		CONVERT(MONEY, NULL),
		CONVERT(MONEY, NULL),
		CONVERT(VARCHAR(1), 'O')
FROM	campaign_revision,
		film_campaign,
		outpost_revision_transaction xtran,
		--outpost_revenue_calendar_week calendar_week,
		revision_transaction_type,
		revision_group,
		branch
WHERE	( film_campaign.campaign_no = campaign_revision.campaign_no )
AND		( campaign_revision.revision_id = xtran.revision_id )
AND		( xtran.revision_transaction_type = revision_transaction_type.revision_transaction_type )
AND		( revision_transaction_type.revision_group = revision_group.revision_group )
--AND		( calendar_week.screening_date = xtran.billing_date )
--AND		( calendar_week.benchmark_end = xtran.revenue_period )
--AND		( calendar_week.reporting_year = DATEPART(YEAR, GETDATE()))
--AND		( calendar_week.calendar = 'CY')
AND		( film_campaign.branch_code = branch.branch_code )
GROUP BY revision_group.revision_group,
		branch.country_code,
		film_campaign.branch_code,
		film_campaign.business_unit_id,
		--calendar_week.reporting_year,
		xtran.revenue_period,
		xtran.delta_date
UNION
SELECT	budgets.revision_group,
		branch.country_code,
		budgets.branch_code,
		budgets.business_unit_id,
		budgets.revenue_period,
		NULL,
		DATEPART(YEAR, GETDATE()),
		CONVERT(MONEY, NULL),
		SUM(budget),
		SUM(forecast),
		CONVERT(VARCHAR(1), 'C')
FROM	revenue_budgets budgets,
		--revenue_calendar_month,   
		revision_group,
		branch
WHERE	( budgets.revision_group = revision_group.revision_group )
--AND		( revenue_calendar_month.benchmark_end = budgets.revenue_period )
--AND		( revenue_calendar_month.calendar = 'CY' )
AND		( budgets.branch_code = branch.branch_code )
GROUP BY budgets.revision_group,
		branch.country_code,
		budgets.branch_code,
		budgets.business_unit_id,
		budgets.revenue_period
UNION
SELECT	budgets.revision_group,
		branch.country_code,
		budgets.branch_code,
		budgets.business_unit_id,
		budgets.revenue_period,
		NULL,
		DATEPART(YEAR, GETDATE()),
		CONVERT(MONEY, NULL),
		SUM(budget),
		SUM(forecast),
		CONVERT(VARCHAR(1), 'O')
FROM	outpost_revenue_budgets budgets,
		--revenue_calendar_month,   
		revision_group,
		branch
WHERE	( budgets.revision_group = revision_group.revision_group )
--AND		( revenue_calendar_month.benchmark_end = budgets.revenue_period )
--AND		( revenue_calendar_month.calendar = 'CY' )
AND		( budgets.branch_code = branch.branch_code )
GROUP BY budgets.revision_group,
		branch.country_code,
		budgets.branch_code,
		budgets.business_unit_id,
		budgets.revenue_period
		
GO
