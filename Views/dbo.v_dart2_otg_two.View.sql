/****** Object:  View [dbo].[v_dart2_otg_two]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dart2_otg_two]
GO
/****** Object:  View [dbo].[v_dart2_otg_two]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view	[dbo].[v_dart2_otg_two]
as
select				film_campaign.campaign_no,
						product_desc,
						business_unit_desc,
						screening_date,
						datepart(dw, time_of_day) as day,
						datepart(hh, time_of_day) as hour,
						dart_demographics_desc,
						country_code,
						sum(viewers) as viewers_sum,
						sum(ots) as ots_sum,
						avg(dwell_avg) as dwell_avg_secs,
						avg(attention_avg) as attention_avg_secs,
						sum(glasses) as glasses_sum,
						sum(sunglasses) as sunglasses_sum,
						sum(moustache) as moustache_sum,
						sum(beard) as beard_sum,
						sum(mood_very_unhappy) as very_unhappy_sum,
						sum(mood_unhappy) as unhappy_sum,
						sum(mood_neutral) as neutral_sum,
						sum(mood_happy) as happy_sum,
						sum(mood_very_happy) as very_happy_sum,
						outpost_player.player_name,
						outpost_player.internal_desc,
						outpost_panel_desc 
from				dart_campaign_panel_actuals_detailed,
						film_campaign,
						business_unit,
						dart_demographics,
						outpost_player_xref,
						outpost_player,
						outpost_panel
where				film_campaign.campaign_no = 	dart_campaign_panel_actuals_detailed.campaign_no
and					dart_campaign_panel_actuals_detailed.dart_demographics_id = dart_demographics.dart_demographics_id
and					film_campaign.business_unit_id = business_unit.business_unit_id
and					screening_date >= '2-oct-2016'
and					film_campaign.business_unit_id = 7
and					dart_campaign_panel_actuals_detailed.outpost_panel_id = outpost_player_xref.outpost_panel_id
and					outpost_player_xref.player_name = outpost_player.player_name
and					dart_campaign_panel_actuals_detailed.outpost_panel_id = outpost_panel.outpost_panel_id
and					outpost_player_xref.outpost_panel_id =  outpost_panel.outpost_panel_id
group by			film_campaign.campaign_no,
						product_desc,
						business_unit_desc,
						screening_date,
						datepart(dw, time_of_day),
						datepart(hh, time_of_day), 
						dart_demographics_desc,
						country_code,
						outpost_player.player_name,
						outpost_player.internal_desc,
						outpost_panel_desc 

						

GO
