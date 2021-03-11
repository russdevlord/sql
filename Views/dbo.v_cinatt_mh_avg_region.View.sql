/****** Object:  View [dbo].[v_cinatt_mh_avg_region]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_mh_avg_region]
GO
/****** Object:  View [dbo].[v_cinatt_mh_avg_region]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_mh_avg_region]
AS
    select  'A' 'country_code',
            temp_table.screening_date 'screening_date',
            temp_table.regional_indicator 'regional_indicator',
            sum (temp_table.attendance / temp_table.occurence) / count(temp_table.count_complex) 'avg_region_attendance'
    from    (select     cinema_attendance.screening_date as screening_date,
                        complex_region_class.regional_indicator as regional_indicator,
                        complex.complex_id as complex_id,
                        cinema_attendance.attendance as attendance,
                        cinema_attendance.movie_id as movie,
                        count(complex.complex_id) as count_complex,
                        (select count(occurence) from movie_history
                        where   complex_id = complex.complex_id
                        and     movie_id = cinema_attendance.movie_id
                        and     screening_date = cinema_attendance.screening_date) as occurence
            from        complex,
                        complex_region_class,
                        cinema_attendance,
                        branch
            where       branch.branch_code = complex.branch_code
            and         branch.country_code = 'A'
            and         complex.complex_region_class = complex_region_class.complex_region_class
            and         cinema_attendance.complex_id = complex.complex_id
            and         complex.complex_id in   (select complex_id 
                                                from    movie_history
                                                where   complex_id = complex.complex_id
                                                and     movie_id = cinema_attendance.movie_id
                                                and     screening_date = cinema_attendance.screening_date )
            group by    cinema_attendance.screening_date,
                        complex_region_class.regional_indicator,
                        complex.complex_id,
                        cinema_attendance.attendance,
                        cinema_attendance.movie_id) as temp_table
    group by    temp_table.screening_date,
                temp_table.regional_indicator
GO
