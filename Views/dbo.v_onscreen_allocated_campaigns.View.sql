/****** Object:  View [dbo].[v_onscreen_allocated_campaigns]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_onscreen_allocated_campaigns]
GO
/****** Object:  View [dbo].[v_onscreen_allocated_campaigns]    Script Date: 12/03/2021 10:03:48 AM ******/
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
