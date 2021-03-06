/****** Object:  View [dbo].[v_test_Tableau_Team_Rep_figures]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_test_Tableau_Team_Rep_figures]
GO
/****** Object:  View [dbo].[v_test_Tableau_Team_Rep_figures]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

--drop view v__test_Tableau_Team_Rep_figures
CREATE	VIEW [dbo].[v_test_Tableau_Team_Rep_figures] AS 
( 
SELECT	DISTINCT 	CAST(v_statrev_rep.campaign_no AS varchar) campaign_no,
					film_campaign.product_desc,
					v_statrev_rep.rep_id,
					client_group.client_group_desc,
					client.client_name,
					agency.agency_name,
					agency_groups.agency_group_name,
					v_statrev_rep.branch_code, 
					branch.branch_name, 
					buying_group_desc,
					statrev_revision_team_xref.team_id,
					v_statrev_rep.revenue_group,
					v_statrev_rep.revenue_group_desc,
					business_unit.business_unit_desc,
					film_campaign.business_unit_id,
					v_statrev_rep.revenue_period,
					v_statrev_rep.transaction_type,
					Sum(v_statrev_rep.cost) AS Revenue,
					v_statrev_rep.country_code,
					sales_team.team_name,
					sales_rep.first_name + ' ' + sales_rep.last_name As Rep_Name,
					'Team' AS mode,
(Select budget FROM statrev_budgets_rep
		WHERE v_statrev_rep.revenue_period = statrev_budgets_rep.revenue_period
		and		v_statrev_rep.revenue_group = statrev_budgets_rep.revenue_group
		and     statrev_budgets_rep.business_unit_id = film_campaign.business_unit_id
		and		statrev_revision_team_xref.team_id = statrev_budgets_rep.team_id)
		AS Budget,	
(Select sum(budget)/3 FROM statrev_budgets_rep
		WHERE Year(v_statrev_rep.revenue_period) = Year(statrev_budgets_rep.revenue_period)
		AND   DATEPART(Q,v_statrev_rep.revenue_period) = DATEPART(Q,statrev_budgets_rep.revenue_period)
		and		v_statrev_rep.revenue_group = statrev_budgets_rep.revenue_group
		and     statrev_budgets_rep.business_unit_id = film_campaign.business_unit_id
		and		statrev_revision_team_xref.team_id = statrev_budgets_rep.team_id)
		AS Qtr_Budget,
		1 AS Row		
FROM		        v_statrev_rep WITH (NOLOCK),
					statrev_revision_team_xref WITH (NOLOCK),
					film_campaign WITH (NOLOCK),
					sales_team WITH (NOLOCK),
					sales_rep WITH (NOLOCK),
					business_unit WITH (NOLOCK),
					client WITH (NOLOCK),
					client_group WITH (NOLOCK),
					agency WITH (NOLOCK),
					agency_buying_groups WITH (NOLOCK),
					agency_groups WITH (NOLOCK),
					branch WITH (NOLOCK)
WHERE	        v_statrev_rep.revision_id = statrev_revision_team_xref.revision_id
and				v_statrev_rep.campaign_no = film_campaign.campaign_no
and				v_statrev_rep.branch_code = branch.branch_code
and				statrev_revision_team_xref.team_id = sales_team.team_id
and				v_statrev_rep.rep_id = sales_rep.rep_id
and		client.client_group_id = client_group.client_group_id
and		client.client_id = film_campaign.client_id
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     agency.agency_id = film_campaign.reporting_agency
AND		film_campaign.business_unit_id = business_unit.business_unit_id
and     v_statrev_rep.rep_id IN (select Rep_ID from sales_rep where Status = 'A')
and v_statrev_rep.revenue_period >= '2014-01-23 00:00:00.000'
and v_statrev_rep.revenue_period <= '2014-12-25 00:00:00.000'
GROUP BY
v_statrev_rep.campaign_no,
film_campaign.product_desc,
v_statrev_rep.rep_id,
client_group.client_group_desc,
client.client_name,
agency.agency_name,
agency_groups.agency_group_name,
v_statrev_rep.branch_code, 
branch.branch_name, 
buying_group_desc,
statrev_revision_team_xref.team_id,
v_statrev_rep.revenue_group,
v_statrev_rep.revenue_group_desc,
v_statrev_rep.revenue_period,
v_statrev_rep.transaction_type,
v_statrev_rep.country_code,
sales_team.team_name,
sales_rep.first_name,
sales_rep.last_name,
film_campaign.business_unit_id,
business_unit.business_unit_desc
UNION ALL
SELECT	DISTINCT 	CAST(v_statrev_rep.campaign_no AS varchar) campaign_no,
					film_campaign.product_desc,
					v_statrev_rep.rep_id,
					client_group.client_group_desc,
					client.client_name,
					agency.agency_name,
					agency_groups.agency_group_name,
					v_statrev_rep.branch_code, 
					branch.branch_name,  
					buying_group_desc,					 
					null,
					v_statrev_rep.revenue_group,
					v_statrev_rep.revenue_group_desc,
					business_unit.business_unit_desc,
					film_campaign.business_unit_id,
					v_statrev_rep.revenue_period,
					v_statrev_rep.transaction_type,
					sum(v_statrev_rep.cost) AS Revenue,
					v_statrev_rep.country_code,
					null,
					sales_rep.first_name + ' ' + sales_rep.last_name As Rep_Name,
					'Sales Rep' AS Mode,
(Select budget FROM statrev_budgets_rep
		WHERE   v_statrev_rep.revenue_period = statrev_budgets_rep.revenue_period
		and     statrev_budgets_rep.business_unit_id = film_campaign.business_unit_id
		and		v_statrev_rep.rep_id = statrev_budgets_rep.rep_id)
		AS Budget,
(Select sum(budget)/3 FROM statrev_budgets_rep
		WHERE Year(v_statrev_rep.revenue_period) = year(statrev_budgets_rep.revenue_period)
		AND   DATEPART(Q,v_statrev_rep.revenue_period) = DATEPART(Q,statrev_budgets_rep.revenue_period)
		and     statrev_budgets_rep.business_unit_id = film_campaign.business_unit_id
		and		v_statrev_rep.rep_id = statrev_budgets_rep.rep_id)
		AS Qtr_Budget,
		1 AS Row				
FROM	v_statrev_rep,
					film_campaign WITH (NOLOCK),
					sales_rep WITH (NOLOCK),
					branch WITH (NOLOCK),
					client WITH (NOLOCK),
					business_unit WITH (NOLOCK),
					client_group WITH (NOLOCK),
					agency WITH (NOLOCK),
					agency_buying_groups WITH (NOLOCK),
					agency_groups WITH (NOLOCK)--,
--					statrev_budgets_rep
WHERE	v_statrev_rep.campaign_no = film_campaign.campaign_no
and		v_statrev_rep.branch_code = branch.branch_code
and		v_statrev_rep.rep_id = sales_rep.rep_id
and		client.client_group_id = client_group.client_group_id
and		client.client_id = film_campaign.client_id
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     agency.agency_id = film_campaign.reporting_agency
and		business_unit.business_unit_id = film_campaign.business_unit_id
and     v_statrev_rep.rep_id IN (select rep_ID from sales_rep where Status = 'A')
and v_statrev_rep.revenue_period >= '2014-07-23 00:00:00.000'
and v_statrev_rep.revenue_period <= '2014-09-24 00:00:00.000'
--and v_statrev_rep.rep_ID = 1844
GROUP BY
v_statrev_rep.campaign_no,
film_campaign.product_desc,
v_statrev_rep.rep_id,
client_group.client_group_desc,
client.client_name,
agency.agency_name,
agency_groups.agency_group_name,
v_statrev_rep.branch_code, 
branch.branch_name,  
buying_group_desc,					 
v_statrev_rep.revenue_group,
v_statrev_rep.revenue_group_desc,
business_unit.business_unit_desc,
film_campaign.business_unit_id,
v_statrev_rep.revenue_period,
v_statrev_rep.transaction_type,
v_statrev_rep.country_code,
sales_rep.first_name,
sales_rep.last_name
)

GO
