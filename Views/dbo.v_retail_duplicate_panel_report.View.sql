/****** Object:  View [dbo].[v_retail_duplicate_panel_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_retail_duplicate_panel_report]
GO
/****** Object:  View [dbo].[v_retail_duplicate_panel_report]    Script Date: 12/03/2021 10:03:49 AM ******/
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
