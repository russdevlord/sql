/****** Object:  StoredProcedure [dbo].[rs_p_statrev_ARCPAG]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[rs_p_statrev_ARCPAG]
GO
/****** Object:  StoredProcedure [dbo].[rs_p_statrev_ARCPAG]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc  [dbo].[rs_p_statrev_ARCPAG]
	@PERIOD_START			datetime,
	@PERIOD_END				datetime,
	@client_id				INT,
	@client_group_id		INT,
	@agency_id				INT,
	@agency_group_id		INT,
	@product_category_id	INT,
	@team_id				INT,
	@rep_id					INT,
	@branch_code			varchar(1),
	@country_code			varchar(1),
	@business_unit_id		int,
	@revenue_group			int,
	@campaign_no			int,
	@report_type			varchar(1) -- 'C' - cinema, 'O' - outpost/retail, '' - All
AS

-- Generic proc for Statutory Revenue reports by
-- 1. Product
-- 2. Client
-- 3. Agency
-- 4. Agency Group
-- 5. Sales Rep

select  VV.campaign_no,
		campaign_name = VV.product_desc,
		VV.campaign_status,
		STX.rep_id,
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
		branch_code = CONVERT(VARCHAR(1), VV.branch_code),
		VV.branch_name,
		VV.business_unit_id,
		VV.business_unit_desc, 
		VV.revenue_group,
		VV.revenue_group_desc,
		VV.master_revenue_group,
		VV.master_revenue_group_desc,
		--VV.revision_id,
		--VV.revenue_period,
		revenue_percent = STX.revenue_percent,
		cost = CONVERT(MONEY, SUM(VV.cost)),
		figure = CONVERT(MONEY, SUM(VV.cost * STX.revenue_percent))
from    v_statrev_report VV INNER JOIN statrev_revision_rep_xref AS STX ON VV.revision_id = STX.revision_id, 
		v_campaign_product_category,
		product_category,
		client,
		client_group,
		agency,
		agency_groups, 
		agency_buying_groups,
		sales_rep,
		sales_team_members,
		sales_team
		--,statrev_revision_rep_xref STX
where	--VV.revision_id = STX.revision_id and
		VV.campaign_no = v_campaign_product_category.campaign_no
and     VV.business_unit_id = v_campaign_product_category.business_unit_id
AND		v_campaign_product_category.product_category = product_category.product_category_id
AND		VV.client_id = client.client_id
AND		client.client_group_id = client_group.client_group_id
AND		VV.agency_id = agency.agency_id
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
AND		STX.rep_id = sales_rep.rep_id
and		sales_rep.rep_id = sales_team_members.rep_id
and		sales_team_members.team_id = sales_team.team_id
AND		( client.client_id = @client_id OR @client_id = 0)
AND		( client_group.client_group_id = @client_group_id OR @client_group_id = 0)
AND		( agency.agency_id = @agency_id OR @agency_id = 0)
and     ( agency.agency_group_id = @agency_group_id OR @agency_group_id = 0)
AND		( product_category.product_category_id = @product_category_id OR @product_category_id = 0)
AND		( VV.country_code = @country_code OR @country_code = '') 
AND		( VV.branch_code = @branch_code OR @branch_code = '')
AND		( VV.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
AND		( VV.revenue_group = @revenue_group OR @revenue_group = 0 )
--AND		( sales_rep.rep_id = @rep_id OR @rep_id = 0 )
AND		( STX.rep_id = @rep_id OR @rep_id = 0 )
AND		( sales_team.team_id = @team_id OR @team_id = 0 )
and		( VV.revenue_period between @PERIOD_START and @PERIOD_END )
AND		( VV.revenue_group >= ( CASE @report_type When 'O' Then 50 Else 0 End )
AND		  VV.revenue_group < ( CASE @report_type When 'C' Then 50 Else 1000 End ))
AND		( VV.campaign_no = @campaign_no OR @campaign_no = 0 )
AND		VV.business_unit_id = sales_team.business_unit_id
group by	VV.campaign_no,
		VV.campaign_status,
		VV.product_desc,
		STX.rep_id,
		--VV.revision_id,
		--VV.revenue_period,
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
having SUM(VV.cost) <> 0
ORDER BY VV.campaign_no,
		STX.rep_id,
		--VV.revenue_period,
		VV.client_id,
		VV.agency_id,
		VV.branch_name,
		VV.business_unit_desc, 
		VV.revenue_group_desc,
		VV.master_revenue_group_desc, 
		STX.revenue_percent
GO
