/****** Object:  View [dbo].[v_film_campaign_details]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_film_campaign_details]
GO
/****** Object:  View [dbo].[v_film_campaign_details]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



CREATE VIEW [dbo].[v_film_campaign_details]
AS
    select	film_campaign.campaign_no,
			film_campaign.product_desc,
			country.country_code,
			country.country_name,
			branch.branch_code,
			branch.branch_name,
			business_unit.business_unit_id,
			business_unit.business_unit_desc,
			agency.agency_id,
			agency.agency_name,
			agency_groups.agency_group_id,
			agency_groups.agency_group_name,
			agency_buying_groups.buying_group_id,
			agency_buying_groups.buying_group_desc,
			film_campaign.client_id,
			client.client_name,
			client_product.client_product_id,
			client_product_desc,
			film_campaign.start_date,
			film_campaign.end_date,
			campaign_value,
			campaign_cost,
			confirmed_value,
			confirmed_cost,
			(select cinetam_reporting_demographics_desc from cinetam_campaign_settings, cinetam_reporting_demographics where cinetam_reporting_demographics.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id and campaign_no = film_campaign.campaign_no ) as cinetam_demographic_desc,
			('') as dart_demographic_desc,
			(select count(spot_id) from campaign_spot where campaign_no = film_campaign.campaign_no and spot_type not in ('G', 'M', 'R', 'T', 'W', 'Y')) as onscreen_spots,
			(select count(spot_id) from outpost_spot where campaign_no = film_campaign.campaign_no and spot_type not in ('G', 'M', 'R', 'T', 'W', 'Y')) as retail_spots
    from	film_campaign,
			client,
			agency,
			client_product,
			agency_groups,
			agency_buying_groups,
			business_unit,
			branch,
			country
    where	film_campaign.client_id = client.client_id 
    and		film_campaign.reporting_agency = agency.agency_id 
    and		film_campaign.client_product_id = client_product.client_product_id
	and		agency.agency_group_id = agency_groups.agency_group_id           
	and		agency_buying_groups.buying_group_id = agency_groups.buying_group_id           
	and		film_campaign.business_unit_id = business_unit.business_unit_id
	and		film_campaign.branch_code = branch.branch_code
	and		branch.country_code = country.country_code


GO
