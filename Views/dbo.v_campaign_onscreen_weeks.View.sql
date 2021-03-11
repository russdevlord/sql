USE [production]
GO
/****** Object:  View [dbo].[v_campaign_onscreen_weeks]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_campaign_onscreen_weeks]
as
select screening_date, campaign_no
from campaign_spot
where spot_status = 'X'
group by  screening_date, campaign_no
GO
