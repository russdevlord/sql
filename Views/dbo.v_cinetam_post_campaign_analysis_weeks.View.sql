/****** Object:  View [dbo].[v_cinetam_post_campaign_analysis_weeks]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_post_campaign_analysis_weeks]
GO
/****** Object:  View [dbo].[v_cinetam_post_campaign_analysis_weeks]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



Create View  [dbo].[v_cinetam_post_campaign_analysis_weeks] As

SELECT        v_fc.screening_date, v_fc.campaign_no,
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


GO
