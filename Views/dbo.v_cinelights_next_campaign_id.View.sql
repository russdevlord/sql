USE [production]
GO
/****** Object:  View [dbo].[v_cinelights_next_campaign_id]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinelights_next_campaign_id]
AS

select  isnull(max(cinelight_campaign_no),0) + 1 as next_campaign_no
from    cinelight_campaigns
GO
