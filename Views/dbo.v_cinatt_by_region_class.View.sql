/****** Object:  View [dbo].[v_cinatt_by_region_class]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_by_region_class]
GO
/****** Object:  View [dbo].[v_cinatt_by_region_class]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_by_region_class]
AS
select  v_dw_fact_complex_cinatt.screening_date 'screening_date',
        complex.complex_id 'complex_id',
        complex_region_class.complex_region_class 'complex_region_class',
        complex_region_class.regional_indicator 'regional_indicator',
        branch.country_code 'country_code',
        sum(v_dw_fact_complex_cinatt.matched_attendance) 'total_attendance_for_matched_movies',
        sum(v_dw_fact_complex_cinatt.raw_attendance)'total_attendance_for_all_movies', 
        (select isnull(sum(attendance),0) 
         from   v_cinatt_excluded_by_complex
         where  v_cinatt_excluded_by_complex.screening_date = v_dw_fact_complex_cinatt.screening_date
         and    v_cinatt_excluded_by_complex.complex_id = complex.complex_id) 'excluded_attendance'
from    v_dw_fact_complex_cinatt, complex, complex_region_class, branch
where   v_dw_fact_complex_cinatt.complex_id = complex.complex_id
and     complex.complex_region_class = complex_region_class.complex_region_class
and     complex.branch_code = branch.branch_code
group by v_dw_fact_complex_cinatt.screening_date,
         complex.complex_id,
         complex_region_class.complex_region_class,
         complex_region_class.regional_indicator,
         branch.country_code
GO
