USE [production]
GO
/****** Object:  View [dbo].[v_retail_duplicate_panel_report]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_retail_duplicate_panel_report]
as
select outpost_panel_desc, outpost_player_xref.player_name from outpost_panel, outpost_player_xref 
where outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id
and outpost_panel.outpost_panel_id in (select outpost_panel_id from outpost_player_xref group by outpost_panel_id having count (player_name) > 1)

GO
