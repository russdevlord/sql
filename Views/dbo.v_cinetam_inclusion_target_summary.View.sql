/****** Object:  View [dbo].[v_cinetam_inclusion_target_summary]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_inclusion_target_summary]
GO
/****** Object:  View [dbo].[v_cinetam_inclusion_target_summary]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


create view [dbo].[v_cinetam_inclusion_target_summary]
as
select			inclusion_cinetam_settings.inclusion_id,
				inclusion_cinetam_targets.cinetam_reporting_demographics_id, 
				sum(inclusion_cinetam_targets.original_target_attendance) as original_target_attendance,
				sum(inclusion_cinetam_targets.target_attendance) as target_attendance,
				sum(inclusion_cinetam_targets.achieved_attendance) as achieved_attendance
from			inclusion_cinetam_settings 
inner join		inclusion_cinetam_targets on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_targets.inclusion_id and inclusion_cinetam_settings.complex_id = inclusion_cinetam_targets.complex_id
inner join		inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
inner join		inclusion on inclusion_cinetam_settings.inclusion_id = inclusion.inclusion_id
group by		inclusion_cinetam_settings.inclusion_id,
				inclusion_cinetam_targets.cinetam_reporting_demographics_id
union all
select			inclusion_cinetam_settings.inclusion_id,
				inclusion_follow_film_targets.cinetam_reporting_demographics_id, 
				sum(inclusion_follow_film_targets.original_target_attendance) as original_target_attendance,
				sum(inclusion_follow_film_targets.target_attendance) as target_attendance,
				sum(inclusion_follow_film_targets.achieved_attendance) as achieved_attendance
from			inclusion_cinetam_settings 
inner join		inclusion_follow_film_targets on inclusion_cinetam_settings.inclusion_id = inclusion_follow_film_targets.inclusion_id and inclusion_cinetam_settings.complex_id = inclusion_follow_film_targets.complex_id
inner join		inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
inner join		inclusion on inclusion_cinetam_settings.inclusion_id = inclusion.inclusion_id
group by		inclusion_cinetam_settings.inclusion_id,
				inclusion_follow_film_targets.cinetam_reporting_demographics_id
GO
