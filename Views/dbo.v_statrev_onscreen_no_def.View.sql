/****** Object:  View [dbo].[v_statrev_onscreen_no_def]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_statrev_onscreen_no_def]
GO
/****** Object:  View [dbo].[v_statrev_onscreen_no_def]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






create view [dbo].[v_statrev_onscreen_no_def]
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
from 		film_campaign, 
			statrev_campaign_revision, 
			statrev_cinema_normal_transaction, 
			statrev_transaction_type, 
			statrev_revenue_group, 
			statrev_revenue_master_group,
			branch,
			business_unit
where		film_campaign.campaign_no = statrev_campaign_revision.campaign_no
and			statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
and			statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and			statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and			statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and			film_campaign.branch_code = branch.branch_code
and         film_campaign.business_unit_id = business_unit.business_unit_id
and			statrev_transaction_type.revenue_group in (1,2,3,7,5)
and			film_campaign.business_unit_id in (2,3,5)
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
GO
