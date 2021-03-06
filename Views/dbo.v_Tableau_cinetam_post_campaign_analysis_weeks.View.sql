/****** Object:  View [dbo].[v_Tableau_cinetam_post_campaign_analysis_weeks]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_Tableau_cinetam_post_campaign_analysis_weeks]
GO
/****** Object:  View [dbo].[v_Tableau_cinetam_post_campaign_analysis_weeks]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE View  [dbo].[v_Tableau_cinetam_post_campaign_analysis_weeks] As

SELECT        'Onscreen' Type, v_fc.screening_date, v_fc.campaign_no, (select product_desc from film_campaign where campaign_no = v_fc.campaign_no) as product_desc,
                             (SELECT        ISNULL(SUM(a.attendance), 0) AS Expr1
                               FROM            attendance_campaign_actuals AS a 
                               WHERE        (a.screening_date = v_fc.screening_date)
											AND 
											(a.campaign_no = v_fc.campaign_no)) AS total_attendance,
                               
                             (SELECT        ISNULL(SUM(cinetam_campaign_targets.attendance), 0) AS target_attendance
                               FROM            cinetam_campaign_targets INNER JOIN
                                                         cinetam_campaign_settings ON 
                                                         cinetam_campaign_targets.campaign_no = cinetam_campaign_settings.campaign_no AND
                                                         cinetam_campaign_targets.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
                               WHERE        (cinetam_campaign_targets.screening_date = v_fc.screening_date) and cinetam_campaign_settings.campaign_no = v_fc.campaign_no)
                          AS target_attendance,
                             (SELECT        ISNULL(SUM(attendance), 0) AS demo_attendance
                               FROM            (SELECT        a.attendance, cinetam_campaign_settings2.cinetam_reporting_demographics_id
                                                         FROM        cinetam_campaign_actuals AS a 
						INNER JOIN cinetam_reporting_demographics_xref 
                         ON a.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
                         INNER JOIN cinetam_campaign_settings as cinetam_campaign_settings2
                         ON cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_campaign_settings2.cinetam_reporting_demographics_id
                         AND a.campaign_no = cinetam_campaign_settings2.campaign_no 
                         WHERE        (a.screening_date = v_fc.screening_date and a.campaign_no = v_fc.campaign_no)) AS t_cinetaam_campaign_actuals)  
                         AS demo_attendance
FROM            v_campaign_onscreen_weeks AS v_fc LEFT OUTER JOIN
                         cinetam_campaign_settings AS cinetam_campaign_settings_1 ON v_fc.campaign_no = cinetam_campaign_settings_1.campaign_no
--WHERE        (v_fc.campaign_no = 208006) --AND (v_fc.screening_date <= @screening_date)
--ORDER BY v_fc.screening_date
Where v_fc.screening_date >= '25-Jul-2012'
UNION ALL
Select Distinct 'Digilite' Type, a.screening_date, a.campaign_no, (select product_desc from film_campaign where campaign_no = a.campaign_no) as product_desc, 
(select Sum(attendance) from cinelight_attendance_digilite_actuals 
where Campaign_no = a.campaign_no 
and cinelight_id IN (Select Distinct cinelight_id from cinelight_spot where campaign_no = a.campaign_no) and screening_date = a.screening_date) As Total_Attendance,
0 target_attendance, sum(Demo_attendance) As Demo_Attendance
FROM
( 
Select 	v_cinetam_movie_history_reporting_demos.Screening_date, 
		sum(v_cinetam_movie_history_reporting_demos.attendance) /Count(Distinct(cinelight_spot.spot_id)) As demo_attendance,
		complex.complex_id,
		v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_id, 
		cinelight_spot.campaign_no, cinelight_spot.package_ID-- ,
		--(select attendance from cinelight_attendance_digilite_actuals where Campaign_no = 208123 and cinelight_id = cinelight_spot.cinelight_id  and screening_date = v_cinetam_movie_history_reporting_demos.Screening_date) AS Actual
	From 
	cinelight_spot,
	cinelight,
	complex,
	v_cinetam_movie_history_reporting_demos
	Where  cinelight_spot.cinelight_id = cinelight.cinelight_id
	and	cinelight.complex_id = complex.complex_id
	and v_cinetam_movie_history_reporting_demos.complex_id = complex.complex_id
	and cinelight_spot.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
	and	v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_id in (select cinetam_reporting_demographics_id from cinetam_campaign_targets where campaign_no = cinelight_spot.campaign_no)
	and v_cinetam_movie_history_reporting_demos.Screening_date >= '25-Jul-2012'
	--and cinelight_spot.campaign_no = 208123
Group by 
		v_cinetam_movie_history_reporting_demos.Screening_date, 
		v_cinetam_movie_history_reporting_demos.cinetam_reporting_demographics_id, cinelight_spot.campaign_no, 
		cinelight_spot.package_ID, complex.complex_id
		)a
Group by a.campaign_no, a.package_id, a.screening_date
UNION ALL
SELECT   'TAP' Type,    v_fc.screening_date, v_fc.campaign_no, (select product_desc from film_campaign where campaign_no = v_fc.campaign_no) as product_desc,
                             (SELECT        ISNULL(SUM(attendance), 0) AS Expr1
                               FROM            attendance_campaign_actuals
                               WHERE        (campaign_no = v_fc.campaign_no) AND (screening_date = v_fc.screening_date)) AS total_attendance,
                             (SELECT        ISNULL(SUM(original_attendance), 0) AS Expr1
                               FROM            cinetam_inclusion_targets
                               WHERE        (inclusion_id = inclusion.inclusion_id) AND (screening_date = v_fc.screening_date) AND 
                                                         (cinetam_reporting_demographics_id = cinetam_inclusion_settings.cinetam_reporting_demographics_id)) AS target_attendance,
                             (SELECT        ISNULL(SUM(cinetam_campaign_actuals.attendance), 0) AS Expr1
                               FROM            cinetam_campaign_actuals INNER JOIN
                                                         cinetam_reporting_demographics_xref ON 
                                                         cinetam_campaign_actuals.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
                               WHERE        (cinetam_campaign_actuals.campaign_no = v_fc.campaign_no) AND (cinetam_campaign_actuals.screening_date = v_fc.screening_date) AND 
                                                         (cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_inclusion_settings.cinetam_reporting_demographics_id)) 
                         AS demo_attendance
FROM            v_campaign_onscreen_weeks AS v_fc INNER JOIN
						 inclusion ON v_fc.campaign_no = inclusion.campaign_no inner join
                         cinetam_inclusion_settings ON inclusion.inclusion_id = cinetam_inclusion_settings.inclusion_id
				Where v_fc.screening_date >= '25-jul-2012'                     
GO
