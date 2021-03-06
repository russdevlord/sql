/****** Object:  View [dbo].[v_cinatt_avg_movie]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_avg_movie]
GO
/****** Object:  View [dbo].[v_cinatt_avg_movie]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_avg_movie]
AS
--     select  branch.country_code 'country_code',
--             cinema_attendance.screening_date 'screening_date',
--             complex_region_class.regional_indicator 'regional_indicator',
--             cinema_attendance.movie_id 'movie_id',
--             movie.long_name 'movie_name',
--             sum(cinema_attendance.attendance / (select count(occurence) from movie_history
--                                                             where complex_id = complex.complex_id
--                                                             and movie_id = cinema_attendance.movie_id
--                                                             and screening_date = cinema_attendance.screening_date) ) / count(complex.complex_id) 'avg_attendance'
--     from    complex,
--             complex_region_class,
--             cinema_attendance,
--             branch,
--             movie
--     where   branch.branch_code = complex.branch_code
--     and     branch.country_code = 'A'
--     and     complex.complex_region_class = complex_region_class.complex_region_class
--     and     cinema_attendance.complex_id = complex.complex_id
--     and     cinema_attendance.movie_id = movie.movie_id
--     and     complex.complex_id in (select complex_id from movie_history
--                                    where complex_id = complex.complex_id and movie_id = cinema_attendance.movie_id and screening_date = cinema_attendance.screening_date )
--     group by branch.country_code,
--             cinema_attendance.screening_date,
--             complex_region_class.regional_indicator,
--             cinema_attendance.movie_id,
--             movie.long_name

   select  branch.country_code 'country_code',
            v_cinatt.screening_date 'screening_date',
            complex_region_class.regional_indicator 'regional_indicator',
            v_cinatt.movie_id 'movie_id',
            movie.long_name 'movie_name',
			sum(v_cinatt.attendance_per_print) / count(v_cinatt.complex_id) 'avg_attendance'
    from    complex,
            complex_region_class,
            v_cinatt,
            branch,
			movie
    where   branch.branch_code = complex.branch_code
    and     branch.country_code = 'A'
    and     complex.complex_region_class = complex_region_class.complex_region_class
    and     v_cinatt.complex_id = complex.complex_id
    and     v_cinatt.prints > 0
    and     v_cinatt.movie_id = movie.movie_id
    group by branch.country_code,
             v_cinatt.screening_date,
             complex_region_class.regional_indicator,
			 v_cinatt.movie_id,
			movie.long_name
GO
