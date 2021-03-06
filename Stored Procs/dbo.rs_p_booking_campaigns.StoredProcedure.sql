/****** Object:  StoredProcedure [dbo].[rs_p_booking_campaigns]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[rs_p_booking_campaigns]
GO
/****** Object:  StoredProcedure [dbo].[rs_p_booking_campaigns]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

-- Generic proc for boolings reports by
-- 1. Product
-- 2. Client
-- 3. Agency
-- 4. Agency Group
-- 5. Sales Rep

CREATE proc  [dbo].[rs_p_booking_campaigns]
	@PERIOD_START		datetime,
	@PERIOD_END			datetime,
	@team_id			INT,
	@rep_id				INT,
	@branch_code		varchar(1),
	@country_code		varchar(1),
	@business_unit_id	int,
	@revision_group		int,
	@report_type		varchar(1) -- 'C' - cinema, 'O' - outpost/retail, '' - All
AS

SELECT	campaign_no = film_campaign.campaign_no,
		campaign_name = film_campaign.product_desc,
		business_unit_id = film_campaign.business_unit_id,   
		campaign_status =  film_campaign.campaign_status,
		figure = sum( nett_amount ),
		revenue_media = sum( nett_amount * is_media ),
		revenue_cinelight = sum( nett_amount * is_cinelight ),
		revenue_marketing = sum( nett_amount * is_cinemarketing ),
		revenue_misc = sum( nett_amount * is_misc ), 
		rep_id = sales_rep.rep_id,
		rep_name = sales_rep.last_name + ', ' + sales_rep.first_name,
		client.client_id,
		client.client_name,
		client_group.client_group_id,
		client_group.client_group_desc,
		agency.agency_id,
		agency.agency_name,
		agency_groups.agency_group_id,
		agency_groups.agency_group_name,
		agency_buying_groups.buying_group_id,
		agency_buying_groups.buying_group_desc,
		product = (	SELECT	product_category.product_category_desc
					FROM   	campaign_package, product_category 
					WHERE 	campaign_package.campaign_no = film_campaign.campaign_no
					and		campaign_package.product_category = product_category.product_category_id
					and		campaign_package.package_code = ( select min(package_code) from campaign_package where campaign_no = film_campaign.campaign_no)
					group by product_category.product_category_desc
					union
					SELECT	DISTINCT product_category.product_category_desc
					FROM   	cinelight_package, product_category
					WHERE 	cinelight_package.campaign_no = film_campaign.campaign_no
					and		cinelight_package.product_category = product_category.product_category_id
					and		cinelight_package.package_code = ( select min(package_code) from cinelight_package where campaign_no = film_campaign.campaign_no)
					and 	cinelight_package.campaign_no not in (select distinct campaign_no from campaign_package)
					group by product_category.product_category_desc
					union
					SELECT 	DISTINCT product_category.product_category_desc
					FROM   	inclusion, product_category 
					WHERE 	inclusion.campaign_no = film_campaign.campaign_no
					and		inclusion.product_category_id = product_category.product_category_id
					and		inclusion.inclusion_id = (	select min(inclusion_id) from inclusion 
														where inclusion_type = 5 and campaign_no = film_campaign.campaign_no)
					and 	inclusion.campaign_no not in (select distinct campaign_no from campaign_package)
					and		inclusion.campaign_no not in (select distinct campaign_no from cinelight_package)
					group by product_category.product_category_desc ),
			booking_figures.figure_date,
			booking_figures.booking_period
FROM	booking_figures,
		film_campaign,
		revision_group,
		client,
		client_group,
		agency,
		agency_groups,
		agency_buying_groups,
		sales_rep,
		branch	
WHERE	( booking_figures.campaign_no = film_campaign.campaign_no )
AND		( booking_figures.revision_group = revision_group.revision_group )
AND		( client.client_group_id = client_group.client_group_id )
AND		( client.client_id = film_campaign.reporting_client )
AND		( film_campaign.reporting_agency = agency.agency_id )
AND		( film_campaign.rep_id = sales_rep.rep_id )
AND		( agency.agency_group_id = agency_groups.agency_group_id )
AND		( agency_groups.buying_group_id = agency_buying_groups.buying_group_id ) 
AND		( film_campaign.branch_code = branch.branch_code ) 
AND		( branch.country_code = @country_code OR @country_code = '')
AND		( film_campaign.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
AND		( booking_figures.revision_group = @revision_group OR @revision_group = 0 )
and		( booking_figures.rep_id = sales_rep.rep_id )
AND		( booking_figures.rep_id = @rep_id OR @rep_id = 0 )
AND		( @team_id = 0 OR EXISTS ( SELECT	team_id 
									FROM	booking_figure_team_xref bx
									WHERE	bx.figure_id = booking_figures.figure_id
									AND		bx.team_id = @team_id))
and		booking_figures.booking_period between @PERIOD_START and @PERIOD_END
AND		( booking_figures.revision_group >= ( CASE @report_type When 'O' Then 50 Else 0 End )
AND		  booking_figures.revision_group < ( CASE @report_type When 'C' Then 50 Else 1000 End ))		
GROUP BY	film_campaign.campaign_no,
			film_campaign.product_desc,
			film_campaign.business_unit_id,
			film_campaign.campaign_status,
			sales_rep.rep_id,
			sales_rep.last_name + ', ' + sales_rep.first_name,
			client.client_id,
			client.client_name,
			client_group.client_group_id,
			client_group.client_group_desc,
			agency.agency_id,
			agency.agency_name,
			agency_groups.agency_group_id,
			agency_groups.agency_group_name,
			agency_buying_groups.buying_group_id,
			agency_buying_groups.buying_group_desc,
			booking_figures.figure_date,
			booking_figures.booking_period
HAVING SUM(nett_amount) <> 0
ORDER BY product ASC
GO
