/****** Object:  View [dbo].[v_cinatt_by_complex]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_by_complex]
GO
/****** Object:  View [dbo].[v_cinatt_by_complex]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_by_complex]
AS
select  cinema_attendance_by_complex.screening_date 'screening_date',
        complex.complex_id 'complex_id',
        complex.complex_name 'complex_name',
        film_market.film_market_no 'film_market_no',
        film_market.film_market_desc 'film_market_desc',
        complex_region_class.complex_region_class 'complex_region_class',
        complex_region_class.regional_indicator 'regional_indicator',
        complex.clash_safety_limit 'safety_limit',
        complex.movie_target 'movie_target',
        sum(cinema_attendance_by_complex.total_attendance) 'total_attendance',
        avg(cinema_attendance_by_complex.avg_per_movie) 'average_per_movie'
from    cinema_attendance_by_complex,
        complex, 
        film_market,
        complex_region_class
where   cinema_attendance_by_complex.complex_id = complex.complex_id
and     complex.complex_region_class = complex_region_class.complex_region_class
and     complex.film_market_no = film_market.film_market_no
and     cinema_attendance_by_complex.actual = 1
group by cinema_attendance_by_complex.screening_date,
         complex.complex_id,
         complex.complex_name,
         film_market.film_market_no,
         film_market.film_market_desc,
         complex_region_class.complex_region_class,
         complex_region_class.regional_indicator,
         complex.clash_safety_limit,
         complex.movie_target
GO
