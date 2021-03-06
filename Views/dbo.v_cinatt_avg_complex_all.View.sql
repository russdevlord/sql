/****** Object:  View [dbo].[v_cinatt_avg_complex_all]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_avg_complex_all]
GO
/****** Object:  View [dbo].[v_cinatt_avg_complex_all]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE VIEW [dbo].[v_cinatt_avg_complex_all]
AS
select  cinatt_by_movie_history.screening_date 'screening_date',
        complex.complex_id 'complex_id',
        complex.complex_name 'complex_name',
        film_market.film_market_no 'film_market_no',
        film_market.film_market_desc 'film_market_desc',
        sum(cinatt_by_movie_history.total_attendance) 'total_attendance',
        count(cinatt_by_movie_history.movie_id) 'total_movies',
        sum(cinatt_by_movie_history.total_attendance) / count(cinatt_by_movie_history.movie_id) 'avg_per_movie'
from    cinatt_by_movie_history, complex, film_market
where   cinatt_by_movie_history.complex_id = complex.complex_id
and     complex.film_market_no = film_market.film_market_no and cinatt_by_movie_history.movie_id <> 102
group by cinatt_by_movie_history.screening_date,
         complex.complex_id,
         complex.complex_name,
         film_market.film_market_no,
         film_market.film_market_desc
GO
