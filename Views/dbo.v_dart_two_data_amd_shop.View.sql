USE [production]
GO
/****** Object:  View [dbo].[v_dart_two_data_amd_shop]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_dart_two_data_amd_shop]
as
SELECT		v_dart_campaign_panel_actuals_detailed_oct.campaign_no,
					film_campaign.product_desc,
					outpost_player_xref.player_name,
					outpost_player.internal_desc,
					outpost_panel_desc,
					screening_date,
					datepart(dw,time_of_day) as day,
					datepart(hh,time_of_day) as hour,
					country_code,
					sum(viewers) as viewers,
					sum(ots) as ots,
					case when sum(viewers) = 0 then 0 else sum(dwell_avg) / sum(viewers) end  as average_dwell_secs,
					case when sum(viewers) = 0 then 0 else sum(attention_avg) / sum(viewers) end as average_attention_secs,
					sum(glasses) as glasses_sum,
					sum(sunglasses) as sunglasses_sum,
					sum(moustache) as moustache_sum,
					sum(beard) as beard_sum,
					sum(mood_very_unhappy) as mood_very_unhappy_sum,
					sum(mood_unhappy) as mood_unhappy_sum,
					sum(mood_neutral) as mood_neutral_sum,
					sum(mood_happy) as mood_happy_sum,
					sum(mood_very_happy) as sum_mood_very_happy
    FROM		outpost_player_xref,
					v_dart_campaign_panel_actuals_detailed_oct,
					outpost_panel,
					dart_demographics,
					film_campaign,
					outpost_player
	where		v_dart_campaign_panel_actuals_detailed_oct.outpost_panel_id = outpost_player_xref.outpost_panel_id
	and			v_dart_campaign_panel_actuals_detailed_oct.outpost_panel_id = outpost_panel.outpost_panel_id
	and  		v_dart_campaign_panel_actuals_detailed_oct.dart_demographics_id = dart_demographics.dart_demographics_id
	and			v_dart_campaign_panel_actuals_detailed_oct.dart_demographics_id  > 20
	and			v_dart_campaign_panel_actuals_detailed_oct.campaign_no = film_campaign.campaign_no
	and			outpost_player_xref.player_name = outpost_player.player_name
	and			outpost_player.media_product_id in (9,11)
	group by v_dart_campaign_panel_actuals_detailed_oct.campaign_no,
					film_campaign.product_desc,
					outpost_player_xref.player_name,
					outpost_player.internal_desc,
					outpost_panel_desc,
					screening_date,
					datepart(dw,time_of_day),
					datepart(hh,time_of_day),
					country_code
GO
