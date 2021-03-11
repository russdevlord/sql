USE [production]
GO
/****** Object:  View [dbo].[v_unassigned_smi]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_unassigned_smi]
as
select 	film_campaign.campaign_no,
				film_campaign.product_desc,
				client.client_name,
				client_product.client_product_desc,
				product_category.product_category_desc
from 		smi_report_group_fc_xref, 
				film_campaign, 
				client, 
				client_product,
				v_campaign_product,
				product_category
where	smi_report_group_fc_xref.smi_report_group_id = 31
and			film_campaign.campaign_status = 'L'
and			film_campaign.campaign_no = smi_report_group_fc_xref.campaign_no
and			film_campaign.client_id = client.client_id
and			film_campaign.client_product_id = client_product.client_product_id
and			film_campaign.campaign_no = v_campaign_product.campaign_no
and			v_campaign_product.product_category_id = product_category.product_category_id
GO
