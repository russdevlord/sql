/****** Object:  View [dbo].[v_statrev_report_temp]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_statrev_report_temp]
GO
/****** Object:  View [dbo].[v_statrev_report_temp]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


create VIEW [dbo].[v_statrev_report_temp]
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
	sum(stat_sub.cost) as cost,
	sum(stat_sub.units) as units,
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
	srt.revision_type
from	branch b,
	business_unit bu,
	film_campaign fc,
	statrev_campaign_revision scr,
	statrev_revision_type srt,
	statrev_revision_category src,
	(	select	statrev_cinema_normal_transaction.revision_id,
				sum(statrev_cinema_normal_transaction.cost) as cost,
				sum(statrev_cinema_normal_transaction.units) as units,
			statrev_cinema_normal_transaction.revenue_period, 
			statrev_cinema_normal_transaction.delta_date,
			statrev_transaction_type.statrev_transaction_type,
			statrev_transaction_type.statrev_transaction_type_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.revenue_group_desc,
			statrev_revenue_master_group.master_revenue_group,
			statrev_revenue_master_group.master_revenue_group_desc,
			type1 = 'C', 
			type2 = 'N'
		from	dbo.statrev_cinema_normal_transaction,
			dbo.statrev_revenue_group,
			dbo.statrev_revenue_master_group,
			dbo.statrev_transaction_type
		WHERE	statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
		and	statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
		and	statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
		group by statrev_cinema_normal_transaction.revision_id,
			statrev_cinema_normal_transaction.revenue_period, 
			statrev_cinema_normal_transaction.delta_date,
			statrev_transaction_type.statrev_transaction_type,
			statrev_transaction_type.statrev_transaction_type_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.revenue_group_desc,
			statrev_revenue_master_group.master_revenue_group,
			statrev_revenue_master_group.master_revenue_group_desc
		union
		select	statrev_outpost_normal_transaction.revision_id,
			sum(statrev_outpost_normal_transaction.cost),
			sum(statrev_outpost_normal_transaction.units),
			statrev_outpost_normal_transaction.revenue_period, 
			statrev_outpost_normal_transaction.delta_date,
			statrev_transaction_type.statrev_transaction_type,
			statrev_transaction_type.statrev_transaction_type_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.revenue_group_desc,
			statrev_revenue_master_group.master_revenue_group,
			statrev_revenue_master_group.master_revenue_group_desc,
			type1 = 'O', 
			type2 = 'N'
		from	dbo.statrev_outpost_normal_transaction,
			dbo.statrev_revenue_group,
			dbo.statrev_revenue_master_group,
			dbo.statrev_transaction_type
		WHERE	statrev_outpost_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
		and	statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
		and	statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
		group by statrev_outpost_normal_transaction.revision_id,
			statrev_outpost_normal_transaction.revenue_period, 
			statrev_outpost_normal_transaction.delta_date,
			statrev_transaction_type.statrev_transaction_type,
			statrev_transaction_type.statrev_transaction_type_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.revenue_group_desc,
			statrev_revenue_master_group.master_revenue_group,
			statrev_revenue_master_group.master_revenue_group_desc
	
		union
		select	statrev_cinema_deferred_transaction.revision_id,
			sum(statrev_cinema_deferred_transaction.cost),
			sum(statrev_cinema_deferred_transaction.units),
			null, 
			statrev_cinema_deferred_transaction.delta_date,
			statrev_transaction_type.statrev_transaction_type,
			statrev_transaction_type.statrev_transaction_type_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.revenue_group_desc,
			statrev_revenue_master_group.master_revenue_group,
			statrev_revenue_master_group.master_revenue_group_desc,
			type1 = 'C', 
			type2 = 'D'
		from	dbo.statrev_cinema_deferred_transaction,
			dbo.statrev_revenue_group,
			dbo.statrev_revenue_master_group,
			dbo.statrev_transaction_type
		WHERE	statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
		and	statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
		and	statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
		group by statrev_cinema_deferred_transaction.revision_id,
			statrev_cinema_deferred_transaction.delta_date,
			statrev_transaction_type.statrev_transaction_type,
			statrev_transaction_type.statrev_transaction_type_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.revenue_group_desc,
			statrev_revenue_master_group.master_revenue_group,
			statrev_revenue_master_group.master_revenue_group_desc
		union
		select 	statrev_outpost_deferred_transaction.revision_id,
			sum(statrev_outpost_deferred_transaction.cost),
			sum(statrev_outpost_deferred_transaction.units),
			null, 
		 	statrev_outpost_deferred_transaction.delta_date,
			statrev_transaction_type.statrev_transaction_type,
			statrev_transaction_type.statrev_transaction_type_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.revenue_group_desc,
			statrev_revenue_master_group.master_revenue_group,
			statrev_revenue_master_group.master_revenue_group_desc,
			type1 = 'O', 
			type2 = 'D'
		from	dbo.statrev_outpost_deferred_transaction,
			dbo.statrev_revenue_group,
			dbo.statrev_revenue_master_group,
			dbo.statrev_transaction_type
		WHERE	statrev_outpost_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
		and	statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
		and	statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
		group by 	statrev_outpost_deferred_transaction.revision_id,
		 	statrev_outpost_deferred_transaction.delta_date,
			statrev_transaction_type.statrev_transaction_type,
			statrev_transaction_type.statrev_transaction_type_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.revenue_group_desc,
			statrev_revenue_master_group.master_revenue_group,
			statrev_revenue_master_group.master_revenue_group_desc) as stat_sub
where	stat_sub.revision_id = scr.revision_id
and	fc.campaign_no = scr.campaign_no
and	fc.branch_code = b.branch_code
and	fc.business_unit_id = bu.business_unit_id
and	scr.revision_type = srt.revision_type
and	scr.revision_category = src.revision_category
group by fc.campaign_no,
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
	b.sort_order,
	bu.business_unit_desc,
	srt.revision_type_desc,
	src.revision_category_desc,
	fc.reporting_agency,
	fc.client_id,
	fc.rep_id,
	fc.agency_id,
	type1,
	type2,
	srt.revision_type
GO
