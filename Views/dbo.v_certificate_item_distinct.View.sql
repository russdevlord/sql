/****** Object:  View [dbo].[v_certificate_item_distinct]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_certificate_item_distinct]
GO
/****** Object:  View [dbo].[v_certificate_item_distinct]    Script Date: 12/03/2021 10:03:48 AM ******/
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
