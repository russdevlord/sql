/****** Object:  View [dbo].[v_cinatt_film_mkt_raw_tot]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_film_mkt_raw_tot]
GO
/****** Object:  View [dbo].[v_cinatt_film_mkt_raw_tot]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_film_mkt_raw_tot]
AS
select  cinema_attendance_by_complex.screening_date 'screening_date',
        film_market.film_market_no 'film_market_no',
        film_market.film_market_desc 'film_market_desc',
        case when film_market.film_market_no < 16 then 'Australia' else 'New Zealand' end 'country',
        sum(cinema_attendance_by_complex.total_attendance) 'total_our_movies',
        avg(cinema_attendance_by_complex.avg_per_movie) 'avg_per_movie_our_movies',
        count(cinema_attendance_by_complex.complex_id) 'num_complexes_our_movies',
        
        (select sum(cinema_attendance.attendance)
        from    cinema_attendance, complex
        where   cinema_attendance.complex_id = complex.complex_id
        and     cinema_attendance.screening_date = cinema_attendance_by_complex.screening_date
        and     complex.film_market_no = film_market.film_market_no) 'total_attendance_all_movies'
        
from    cinema_attendance_by_complex, complex, film_market
where   cinema_attendance_by_complex.complex_id = complex.complex_id
and     complex.film_market_no = film_market.film_market_no
and     cinema_attendance_by_complex.actual = 1

group by cinema_attendance_by_complex.screening_date,
         film_market.film_market_no,
         film_market.film_market_desc
GO
