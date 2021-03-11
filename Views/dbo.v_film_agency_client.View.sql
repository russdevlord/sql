USE [production]
GO
/****** Object:  View [dbo].[v_film_agency_client]    Script Date: 11/03/2021 2:30:32 PM ******/
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
