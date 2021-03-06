/****** Object:  StoredProcedure [dbo].[p_dart_store_campaign_info]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_dart_store_campaign_info]
GO
/****** Object:  StoredProcedure [dbo].[p_dart_store_campaign_info]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc	[dbo].[p_dart_store_campaign_info]		@screening_date				datetime
			
as

declare			@error					int

SET NOCOUNT ON

delete		dart_campaign_panel_actuals
where		screening_date = @screening_date

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error uploading OTS file', 16, 1)
	return -1
end

delete		dart_campaign_panel_actuals_detailed
where		screening_date = @screening_date

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error uploading OTS file', 16, 1)
	return -1
end

--Insert dart_quividi_data for actuals

insert into dart_campaign_panel_actuals
(
	campaign_no,
	package_id,
	dart_demographics_id,
	screening_date,
	outpost_panel_id,
	country_code,
	actual,
	viewers,
	dwell_avg,
	dwell_min,
	dwell_max,
	attention_avg,
	attention_min,
	attention_max,
	ots,
	glasses,
	sunglasses,
	moustache,
	beard,
	mood_very_unhappy,
	mood_unhappy,
	mood_neutral,
	mood_happy,
	mood_very_happy	 
)
select			campaign_no,
					package_id,
					dart_demographics_id,
					screening_date,
					outpost_panel_id,
					country_code,
					'A',
					sum(viewers),
					avg(dwell_avg),
					sum(dwell_min),
					sum(dwell_max),
					avg(attention_avg),
					sum(attention_min),
					sum(attention_max),
					0,
					sum(glasses),
					sum(sunglasses),
					sum(moustache),
					sum(beard),
					sum(mood_very_unhappy),
					sum(mood_unhappy),
					sum(mood_neutral),
					sum(mood_happy),
					sum(mood_very_happy)	
from			dart_dcmedia_player_pop
where			screening_date = @screening_date
group by		campaign_no, 
					dart_demographics_id,
					screening_date,
					outpost_panel_id,
					country_code,
					package_id

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error inserting dart_campaign_panel_actuals file', 16, 1)
	return -1
end

--Insert dart_quividi_data_detailed for actuals

insert into dart_campaign_panel_actuals_detailed
(
	campaign_no,
	package_id,
	dart_demographics_id,
	screening_date,
	time_of_day,
	outpost_panel_id,
	country_code,
	actual,
	viewers,
	dwell_avg,
	dwell_min,
	dwell_max,
	attention_avg,
	attention_min,
	attention_max,
	ots,
	glasses,
	sunglasses,
	moustache,
	beard,
	mood_very_unhappy,
	mood_unhappy,
	mood_neutral,
	mood_happy,
	mood_very_happy	
)
select			campaign_no,
					package_id, 
					dart_demographics_id,
					screening_date,
					dateadd(hour, datediff(hour, 0, start_time), 0),
					outpost_panel_id,
					country_code,
					'A',
					sum(viewers),
					avg(dwell_avg),
					sum(dwell_min),
					sum(dwell_max),
					avg(attention_avg),
					sum(attention_min),
					sum(attention_max),
					0,
					sum(glasses),
					sum(sunglasses),
					sum(moustache),
					sum(beard),
					sum(mood_very_unhappy),
					sum(mood_unhappy),
					sum(mood_neutral),
					sum(mood_happy),
					sum(mood_very_happy)	
from			dart_dcmedia_player_pop
where			screening_date = @screening_date
group by		campaign_no, 
					dart_demographics_id,
					screening_date,
					outpost_panel_id,
					country_code,
					package_id,
					dateadd(hour, datediff(hour, 0, start_time), 0)
						
select @error = @@error
if @error <> 0 
begin
	raiserror ('Error uploading dart_campaign_panel_actuals_detailed', 16, 1)
	return -1
end

create table #dart_ots_camp
(
	outpost_panel_id		int,
	screening_date			datetime,
	time_of_day				datetime,
	country_code			char(1),
	ots_count					int,
	watcher_count			int,
	campaign_no				int,
	package_id					int
)

insert			into #dart_ots_camp
select			dart_quividi_ots.outpost_panel_id,
					screening_date,
					dateadd(hour, datediff(hour, 0, start_time), 0),
					country_code,
					sum(round(ots_count * campaign_percentage, 0)) as campaign_ots,
					sum(round(watcher_count * campaign_percentage, 0)) as campaign_watch,
					campaign_no,
					package_id
from			dart_quividi_ots,
					v_dart_campaign_time_split
where			dart_quividi_ots.start_time between v_dart_campaign_time_split.start_date and v_dart_campaign_time_split.end_date
and				dart_quividi_ots.outpost_panel_id = v_dart_campaign_time_split.outpost_panel_id
and				screening_date = @screening_date
and				dart_quividi_ots.outpost_panel_id in (select outpost_panel_id from outpost_player_xref where player_name in (select player_name from outpost_player where media_product_id not in (12, 13, 17)))
group by		dart_quividi_ots.outpost_panel_id,
					screening_date,
					dateadd(hour, datediff(hour, 0, start_time), 0),
					country_code,
					campaign_no,
					package_id

--Insert dart_quividi_data_ots_detailed for actuals
update		dart_campaign_panel_actuals_detailed
set				ots = temp_table.ots
from			(select			v_dart_campaign_package_details.screening_date,
											v_dart_campaign_package_details.time_of_day,
											v_dart_campaign_package_details.country_code,
											v_dart_campaign_package_details.outpost_panel_id,
											v_dart_campaign_package_details.campaign_no,
											v_dart_campaign_package_details.package_id,
											v_dart_campaign_package_details.dart_demographics_id,
											sum(convert(numeric(38,30), #dart_ots_camp.ots_count)) * (sum(convert(numeric(38,30), v_dart_campaign_package_details.count_camp)) / max(convert(numeric(38,30), v_dart_campaign_package_details.tot_count_camp)))  as ots
					from				#dart_ots_camp,
											v_dart_campaign_package_details
					where				#dart_ots_camp.screening_date = v_dart_campaign_package_details.screening_date
					and					#dart_ots_camp.country_code = v_dart_campaign_package_details.country_code
					and					#dart_ots_camp.outpost_panel_id = v_dart_campaign_package_details.outpost_panel_id
					and					#dart_ots_camp.time_of_day = v_dart_campaign_package_details.time_of_day
					and					#dart_ots_camp.campaign_no = v_dart_campaign_package_details.campaign_no
					and					#dart_ots_camp.package_id = v_dart_campaign_package_details.package_id
					and					#dart_ots_camp.outpost_panel_id in  (select outpost_panel_id from outpost_player_xref where player_name in (select player_name from outpost_player where media_product_id not in (12, 13, 17)))
					and					#dart_ots_camp.screening_date = @screening_date
					group by			v_dart_campaign_package_details.screening_date,
 											v_dart_campaign_package_details.country_code,
											v_dart_campaign_package_details.outpost_panel_id,
											v_dart_campaign_package_details.campaign_no,
											v_dart_campaign_package_details.package_id,
											v_dart_campaign_package_details.dart_demographics_id,
											v_dart_campaign_package_details.time_of_day) as temp_table
where			dart_campaign_panel_actuals_detailed.screening_date = temp_table.screening_date
and				dart_campaign_panel_actuals_detailed.country_code = temp_table.country_code
and				dart_campaign_panel_actuals_detailed.outpost_panel_id = temp_table.outpost_panel_id
and				dart_campaign_panel_actuals_detailed.campaign_no = temp_table.campaign_no
and				dart_campaign_panel_actuals_detailed.dart_demographics_id = temp_table.dart_demographics_id
and				dart_campaign_panel_actuals_detailed.time_of_day = temp_table.time_of_day
and				dart_campaign_panel_actuals_detailed.package_id = temp_table.package_id
and				dart_campaign_panel_actuals_detailed.screening_date =@screening_date

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error updating campaign OTS detailed', 16, 1)
	return -1
end

--Update dart_campaign_panel_actuals for actual ots
update		dart_campaign_panel_actuals
set				ots = temp_table.ots
from			(select			screening_date,
											country_code,
											outpost_panel_id,
											campaign_no,
											package_id,
											dart_demographics_id,
											sum(dart_campaign_panel_actuals_detailed.ots) as ots
					from				dart_campaign_panel_actuals_detailed
					group by			screening_date,
											country_code,
											outpost_panel_id,
											campaign_no,
											dart_demographics_id,
											package_id) as temp_table
where			dart_campaign_panel_actuals.screening_date = temp_table.screening_date
and				dart_campaign_panel_actuals.country_code = temp_table.country_code
and				dart_campaign_panel_actuals.outpost_panel_id = temp_table.outpost_panel_id
and				temp_table.outpost_panel_id in (select outpost_panel_id from outpost_player_xref where player_name in (select player_name from outpost_player where media_product_id not in (12, 13, 17)))
and				dart_campaign_panel_actuals.campaign_no = temp_table.campaign_no
and				dart_campaign_panel_actuals.package_id = temp_table.package_id
and				dart_campaign_panel_actuals.dart_demographics_id = temp_table.dart_demographics_id
and				dart_campaign_panel_actuals.screening_date =@screening_date


select @error = @@error
if @error <> 0 
begin
	raiserror ('Error updating campaign OTS', 16, 1)
	return -1
end

/*
 * Petro OTS Calculations
 */

return 0
GO
