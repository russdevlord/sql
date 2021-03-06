/****** Object:  View [dbo].[v_bi_Campaign_Spots]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_bi_Campaign_Spots]
GO
/****** Object:  View [dbo].[v_bi_Campaign_Spots]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[v_bi_Campaign_Spots]
AS
SELECT     A.SCREENING_DATE, a.type, CASE WHEN a.type = 'digilite' THEN 7 WHEN a.type = 'onscreen' THEN 1 END Type_ID, Sum(charge_rate_sum) / SUM(a.no_spots) Avg_Rate, SUM(a.no_spots)
                       no_spots, a.campaign_no, SUM(charge_rate_sum) as revenue, a.package_id
FROM         v_all_cinema_spots a JOIN
                      film_campaign b ON a.campaign_no = b.campaign_no
WHERE     type NOT IN ('takeouts') AND a.spot_type IN ('B', 'C', 'D', 'S')
GROUP BY A.SCREENING_DATE, a.type, a.campaign_no,a. package_id
UNION ALL
SELECT     A.SCREENING_DATE, a.Type, 
                      CASE WHEN a.type = 'Petro Panel' THEN 200 WHEN a.type = 'Retail Wall' THEN 103 WHEN a.type = 'Retail Superscreen' THEN 106 WHEN a.type = 'Retail Panels' THEN
                       100 WHEN a.type = 'Sports' THEN 250 WHEN a.type = 'Petro CStore' THEN 207 END Type_ID, Sum(charge_rate_sum) / SUM(a.no_spots) Avg_Rate, SUM(a.no_spots) 
                      no_spots, a.campaign_no, SUM(charge_rate_sum) as revenue, a.package_id
FROM         v_all_retail_spots a JOIN
                      film_campaign b ON a.campaign_no = b.campaign_no
WHERE     type NOT IN ('takeouts') AND a.spot_type IN ('B', 'C', 'D', 'S')
GROUP BY A.SCREENING_DATE, a.type, a.campaign_no,a.package_id

GO
