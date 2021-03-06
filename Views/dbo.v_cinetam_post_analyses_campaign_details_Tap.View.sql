/****** Object:  View [dbo].[v_cinetam_post_analyses_campaign_details_Tap]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_post_analyses_campaign_details_Tap]
GO
/****** Object:  View [dbo].[v_cinetam_post_analyses_campaign_details_Tap]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

Create View [dbo].[v_cinetam_post_analyses_campaign_details_Tap] As
select client_name, client_product_desc, agency_name, film_campaign.campaign_no, product_desc, inclusion_cinetam_settings.cinetam_reporting_demographics_id, 
 cinetam_reporting_demographics_desc
from film_campaign, client, client_product, agency, inclusion_cinetam_settings, cinetam_reporting_demographics, inclusion
where film_campaign.client_id  =client.client_id
and film_campaign.client_product_id = client_product.client_product_id
and film_campaign.agency_id = agency.agency_id
and film_campaign.campaign_no = inclusion.campaign_no
and inclusion.inclusion_id = inclusion_cinetam_settings.inclusion_id
and inclusion_cinetam_settings.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
GO
