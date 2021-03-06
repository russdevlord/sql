/****** Object:  View [dbo].[v_dart_two_version_three]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dart_two_version_three]
GO
/****** Object:  View [dbo].[v_dart_two_version_three]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_dart_two_version_three]
as
SELECT		dart_campaign_panel_actuals_detailed.campaign_no,
					film_campaign.product_desc,
					business_unit_desc,
					screening_date,
					datepart(dw,time_of_day) as day,
					datepart(hh,time_of_day) as hour,
					dart_demographics_desc,
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
					dart_campaign_panel_actuals_detailed,
					outpost_panel,
					dart_demographics,
					film_campaign,
					outpost_player,
					business_unit
	where		dart_campaign_panel_actuals_detailed.outpost_panel_id = outpost_player_xref.outpost_panel_id
	and			dart_campaign_panel_actuals_detailed.outpost_panel_id = outpost_panel.outpost_panel_id
	and  		dart_campaign_panel_actuals_detailed.dart_demographics_id = dart_demographics.dart_demographics_id
	and			dart_campaign_panel_actuals_detailed.dart_demographics_id  > 20
	and			dart_campaign_panel_actuals_detailed.campaign_no = film_campaign.campaign_no
	and			outpost_player_xref.player_name = outpost_player.player_name
	and			film_campaign.business_unit_id = business_unit.business_unit_id
	group by dart_campaign_panel_actuals_detailed.campaign_no,
					film_campaign.product_desc,
					screening_date,
					business_unit_desc,
					datepart(dw,time_of_day),
					datepart(hh,time_of_day),
					dart_demographics_desc,
					country_code
GO
