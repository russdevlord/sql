/****** Object:  View [dbo].[v_nsw_direct_statrev]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_nsw_direct_statrev]
GO
/****** Object:  View [dbo].[v_nsw_direct_statrev]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_nsw_direct_statrev]
as
select film_campaign.campaign_no, film_campaign.product_desc, revenue_period, agency_name,  client_name, sum(cost) as revenue 
from v_statrev, film_campaign, agency, client  
where film_campaign.branch_code = 'N' and revenue_period > '1-jul-2015' and business_unit_desc like '%Direct%'
and v_statrev.campaign_no = film_campaign.campaign_no 
and film_campaign.reporting_agency = agency.agency_id
and film_campaign.client_id = client.client_id
group by film_campaign.campaign_no, film_campaign.product_desc, revenue_period, agency_name, client_name

GO
