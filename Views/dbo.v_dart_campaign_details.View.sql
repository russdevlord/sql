/****** Object:  View [dbo].[v_dart_campaign_details]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dart_campaign_details]
GO
/****** Object:  View [dbo].[v_dart_campaign_details]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_dart_campaign_details]
as
select		campaign_no, 
			dart_demographics_id, 
			screening_date, 	
			dateadd(hour, datediff(hour, 0, start_time), 0) as time_of_day,
			outpost_panel_id, 
			country_code,  
			sum(viewers) as camp_viewers, 
			count(campaign_no) as count_camp,
			(select		sum(sub.viewers) as camp_viewers
			from		dart_dcmedia_player_pop sub
			where		sub.dart_demographics_id = dart_dcmedia_player_pop.dart_demographics_id
			and			sub.screening_date = dart_dcmedia_player_pop.screening_date
			and			dateadd(hour, datediff(hour, 0, sub.start_time), 0)  =  dateadd(hour, datediff(hour, 0, dart_dcmedia_player_pop.start_time), 0) 
			and			sub.outpost_panel_id  =  dart_dcmedia_player_pop.outpost_panel_id
			and			sub.country_code = dart_dcmedia_player_pop.country_code) as demo_viewers,
			(select		count(sub.campaign_no) as count_camp
			from		dart_dcmedia_player_pop sub
			where		sub.dart_demographics_id = dart_dcmedia_player_pop.dart_demographics_id
			and			sub.screening_date = dart_dcmedia_player_pop.screening_date
			and			dateadd(hour, datediff(hour, 0, sub.start_time), 0)  =  dateadd(hour, datediff(hour, 0, dart_dcmedia_player_pop.start_time), 0) 
			and			sub.outpost_panel_id  =  dart_dcmedia_player_pop.outpost_panel_id
			and			sub.country_code = dart_dcmedia_player_pop.country_code) as demo_camp,
			(select		sum(sub.viewers) as camp_viewers
			from		dart_dcmedia_player_pop sub
			where		sub.screening_date = dart_dcmedia_player_pop.screening_date
			and			dateadd(hour, datediff(hour, 0, sub.start_time), 0)  =  dateadd(hour, datediff(hour, 0, dart_dcmedia_player_pop.start_time), 0) 
			and			sub.outpost_panel_id  =  dart_dcmedia_player_pop.outpost_panel_id
			and			sub.country_code = dart_dcmedia_player_pop.country_code) as tot_viewers,
			(select		count(sub.campaign_no) as count_camp
			from		dart_dcmedia_player_pop sub
			where		sub.screening_date = dart_dcmedia_player_pop.screening_date
			and			dateadd(hour, datediff(hour, 0, sub.start_time), 0)  =  dateadd(hour, datediff(hour, 0, dart_dcmedia_player_pop.start_time), 0) 
			and			sub.outpost_panel_id  =  dart_dcmedia_player_pop.outpost_panel_id
			and			sub.country_code = dart_dcmedia_player_pop.country_code) as tot_camp,
			(select		sum(sub.viewers) as camp_viewers
			from		dart_dcmedia_player_pop sub
			where		sub.screening_date = dart_dcmedia_player_pop.screening_date
			and			dateadd(hour, datediff(hour, 0, sub.start_time), 0)  =  dateadd(hour, datediff(hour, 0, dart_dcmedia_player_pop.start_time), 0) 
			and			sub.outpost_panel_id  =  dart_dcmedia_player_pop.outpost_panel_id
			and			sub.country_code = dart_dcmedia_player_pop.country_code) as all_camp_viewers,
			(select		count(sub.campaign_no) as count_camp
			from		dart_dcmedia_player_pop sub
			where		sub.screening_date = dart_dcmedia_player_pop.screening_date
			and			dateadd(hour, datediff(hour, 0, sub.start_time), 0)  =  dateadd(hour, datediff(hour, 0, dart_dcmedia_player_pop.start_time), 0) 
			and			sub.outpost_panel_id  =  dart_dcmedia_player_pop.outpost_panel_id
			and			sub.country_code = dart_dcmedia_player_pop.country_code) as tot_count_camp			
from		dart_dcmedia_player_pop
group by	campaign_no, 
					dart_demographics_id, 
					screening_date, 	
					dateadd(hour, datediff(hour, 0, start_time), 0), 
					outpost_panel_id, 
					country_code
GO
