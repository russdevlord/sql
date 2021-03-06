/****** Object:  View [dbo].[v_statrev_Tableau_Extract]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statrev_Tableau_Extract]
GO
/****** Object:  View [dbo].[v_statrev_Tableau_Extract]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



--select top 10 * from [v_joined_Adex_Tableau_Extract]

--Drop View [v_statrev_Tableau_Extract]

CREATE view [dbo].[v_statrev_Tableau_Extract]
as
select 	Distinct	
			film_campaign.campaign_no, 
			film_campaign.product_desc,
			client_group.client_group_desc,
			client.client_name,
			client.client_id,
			client_group.client_group_id,
			agency.agency_name,
			agency.agency_id,
			agency_buying_groups.buying_group_desc,
			agency_buying_groups.buying_group_id,
			agency_groups.agency_group_name,
			agency_groups.agency_group_id,
			--statrev_cinema_normal_transaction.transaction_type,
			statrev_cinema_normal_transaction.revenue_period, 
			sum(statrev_cinema_normal_transaction.cost) as cost, 
			--statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
			branch_name, branch.branch_code,branch.country_code,
			business_unit_desc,
			business_unit.business_unit_ID,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			(Select Min(Avg_duration) from V_campaign_spot_reporting  with (nolock) where film_campaign.campaign_no = V_campaign_spot_reporting.campaign_no) as Avg_duration
from 		film_campaign with (nolock)
			JOIN statrev_campaign_revision 
			ON  film_campaign.campaign_no = statrev_campaign_revision.campaign_no
			JOIN statrev_cinema_normal_transaction  with (nolock)
			ON statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
			JOIN statrev_transaction_type  with (nolock)
			ON statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
			JOIN statrev_revenue_group  with (nolock)
			ON statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
			JOIN statrev_revenue_master_group  with (nolock)
			ON statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
			JOIN branch  with (nolock)
			ON film_campaign.branch_code = branch.branch_code
			JOIN business_unit  with (nolock)
			ON film_campaign.business_unit_id = business_unit.business_unit_id
			JOIN client  with (nolock)
			ON client.client_id = film_campaign.client_id
			JOIN client_group  with (nolock)
			ON client.client_group_id = client_group.client_group_id
			JOIN agency  with (nolock)
			ON agency.agency_id = film_campaign.reporting_agency
			JOIN agency_groups  with (nolock)
			ON agency.agency_group_id = agency_groups.agency_group_id
			JOIN agency_buying_groups  with (nolock)
			ON 	agency_groups.buying_group_id = agency_buying_groups.buying_group_id
where		
			statrev_cinema_normal_transaction.revenue_period >=  '28-Jun-2012' 
and			statrev_cinema_normal_transaction.cost <> 0
group by 	film_campaign.campaign_no, 
			film_campaign.product_desc,
			client_group.client_group_desc,
			client.client_name,
			client.client_id,
			agency.agency_name,
			agency_buying_groups.buying_group_desc,
			agency_groups.agency_group_name,
			statrev_cinema_normal_transaction.revenue_period, 
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
            business_unit.business_unit_ID,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			client.client_id, 
			agency.agency_id,
			client_group.client_group_id,
			statrev_campaign_revision.campaign_no,
			client_group.client_group_id,
			agency_buying_groups.buying_group_id,
			agency_groups.agency_group_id
			
union
select 	Distinct	
			film_campaign.campaign_no, 
			film_campaign.product_desc,
			client_group.client_group_desc,
			client.client_name,
			client.client_id,
			client_group.client_group_id,
			agency.agency_name,
			agency.agency_id,
			agency_buying_groups.buying_group_desc,
			agency_buying_groups.buying_group_id,
			agency_groups.agency_group_name,
			agency_groups.agency_group_id,
			statrev_outpost_normal_transaction.revenue_period, 
			sum(statrev_outpost_normal_transaction.cost) as cost, 
			revenue_group_desc,
			master_revenue_group_desc,
			branch_name, branch.branch_code,branch.country_code,
			business_unit_desc,
			business_unit.business_unit_ID,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			15 Avg_duration
from 		film_campaign  with (nolock)
			JOIN statrev_campaign_revision  with (nolock)
			ON  film_campaign.campaign_no = statrev_campaign_revision.campaign_no			
			JOIN statrev_outpost_normal_transaction  with (nolock)
			ON statrev_campaign_revision.revision_id = statrev_outpost_normal_transaction.revision_id
			JOIN statrev_transaction_type  with (nolock)
			ON statrev_outpost_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
			JOIN statrev_revenue_group  with (nolock)
			ON statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
			JOIN statrev_revenue_master_group  with (nolock)
			ON statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
			JOIN branch  with (nolock)
			ON film_campaign.branch_code = branch.branch_code
			JOIN business_unit  with (nolock)
			ON film_campaign.business_unit_id = business_unit.business_unit_id
			JOIN client  with (nolock)
			ON client.client_id = film_campaign.client_id
			JOIN client_group  with (nolock)
			ON client.client_group_id = client_group.client_group_id
			JOIN agency  with (nolock)
			ON agency.agency_id = film_campaign.reporting_agency
			JOIN agency_groups  with (nolock)
			ON agency.agency_group_id = agency_groups.agency_group_id
			JOIN agency_buying_groups  with (nolock)
			ON 	agency_groups.buying_group_id = agency_buying_groups.buying_group_id
Where 		statrev_outpost_normal_transaction.revenue_period >= '28-Jun-2012' 
and			statrev_outpost_normal_transaction.cost <> 0
group by 	film_campaign.campaign_no, 
			film_campaign.product_desc,
			client_group.client_group_desc,
			client.client_name,
			client.client_id,
			agency.agency_name,
			agency_buying_groups.buying_group_desc,
			agency_groups.agency_group_name,
			statrev_outpost_normal_transaction.revenue_period, 
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
            business_unit.business_unit_ID,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			client.client_id, 
			agency.agency_id,
			client_group.client_group_id,
			statrev_campaign_revision.campaign_no,
			client_group.client_group_id,
			agency_buying_groups.buying_group_id,
			agency_groups.agency_group_id

GO
