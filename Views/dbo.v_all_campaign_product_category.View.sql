/****** Object:  View [dbo].[v_all_campaign_product_category]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_all_campaign_product_category]
GO
/****** Object:  View [dbo].[v_all_campaign_product_category]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE VIEW [dbo].[v_all_campaign_product_category] 
AS
    SELECT 	distinct campaign_package.campaign_no, campaign_package.product_category, business_unit_id, product_category.product_category_desc
FROM   	campaign_package , film_campaign, product_category
WHERE 		campaign_package.campaign_no = film_campaign.campaign_no
and		campaign_package.product_category = product_category.product_category_id
group by campaign_package.campaign_no, campaign_package.product_category, business_unit_id, product_category.product_category_desc
union
SELECT 	distinct cinelight_package.campaign_no ,cinelight_package.product_category, business_unit_id, product_category.product_category_desc
FROM   	cinelight_package , film_campaign , product_category
WHERE 	cinelight_package.campaign_no = film_campaign.campaign_no
and		cinelight_package.product_category = product_category.product_category_id
group by cinelight_package.campaign_no,cinelight_package.product_category, business_unit_id, product_category.product_category_desc
union
SELECT 	distinct inclusion.campaign_no , inclusion.product_category_id, business_unit_id, product_category.product_category_desc
FROM   	inclusion , film_campaign , product_category
WHERE 	 inclusion.campaign_no = film_campaign.campaign_no
and		inclusion.inclusion_id = (select min(inclusion_id) from inclusion where inclusion_type in (5,18) and campaign_no = film_campaign.campaign_no)
and		inclusion.product_category_id = product_category.product_category_id
group by inclusion.campaign_no, inclusion.product_category_id, business_unit_id, product_category.product_category_desc
union
SELECT 	distinct outpost_package.campaign_no ,outpost_package.product_category, business_unit_id, product_category.product_category_desc
FROM   	outpost_package , film_campaign , product_category
WHERE 	outpost_package.campaign_no = film_campaign.campaign_no
and		outpost_package.product_category = product_category.product_category_id
group by outpost_package.campaign_no,outpost_package.product_category, business_unit_id, product_category.product_category_desc

GO
