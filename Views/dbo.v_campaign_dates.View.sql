USE [production]
GO
/****** Object:  View [dbo].[v_campaign_dates]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_campaign_dates]
as
select			campaign_no,
				min(start_date) as start_date,
				max(screen_end_date) as end_date,
				max(used_by_date) as used_by_date
from			(select			campaign_no,
								min(screening_date) as start_date,
								max(screening_date) as screen_end_date,
								null as used_by_date
				from			campaign_spot
				group by		campaign_no
				union all
				select			campaign_no,
								min(screening_date) as start_date,
								max(screening_date) as screen_end_date,
								null as used_by_date
				from			cinelight_spot
				group by		campaign_no
				union all
				select			campaign_no,
								min(screening_date) as start_date,
								max(screening_date) as screen_end_date,
								null as used_by_date
				from			inclusion_spot
				group by		campaign_no
				union all
				select			campaign_no,
								min(start_date) as start_date,
								null as screen_end_date,
								max(used_by_date) as used_by_date
				from			campaign_package
				group by		campaign_no
				union all
				select			campaign_no,
								min(start_date) as start_date,
								null as screen_end_date,
								max(used_by_date) as used_by_date
				from			cinelight_package
				group by		campaign_no
				union all
				select			campaign_no,
								min(start_date) as start_date,
								null as screen_end_date,
								max(used_by_date) as used_by_date
				from			inclusion
				group by		campaign_no) as temp_table
group by		campaign_no
GO
