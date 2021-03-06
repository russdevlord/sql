/****** Object:  View [dbo].[v_cinetam_inclusion_region_count]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_inclusion_region_count]
GO
/****** Object:  View [dbo].[v_cinetam_inclusion_region_count]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_cinetam_inclusion_region_count]
as
select			temp_table.inclusion_id,
				sum(temp_table.metro) as metro_count,
				sum(temp_table.regional) as regional_count
from			(select			inclusion_cinetam_settings.inclusion_id,	
								case when complex_region_class = 'M' then 1 else 0 end as metro	,
								case when complex_region_class = 'M' then 0 else 1 end as regional
				from			inclusion_cinetam_settings 
				inner join		complex on inclusion_cinetam_settings.complex_id = complex.complex_id) as temp_table
group by		temp_table.inclusion_id
GO
