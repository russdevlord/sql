/****** Object:  View [dbo].[aaa_temp_view]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[aaa_temp_view]
GO
/****** Object:  View [dbo].[aaa_temp_view]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[aaa_temp_view]
as
select		temp_table.campaign_no,
			temp_table.screening_date,
			temp_table.mode,
			sum(temp_table.demo_attendance) as demo_attendance,
			sum(temp_table.total_attendance) as total_attendance
from		(Select		a.campaign_no, 
						a.screening_date,
						1 as mode,
						sum(demo_attendance) As demo_attendance,
						(select	Sum(attendance) 
						from	movie_history 
						where	complex_id = a.complex_id 
						and		screening_date = a.screening_date) As total_attendance,
						a.complex_id
			FROM		(			Select		v_cinetam_movie_history_reporting_demos.screening_date, 
									sum(v_cinetam_movie_history_reporting_demos.attendance) /Count(Distinct(cinelight_spot.spot_id)) As demo_attendance,
									complex.complex_id,
									v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_id, 
									cinelight_spot.campaign_no, cinelight_spot.package_id 
						From		cinelight_spot,
									v_cinelight_certificate_item_distinct,
									cinelight,
									complex,
									v_cinetam_movie_history_reporting_demos
						where		cinelight_spot.cinelight_id = cinelight.cinelight_id
						and			cinelight.complex_id = complex.complex_id
						and			cinelight_spot.spot_id = v_cinelight_certificate_item_distinct.spot_id
						and			v_cinetam_movie_history_reporting_demos.complex_id = complex.complex_id
						and			cinelight_spot.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
						and			v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_id in (select cinetam_reporting_demographics_id from cinetam_campaign_settings where campaign_no = cinelight_spot.campaign_no)
						Group by	v_cinetam_movie_history_reporting_demos.Screening_date, 
									v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_id, 
									cinelight_spot.campaign_no, 
									cinelight_spot.package_id, 
									complex.complex_id
						union 						
						Select		v_cinetam_movie_history_reporting_demos.screening_date, 
									sum(v_cinetam_movie_history_reporting_demos.attendance) /Count(distinct (cinelight_spot.spot_id)) As demo_attendance,
									complex.complex_id,
									v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_id, 
									cinelight_spot.campaign_no, cinelight_spot.package_ID 
						From		cinelight_spot,
									v_cinelight_playlist_item_distinct,
									cinelight,
									complex,
									v_cinetam_movie_history_reporting_demos
						where		cinelight_spot.cinelight_id = cinelight.cinelight_id
						and			cinelight.complex_id = complex.complex_id
						and			cinelight_spot.spot_id = v_cinelight_playlist_item_distinct.spot_id
						and			v_cinetam_movie_history_reporting_demos.complex_id = complex.complex_id
						and			cinelight_spot.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
						and			v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_id in (select cinetam_reporting_demographics_id from cinetam_campaign_settings where campaign_no = cinelight_spot.campaign_no)
						Group by	v_cinetam_movie_history_reporting_demos.screening_date, 
									v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_id, 
									cinelight_spot.campaign_no, 
									cinelight_spot.package_id, 
									complex.complex_id) a
			Group by	a.campaign_no, 
						a.screening_date,
						a.complex_id) as temp_table
group by	temp_table.campaign_no,
			temp_table.screening_date,
			temp_table.mode
union
Select		Distinct campaign_no, 
			screening_date,
			2 as mode,
			(0) As Demo_Attendance,
			sum(attendance)  As Total_Attendance
FROM		cinelight_attendance_actuals
Group by	campaign_no, 
			screening_date		

GO
