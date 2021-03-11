/****** Object:  View [dbo].[v_cinelights_next_campaign_id]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinelights_next_campaign_id]
GO
/****** Object:  View [dbo].[v_cinelights_next_campaign_id]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinelights_next_campaign_id]
AS

select  isnull(max(cinelight_campaign_no),0) + 1 as next_campaign_no
from    cinelight_campaigns
GO
