/****** Object:  View [dbo].[v_statrev]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statrev]
GO
/****** Object:  View [dbo].[v_statrev]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create view [dbo].[v_statrev]
as
select 		film_campaign.campaign_no, 
			film_campaign.product_desc,
			statrev_cinema_normal_transaction.transaction_type, 
			statrev_cinema_normal_transaction.screening_date, 
			statrev_cinema_normal_transaction.revenue_period, 
			statrev_cinema_normal_transaction.delta_date, 
			sum(statrev_cinema_normal_transaction.cost) as cost, 
			sum(statrev_cinema_normal_transaction.units) as units, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
			branch_name, branch.branch_code,branch.country_code,
			business_unit_desc,
			business_unit.business_unit_id,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id
from 		film_campaign with (nolock), 
			statrev_campaign_revision with (nolock), 
			statrev_cinema_normal_transaction with (nolock), 
			statrev_transaction_type with (nolock), 
			statrev_revenue_group with (nolock), 
			statrev_revenue_master_group with (nolock),
			branch with (nolock),
			business_unit with (nolock)
where		film_campaign.campaign_no = statrev_campaign_revision.campaign_no
and			statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
and			statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and			statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and			statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and			film_campaign.branch_code = branch.branch_code
and         film_campaign.business_unit_id = business_unit.business_unit_id
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
            business_unit_desc,business_unit.business_unit_id,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id
union
select 		film_campaign.campaign_no, 
			film_campaign.product_desc,
			statrev_outpost_normal_transaction.transaction_type, 
			statrev_outpost_normal_transaction.screening_date, 
			statrev_outpost_normal_transaction.revenue_period, 
			statrev_outpost_normal_transaction.delta_date, 
			sum(statrev_outpost_normal_transaction.cost) as cost, 
			sum(statrev_outpost_normal_transaction.units) as units, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc, business_unit.business_unit_id,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id
from 		film_campaign with (nolock), 
			statrev_campaign_revision with (nolock), 
			statrev_outpost_normal_transaction with (nolock), 
			statrev_transaction_type with (nolock), 
			statrev_revenue_group with (nolock), 
			statrev_revenue_master_group with (nolock),
			branch with (nolock),
            business_unit with (nolock)
where		film_campaign.campaign_no = statrev_campaign_revision.campaign_no
and			statrev_campaign_revision.revision_id = statrev_outpost_normal_transaction.revision_id
and			statrev_outpost_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and			statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and			statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and			film_campaign.branch_code = branch.branch_code
and         film_campaign.business_unit_id = business_unit.business_unit_id
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
            business_unit_desc, business_unit.business_unit_id,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id
union
select 		film_campaign.campaign_no, 
			film_campaign.product_desc,
			statrev_cinema_deferred_transaction.transaction_type, 
			null, 
			null, 
			statrev_cinema_deferred_transaction.delta_date, 
			sum(statrev_cinema_deferred_transaction.cost) as cost, 
			sum(statrev_cinema_deferred_transaction.units) as units, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc, business_unit.business_unit_id,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id
from 		film_campaign with (nolock), 
			statrev_campaign_revision with (nolock), 
			statrev_cinema_deferred_transaction with (nolock), 
			statrev_transaction_type with (nolock), 
			statrev_revenue_group with (nolock), 
			statrev_revenue_master_group with (nolock),
			branch with (nolock),
            business_unit with (nolock)
where		film_campaign.campaign_no = statrev_campaign_revision.campaign_no
and			statrev_campaign_revision.revision_id = statrev_cinema_deferred_transaction.revision_id
and			statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and			statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and			statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and			film_campaign.branch_code = branch.branch_code
and         film_campaign.business_unit_id = business_unit.business_unit_id
group by 	film_campaign.campaign_no, 
			film_campaign.product_desc,
			statrev_cinema_deferred_transaction.transaction_type, 
			statrev_cinema_deferred_transaction.delta_date, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc, business_unit.business_unit_id,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id
union
select 		film_campaign.campaign_no, 
			film_campaign.product_desc,
			statrev_outpost_deferred_transaction.transaction_type, 
			null, 
			null, 
			statrev_outpost_deferred_transaction.delta_date, 
			sum(statrev_outpost_deferred_transaction.cost) as cost, 
			sum(statrev_outpost_deferred_transaction.units) as units, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc, business_unit.business_unit_id,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id
from 		film_campaign with (nolock), 
			statrev_campaign_revision with (nolock), 
			statrev_outpost_deferred_transaction with (nolock), 
			statrev_transaction_type with (nolock), 
			statrev_revenue_group with (nolock), 
			statrev_revenue_master_group with (nolock),
			branch with (nolock),
            business_unit with (nolock)
where		film_campaign.campaign_no = statrev_campaign_revision.campaign_no
and			statrev_campaign_revision.revision_id = statrev_outpost_deferred_transaction.revision_id
and			statrev_outpost_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and			statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and			statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and			film_campaign.branch_code = branch.branch_code
and         film_campaign.business_unit_id = business_unit.business_unit_id
group by 	film_campaign.campaign_no, 
			film_campaign.product_desc,
			statrev_outpost_deferred_transaction.transaction_type, 
			statrev_outpost_deferred_transaction.delta_date, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
            business_unit.business_unit_id,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id



GO
