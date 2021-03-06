/****** Object:  View [dbo].[v_retail_orphan_panel_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_retail_orphan_panel_report]
GO
/****** Object:  View [dbo].[v_retail_orphan_panel_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_retail_orphan_panel_report]
as
select outpost_panel_desc, outpost_venue_name from outpost_panel, outpost_venue 
where outpost_panel_id not in (select outpost_panel_id from outpost_player_xref) 
--and outpost_panel_id in (select outpost_panel_id from outpost_spot where campaign_no in (select campaign_no from film_campaign where campaign_status in ('F','L')))
and outpost_panel.outpost_venue_id = outpost_venue.outpost_venue_id
and outpost_panel.outpost_panel_status = 'O'

GO
