/****** Object:  View [dbo].[v_cinelight_playlist_item_distinct]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinelight_playlist_item_distinct]
GO
/****** Object:  View [dbo].[v_cinelight_playlist_item_distinct]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE VIEW [dbo].[v_cinelight_playlist_item_distinct]
AS

    select      distinct spot_id
    from        cinelight_playlist_item_spot_xref
    group by    spot_id
GO
