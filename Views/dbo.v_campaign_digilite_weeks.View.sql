/****** Object:  View [dbo].[v_campaign_digilite_weeks]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_campaign_digilite_weeks]
GO
/****** Object:  View [dbo].[v_campaign_digilite_weeks]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_campaign_digilite_weeks]
as
select screening_date, campaign_no
from cinelight_spot
where spot_status = 'X'
group by  screening_date, campaign_no

GO
