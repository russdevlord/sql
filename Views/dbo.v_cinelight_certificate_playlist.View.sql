/****** Object:  View [dbo].[v_cinelight_certificate_playlist]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinelight_certificate_playlist]
GO
/****** Object:  View [dbo].[v_cinelight_certificate_playlist]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE VIEW [dbo].[v_cinelight_certificate_playlist]( 
	player_name, 
	playlist_id,
	complex_id,
	complex_name,
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
SELECT		cinelight_playlist.player_name,
			cinelight_playlist.playlist_id,
			complex.complex_id,
			complex.complex_name,
			CONVERT(DATE,cinelight_playlist.start_date),
			CONVERT(TIME,cinelight_playlist.start_date),
			CONVERT(DATE,cinelight_playlist.end_date),
			CONVERT(TIME,cinelight_playlist.end_date),		
			CONVERT(DATETIME,cinelight_playlist.start_date),
			CONVERT(DATETIME,cinelight_playlist.end_date),
			(select max(package_id) from cinelight_spot, cinelight_playlist_item_spot_xref where cinelight_spot.spot_id = cinelight_playlist_item_spot_xref.spot_id and  cinelight_playlist_item_spot_xref.cinelight_playlist_item_id = cinelight_playlist_item.cinelight_playlist_item_id) as package_id,
			(select max(campaign_no) from cinelight_spot, cinelight_playlist_item_spot_xref where cinelight_spot.spot_id = cinelight_playlist_item_spot_xref.spot_id and  cinelight_playlist_item_spot_xref.cinelight_playlist_item_id = cinelight_playlist_item.cinelight_playlist_item_id) as campaign_no,
			cinelight_playlist.screening_date,
			cinelight_print.print_id,
			cinelight_print.print_name,
			cinelight_playlist_item.sequence_no,
			cinelight_print.dcmedia_media_id as dcmedia_id,
			(select		max(outpost_package_burst.end_date) 
			from			outpost_package_burst, 
								cinelight_playlist_item_spot_xref, 
								cinelight_spot
			where		cinelight_playlist_item_spot_xref.spot_id = cinelight_spot.spot_id
			and				cinelight_spot.package_id = outpost_package_burst.package_id
			and				outpost_package_burst.start_date <= dateadd(dd, 6, cinelight_spot.screening_date)
			and				outpost_package_burst.end_date >= cinelight_spot.screening_date
			and				cinelight_playlist_item_spot_xref.cinelight_playlist_item_id = cinelight_playlist_item.cinelight_playlist_item_id) as campaign_end_date
from				cinelight_playlist,
			cinelight_dsn_players,  
			complex, 
			cinelight_print,   
			cinelight_playlist_item
where			cinelight_playlist.player_name = cinelight_dsn_players.player_name
and					cinelight_dsn_players.complex_id = complex.complex_id
and					cinelight_playlist_item.playlist_id = cinelight_playlist.playlist_id
and					cinelight_print.print_id = cinelight_playlist_item.print_id

GO
