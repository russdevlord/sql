/****** Object:  View [dbo].[v_cinetam_post_campaign_analysis_weeks_digilite]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_post_campaign_analysis_weeks_digilite]
GO
/****** Object:  View [dbo].[v_cinetam_post_campaign_analysis_weeks_digilite]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create View [dbo].[v_cinetam_post_campaign_analysis_weeks_digilite] AS

/*select		temp_table.campaign_no,
				temp_table.screening_date,
				temp_table.mode,
				sum(temp_table.demo_attendance) as demo_attendance,
				(select	Sum(attendance) 
				from		cinelight_attendance_actuals 
				where		screening_date = temp_table.screening_date
				and			campaign_no = temp_table.campaign_no) As total_attendance
from		(Select		a.campaign_no, 
						a.screening_date,
						1 as mode,
						sum(demo_attendance) As demo_attendance,
						(0) As total_attendance,
						a.complex_id
			FROM		(Select		v_cinetam_movie_history_reporting_demos.screening_date, 
									sum(v_cinetam_movie_history_reporting_demos.attendance) /Count(Distinct(cinelight_spot.spot_id)) As demo_attendance,
									complex.complex_id,
									v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_id, 
									cinelight_spot.campaign_no
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
			screening_date*/
			/*(select cinetam_reporting_demographics_id from cinetam_campaign_settings where campaign_no = cinelight_spot.campaign_no)*/
			
select			campaign_no,
					screening_date,
					1 as mode,
					sum(demo_attendance) as demo_attendance,
					sum(attendance) as total_attendance
from			(select		campaign_no,
										screening_date,
										complex_id,
										(select	sum(attendance) 
										from		cinetam_movie_history 
										where		screening_date = temp_table.screening_date 
										and			complex_id = temp_table.complex_id 
										and			cinetam_demographics_id in (select cinetam_demographics_id from cinetam_reporting_demographics_xref where cinetam_reporting_demographics_id in (select cinetam_reporting_demographics_id from cinetam_campaign_settings where campaign_no = temp_table.campaign_no))) as demo_attendance,
										(select	sum(attendance) 
										from		movie_history 
										where		screening_date = temp_table.screening_date 
										and			complex_id = temp_table.complex_id) as attendance
					from			(	select 			film_campaign.campaign_no,
																screening_date,
																complex_id
											from			film_campaign,
																cinelight_spot,
																cinelight
											where			film_campaign.campaign_no = cinelight_spot.campaign_no
											and				cinelight_spot.spot_status = 'X'
											and				cinelight_spot.cinelight_id = cinelight.cinelight_id
											group by 	film_campaign.campaign_no,
																screening_date,
																complex_id) as temp_table) as temp_table_two
group by		campaign_no,
					screening_date																
union all								
select			campaign_no,
					screening_date,
					2,
					0 as demo_attendance,
					sum(attendance) as total_attendance
from			(select		campaign_no,
										screening_date,
										complex_id,
										(select	sum(attendance) 
										from		movie_history 
										where		screening_date = temp_table.screening_date 
										and			complex_id = temp_table.complex_id) as attendance
					from			(	select 			film_campaign.campaign_no,
																screening_date,
																complex_id
											from			film_campaign,
																cinelight_spot,
																cinelight
											where			film_campaign.campaign_no = cinelight_spot.campaign_no
											and				cinelight_spot.spot_status = 'X'
											and				cinelight_spot.cinelight_id = cinelight.cinelight_id
											group by 	film_campaign.campaign_no,
																screening_date,
																complex_id) as temp_table) as temp_table_two
group by		campaign_no,
					screening_date																






GO
