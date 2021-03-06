/****** Object:  View [dbo].[v_mgtrev]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_mgtrev]
GO
/****** Object:  View [dbo].[v_mgtrev]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE view [dbo].[v_mgtrev]
as
select 		film_campaign.campaign_no,
            product_desc,
            film_campaign.branch_code,
            business_unit_desc,
            revision_group.revision_group_desc,
            campaign_status,
            revenue_period,
            billing_date,
            client_name, 
            client_group_desc,
            agency_name,
            agency_group_name,
            buying_group_desc,
            first_name + ' ' + last_name 'rep_name',
            sum(cost) as revenue,
            delta_date,
            branch.country_code,
            business_unit.business_unit_id,
            revision_group.revision_group,
            type1 = 'C'
from 		revision_transaction,
			campaign_revision,
			revision_transaction_type,
			film_campaign,
            business_unit,
            client,
            client_group,
            agency,
            agency_groups,
            agency_buying_groups,
            sales_rep,
            revision_group,
            branch
where 		revision_transaction.revision_id = campaign_revision.revision_id
and			campaign_revision.campaign_no = film_campaign.campaign_no
and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
and         business_unit.business_unit_id = film_campaign.business_unit_id
and         sales_rep.rep_id = film_campaign.rep_id
and         film_campaign.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         film_campaign.reporting_agency = agency.agency_id
and         agency.agency_group_id = agency_groups.agency_group_id
and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and         revision_transaction_type.revision_group = revision_group.revision_group
AND			film_campaign.branch_code = branch.branch_code
group by    film_campaign.campaign_no,
            product_desc,
            film_campaign.branch_code,
            business_unit_desc,
            revision_group.revision_group_desc,
            campaign_status,
            revenue_period,
            billing_date,
            client_name, 
            client_group_desc,
            agency_name,
            agency_group_name,
            buying_group_desc,
            first_name,
            last_name,
            delta_date,
            branch.country_code,
            business_unit.business_unit_id,
            revision_group.revision_group
union all
select 		film_campaign.campaign_no,
            product_desc,
            film_campaign.branch_code,
            business_unit_desc,
            revision_group.revision_group_desc,
            campaign_status,
            revenue_period,
            billing_date,
            client_name, 
            client_group_desc,
            agency_name,
            agency_group_name,
            buying_group_desc,
            first_name + ' ' + last_name 'rep_name',
            sum(cost) as revenue,
            delta_date,
			branch.country_code,
            business_unit.business_unit_id,
            revision_group.revision_group,
            type1 = 'O'
from 		outpost_revision_transaction,
			campaign_revision,
			revision_transaction_type,
			film_campaign,
            business_unit,
            client,
            client_group,
            agency,
            agency_groups,
            agency_buying_groups,
            sales_rep,
            revision_group,
			branch
where 		outpost_revision_transaction.revision_id = campaign_revision.revision_id
and			campaign_revision.campaign_no = film_campaign.campaign_no
and			outpost_revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
and         business_unit.business_unit_id  = film_campaign.business_unit_id
and         sales_rep.rep_id = film_campaign.rep_id
and         film_campaign.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         film_campaign.reporting_agency = agency.agency_id
and         agency.agency_group_id = agency_groups.agency_group_id
and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and         revision_transaction_type.revision_group = revision_group.revision_group
AND			film_campaign.branch_code = branch.branch_code
group by    film_campaign.campaign_no,
            product_desc,
            film_campaign.branch_code,
            business_unit_desc,
            revision_group.revision_group_desc,
            campaign_status,
            revenue_period,
            billing_date,
            client_name, 
            client_group_desc,
            agency_name,
            agency_group_name,
            buying_group_desc,
            first_name,
            last_name,
            delta_date,
            branch.country_code,
            business_unit.business_unit_id,
            revision_group.revision_group
GO
