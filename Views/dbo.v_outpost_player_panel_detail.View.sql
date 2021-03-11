USE [production]
GO
/****** Object:  View [dbo].[v_outpost_player_panel_detail]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create View  [dbo].[v_outpost_player_panel_detail] As
select outpost_panel.outpost_panel_id, outpost_panel_desc, outpost_player.player_name, outpost_player.internal_desc
from outpost_panel,outpost_player_xref, outpost_player
where outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id
and outpost_player_xref.player_name = outpost_player.player_name

GO
