/****** Object:  View [dbo].[v_outpost_certificate_playlist]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_outpost_certificate_playlist]
GO
/****** Object:  View [dbo].[v_outpost_certificate_playlist]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE VIEW [dbo].[v_outpost_certificate_playlist]( 
	player_name, 
	playlist_id,
	outpost_venue_id,
	outpost_venue_name,
	start_date, 
	start_time, 
	end_date, 
	end_time, 
	start_datetime,	
	end_datetime,
	package_id, 
	campaign_no, 
	screening_date,
	print_id,
	print_name, 
	sequence_no, 
	dcmedia_id,
	campaign_end_date)
AS
SELECT		outpost_playlist.player_name,
						outpost_playlist.playlist_id,
						outpost_venue.outpost_venue_id,
						outpost_venue.outpost_venue_name,
						CONVERT(DATE,outpost_playlist.start_date),
						CONVERT(TIME,outpost_playlist.start_date),
						CONVERT(DATE,outpost_playlist.end_date),
						CONVERT(TIME,outpost_playlist.end_date),		
						CONVERT(DATETIME,outpost_playlist.start_date),
						CONVERT(DATETIME,outpost_playlist.end_date),
						(select max(package_id) from outpost_spot, outpost_playlist_item_spot_xref where outpost_spot.spot_id = outpost_playlist_item_spot_xref.spot_id and  outpost_playlist_item_spot_xref.outpost_playlist_item_id = outpost_playlist_item.outpost_playlist_item_id) as package_id,
						(select max(campaign_no) from outpost_spot, outpost_playlist_item_spot_xref where outpost_spot.spot_id = outpost_playlist_item_spot_xref.spot_id and  outpost_playlist_item_spot_xref.outpost_playlist_item_id = outpost_playlist_item.outpost_playlist_item_id) as campaign_no,
						outpost_playlist.screening_date,
						outpost_print.print_id,
						outpost_print.print_name,
						outpost_playlist_item.sequence_no,
						outpost_print.dcmedia_id,
						(select		max(outpost_package_burst.end_date) 
						from			outpost_package_burst, 
											outpost_playlist_item_spot_xref, 
											outpost_spot
						where		outpost_playlist_item_spot_xref.spot_id = outpost_spot.spot_id
						and				outpost_spot.package_id = outpost_package_burst.package_id
						and				outpost_package_burst.start_date <= dateadd(dd, 6, outpost_spot.screening_date)
						and				outpost_package_burst.end_date >= outpost_spot.screening_date
						and				outpost_playlist_item_spot_xref.outpost_playlist_item_id = outpost_playlist_item.outpost_playlist_item_id) as campaign_end_date
from				outpost_playlist,
						outpost_player,  
						outpost_venue, 
						outpost_print,   
						outpost_playlist_item
where			outpost_playlist.player_name = outpost_player.player_name
and					outpost_player.outpost_venue_id = outpost_venue.outpost_venue_id
and					outpost_playlist_item.playlist_id = outpost_playlist.playlist_id
and					outpost_print.print_id = outpost_playlist_item.print_id
GO
