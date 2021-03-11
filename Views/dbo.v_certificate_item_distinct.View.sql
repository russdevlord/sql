USE [production]
GO
/****** Object:  View [dbo].[v_certificate_item_distinct]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_certificate_item_distinct]
AS

    select      distinct spot_reference,
                certificate_group,
                certificate_source
    from        certificate_item
    group by    spot_reference,
                certificate_group,
                certificate_source
GO
