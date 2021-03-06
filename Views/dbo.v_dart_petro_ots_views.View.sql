/****** Object:  View [dbo].[v_dart_petro_ots_views]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dart_petro_ots_views]
GO
/****** Object:  View [dbo].[v_dart_petro_ots_views]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Script for SelectTopNRows command from SSMS  ******/
create view [dbo].[v_dart_petro_ots_views]
as
SELECT campaign_no, screening_date, viewers, ots, v_outpost_player_panel_detail.* from dart_petro_engagement, v_outpost_player_panel_detail
where dart_petro_engagement.outpost_panel_id =  v_outpost_player_panel_detail.outpost_panel_id
GO
