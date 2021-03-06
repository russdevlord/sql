/****** Object:  View [dbo].[v_dw_dim_campaigns]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dw_dim_campaigns]
GO
/****** Object:  View [dbo].[v_dw_dim_campaigns]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_dw_dim_campaigns]
AS
    select film_campaign.campaign_no 'campaign_no',
           film_campaign.product_desc 'campaign_name',
           client.client_name 'client_name',
           agency.agency_name 'agency_name',
           film_campaign.branch_code 'branch_code',
           film_campaign.campaign_cost 'campaign_cost',
           film_campaign.start_date 'campaign_start_date',
           (select min(screening_date) 
            from    v_spots_billed_allocated 
            where   campaign_no = film_campaign.campaign_no) as 'first_screening_week',
           (select count(spot_id) 
            from    v_spots_billed_allocated 
            where   campaign_no = film_campaign.campaign_no) as 'billed_screening_weeks',
           (select count(distinct screening_date) 
            from    v_spots_billed_allocated 
            where   campaign_no = film_campaign.campaign_no) as 'billed_weeks_on_screen'
    from   film_campaign,
           client,
           agency
    where  film_campaign.client_id = client.client_id and
           film_campaign.reporting_agency = agency.agency_id and
           film_campaign.campaign_status not in ('P', 'Z')
GO
