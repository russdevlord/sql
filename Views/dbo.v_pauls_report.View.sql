/****** Object:  View [dbo].[v_pauls_report]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_pauls_report]
GO
/****** Object:  View [dbo].[v_pauls_report]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_pauls_report]
as
SELECT client_name,
	   client_product_desc, 
       branch_name,
       business_unit_desc,
       screening_date,
       sum(cost) as revenue
  FROM v_statrev, client , film_campaign, client_product
  where screening_date > '1-jan-2015'
  and v_statrev.campaign_no = film_campaign.campaign_no
  and film_campaign.reporting_client = client.client_id
  and 	film_campaign.client_product_id = client_product.client_product_id
  group by  client_name,
	   client_product_desc, 
       branch_name,
       business_unit_desc,
       screening_date

GO
