/****** Object:  View [dbo].[v_dart_petro_campaign_viewer_split]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dart_petro_campaign_viewer_split]
GO
/****** Object:  View [dbo].[v_dart_petro_campaign_viewer_split]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	create view [dbo].[v_dart_petro_campaign_viewer_split]
	as
	select		campaign_no, 
				package_id,
				screening_date,
				outpost_panel_id,
				time_of_day, 
				sum(viewers) as campaign_viewers,
				(select		sum(viewers) 
				from		dart_campaign_panel_actuals_detailed details_2
				where		details_1.screening_date = details_2.screening_date
				and			details_1.outpost_panel_id = details_2.outpost_panel_id
				and			details_1.time_of_day = details_2.time_of_day) as all_viewers,
				convert(numeric(12,8), sum(viewers)) / (select		convert(numeric(12,8), sum(viewers))
								from		dart_campaign_panel_actuals_detailed details_2
								where		details_1.screening_date = details_2.screening_date
								and			details_1.outpost_panel_id = details_2.outpost_panel_id
								and			details_1.time_of_day = details_2.time_of_day) as view_percentage
	from		dart_campaign_panel_actuals_detailed details_1
	group by	campaign_no, 
				package_id,
				screening_date,
				outpost_panel_id,
				time_of_day			
				
				
GO
