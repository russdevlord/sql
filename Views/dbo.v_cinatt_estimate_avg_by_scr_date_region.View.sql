/****** Object:  View [dbo].[v_cinatt_estimate_avg_by_scr_date_region]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_estimate_avg_by_scr_date_region]
GO
/****** Object:  View [dbo].[v_cinatt_estimate_avg_by_scr_date_region]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_estimate_avg_by_scr_date_region] 
AS

        select  'A' as country_code,
                'Y' as region_indicator,
                v_cinatt.screening_date as screening_date,
                ( avg(case attendance_per_print when 0 then attendance_per_movie else attendance_per_print end ) 
                    * sum(case prints when 0 then 1 else prints end) ) / count(distinct complex.complex_id) as est_attendance                    
        FROM    v_cinatt, branch, complex, complex_region_class
        WHERE   branch.branch_code = complex.branch_code 
        AND     branch.country_code = 'A' 
        AND     complex_region_class.regional_indicator = 'Y'
        AND     complex.complex_region_class = complex_region_class.complex_region_class
        AND     v_cinatt.complex_id = complex.complex_id 
        and     v_cinatt.attendance_per_movie > 0
        group by screening_date
        
        UNION ALL
        
        select  'A' as country_code,
                'N' as region_indicator,
                v_cinatt.screening_date as screening_date,
                ( avg(case attendance_per_print when 0 then attendance_per_movie else attendance_per_print end ) 
        * sum(case prints when 0 then 1 else prints end) ) / count(distinct complex.complex_id) as est_attendance                    
        FROM    v_cinatt, branch, complex, complex_region_class
        WHERE   branch.branch_code = complex.branch_code 
        AND     branch.country_code = 'A' 
        AND     complex_region_class.regional_indicator = 'N'
        AND     complex.complex_region_class = complex_region_class.complex_region_class
        AND     v_cinatt.complex_id = complex.complex_id 
        and     v_cinatt.attendance_per_movie > 0
        group by screening_date

        UNION ALL
        
        select  'Z' as country_code,
                '' as region_indicator,
                v_cinatt.screening_date as screening_date,
                ( ( avg(case attendance_per_print when 0 then attendance_per_movie else attendance_per_print end ) 
                * sum(case prints when 0 then 1 else prints end) ) / count(distinct complex.complex_id) ) as est_attendance
        FROM    v_cinatt, branch, complex
        WHERE   branch.branch_code = complex.branch_code 
        AND     branch.country_code = 'Z' 
        AND     v_cinatt.complex_id = complex.complex_id 
        and     v_cinatt.attendance_per_movie > 0
        group by screening_date
GO
