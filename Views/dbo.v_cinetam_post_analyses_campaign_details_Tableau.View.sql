/****** Object:  View [dbo].[v_cinetam_post_analyses_campaign_details_Tableau]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_post_analyses_campaign_details_Tableau]
GO
/****** Object:  View [dbo].[v_cinetam_post_analyses_campaign_details_Tableau]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create View  [dbo].[v_cinetam_post_analyses_campaign_details_Tableau]
AS 
SELECT       client.client_ID, client.client_name, client_product.client_product_id, client_product.client_product_desc, 
			 agency.agency_id, agency.agency_name, film_campaign.campaign_no, film_campaign.product_desc, 
             cinetam_reporting_demographics.cinetam_reporting_demographics_id, cinetam_campaign_targets.attendance, makeup_deadline,
             cinetam_reporting_demographics_desc, film_campaign.start_date, 
                         film_campaign.end_date
FROM         film_campaign INNER JOIN
                         client ON film_campaign.client_id = client.client_id INNER JOIN
                         client_product ON film_campaign.client_product_id = client_product.client_product_id INNER JOIN
                         agency ON film_campaign.agency_id = agency.agency_id INNER JOIN
                         cinetam_campaign_targets ON film_campaign.campaign_no = cinetam_campaign_targets.campaign_no
                         INNER JOIN
                         cinetam_reporting_demographics 
                         ON cinetam_reporting_demographics.cinetam_reporting_demographics_id = cinetam_campaign_targets.cinetam_reporting_demographics_id                         
UNION ALL
select					client.client_ID, client_name, client_product.client_product_id, client_product_desc, 
						agency.agency_ID, agency_name, film_campaign.campaign_no, product_desc, 
						cinetam_inclusion_settings.cinetam_reporting_demographics_id, cinetam_inclusion_settings.attendance, makeup_deadline, 
						cinetam_reporting_demographics_desc ,film_campaign.start_date, 
			 film_campaign.end_date
from film_campaign, client, client_product, agency, cinetam_inclusion_settings, cinetam_reporting_demographics, inclusion
where film_campaign.client_id  =client.client_id
and film_campaign.client_product_id = client_product.client_product_id
and film_campaign.agency_id = agency.agency_id
and film_campaign.campaign_no = inclusion.campaign_no
and inclusion.inclusion_id = cinetam_inclusion_settings.inclusion_id
and cinetam_inclusion_settings.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
GO
