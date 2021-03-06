/****** Object:  View [dbo].[v_cinetam_post_campaign_analysis_weeks_package]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_post_campaign_analysis_weeks_package]
GO
/****** Object:  View [dbo].[v_cinetam_post_campaign_analysis_weeks_package]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create View  [dbo].[v_cinetam_post_campaign_analysis_weeks_package] As
SELECT        v_fc.screening_date, v_fc.package_id,
                             (SELECT        ISNULL(SUM(a.attendance), 0) AS Expr1
                               FROM            movie_history AS a INNER JOIN
                                                         v_certificate_item_distinct AS b ON a.certificate_group = b.certificate_group INNER JOIN
                                                         campaign_spot AS c ON b.spot_reference = c.spot_id AND c.package_id = v_fc.package_id
                               WHERE        (c.package_id = v_fc.package_id) AND (a.screening_date = v_fc.screening_date)) AS total_attendance,
                             (SELECT        ISNULL(SUM(cinetam_campaign_package_targets.attendance), 0) AS target_attendance
                               FROM            cinetam_campaign_package_targets INNER JOIN
                                                         cinetam_campaign_package_settings ON 
                                                         cinetam_campaign_package_targets.cinetam_reporting_demographics_id = cinetam_campaign_package_settings.cinetam_reporting_demographics_id
                                                          AND cinetam_campaign_package_targets.package_id = cinetam_campaign_package_settings.package_id
                               WHERE        (cinetam_campaign_package_targets.package_id = v_fc.package_id) AND (cinetam_campaign_package_targets.screening_date = v_fc.screening_date))
                          AS target_attendance,
                             (SELECT        ISNULL(SUM(attendance), 0) AS demo_attendance
                               FROM            (SELECT        a.attendance, a.cinetam_reporting_demographics_id
                                                         FROM            v_cinetam_movie_history_Details AS a INNER JOIN
                                                                                   v_certificate_item_distinct AS b ON a.certificate_group = b.certificate_group INNER JOIN
                                                                                   campaign_spot AS c ON b.spot_reference = c.spot_id INNER JOIN
                                                                                   cinetam_campaign_package_settings AS cinetam_campaign_package_settings_2 ON 
                                                                                   cinetam_campaign_package_settings_2.package_id = c.package_id AND 
                                                                                   a.cinetam_reporting_demographics_id = cinetam_campaign_package_settings_2.cinetam_reporting_demographics_id
                                                         WHERE        (c.package_id = v_fc.package_ID) AND (c.screening_date = v_fc.screening_date)) AS t_cinetaam_campaign_actuals) 
                         AS demo_attendance
FROM            v_campaign_onscreen_weeks_Package AS v_fc LEFT OUTER JOIN
                         cinetam_campaign_package_settings AS cinetam_campaign_package_settings_1 ON v_fc.package_id = cinetam_campaign_package_settings_1.package_id
--WHERE        (v_fc.package_id = @Package_Code) AND (v_fc.screening_date <= @screening_date)
--ORDER BY v_fc.screening_date
GO
