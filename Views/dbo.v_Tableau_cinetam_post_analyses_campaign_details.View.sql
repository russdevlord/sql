/****** Object:  View [dbo].[v_Tableau_cinetam_post_analyses_campaign_details]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_Tableau_cinetam_post_analyses_campaign_details]
GO
/****** Object:  View [dbo].[v_Tableau_cinetam_post_analyses_campaign_details]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create View  [dbo].[v_Tableau_cinetam_post_analyses_campaign_details]
AS
SELECT        client.client_name, client_product.client_product_desc, agency.agency_name, film_campaign.campaign_no, film_campaign.product_desc, 
              0 cinetam_reporting_demographics_id, cinetam_campaign_targets.attendance, makeup_deadline,
              cinetam_reporting_demographics_desc, film_campaign.campaign_budget, film_campaign.start_date, 
                         film_campaign.end_date, campaign_cost + (select Sum(charge_rate) from cinelight_spot Where campaign_no = cinetam_campaign_targets.campaign_no) as Media_spend
FROM          film_campaign INNER JOIN
                         client ON film_campaign.client_id = client.client_id INNER JOIN
                         client_product ON film_campaign.client_product_id = client_product.client_product_id INNER JOIN
                         agency ON film_campaign.agency_id = agency.agency_id INNER JOIN
                         cinetam_campaign_targets ON film_campaign.campaign_no = cinetam_campaign_targets.campaign_no
                         INNER JOIN
                         cinetam_reporting_demographics ON cinetam_reporting_demographics.cinetam_reporting_demographics_id = cinetam_campaign_targets.cinetam_reporting_demographics_id
UNION ALL
SELECT        client.client_name, client_product.client_product_desc, agency.agency_name, film_campaign.campaign_no, film_campaign.product_desc, 
              0 cinetam_reporting_demographics_id, cinetam_inclusion_targets.attendance, makeup_deadline,
              cinetam_reporting_demographics_desc, film_campaign.campaign_budget, film_campaign.start_date, 
                         film_campaign.end_date, campaign_cost + (select Sum(charge_rate) from cinelight_spot Where campaign_no = cinetam_inclusion_targets.campaign_no) as Media_spend
FROM          film_campaign INNER JOIN
                         client ON film_campaign.client_id = client.client_id INNER JOIN
                         client_product ON film_campaign.client_product_id = client_product.client_product_id INNER JOIN
                         agency ON film_campaign.agency_id = agency.agency_id INNER JOIN
                         cinetam_inclusion_targets ON film_campaign.campaign_no = cinetam_inclusion_targets.campaign_no
                         INNER JOIN
                         cinetam_reporting_demographics ON cinetam_reporting_demographics.cinetam_reporting_demographics_id = cinetam_inclusion_targets.cinetam_reporting_demographics_id
GO
