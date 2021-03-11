USE [production]
GO
/****** Object:  View [dbo].[v_cinetam_inclusion_region_count]    Script Date: 11/03/2021 2:30:32 PM ******/
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
