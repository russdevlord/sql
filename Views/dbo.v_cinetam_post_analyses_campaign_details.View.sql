/****** Object:  View [dbo].[v_cinetam_post_analyses_campaign_details]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_post_analyses_campaign_details]
GO
/****** Object:  View [dbo].[v_cinetam_post_analyses_campaign_details]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




Create View  [dbo].[v_cinetam_post_analyses_campaign_details]
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
              0 cinetam_reporting_demographics_id, inclusion_cinetam_targets.target_attendance, makeup_deadline,
              cinetam_reporting_demographics_desc, film_campaign.campaign_budget, film_campaign.start_date, 
              film_campaign.end_date, campaign_cost + (select Sum(charge_rate) from cinelight_spot Where campaign_no = film_campaign.campaign_no) as Media_spend
FROM          film_campaign INNER JOIN
              client ON film_campaign.client_id = client.client_id INNER JOIN
              client_product ON film_campaign.client_product_id = client_product.client_product_id INNER JOIN
              agency ON film_campaign.agency_id = agency.agency_id INNER JOIN
			  inclusion on film_campaign.campaign_no = inclusion.campaign_no inner join
              inclusion_cinetam_targets ON inclusion.inclusion_id = inclusion_cinetam_targets.inclusion_id
              INNER JOIN
			cinetam_reporting_demographics ON cinetam_reporting_demographics.cinetam_reporting_demographics_id = inclusion_cinetam_targets.cinetam_reporting_demographics_id
UNION ALL
SELECT        client.client_name, client_product.client_product_desc, agency.agency_name, film_campaign.campaign_no, film_campaign.product_desc, 
              0 cinetam_reporting_demographics_id, cinetam_campaign_settings.attendance, makeup_deadline,
              cinetam_reporting_demographics_desc, film_campaign.campaign_budget, film_campaign.start_date, 
              film_campaign.end_date, campaign_cost + (select Sum(charge_rate) from cinelight_spot Where campaign_no = cinetam_campaign_settings.campaign_no) as Media_spend
FROM          film_campaign INNER JOIN
              client ON film_campaign.client_id = client.client_id INNER JOIN
              client_product ON film_campaign.client_product_id = client_product.client_product_id INNER JOIN
              agency ON film_campaign.agency_id = agency.agency_id INNER JOIN
              cinetam_campaign_settings ON film_campaign.campaign_no = cinetam_campaign_settings.campaign_no
              INNER JOIN
              cinetam_reporting_demographics ON cinetam_reporting_demographics.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
where		  film_campaign.campaign_no not in (select campaign_no from cinetam_campaign_targets)	              
GO
