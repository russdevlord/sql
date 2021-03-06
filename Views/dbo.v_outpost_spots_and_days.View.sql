/****** Object:  View [dbo].[v_outpost_spots_and_days]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_outpost_spots_and_days]
GO
/****** Object:  View [dbo].[v_outpost_spots_and_days]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_outpost_spots_and_days]
as
select		campaign_no,
					package_id,
					spot_id, 
					outpost_panel_id,
					screening_date, 
					spot_status,
					spot_type, 					
					(SELECT COUNT(osds.spot_id) 
					FROM		outpost_spot_daily_segment osds
					WHERE	datepart(hh, osds.start_date) = 8 and
										datepart(mi, osds.start_date) = 0 and
										datepart(ss, osds.start_date) = 0 and
										datepart(hh, osds.end_date) = 23 and
										datepart(mi, osds.end_date) = 59 and
										datepart(ss, osds.end_date) = 59 and
										osds.spot_id = outpost_spot.spot_id) as days_booked
from		outpost_spot		
GO
