/****** Object:  View [dbo].[v_michael]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_michael]
GO
/****** Object:  View [dbo].[v_michael]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_michael]
as
select rep_name, v_statrev_rep.campaign_no, client_name, agency_name, revenue_period, sum(cost) as rev 
from v_statrev_rep, agency, client, film_campaign
where revenue_period between '1-jan-2012' and '30-jun-2012' 
and business_unit_desc = 'Agency Sales Dept' 
and client.client_id = film_campaign.client_id
and	agency.agency_id = film_campaign.agency_id
and v_statrev_rep.campaign_no = film_campaign.campaign_no
group by rep_name, v_statrev_rep.campaign_no, client_name, agency_name, revenue_period
GO
