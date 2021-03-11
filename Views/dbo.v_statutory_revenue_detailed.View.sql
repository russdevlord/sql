USE [production]
GO
/****** Object:  View [dbo].[v_statutory_revenue_detailed]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_statutory_revenue_detailed]
as
select  client_name,  client_group_desc, agency_name, agency_group_name, buying_group_desc, v_statutory_revenue.*
from    client, client_group, v_statutory_revenue, film_campaign, agency, agency_groups, agency_buying_groups
where   client.client_group_id = client_group.client_group_id
and     client.client_id = film_campaign.client_id
and     film_campaign.campaign_no = v_statutory_revenue.campaign_no
and     agency.agency_group_id = agency_groups.agency_group_id
and     agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and     agency.agency_id = film_campaign.reporting_agency
GO
