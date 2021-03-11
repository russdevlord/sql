USE [production]
GO
/****** Object:  View [dbo].[v_outpost_spot_item_distinct]    Script Date: 11/03/2021 2:30:32 PM ******/
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
