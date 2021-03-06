/****** Object:  View [dbo].[v_cinatt_by_film_market]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_by_film_market]
GO
/****** Object:  View [dbo].[v_cinatt_by_film_market]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_by_film_market]
AS
select  v_dw_fact_complex_cinatt.screening_date 'screening_date',
        film_market.film_market_no 'film_market_no',
        film_market.film_market_desc 'film_market_desc',
        case when film_market.film_market_no < 16 then 'Australia' else 'New Zealand' end 'country',
        sum(v_dw_fact_complex_cinatt.matched_attendance) 'total_attendance_per_matched_movie',
        count(v_dw_fact_complex_cinatt.complex_id) 'num_complexes_with_match_movies',
        sum(v_dw_fact_complex_cinatt.raw_attendance)'total_attendance_for_all_movies', 
        (select isnull(sum(attendance),0) 
         from   v_cinatt_excluded_by_complex, complex
         where  v_cinatt_excluded_by_complex.screening_date = v_dw_fact_complex_cinatt.screening_date
         and    v_cinatt_excluded_by_complex.complex_id = complex.complex_id
         and    complex.film_market_no = film_market.film_market_no) 'excluded_attendance'
from    v_dw_fact_complex_cinatt, complex, film_market
where   v_dw_fact_complex_cinatt.complex_id = complex.complex_id
and     complex.film_market_no = film_market.film_market_no
group by v_dw_fact_complex_cinatt.screening_date,
         film_market.film_market_no,
         film_market.film_market_desc
GO
