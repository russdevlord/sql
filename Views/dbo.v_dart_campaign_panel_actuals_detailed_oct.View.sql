/****** Object:  View [dbo].[v_dart_campaign_panel_actuals_detailed_oct]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dart_campaign_panel_actuals_detailed_oct]
GO
/****** Object:  View [dbo].[v_dart_campaign_panel_actuals_detailed_oct]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_dart_campaign_panel_actuals_detailed_oct]
as
select * from  dart_campaign_panel_actuals_detailed where screening_date > '1-oct-2016'
GO
