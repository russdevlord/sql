/****** Object:  View [dbo].[v_cinetam_post_analyses_campaign_details_All_Attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_post_analyses_campaign_details_All_Attendance]
GO
/****** Object:  View [dbo].[v_cinetam_post_analyses_campaign_details_All_Attendance]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create View  [dbo].[v_cinetam_post_analyses_campaign_details_All_Attendance]
AS
SELECT        client.client_name, client_product.client_product_desc, agency.agency_name, film_campaign.campaign_no, film_campaign.product_desc, 
              0 cinetam_reporting_demographics_id, attendance_campaign_actuals.attendance, makeup_deadline,
              'All Attendance' As cinetam_reporting_demographics_desc, film_campaign.campaign_budget, film_campaign.start_date, 
                         film_campaign.end_date
FROM          film_campaign INNER JOIN
                         client ON film_campaign.client_id = client.client_id INNER JOIN
                         client_product ON film_campaign.client_product_id = client_product.client_product_id INNER JOIN
                         agency ON film_campaign.agency_id = agency.agency_id INNER JOIN
                         attendance_campaign_actuals ON film_campaign.campaign_no = attendance_campaign_actuals.campaign_no
GO
