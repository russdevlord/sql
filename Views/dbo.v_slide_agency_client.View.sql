/****** Object:  View [dbo].[v_slide_agency_client]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_slide_agency_client]
GO
/****** Object:  View [dbo].[v_slide_agency_client]    Script Date: 12/03/2021 10:03:48 AM ******/
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
