/****** Object:  StoredProcedure [dbo].[p_dart_two_data_demo]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_dart_two_data_demo]
GO
/****** Object:  StoredProcedure [dbo].[p_dart_two_data_demo]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_dart_two_data_demo]
as

declare		@query			varchar(max),
					@full_desc		varchar(max)

select @full_desc =stuff((select distinct '],[' + full_desc from v_outpost_retailer_player_xref_ltd order by '],['  + full_desc for xml path ('')),1,2,'') + ']'

SET @query =
'SELECT * FROM
(
    SELECT	dart_campaign_panel_actuals_detailed.campaign_no,
					film_campaign.product_desc,
					full_desc, 
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
					sum(mood_very_happy) as sum_mood_very_happy,					
					count(distinct full_desc) as has_it
    FROM		outpost_player_xref,
					dart_campaign_panel_actuals_detailed,
					outpost_panel,
					dart_demographics,
					film_campaign,
					outpost_player,
					v_outpost_retailer_player_xref_ltd
	where		dart_campaign_panel_actuals_detailed.outpost_panel_id = outpost_player_xref.outpost_panel_id
	and			dart_campaign_panel_actuals_detailed.outpost_panel_id = outpost_panel.outpost_panel_id
	and  		dart_campaign_panel_actuals_detailed.dart_demographics_id = dart_demographics.dart_demographics_id
	and			dart_campaign_panel_actuals_detailed.dart_demographics_id  > 20
	and			dart_campaign_panel_actuals_detailed.campaign_no = film_campaign.campaign_no
	and			outpost_player_xref.player_name = outpost_player.player_name
	and			v_outpost_retailer_player_xref_ltd.player_name = outpost_player.player_name
	and			v_outpost_retailer_player_xref_ltd.player_name = outpost_player_xref.player_name
	group by dart_campaign_panel_actuals_detailed.campaign_no,
					film_campaign.product_desc,
					screening_date,
					datepart(dw,time_of_day),
					datepart(hh,time_of_day),
					dart_demographics_desc,
					country_code,
					full_desc
) t
PIVOT (SUM(has_it) FOR full_desc
IN ('+@full_desc+')) AS pvt'
 
EXECUTE (@query)
return 0
GO
