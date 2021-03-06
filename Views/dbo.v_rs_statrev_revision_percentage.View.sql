/****** Object:  View [dbo].[v_rs_statrev_revision_percentage]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_rs_statrev_revision_percentage]
GO
/****** Object:  View [dbo].[v_rs_statrev_revision_percentage]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW  [dbo].[v_rs_statrev_revision_percentage] (
		campaign_no,
		rep_id,
		rep_name,
		team_id,
		team_name,
		client_id,
		client_name,
		client_group_id,
		client_group_desc,
		agency_id,
		agency_name,
		agency_group_id,
		agency_group_name,
		buying_group_id,
		buying_group_desc,
		product_category_id,
		product_category_desc,
		branch_code,
		branch_name,
		business_unit_id, 
		business_unit_desc, 
		revenue_group_id,
		revenue_group_desc,
		master_revenue_group_id, 
		master_revenue_group_desc, 
		figure,
		revenue_percent,
		revenue_period )
AS

select  VV.campaign_no,
		VV.rep_id,
		rep_name = sales_rep.last_name + ', ' + sales_rep.first_name,
		sales_team.team_id,
		sales_team.team_name,
		VV.client_id,
		client.client_name,
		client_group.client_group_id,
		client_group.client_group_desc,
		VV.agency_id,
		agency.agency_name,
		agency_groups.agency_group_id,
		agency_groups.agency_group_name,
		agency_buying_groups.buying_group_id,
		agency_buying_groups.buying_group_desc,
		product_category.product_category_id,
		product_category.product_category_desc,
		VV.branch_code,
		VV.branch_name,
		VV.business_unit_id, 
		VV.business_unit_desc, 
		VV.revenue_group,
		VV.revenue_group_desc,
		VV.master_revenue_group, 
		VV.master_revenue_group_desc, 
		figure = SUM(VV.cost),
		STX.revenue_percent,
		VV.revenue_period
from    v_statrev_report VV, 
		v_campaign_product_category,
		product_category,
		client,
		client_group,
		agency,
		agency_groups, 
		agency_buying_groups,
		sales_rep,
		sales_team_members,
		sales_team,
		statrev_revision_rep_xref STX
where	--VV.revenue_period BETWEEN @PERIOD_START AND @PERIOD_END AND		
		VV.revision_id = STX.revision_id
AND		VV.rep_id = STX.rep_id
and     VV.campaign_no = v_campaign_product_category.campaign_no
and     VV.business_unit_id = v_campaign_product_category.business_unit_id
AND		v_campaign_product_category.product_category = product_category.product_category_id
AND		VV.client_id = client.client_id
AND		client.client_group_id = client_group.client_group_id
AND		VV.agency_id = agency.agency_id
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
AND		VV.rep_id = sales_rep.rep_id
and		sales_rep.rep_id = sales_team_members.rep_id
and		sales_team_members.team_id = sales_team.team_id
--AND		( VV.country_code = @country_code OR @country_code = '')
--AND		( VV.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
--AND		( VV.revenue_group = @revenue_group OR @revenue_group = 0 )
--AND		( sales_rep.rep_id = @rep_id OR @rep_id = 0 )
--AND		( sales_team.team_id = @team_id OR @team_id = 0 )
--and		(( VV.revenue_period between @PERIOD_START and @PERIOD_END )) -- OR @revenue_period IS NULL)
--AND		( VV.revenue_group >= ( CASE @report_type When 'O' Then 50 Else 0 End )
--AND		  VV.revenue_group < ( CASE @report_type When 'C' Then 50 Else 1000 End ))
--AND		( VV.campaign_no = @campaign_no OR @campaign_no = 0 )
group by	VV.campaign_no,
		VV.revenue_period,
		VV.rep_id,
		sales_rep.last_name,
		sales_rep.first_name,
		sales_team.team_id,
		sales_team.team_name,
		VV.client_id,
		client.client_name,
		client_group.client_group_id,
		client_group.client_group_desc,
		VV.agency_id,
		agency.agency_name,
		agency_groups.agency_group_id,
		agency_groups.agency_group_name,
		agency_buying_groups.buying_group_id,
		agency_buying_groups.buying_group_desc,
		product_category.product_category_id,
		product_category.product_category_desc,
		VV.branch_code,
		VV.branch_name,
		VV.business_unit_id, 
		VV.business_unit_desc, 
		VV.revenue_group,
		VV.revenue_group_desc,
		VV.master_revenue_group, 
		VV.master_revenue_group_desc, 
		STX.revenue_percent
GO
