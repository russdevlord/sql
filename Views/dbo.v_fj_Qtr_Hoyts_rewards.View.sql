/****** Object:  View [dbo].[v_fj_Qtr_Hoyts_rewards]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_fj_Qtr_Hoyts_rewards]
GO
/****** Object:  View [dbo].[v_fj_Qtr_Hoyts_rewards]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--DROP View v_fj_Qtr_Hoyts_rewards
Create View [dbo].[v_fj_Qtr_Hoyts_rewards] AS
Select Screening_date,DATENAME(Year,Screening_Date) YY,DATENAME(QUARTER,Screening_Date) QQ, DATENAME(M,Screening_Date) MM, cinetam_demographics_id, cinetam_demographics_desc AS Demographics, Unique_members, tot_trans
From(
SELECT screening_date, cinetam_demographics_id, cinetam_demographics_desc, COUNT(DISTINCT membership_id) AS Unique_members, SUM(unique_transactions) AS tot_trans, 
        SUM(adult_tickets) AS tot_adult_tickets, SUM(child_tickets) AS tot_child_tickets
        FROM            v_movio_data_demo_fsd
        GROUP BY screening_date,cinetam_demographics_id, cinetam_demographics_desc
        UNION ALL
        SELECT        v_movio_data_demo_fsd_1.screening_date, cinetam_reporting_demographics_xref.cinetam_demographics_id, cinetam_reporting_demographics.cinetam_reporting_demographics_desc, 
                      COUNT(DISTINCT v_movio_data_demo_fsd_1.membership_id) AS Unique_members, SUM(v_movio_data_demo_fsd_1.unique_transactions) AS tot_trans,
                      SUM(v_movio_data_demo_fsd_1.adult_tickets) AS tot_adult_tickets, SUM(v_movio_data_demo_fsd_1.child_tickets) AS tot_child_tickets
        FROM            v_movio_data_demo_fsd AS v_movio_data_demo_fsd_1 INNER JOIN
                      cinetam_reporting_demographics_xref ON 
                      v_movio_data_demo_fsd_1.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id INNER JOIN
                      cinetam_reporting_demographics ON 
                      cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
                      WHERE        (cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id NOT IN (8, 13))
                      GROUP BY v_movio_data_demo_fsd_1.screening_date, cinetam_reporting_demographics_xref.cinetam_demographics_id, cinetam_reporting_demographics.cinetam_reporting_demographics_desc )a
GO
