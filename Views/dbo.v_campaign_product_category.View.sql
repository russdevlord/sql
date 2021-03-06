/****** Object:  View [dbo].[v_campaign_product_category]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_campaign_product_category]
GO
/****** Object:  View [dbo].[v_campaign_product_category]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE VIEW [dbo].[v_campaign_product_category] 
AS
    SELECT 	distinct campaign_package.campaign_no, campaign_package.product_category, business_unit_id
FROM   	campaign_package , film_campaign 
WHERE 		campaign_package.campaign_no = film_campaign.campaign_no
and		campaign_package.package_code = (select min(package_code) from campaign_package where campaign_no = film_campaign.campaign_no)
group by campaign_package.campaign_no, campaign_package.product_category, business_unit_id
union
SELECT 	distinct cinelight_package.campaign_no ,cinelight_package.product_category, business_unit_id
FROM   	cinelight_package , film_campaign 
WHERE 	cinelight_package.campaign_no = film_campaign.campaign_no
and		cinelight_package.package_code = (select min(package_code) from cinelight_package where campaign_no = film_campaign.campaign_no)
and 		cinelight_package.campaign_no not in (select distinct campaign_no from campaign_package)
group by cinelight_package.campaign_no,cinelight_package.product_category, business_unit_id
union
SELECT 	distinct inclusion.campaign_no , inclusion.product_category_id, business_unit_id
FROM   	inclusion , film_campaign 
WHERE 	 inclusion.campaign_no = film_campaign.campaign_no
and		inclusion.inclusion_id = (select min(inclusion_id) from inclusion where inclusion_type = 5 and campaign_no = film_campaign.campaign_no)
and 		inclusion.campaign_no not in (select distinct campaign_no from campaign_package)
and		inclusion.campaign_no not in (select distinct campaign_no from cinelight_package)
group by inclusion.campaign_no, inclusion.product_category_id, business_unit_id
union
SELECT 	distinct outpost_package.campaign_no ,outpost_package.product_category, business_unit_id
FROM   	outpost_package , film_campaign 
WHERE 	outpost_package.campaign_no = film_campaign.campaign_no
and		outpost_package.package_code = (select min(package_code) from outpost_package where campaign_no = film_campaign.campaign_no)
and 		outpost_package.campaign_no not in (select distinct campaign_no from campaign_package)
and 		outpost_package.campaign_no not in (select distinct campaign_no from inclusion where inclusion_type = 5)
and		outpost_package.campaign_no not in (select distinct campaign_no from cinelight_package)
group by outpost_package.campaign_no,outpost_package.product_category, business_unit_id
union
SELECT 	distinct inclusion.campaign_no , inclusion.product_category_id, business_unit_id
FROM   	inclusion , film_campaign 
WHERE 	 inclusion.campaign_no = film_campaign.campaign_no
and		inclusion.inclusion_id = (select min(inclusion_id) from inclusion where inclusion_type = 18 and campaign_no = film_campaign.campaign_no)
and 		inclusion.campaign_no not in (select distinct campaign_no from campaign_package)
and		inclusion.campaign_no not in (select distinct campaign_no from cinelight_package)
and 		inclusion.campaign_no not in (select distinct campaign_no from outpost_package)
and		inclusion.campaign_no not in (select distinct campaign_no from inclusion where inclusion_type = 5)
group by inclusion.campaign_no, inclusion.product_category_id, business_unit_id
GO
