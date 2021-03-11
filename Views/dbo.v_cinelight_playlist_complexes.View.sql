USE [production]
GO
/****** Object:  View [dbo].[v_cinelight_playlist_complexes]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE VIEW [dbo].[v_cinelight_playlist_complexes]
AS

    select			cinelight.complex_id,
						cinelight_spot.campaign_no,
						cinelight_spot.screening_date
    from				cinelight_playlist_item_spot_xref
	inner join		cinelight_spot on 	cinelight_playlist_item_spot_xref.spot_id = cinelight_spot.spot_id
	inner join		cinelight on cinelight_spot.cinelight_id = cinelight.cinelight_id
	where			spot_status = 'X'
    group by		cinelight.complex_id,
						cinelight_spot.campaign_no,
						cinelight_spot.screening_date
GO
