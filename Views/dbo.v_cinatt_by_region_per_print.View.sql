/****** Object:  View [dbo].[v_cinatt_by_region_per_print]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_by_region_per_print]
GO
/****** Object:  View [dbo].[v_cinatt_by_region_per_print]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_by_region_per_print]
AS

   select  branch.country_code 'country_code',
            v_cinatt.screening_date 'screening_date',
            complex_region_class.regional_indicator 'regional_indicator',
            sum(v_cinatt.attendance_per_movie) 'attendance_per_movie',
            sum(v_cinatt.prints) 'num_prints',
            sum(v_cinatt.attendance_per_movie) / sum(v_cinatt.prints) 'avg_attendance_per_print'
    from    complex,
            complex_region_class,
            v_cinatt,
            branch
    where   branch.branch_code = complex.branch_code
    and     branch.country_code = 'A'
    and     complex.complex_region_class = complex_region_class.complex_region_class
    and     v_cinatt.complex_id = complex.complex_id
    and     v_cinatt.prints > 0
    group by branch.country_code,
             v_cinatt.screening_date,
             complex_region_class.regional_indicator
GO
