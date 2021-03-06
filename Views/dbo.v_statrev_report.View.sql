/****** Object:  View [dbo].[v_statrev_report]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statrev_report]
GO
/****** Object:  View [dbo].[v_statrev_report]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


create VIEW [dbo].[v_statrev_report]
AS 

SELECT	fc.campaign_no,
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
	stat_sub.tran_id,
	stat_sub.cost,
	stat_sub.units,
	stat_sub.revenue_period, 
	stat_sub.delta_date,
	stat_sub.statrev_transaction_type,
	stat_sub.statrev_transaction_type_desc,
	stat_sub.revenue_group,
	stat_sub.revenue_group_desc,
	stat_sub.master_revenue_group,
	stat_sub.master_revenue_group_desc,
	b.branch_code, 
	b.country_code,
	b.branch_name,
	b.sort_order as branch_sort_order,
	bu.business_unit_desc,
	srt.revision_type_desc,
	src.revision_category_desc,
	fc.reporting_agency,
	fc.client_id,
	fc.rep_id,
	fc.agency_id,
	type1,
	type2,
	type3,
	srt.revision_type
from	branch b with (nolock),
	business_unit bu with (nolock),
	film_campaign fc with (nolock),
	statrev_campaign_revision scr with (nolock),
	statrev_revision_type srt with (nolock),
	statrev_revision_category src with (nolock),
	(	select	statrev_cinema_normal_transaction.revision_id,
			statrev_cinema_normal_transaction.tran_id,
			statrev_cinema_normal_transaction.cost,
			statrev_cinema_normal_transaction.units,
			statrev_cinema_normal_transaction.revenue_period, 
			statrev_cinema_normal_transaction.delta_date,
			statrev_transaction_type.statrev_transaction_type,
			statrev_transaction_type.statrev_transaction_type_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.revenue_group_desc,
			statrev_revenue_master_group.master_revenue_group,
			statrev_revenue_master_group.master_revenue_group_desc,
			type1 = case when statrev_revenue_master_group.master_revenue_group in (180,190,200,210) then 'F' else 'C' end,
			type2 = 'N',
			type3 = case when statrev_revenue_master_group.master_revenue_group in (180,190,200,210) then 'F' else 'C' end
		from	dbo.statrev_cinema_normal_transaction with (nolock),
			dbo.statrev_revenue_group with (nolock),
			dbo.statrev_revenue_master_group with (nolock),
			dbo.statrev_transaction_type with (nolock)
		WHERE	statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
		and	statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
		and	statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
		union
		select	statrev_outpost_normal_transaction.revision_id,
			statrev_outpost_normal_transaction.tran_id,
			statrev_outpost_normal_transaction.cost,
			statrev_outpost_normal_transaction.units,
			statrev_outpost_normal_transaction.revenue_period, 
			statrev_outpost_normal_transaction.delta_date,
			statrev_transaction_type.statrev_transaction_type,
			statrev_transaction_type.statrev_transaction_type_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.revenue_group_desc,
			statrev_revenue_master_group.master_revenue_group,
			statrev_revenue_master_group.master_revenue_group_desc,
			type1 = 'O', 
			type2 = 'N',
			type3 = 'O'
		from	dbo.statrev_outpost_normal_transaction with (nolock),
			dbo.statrev_revenue_group with (nolock),
			dbo.statrev_revenue_master_group with (nolock),
			dbo.statrev_transaction_type with (nolock)
		WHERE	statrev_outpost_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
		and	statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
		and	statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
		union
		select	statrev_cinema_deferred_transaction.revision_id,
			statrev_cinema_deferred_transaction.tran_id,
			statrev_cinema_deferred_transaction.cost,
			statrev_cinema_deferred_transaction.units,
			null, 
			statrev_cinema_deferred_transaction.delta_date,
			statrev_transaction_type.statrev_transaction_type,
			statrev_transaction_type.statrev_transaction_type_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.revenue_group_desc,
			statrev_revenue_master_group.master_revenue_group,
			statrev_revenue_master_group.master_revenue_group_desc,
			type1 = case when statrev_revenue_master_group.master_revenue_group in (180,190,200,210) then 'F' else 'C' end, 
			type2 = 'D',
			type3 = case when statrev_revenue_master_group.master_revenue_group in (180,190,200,210) then 'F' else 'C' end
		from	dbo.statrev_cinema_deferred_transaction with (nolock),
			dbo.statrev_revenue_group with (nolock),
			dbo.statrev_revenue_master_group with (nolock),
			dbo.statrev_transaction_type with (nolock)
		WHERE	statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
		and	statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
		and	statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
		union
		select 	statrev_outpost_deferred_transaction.revision_id,
			statrev_outpost_deferred_transaction.tran_id,
			statrev_outpost_deferred_transaction.cost,
			statrev_outpost_deferred_transaction.units,
			null, 
		 	statrev_outpost_deferred_transaction.delta_date,
			statrev_transaction_type.statrev_transaction_type,
			statrev_transaction_type.statrev_transaction_type_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.revenue_group_desc,
			statrev_revenue_master_group.master_revenue_group,
			statrev_revenue_master_group.master_revenue_group_desc,
			type1 = 'O', 
			type2 = 'D',
			type3 = 'O'
		from	dbo.statrev_outpost_deferred_transaction with (nolock),
			dbo.statrev_revenue_group with (nolock),
			dbo.statrev_revenue_master_group with (nolock),
			dbo.statrev_transaction_type with (nolock)
		WHERE	statrev_outpost_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
		and	statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
		and	statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group) as stat_sub
where	stat_sub.revision_id = scr.revision_id
and	fc.campaign_no = scr.campaign_no
and	fc.branch_code = b.branch_code
and	fc.business_unit_id = bu.business_unit_id
and	scr.revision_type = srt.revision_type
and	scr.revision_category = src.revision_category
GO
