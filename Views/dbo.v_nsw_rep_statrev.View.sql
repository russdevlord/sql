/****** Object:  View [dbo].[v_nsw_rep_statrev]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_nsw_rep_statrev]
GO
/****** Object:  View [dbo].[v_nsw_rep_statrev]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_nsw_rep_statrev]
as
select film_campaign.campaign_no, film_campaign.product_desc, revenue_period, rep_name, agency_name, sum(cost) as revenue 
from v_statrev_rep, film_campaign, agency  
where film_campaign.branch_code = 'N' and revenue_period > '1-jul-2015' and business_unit_desc like '%Agency%'
and v_statrev_rep.campaign_no = film_campaign.campaign_no 
and film_campaign.reporting_agency = agency.agency_id
group by film_campaign.campaign_no, film_campaign.product_desc, revenue_period, rep_name, agency_name
GO
