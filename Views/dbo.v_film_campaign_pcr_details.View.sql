USE [production]
GO
/****** Object:  View [dbo].[v_film_campaign_pcr_details]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


create view	[dbo].[v_film_campaign_pcr_details] As
select			client_name, 
					client_product_desc, 
					agency_name, 
					film_campaign.campaign_no, 
					product_desc
from				film_campaign
inner join		client on film_campaign.client_id  =client.client_id
inner join		client_product on film_campaign.client_product_id = client_product.client_product_id
inner join		agency on film_campaign.agency_id = agency.agency_id




GO
