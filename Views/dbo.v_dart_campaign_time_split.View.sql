/****** Object:  View [dbo].[v_dart_campaign_time_split]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dart_campaign_time_split]
GO
/****** Object:  View [dbo].[v_dart_campaign_time_split]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create view [dbo].[v_dart_campaign_time_split]
as
select		temp_table.campaign_no,
			temp_table.package_id, 
			temp_table.outpost_panel_id,
			temp_table.start_date,
			temp_table.end_date,
			avg(temp_table.duration) as duration,
			avg(temp_table.playlist_duration) as playlist_duration,
			avg(temp_table.campaign_percentage) as campaign_percentage
from		(select		outpost_package.campaign_no, 
						outpost_package.package_id, 
						outpost_panel_id,
						dateadd(hh, -2, outpost_playlist.start_date) as start_date,
						outpost_playlist.end_date,
						outpost_package.duration,
						(select		sum(duration) 
						from		outpost_playlist_item, 
									outpost_print 
						where		outpost_playlist_item.print_id = outpost_print.print_id
						and			outpost_playlist_item.playlist_id = outpost_playlist.playlist_id) as playlist_duration,
						convert(numeric(12,8), outpost_package.duration) / (select		sum(duration) 
													from		outpost_playlist_item, 
																outpost_print 
													where		outpost_playlist_item.print_id = outpost_print.print_id
													and			outpost_playlist_item.playlist_id = outpost_playlist.playlist_id) as campaign_percentage
			from		outpost_playlist,
						outpost_playlist_spot_xref,
						outpost_spot,
						outpost_package
			where		outpost_playlist.playlist_id = outpost_playlist_spot_xref.playlist_id
			and			outpost_playlist_spot_xref.spot_id = outpost_spot.spot_id
			and			outpost_package.package_id = outpost_spot.package_id
			/*and			datepart(hh, outpost_playlist.start_date) = 8
			union
			select		outpost_package.campaign_no,
						outpost_package.package_id, 
						outpost_panel_id,
						outpost_playlist.start_date,
						outpost_playlist.end_date,
						outpost_package.duration,
						(select		sum(duration) 
						from		outpost_playlist_item, 
									outpost_print 
						where		outpost_playlist_item.print_id = outpost_print.print_id
						and			outpost_playlist_item.playlist_id = outpost_playlist.playlist_id) as playlist_duration,
						convert(numeric(12,8), outpost_package.duration) / (select		sum(duration) 
													from		outpost_playlist_item, 
																outpost_print 
													where		outpost_playlist_item.print_id = outpost_print.print_id
													and			outpost_playlist_item.playlist_id = outpost_playlist.playlist_id) as campaign_percentage
			from		outpost_playlist,
						outpost_playlist_spot_xref,
						outpost_spot,
						outpost_package
			where		outpost_playlist.playlist_id = outpost_playlist_spot_xref.playlist_id
			and			outpost_playlist_spot_xref.spot_id = outpost_spot.spot_id
			and			outpost_package.package_id = outpost_spot.package_id
			and			datepart(hh, outpost_playlist.start_date) = 6*/) as temp_table
group by	temp_table.campaign_no,
			temp_table.package_id, 
			temp_table.outpost_panel_id,
			temp_table.start_date,
			temp_table.end_date




GO
