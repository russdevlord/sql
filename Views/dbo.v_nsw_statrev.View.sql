USE [production]
GO
/****** Object:  View [dbo].[v_nsw_statrev]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_nsw_statrev]
as
select film_campaign.campaign_no, film_campaign.product_desc, revenue_period, agency_name,  sum(cost) as revenue 
from v_statrev, film_campaign, agency  
where film_campaign.branch_code = 'N' and revenue_period > '1-jul-2015' and business_unit_desc like '%Agency%'
and v_statrev.campaign_no = film_campaign.campaign_no 
and film_campaign.reporting_agency = agency.agency_id
group by film_campaign.campaign_no, film_campaign.product_desc, revenue_period, agency_name
GO
