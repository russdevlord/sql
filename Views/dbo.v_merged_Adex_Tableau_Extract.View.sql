/****** Object:  View [dbo].[v_merged_Adex_Tableau_Extract]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_merged_Adex_Tableau_Extract]
GO
/****** Object:  View [dbo].[v_merged_Adex_Tableau_Extract]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

--select top 10 * from [v_Adex_Tableau_Extract]

--Drop View [v_Adex_Tableau_Extract]

CREATE view [dbo].[v_merged_Adex_Tableau_Extract]
as
select 		film_campaign.campaign_no, 
			film_campaign.product_desc,
			client_group.client_group_desc,
			client.client_name,
			client.client_id,
			client_group.client_group_id,
			agency.agency_name,
			agency.agency_id,
			agency_buying_groups.buying_group_desc,
			agency_groups.agency_group_name,
			statrev_cinema_normal_transaction.transaction_type,
			statrev_cinema_normal_transaction.revenue_period, 
			sum(statrev_cinema_normal_transaction.cost) as cost, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
			branch_name, branch.branch_code,branch.country_code,
			business_unit_desc,
			business_unit.business_unit_ID,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			Avg_duration,
			V_Adex_Tableau_extract.[Market Date]
			,V_Adex_Tableau_extract.[buying_group_id]
			,V_Adex_Tableau_extract.[agency_group_id]
			,V_Adex_Tableau_extract.[agencycategory]
			,V_Adex_Tableau_extract.[agency]
			,V_Adex_Tableau_extract.[advertiser]
			,V_Adex_Tableau_extract.[category]
			,V_Adex_Tableau_extract.[MTV 000]
			,V_Adex_Tableau_extract.[RTV 000]
			,V_Adex_Tableau_extract.[Mpress 000]
			,V_Adex_Tableau_extract.[Rpress 000]
			,V_Adex_Tableau_extract.[Mags 000]
			,V_Adex_Tableau_extract.[Radio 000]
			,V_Adex_Tableau_extract.[Out of Home 000]
			,V_Adex_Tableau_extract.[Cinema 000]
			,V_Adex_Tableau_extract.[Direct Mail 000]
from 		film_campaign, 
			statrev_campaign_revision, 
			statrev_cinema_normal_transaction, 
			statrev_transaction_type, 
			statrev_revenue_group, 
			statrev_revenue_master_group,
			branch,
			business_unit,
			client,
			client_group,
			agency,
			agency_buying_groups,
			agency_groups,
			V_campaign_spot_reporting,
			V_Adex_Tableau_extract
where		film_campaign.campaign_no = statrev_campaign_revision.campaign_no
and			statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
and			statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and			statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and			statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and			film_campaign.branch_code = branch.branch_code
and         film_campaign.business_unit_id = business_unit.business_unit_id
and		    client.client_id = film_campaign.client_id
and			agency.agency_id = film_campaign.reporting_agency
and			client.client_group_id = client_group.client_group_id
and			agency.agency_group_id = agency_groups.agency_group_id
and			agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and			V_campaign_spot_reporting.campaign_no = film_campaign.campaign_no
and			V_campaign_spot_reporting.type_id  = statrev_transaction_type.statrev_transaction_type
and			statrev_cinema_normal_transaction.delta_date >= '28-Jun-2012' 
and			statrev_cinema_normal_transaction.cost <> 0
and			Month(V_Adex_Tableau_extract.[Market Date]) = month(statrev_cinema_normal_transaction.revenue_period)
and			Year(V_Adex_Tableau_extract.[Market Date]) = Year(statrev_cinema_normal_transaction.revenue_period)	
group by 	film_campaign.campaign_no, 
			film_campaign.product_desc,
			client_group.client_group_desc,
			client.client_name,
			client.client_id,
			agency.agency_name,
			agency_buying_groups.buying_group_desc,
			agency_groups.agency_group_name,
			statrev_cinema_normal_transaction.transaction_type, 
			statrev_cinema_normal_transaction.revenue_period, 
			statrev_transaction_type_desc,
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
			statrev_transaction_type.statrev_transaction_type,
			V_campaign_spot_reporting.avg_duration,
			V_Adex_Tableau_extract.[Market Date]
			,V_Adex_Tableau_extract.[buying_group_id]
			,V_Adex_Tableau_extract.[agency_group_id]
			,V_Adex_Tableau_extract.[agencycategory]
			,V_Adex_Tableau_extract.[agency]
			,V_Adex_Tableau_extract.[advertiser]
			,V_Adex_Tableau_extract.[category]
			,V_Adex_Tableau_extract.[MTV 000]
			,V_Adex_Tableau_extract.[RTV 000]
			,V_Adex_Tableau_extract.[Mpress 000]
			,V_Adex_Tableau_extract.[Rpress 000]
			,V_Adex_Tableau_extract.[Mags 000]
			,V_Adex_Tableau_extract.[Radio 000]
			,V_Adex_Tableau_extract.[Out of Home 000]
			,V_Adex_Tableau_extract.[Cinema 000]
			,V_Adex_Tableau_extract.[Direct Mail 000]
union
select 		film_campaign.campaign_no, 
			film_campaign.product_desc,
			client_group.client_group_desc,
			client.client_name,
			client.client_id,
			client_group.client_group_id,
			agency.agency_name,
			agency.agency_id,
			agency_buying_groups.buying_group_desc,
			agency_groups.agency_group_name,
			statrev_outpost_normal_transaction.transaction_type, 
			statrev_outpost_normal_transaction.revenue_period, 
			sum(statrev_outpost_normal_transaction.cost) as cost, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
            business_unit.business_unit_ID,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			avg_duration,
			 V_Adex_Tableau_extract.[Market Date]
			,V_Adex_Tableau_extract.[buying_group_id]
			,V_Adex_Tableau_extract.[agency_group_id]
			,V_Adex_Tableau_extract.[agencycategory]
			,V_Adex_Tableau_extract.[agency]
			,V_Adex_Tableau_extract.[advertiser]
			,V_Adex_Tableau_extract.[category]
			,V_Adex_Tableau_extract.[MTV 000]
			,V_Adex_Tableau_extract.[RTV 000]
			,V_Adex_Tableau_extract.[Mpress 000]
			,V_Adex_Tableau_extract.[Rpress 000]
			,V_Adex_Tableau_extract.[Mags 000]
			,V_Adex_Tableau_extract.[Radio 000]
			,V_Adex_Tableau_extract.[Out of Home 000]
			,V_Adex_Tableau_extract.[Cinema 000]
			,V_Adex_Tableau_extract.[Direct Mail 000]
from 		film_campaign, 
			statrev_campaign_revision, 
			statrev_outpost_normal_transaction, 
			statrev_transaction_type, 
			statrev_revenue_group, 
			statrev_revenue_master_group,
			branch,
            business_unit,
            client,
            client_group,
            agency,
			agency_buying_groups,
			agency_groups,
			V_campaign_spot_reporting,
			V_Adex_Tableau_extract
where		film_campaign.campaign_no = statrev_campaign_revision.campaign_no
and			statrev_campaign_revision.revision_id = statrev_outpost_normal_transaction.revision_id
and			statrev_outpost_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and			statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and			statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and			film_campaign.branch_code = branch.branch_code
and         film_campaign.business_unit_id = business_unit.business_unit_id
and			client.client_group_id = client_group.client_group_id
and		    client.client_id = film_campaign.client_id
and			agency.agency_group_id = agency_groups.agency_group_id
and			agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and			agency.agency_id = film_campaign.reporting_agency
and			V_campaign_spot_reporting.campaign_no =  film_campaign.campaign_no
and			statrev_transaction_type.statrev_transaction_type = V_campaign_spot_reporting.type_id
and			statrev_outpost_normal_transaction.revenue_period >= '28-Jun-2012' 
and			statrev_outpost_normal_transaction.cost <> 0
and			Month(V_Adex_Tableau_extract.[Market Date]) = Month(statrev_outpost_normal_transaction.revenue_period)
and			Year(V_Adex_Tableau_extract.[Market Date]) = Year(statrev_outpost_normal_transaction.revenue_period)	
group by 	film_campaign.campaign_no, 
			film_campaign.product_desc,
			client_group.client_group_desc,
			client.client_name,
			client.client_id,
			agency.agency_name,
			agency_buying_groups.buying_group_desc,
			agency_groups.agency_group_name,
			statrev_outpost_normal_transaction.transaction_type, 
			statrev_outpost_normal_transaction.revenue_period, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
            business_unit.business_unit_ID,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			agency.agency_id,
			client_group.client_group_id,
			statrev_campaign_revision.campaign_no,
			statrev_transaction_type.statrev_transaction_type,
			V_campaign_spot_reporting.avg_duration
			,V_Adex_Tableau_extract.[Market Date]
			,V_Adex_Tableau_extract.[buying_group_id]
			,V_Adex_Tableau_extract.[agency_group_id]
			,V_Adex_Tableau_extract.[agencycategory]
			,V_Adex_Tableau_extract.[agency]
			,V_Adex_Tableau_extract.[advertiser]
			,V_Adex_Tableau_extract.[category]
			,V_Adex_Tableau_extract.[MTV 000]
			,V_Adex_Tableau_extract.[RTV 000]
			,V_Adex_Tableau_extract.[Mpress 000]
			,V_Adex_Tableau_extract.[Rpress 000]
			,V_Adex_Tableau_extract.[Mags 000]
			,V_Adex_Tableau_extract.[Radio 000]
			,V_Adex_Tableau_extract.[Out of Home 000]
			,V_Adex_Tableau_extract.[Cinema 000]
			,V_Adex_Tableau_extract.[Direct Mail 000]
/*union
select 		film_campaign.campaign_no, 
			film_campaign.product_desc,
			client_group.client_group_desc,
			client.client_name,
			client.client_id,
			client_group.client_group_id,
			agency.agency_name,
			agency.agency_id,
			agency_buying_groups.buying_group_desc,
			agency_groups.agency_group_name,
			statrev_cinema_deferred_transaction.transaction_type, 
			null, 
			null, 
			sum(statrev_cinema_deferred_transaction.cost) as cost, 
			sum(statrev_cinema_deferred_transaction.units) as units, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
            business_unit.business_unit_ID,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id,
			Avg_duration
from 		film_campaign, 
			statrev_campaign_revision, 
			statrev_cinema_deferred_transaction, 
			statrev_transaction_type, 
			statrev_revenue_group, 
			statrev_revenue_master_group,
			branch,
            business_unit,
            client,
            client_group,
            agency,
			agency_buying_groups,
			agency_groups,
			V_campaign_spot_reporting
where		film_campaign.campaign_no = statrev_campaign_revision.campaign_no
and			statrev_campaign_revision.revision_id = statrev_cinema_deferred_transaction.revision_id
and			statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and			statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and			statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and			film_campaign.branch_code = branch.branch_code
and         film_campaign.business_unit_id = business_unit.business_unit_id
and			client.client_group_id = client_group.client_group_id
and		    client.client_id = film_campaign.client_id
and		    agency.agency_group_id = agency_groups.agency_group_id
and			agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and			agency.agency_id = film_campaign.reporting_agency
and			V_campaign_spot_reporting.campaign_no =  film_campaign.campaign_no
and			statrev_transaction_type.statrev_transaction_type = V_campaign_spot_reporting.type_id
and			statrev_cinema_deferred_transaction.delta_date >= '28-Jun-2012' 
group by 	film_campaign.campaign_no, 
			film_campaign.product_desc,
			client_group.client_group_desc,
			client.client_name,
			agency.agency_name,
			agency_buying_groups.buying_group_desc,
			agency_groups.agency_group_name,
			statrev_cinema_deferred_transaction.transaction_type, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
            business_unit.business_unit_ID,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id,
			client.client_id,
			agency.agency_id,
			client_group.client_group_id,
			statrev_campaign_revision.campaign_no,
			statrev_transaction_type.statrev_transaction_type,
			V_campaign_spot_reporting.avg_duration
union
select 		film_campaign.campaign_no, 
			film_campaign.product_desc,
			client_group.client_group_desc,
			client.client_name,
			client.client_id,
			client_group.client_group_id,
			agency.agency_name,
			agency.agency_id,
			agency_buying_groups.buying_group_desc,
			agency_groups.agency_group_name,
			statrev_outpost_deferred_transaction.transaction_type, 
			null, 
			null, 
			sum(statrev_outpost_deferred_transaction.cost) as cost, 
			sum(statrev_outpost_deferred_transaction.units) as units, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
            business_unit.business_unit_ID,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id,
			Avg_duration
from 		film_campaign, 
			statrev_campaign_revision, 
			statrev_outpost_deferred_transaction, 
			statrev_transaction_type, 
			statrev_revenue_group, 
			statrev_revenue_master_group,
			branch,
            business_unit,
            Client,
            Client_group,
            agency,
			agency_buying_groups,
			agency_groups,
			V_campaign_spot_reporting
where		film_campaign.campaign_no = statrev_campaign_revision.campaign_no
and			statrev_campaign_revision.revision_id = statrev_outpost_deferred_transaction.revision_id
and			statrev_outpost_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and			statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and			statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and			film_campaign.branch_code = branch.branch_code
and         film_campaign.business_unit_id = business_unit.business_unit_id
and			client.client_group_id = client_group.client_group_id
and		    client.client_id = film_campaign.client_id
and			agency.agency_group_id = agency_groups.agency_group_id
and			agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and		    agency.agency_id = film_campaign.reporting_agency
and			V_campaign_spot_reporting.campaign_no =  film_campaign.campaign_no
and			statrev_transaction_type.statrev_transaction_type = V_campaign_spot_reporting.type_id
and			statrev_outpost_deferred_transaction.delta_date>= '28-Jun-2012' 
group by 	film_campaign.campaign_no, 
			film_campaign.product_desc,
			client_group.client_group_desc,
			client.client_name,
			agency.agency_name,
			agency_buying_groups.buying_group_desc,
			agency_groups.agency_group_name,
			statrev_outpost_deferred_transaction.transaction_type, 
			statrev_transaction_type_desc,
			revenue_group_desc,
			master_revenue_group_desc,
            branch_name, branch.branch_code,branch.country_code,
            business_unit_desc,
            business_unit.business_unit_ID,
			statrev_revenue_group.revenue_group,
			statrev_revenue_group.master_revenue_group,
			statrev_campaign_revision.revision_id,
			client.client_id,
			agency.agency_id,
			client_group.client_group_id,
			statrev_campaign_revision.campaign_no,
			statrev_transaction_type.statrev_transaction_type,
			V_campaign_spot_reporting.avg_duration
*/



GO
