/****** Object:  View [dbo].[v_statrev_rep]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statrev_rep]
GO
/****** Object:  View [dbo].[v_statrev_rep]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_statrev_rep]
as
select 		film_campaign.campaign_no, 
			film_campaign.product_desc,
			statrev_cinema_normal_transaction.transaction_type, 
			statrev_cinema_normal_transaction.screening_date, 
			statrev_cinema_normal_transaction.revenue_period, 
			statrev_cinema_normal_transaction.delta_date, 
			sum(statrev_cinema_normal_transaction.cost * statrev_revision_rep_xref.revenue_percent ) as cost, 
			sum(statrev_cinema_normal_transaction.units) as units, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
			branch_name, branch.branch_code,branch.country_code,
			business_unit_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id,
			sales_rep.rep_id,
			sales_rep.first_name + ' ' + sales_rep.last_name as rep_name
from 		film_campaign, 
			statrev_campaign_revision, 
			statrev_cinema_normal_transaction, 
			statrev_transaction_type, 
			statrev_revenue_group, 
			statrev_revenue_master_group,
			branch,
			business_unit,
			statrev_revision_rep_xref, sales_rep
where		film_campaign.campaign_no = statrev_campaign_revision.campaign_no
and			statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
and			statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and			statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and			statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and			film_campaign.branch_code = branch.branch_code
and         film_campaign.business_unit_id = business_unit.business_unit_id
and 		statrev_revision_rep_xref.revision_id  = statrev_campaign_revision.revision_id
and 		statrev_revision_rep_xref.rep_id  = sales_rep.rep_id
group by 	film_campaign.campaign_no, 
			film_campaign.product_desc,
			statrev_cinema_normal_transaction.transaction_type, 
			statrev_cinema_normal_transaction.screening_date, 
			statrev_cinema_normal_transaction.revenue_period, 
			statrev_cinema_normal_transaction.delta_date, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id,
			sales_rep.rep_id,
			sales_rep.first_name , sales_rep.last_name
union
select 		film_campaign.campaign_no, 
			film_campaign.product_desc,
			statrev_outpost_normal_transaction.transaction_type, 
			statrev_outpost_normal_transaction.screening_date, 
			statrev_outpost_normal_transaction.revenue_period, 
			statrev_outpost_normal_transaction.delta_date, 
			sum(statrev_outpost_normal_transaction.cost * statrev_revision_rep_xref.revenue_percent) as cost, 
			sum(statrev_outpost_normal_transaction.units) as units, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id,
			sales_rep.rep_id,
			sales_rep.first_name + ' ' +  sales_rep.last_name
from 		film_campaign, 
			statrev_campaign_revision, 
			statrev_outpost_normal_transaction, 
			statrev_transaction_type, 
			statrev_revenue_group, 
			statrev_revenue_master_group,
			branch,
            business_unit,
			statrev_revision_rep_xref, sales_rep
where		film_campaign.campaign_no = statrev_campaign_revision.campaign_no
and			statrev_campaign_revision.revision_id = statrev_outpost_normal_transaction.revision_id
and			statrev_outpost_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and			statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and			statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and			film_campaign.branch_code = branch.branch_code
and         film_campaign.business_unit_id = business_unit.business_unit_id
and 		statrev_revision_rep_xref.revision_id  = statrev_campaign_revision.revision_id
and 		statrev_revision_rep_xref.rep_id  = sales_rep.rep_id
group by 	film_campaign.campaign_no, 
			film_campaign.product_desc,
			statrev_outpost_normal_transaction.transaction_type, 
			statrev_outpost_normal_transaction.screening_date, 
			statrev_outpost_normal_transaction.revenue_period, 
			statrev_outpost_normal_transaction.delta_date, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id,
			sales_rep.rep_id,
			sales_rep.first_name ,sales_rep.last_name
union
select 		film_campaign.campaign_no, 
			film_campaign.product_desc,
			statrev_cinema_deferred_transaction.transaction_type, 
			null, 
			null, 
			statrev_cinema_deferred_transaction.delta_date, 
			sum(statrev_cinema_deferred_transaction.cost * statrev_revision_rep_xref.revenue_percent) as cost, 
			sum(statrev_cinema_deferred_transaction.units) as units, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id,
			sales_rep.rep_id,
			sales_rep.first_name + ' ' + sales_rep.last_name
from 		film_campaign, 
			statrev_campaign_revision, 
			statrev_cinema_deferred_transaction, 
			statrev_transaction_type, 
			statrev_revenue_group, 
			statrev_revenue_master_group,
			branch,
            business_unit,
			statrev_revision_rep_xref, sales_rep
where		film_campaign.campaign_no = statrev_campaign_revision.campaign_no
and			statrev_campaign_revision.revision_id = statrev_cinema_deferred_transaction.revision_id
and			statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and			statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and			statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and			film_campaign.branch_code = branch.branch_code
and         film_campaign.business_unit_id = business_unit.business_unit_id
and 		statrev_revision_rep_xref.revision_id  = statrev_campaign_revision.revision_id
and 		statrev_revision_rep_xref.rep_id  = sales_rep.rep_id
group by 	film_campaign.campaign_no, 
			film_campaign.product_desc,
			statrev_cinema_deferred_transaction.transaction_type, 
			statrev_cinema_deferred_transaction.delta_date, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id,
			sales_rep.rep_id,
			sales_rep.first_name , sales_rep.last_name
union
select 		film_campaign.campaign_no, 
			film_campaign.product_desc,
			statrev_outpost_deferred_transaction.transaction_type, 
			null, 
			null, 
			statrev_outpost_deferred_transaction.delta_date, 
			sum(statrev_outpost_deferred_transaction.cost * statrev_revision_rep_xref.revenue_percent) as cost, 
			sum(statrev_outpost_deferred_transaction.units) as units, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id,
			sales_rep.rep_id,
			sales_rep.first_name + ' ' + sales_rep.last_name
from 		film_campaign, 
			statrev_campaign_revision, 
			statrev_outpost_deferred_transaction, 
			statrev_transaction_type, 
			statrev_revenue_group, 
			statrev_revenue_master_group,
			branch,
            business_unit,
			statrev_revision_rep_xref, sales_rep
where		film_campaign.campaign_no = statrev_campaign_revision.campaign_no
and			statrev_campaign_revision.revision_id = statrev_outpost_deferred_transaction.revision_id
and			statrev_outpost_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and			statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and			statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and			film_campaign.branch_code = branch.branch_code
and         film_campaign.business_unit_id = business_unit.business_unit_id
and 		statrev_revision_rep_xref.revision_id  = statrev_campaign_revision.revision_id
and 		statrev_revision_rep_xref.rep_id  = sales_rep.rep_id
group by 	film_campaign.campaign_no, 
			film_campaign.product_desc,
			statrev_outpost_deferred_transaction.transaction_type, 
			statrev_outpost_deferred_transaction.delta_date, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id,
			sales_rep.rep_id,
			sales_rep.first_name , sales_rep.last_name
GO
