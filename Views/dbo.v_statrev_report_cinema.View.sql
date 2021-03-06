/****** Object:  View [dbo].[v_statrev_report_cinema]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_statrev_report_cinema]
GO
/****** Object:  View [dbo].[v_statrev_report_cinema]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



create VIEW [dbo].[v_statrev_report_cinema]
AS 

select			fc.campaign_no,
				fc.product_desc,
				fc.business_unit_id,
				fc.campaign_status,
				fc.includes_follow_film,
				fc.includes_gold_class,
				fc.includes_premium_position,
				fc.includes_media,
				fc.includes_cinelights,
				fc.includes_infoyer,
				fc.includes_miscellaneous,
				fc.includes_retail,
				scr.confirmation_date,
				scr.revision_no,
				scr.revision_id,
				tran_id,
				cost,
				units,
				revenue_period, 
				delta_date,
				statrev_transaction_type,
				statrev_transaction_type_desc,
				statrev_revenue_group.revenue_group,
				revenue_group_desc,
				statrev_revenue_group.master_revenue_group,
				master_revenue_group_desc,
				b.branch_code, 
				b.branch_name,
				b.country_code,
				country_name,
				b.sort_order as branch_sort_order,
				bu.business_unit_desc,
				srt.revision_type_desc,
				src.revision_category_desc,
				fc.reporting_agency,
				fc.client_id,
				fc.rep_id,
				fc.agency_id,
				srt.revision_type,
				ar.agency_name as reporting_agency_name,
				client_name,
				sr.first_name + ' ' + sr.last_name as rep_name,
				aa.agency_name
from			film_campaign fc with (nolock)
inner join		branch b with (nolock) on fc.branch_code = b.branch_code
inner join		business_unit bu with (nolock) on fc.business_unit_id = bu.business_unit_id
inner join		statrev_campaign_revision scr with (nolock) on fc.campaign_no = scr.campaign_no
inner join		statrev_revision_type srt with (nolock) on scr.revision_type = srt.revision_type
inner join		statrev_revision_category src with (nolock) on scr.revision_category = src.revision_category
inner join		statrev_cinema_normal_transaction with (nolock) on scr.revision_id = statrev_cinema_normal_transaction.revision_id
inner join		statrev_transaction_type with (nolock) on statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
inner join		statrev_revenue_group with (nolock) on statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
inner join		statrev_revenue_master_group with (nolock) on statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
inner join		country  with (nolock)on b.country_code = country.country_code
inner join		agency ar  with (nolock)on fc.reporting_agency = ar.agency_id
inner join		client cl  with (nolock)on fc.client_id = cl.client_id
inner join		sales_rep sr  with (nolock)on fc.rep_id = sr.rep_id
inner join 		agency aa  with (nolock)on fc.agency_id = aa.agency_id


GO
