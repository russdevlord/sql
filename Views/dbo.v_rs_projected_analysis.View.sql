/****** Object:  View [dbo].[v_rs_projected_analysis]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_rs_projected_analysis]
GO
/****** Object:  View [dbo].[v_rs_projected_analysis]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW  [dbo].[v_rs_projected_analysis] (
		benchmark_end,
		country_code,
		branch_code,
		branch_name,
		business_unit_id,
		business_unit_desc,
		media_product_id,
		media_product_desc,
		agency_deal,
		agency_id,
		agency_name,
		agency_group_id,
		agency_group_name,
		client_id,
		client_name,
		client_group_id,
		client_group_desc,
		buying_group_id,
		buying_group_desc,
		billings)
AS

SELECT	x.benchmark_end,
		branch.country_code,
		CONVERT(VARCHAR(1),fc.branch_code),
		branch.branch_name,
		fc.business_unit_id,
		bu.business_unit_desc,
		cp.media_product_id,
		mp.media_product_desc,
		fc.agency_deal,
		fc.agency_id,
		agency.agency_name,
		ag.agency_group_id,
		ag.agency_group_name,
		fc.client_id,
		client.client_name,
		client.client_group_id,
		cg.client_group_desc,
		abg.buying_group_id,
		abg.buying_group_desc,
		CONVERT(MONEY,SUM(ISNULL(cs.charge_rate,0) * (convert(numeric(6,4),x.no_days)/7.0)))
FROM	campaign_spot cs,
		film_screening_date_xref x,
		campaign_package cp,
		film_campaign fc,
		agency,
		agency_groups ag,
		agency_buying_groups abg,
		client,
		client_group cg,
		business_unit bu,
		media_product mp,
		branch
WHERE	cs.billing_date = x.screening_date
and		cs.package_id = cp.package_id
and		cp.campaign_no = fc.campaign_no
and		fc.reporting_agency = agency.agency_id
and     agency.agency_group_id = ag.agency_group_id
and		ag.buying_group_id = abg.buying_group_id
AND		fc.client_id = client.client_id
AND		client.client_group_id = cg.client_group_id
AND		cp.media_product_id = mp.media_product_id
and		mp.system_use_only = 'N'
and		mp.media = 'Y'
AND		fc.business_unit_id = bu.business_unit_id
AND		fc.branch_code = branch.branch_code
and		bu.system_use_only = 'N'
AND		cs.spot_status != 'P'
GROUP BY   x.benchmark_end,
		fc.business_unit_id,
		cp.media_product_id,
		fc.agency_id,
		fc.client_id,
		client.client_group_id,
		ag.agency_group_id,
		abg.buying_group_id,
		mp.media_product_desc,
		bu.business_unit_desc,
		agency.agency_name,
		client.client_name,
		fc.agency_deal,
		ag.agency_group_name,
		cg.client_group_desc,
		abg.buying_group_desc,
		branch.country_code,
		fc.branch_code,
		branch.branch_name

GO
