/****** Object:  View [dbo].[v_cinatt_estimate_avg_by_scr_date_complex]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_estimate_avg_by_scr_date_complex]
GO
/****** Object:  View [dbo].[v_cinatt_estimate_avg_by_scr_date_complex]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_estimate_avg_by_scr_date_complex]
AS

        select v_cinatt.screening_date as screening_date,
               v_cinatt.complex_id as complex_id, 
                avg(case attendance_per_print when 0 then attendance_per_movie else attendance_per_print end ) 
                * sum(case prints when 0 then 1 else prints end) as est_attendance
        FROM    v_cinatt
        WHERE   v_cinatt.attendance_per_movie > 0
        group by v_cinatt.screening_date, v_cinatt.complex_id
GO
