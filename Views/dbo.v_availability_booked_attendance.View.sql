/****** Object:  View [dbo].[v_availability_booked_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_availability_booked_attendance]
GO
/****** Object:  View [dbo].[v_availability_booked_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_availability_booked_attendance]
as
select			inclusion_cinetam_targets.complex_id,
					inclusion_cinetam_targets.screening_date,
					inclusion_cinetam_targets.original_target_attendance,
					campaign_package.duration,
					spot_type,
					inclusion_cinetam_targets.cinetam_reporting_demographics_id,
					round(inclusion_cinetam_targets.original_target_attendance / availability_demo_matching.attendance_share, 0) as seceqv_attendance,
					round(inclusion_cinetam_targets.original_target_attendance / availability_demo_matching.attendance_share / 30.0 * campaign_package.duration, 0) as all_peep_30seceqv_attendance
from				inclusion_cinetam_targets
inner join		inclusion_cinetam_settings on inclusion_cinetam_targets.inclusion_id = inclusion_cinetam_settings.inclusion_id
inner join		inclusion_cinetam_package on inclusion_cinetam_targets.inclusion_id = inclusion_cinetam_package.inclusion_id
inner join		campaign_package on inclusion_cinetam_package.package_id = campaign_package.package_id
inner join		inclusion_spot on inclusion_cinetam_targets.inclusion_id = inclusion_spot.inclusion_id  and inclusion_cinetam_targets.screening_date = inclusion_spot.screening_date
inner join		availability_demo_matching on inclusion_cinetam_targets.complex_id = availability_demo_matching.complex_id 
and				 dbo.f_prev_attendance_screening_date(inclusion_cinetam_targets.screening_date) =availability_demo_matching.screening_date
and				inclusion_cinetam_targets.cinetam_reporting_demographics_id = availability_demo_matching.cinetam_reporting_demographics_id  
where			spot_status <> 'P'

union all

select			inclusion_follow_film_targets.complex_id,
					inclusion_follow_film_targets.screening_date,
					inclusion_follow_film_targets.original_target_attendance as attendance,
					campaign_package.duration,
					spot_type,
					inclusion_follow_film_targets.cinetam_reporting_demographics_id,
					round(inclusion_follow_film_targets.original_target_attendance / availability_demo_matching.attendance_share, 0) as seceqv_attendance,
					round(inclusion_follow_film_targets.original_target_attendance / availability_demo_matching.attendance_share / 30.0 * campaign_package.duration, 0) as all_peep_30seceqv_attendance
from				inclusion_follow_film_targets
inner join		inclusion_cinetam_package on inclusion_follow_film_targets.inclusion_id = inclusion_cinetam_package.inclusion_id
inner join		campaign_package on inclusion_cinetam_package.package_id = campaign_package.package_id
inner join		inclusion_spot on inclusion_follow_film_targets.inclusion_id = inclusion_spot.inclusion_id  and inclusion_follow_film_targets.screening_date = inclusion_spot.screening_date
inner join		availability_demo_matching on inclusion_follow_film_targets.complex_id = availability_demo_matching.complex_id 
and				dbo.f_prev_attendance_screening_date(inclusion_follow_film_targets.screening_date) = availability_demo_matching.screening_date
and				inclusion_follow_film_targets.cinetam_reporting_demographics_id = availability_demo_matching.cinetam_reporting_demographics_id  
where			spot_status <> 'P'

union all

select			campaign_spot.complex_id,
					campaign_spot.screening_date,
					sum(availability_avg_mm_attendance.avg_mm_attendance) as attendance,
					campaign_package.duration,
					spot_type,
					0,
					sum(round(availability_avg_mm_attendance.avg_mm_attendance , 0)) as seceqv_attendance,
					sum(round(availability_avg_mm_attendance.avg_mm_attendance / 30.0 * campaign_package.duration, 0)) as all_peep_30seceqv_attendance
from				campaign_spot
--inner join		complex on campaign_spot.complex_id = complex.complex_id
--inner join		v_availability_avg_mm_attendance on complex.film_market_no = v_availability_avg_mm_attendance.film_market_no
inner join		availability_avg_mm_attendance on campaign_spot.complex_id = availability_avg_mm_attendance.complex_id
and				dbo.f_prev_attendance_screening_date(campaign_spot.screening_date) = availability_avg_mm_attendance.screening_date
inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id
where			spot_status <> 'P' and spot_status <> 'U'
and				spot_type not in ('F', 'A', 'K', 'T')
group by		campaign_spot.complex_id,
					campaign_spot.screening_date,
					campaign_package.duration,
					spot_type

GO
