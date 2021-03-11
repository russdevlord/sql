USE [production]
GO
/****** Object:  View [dbo].[v_dart_panel_matrix_lite]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




Create View [dbo].[v_dart_panel_matrix_lite] AS
select		opx.player_name,
			pan.outpost_panel_id,
			play.internal_desc ,
			play.media_product_id 
From		outpost_panel pan
JOIN		outpost_player_xref opx 
				on opx.outpost_panel_id = pan.outpost_panel_id
JOIN		outpost_player play
				on opx.player_name = play.player_name





GO
