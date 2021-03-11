USE [production]
GO
/****** Object:  View [dbo].[v_slide_agency_client]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_slide_agency_client]
AS
    select slide_campaign.campaign_no 'campaign_no',
           slide_campaign.name_on_slide 'campaign_name',
           client_name 'client_name',
           agency.agency_name 'agency_name',
           slide_campaign.branch_code 'branch_code'
    from   slide_campaign,
           client,
           agency
    where  slide_campaign.client_id = client.client_id and
           slide_campaign.agency_id = agency.agency_id and
           campaign_status not in ('U', 'Z')
GO
