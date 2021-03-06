/****** Object:  StoredProcedure [dbo].[p_dart_two_data_one]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_dart_two_data_one]
GO
/****** Object:  StoredProcedure [dbo].[p_dart_two_data_one]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_dart_two_data_one]
as

declare		@query			varchar(max),
					@full_desc		varchar(max)

select @full_desc =stuff((select distinct '],[' + full_desc from v_outpost_retailer_player_xref order by '],['  + full_desc for xml path ('')),1,2,'') + ']'

SET @query =
'SELECT * FROM
(
    SELECT	v_outpost_retailer_player_xref.player_name,
					outpost_panel_desc,
					full_desc,
					screening_date,
					datepart(dw,start_time) as day,
					datepart(hh,start_time) as hour,
					dart_demographics_desc,
					country_code,
					sum(viewers) as viewers,
					case when sum(viewers) = 0 then 0 else sum(dwell_avg) / sum(viewers)  end  as average_dwell_secs,
					case when sum(viewers) = 0 then 0 else sum(attention_avg) / sum(viewers) end as average_attention_secs,
					sum(case when glasses = 2 then 1 else 0 end) as glasses_sum,
					sum(case when glasses = 3 then 1 else 0 end) as sunglasses_sum,
					sum(case when moustache = 2 then 1 else 0 end) as moustache_sum,
					sum(case when beard = 2 then 1 else 0 end) as beard_sum,
					sum(mood_very_unhappy) as mood_very_unhappy_sum,
					sum(mood_unhappy) as mood_unhappy_sum,
					sum(mood_neutral) as mood_neutral_sum,
					sum(mood_happy) as mood_happy_sum,
					sum(mood_very_happy) as sum_mood_very_happy,					
					count(distinct full_desc) as has_it
    FROM		v_outpost_retailer_player_xref,
					outpost_player_xref,
					dart_quividi_details,
					outpost_panel,
					dart_demographics
	where		v_outpost_retailer_player_xref.player_name = outpost_player_xref.player_name
	and			dart_quividi_details.outpost_panel_id = outpost_player_xref.outpost_panel_id
	and			dart_quividi_details.outpost_panel_id = outpost_panel.outpost_panel_id
	and  		dart_quividi_details.dart_demographics_id = dart_demographics.dart_demographics_id
	and			dart_quividi_details.dart_demographics_id  > 20
	group by v_outpost_retailer_player_xref.player_name,
					outpost_panel_desc,
					full_desc,
					screening_date,
					datepart(dw,start_time),
					datepart(hh,start_time),
					dart_demographics_desc,
					country_code
) t
PIVOT (SUM(has_it) FOR full_desc
IN ('+@full_desc+')) AS pvt'
 
EXECUTE (@query)
return 0
GO
