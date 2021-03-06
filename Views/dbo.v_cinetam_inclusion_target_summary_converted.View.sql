/****** Object:  View [dbo].[v_cinetam_inclusion_target_summary_converted]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_inclusion_target_summary_converted]
GO
/****** Object:  View [dbo].[v_cinetam_inclusion_target_summary_converted]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_cinetam_inclusion_target_summary_converted]
as
select			inclusion_cinetam_settings.inclusion_id,
				criteria_demo.cinetam_reporting_demographics_id, 
				sum(inclusion_cinetam_targets.original_target_attendance / (case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end / case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end)) as original_target_attendance,
				sum(inclusion_cinetam_targets.target_attendance / (case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end / case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end)) as target_attendance,
				sum(inclusion_cinetam_targets.achieved_attendance / (case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end / case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end))  as achieved_attendance
from			inclusion_cinetam_settings 
inner join		inclusion_cinetam_targets on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_targets.inclusion_id and inclusion_cinetam_settings.complex_id = inclusion_cinetam_targets.complex_id
inner join		inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
inner join		inclusion on inclusion_cinetam_settings.inclusion_id = inclusion.inclusion_id
inner join		film_screening_date_attendance_prev on inclusion_cinetam_targets.screening_date = film_screening_date_attendance_prev.screening_date
inner join		availability_demo_matching as target_demo 
on				inclusion_cinetam_targets.cinetam_reporting_demographics_id = target_demo.cinetam_reporting_demographics_id
and				film_screening_date_attendance_prev.prev_screening_date = target_demo.screening_date
and				inclusion_cinetam_targets.complex_id = target_demo.complex_id
inner join		availability_demo_matching as criteria_demo 
on				film_screening_date_attendance_prev.prev_screening_date = criteria_demo.screening_date
and				inclusion_cinetam_targets.complex_id = criteria_demo.complex_id
group by		inclusion_cinetam_settings.inclusion_id,
				criteria_demo.cinetam_reporting_demographics_id
union all
select			inclusion_cinetam_settings.inclusion_id,
				criteria_demo.cinetam_reporting_demographics_id, 
				sum(inclusion_follow_film_targets.original_target_attendance / (case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end / case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end)) as original_target_attendance,
				sum(inclusion_follow_film_targets.target_attendance / (case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end / case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end)) as target_attendance,
				sum(inclusion_follow_film_targets.achieved_attendance / (case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end / case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end))  as achieved_attendance
from			inclusion_cinetam_settings 
inner join		inclusion_follow_film_targets on inclusion_cinetam_settings.inclusion_id = inclusion_follow_film_targets.inclusion_id and inclusion_cinetam_settings.complex_id = inclusion_follow_film_targets.complex_id
inner join		inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
inner join		inclusion on inclusion_cinetam_settings.inclusion_id = inclusion.inclusion_id
inner join		film_screening_date_attendance_prev on inclusion_follow_film_targets.screening_date = film_screening_date_attendance_prev.screening_date
inner join		availability_demo_matching as target_demo 
on				inclusion_follow_film_targets.cinetam_reporting_demographics_id = target_demo.cinetam_reporting_demographics_id
and				film_screening_date_attendance_prev.prev_screening_date = target_demo.screening_date
and				inclusion_follow_film_targets.complex_id = target_demo.complex_id
inner join		availability_demo_matching as criteria_demo 
on				film_screening_date_attendance_prev.prev_screening_date = criteria_demo.screening_date
and				inclusion_follow_film_targets.complex_id = criteria_demo.complex_id
group by		inclusion_cinetam_settings.inclusion_id,
				criteria_demo.cinetam_reporting_demographics_id
GO
