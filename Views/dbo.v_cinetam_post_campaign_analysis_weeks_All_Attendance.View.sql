/****** Object:  View [dbo].[v_cinetam_post_campaign_analysis_weeks_All_Attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_post_campaign_analysis_weeks_All_Attendance]
GO
/****** Object:  View [dbo].[v_cinetam_post_campaign_analysis_weeks_All_Attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


Create View [dbo].[v_cinetam_post_campaign_analysis_weeks_All_Attendance] As
SELECT        v_fc.screening_date,
                             (SELECT        ISNULL(SUM(attendance), 0) AS Expr1
                               FROM            attendance_campaign_actuals
                               WHERE        (campaign_no = v_fc.campaign_no) AND (screening_date = v_fc.screening_date)) AS total_attendance,
                                     0 AS target_attendance,
                                     0 AS demo_attendance, v_fc.campaign_no
FROM            v_campaign_onscreen_weeks AS v_fc 

GO
