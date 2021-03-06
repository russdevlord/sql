/****** Object:  View [dbo].[v_package_dates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_package_dates]
GO
/****** Object:  View [dbo].[v_package_dates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_package_dates]
as
select			package_id,
				min(start_date) as start_date,
				max(end_date) as end_date
from			(select			package_id,
								min(screening_date) as start_date,
								max(screening_date) as end_date
				from			campaign_spot
				group by		package_id
				union all
				select			inclusion_cinetam_package.package_id,
								min(screening_date) as start_date,
								max(screening_date) as end_date
				from			inclusion_spot
				inner join		inclusion_cinetam_package on inclusion_spot.inclusion_id = inclusion_cinetam_package.inclusion_id
				group by		package_id) as temp_table
group by		package_id
GO
