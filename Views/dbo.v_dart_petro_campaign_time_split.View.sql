/****** Object:  View [dbo].[v_dart_petro_campaign_time_split]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dart_petro_campaign_time_split]
GO
/****** Object:  View [dbo].[v_dart_petro_campaign_time_split]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create view [dbo].[v_dart_petro_campaign_time_split]
as
select		temp_table.campaign_no,
			temp_table.package_id, 
			temp_table.outpost_panel_id,
			temp_table.screening_date,
			avg(temp_table.duration) as duration,
			avg(temp_table.playlist_duration) as playlist_duration,
			avg(temp_table.campaign_percentage) as campaign_percentage
from		(select		pack_outer.campaign_no,
						pack_outer.package_id, 
						outpost_panel_id,
						screening_date,
						pack_outer.duration,
						(select		sum(duration) 
						from		outpost_package pack_inner,
									outpost_spot spot_inner
						where		pack_inner.package_id = spot_inner.package_id
						and			spot_outer.outpost_panel_id = spot_inner.outpost_panel_id
						and			spot_outer.screening_date = spot_inner.screening_date
						and			spot_status <> 'P') as playlist_duration,
						convert(numeric(12,8), pack_outer.duration) /  convert(numeric(12,8),(select		sum(duration) 
												from		outpost_package pack_inner,
															outpost_spot spot_inner
												where		pack_inner.package_id = spot_inner.package_id
												and			spot_outer.outpost_panel_id = spot_inner.outpost_panel_id
												and			spot_outer.screening_date = spot_inner.screening_date
												and			spot_status <> 'P')) as campaign_percentage
			from		outpost_spot spot_outer,
						outpost_package pack_outer
			where		pack_outer.package_id = spot_outer.package_id
			and			spot_status <> 'P') as temp_table
group by	temp_table.campaign_no,
			temp_table.package_id, 
			temp_table.outpost_panel_id,
			temp_table.screening_date



GO
