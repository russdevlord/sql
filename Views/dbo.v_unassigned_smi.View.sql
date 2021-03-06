/****** Object:  View [dbo].[v_unassigned_smi]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_unassigned_smi]
GO
/****** Object:  View [dbo].[v_unassigned_smi]    Script Date: 12/03/2021 10:03:48 AM ******/
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
