/****** Object:  View [dbo].[v_client_groups]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_client_groups]
GO
/****** Object:  View [dbo].[v_client_groups]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_client_groups]
AS
    select campaign_no,
           client.client_id,
           client_group.client_group_id,
           'Client' as source_mode,
           client.client_id as source_id,
           client_name as source_name
    from   film_campaign_reporting_client,
           client,
           client_group
    where  film_campaign_reporting_client.client_id = client.client_id and
           client.client_group_id = client_group.client_group_id and
           client_group_desc = 'Other'
           
   union
           
    select campaign_no,
           client.client_id,
           client_group.client_group_id,
           'Client Group' as source_mode,
           client_group.client_group_id as source_id,
           client_group_desc as source_name
    from   film_campaign_reporting_client,
           client,
           client_group
    where  film_campaign_reporting_client.client_id = client.client_id and
           client.client_group_id = client_group.client_group_id and
           client_group_desc != 'Other'
GO
