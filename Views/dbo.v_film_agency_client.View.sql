/****** Object:  View [dbo].[v_film_agency_client]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_film_agency_client]
GO
/****** Object:  View [dbo].[v_film_agency_client]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_film_agency_client]
AS
    select film_campaign.campaign_no 'campaign_no',
           film_campaign.product_desc 'campaign_name',
           client_name 'client_name',
           agency.agency_name 'agency_name',
           film_campaign.branch_code 'branch_code',
           campaign_cost 'campaign_cost'
    from   film_campaign,
           client,
           agency
    where  film_campaign.client_id = client.client_id and
           film_campaign.reporting_agency = agency.agency_id and
           campaign_status not in ('P', 'Z')
GO
