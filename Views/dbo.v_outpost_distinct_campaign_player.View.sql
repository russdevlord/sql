/****** Object:  View [dbo].[v_outpost_distinct_campaign_player]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_outpost_distinct_campaign_player]
GO
/****** Object:  View [dbo].[v_outpost_distinct_campaign_player]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_outpost_distinct_campaign_player]
as
select		campaign_no, 
					package_id, 
					outpost_player.player_name, 
					v_outpost_spots_and_days.screening_date, 
					count(spot_id)/count(v_outpost_spots_and_days.outpost_panel_id) as booking_count ,
					sum(days_booked)	/ 	count(v_outpost_spots_and_days.outpost_panel_id)	as days_taken			
from			v_outpost_spots_and_days, 
					outpost_player_xref, 
					outpost_player
where		v_outpost_spots_and_days.outpost_panel_id = outpost_player_xref.outpost_panel_id 
and				outpost_player_xref.player_name = outpost_player.player_name
and				v_outpost_spots_and_days.spot_status in ('X', 'A')
group by	campaign_no, 
					package_id, 
					outpost_player.player_name, 
					v_outpost_spots_and_days.screening_date
union 
select		null,
					null,
					outpost_player.player_name,
					outpost_screening_dates.screening_date,
					0,
					0
from			outpost_player,
					outpost_screening_dates
where		player_name not in (select	distinct player_name 
															from		v_outpost_spots_and_days, 
																			outpost_player_xref
															where	v_outpost_spots_and_days.outpost_panel_id = outpost_player_xref.outpost_panel_id 
															and			outpost_player_xref.player_name = outpost_player.player_name
															and			v_outpost_spots_and_days.spot_status in ('X', 'A')
															and			screening_date = outpost_screening_dates.screening_date)					
	
					
GO
