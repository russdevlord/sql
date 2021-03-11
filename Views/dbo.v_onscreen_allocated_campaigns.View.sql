USE [production]
GO
/****** Object:  View [dbo].[v_onscreen_allocated_campaigns]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_onscreen_allocated_campaigns]
as
select			campaign_no,
					screening_date,
					count(spot_id) as no_spots
from			v_spots_allocated
group by		campaign_no,
					screening_date
GO
