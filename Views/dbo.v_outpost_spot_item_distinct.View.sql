/****** Object:  View [dbo].[v_outpost_spot_item_distinct]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_outpost_spot_item_distinct]
GO
/****** Object:  View [dbo].[v_outpost_spot_item_distinct]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



CREATE VIEW [dbo].[v_outpost_spot_item_distinct]
AS

    select      distinct spot_id
    from        outpost_playlist_item_spot_xref
    group by    spot_id


GO
