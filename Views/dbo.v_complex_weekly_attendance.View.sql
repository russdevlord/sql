/****** Object:  View [dbo].[v_complex_weekly_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_complex_weekly_attendance]
GO
/****** Object:  View [dbo].[v_complex_weekly_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create view [dbo].[v_complex_weekly_attendance]
as
select 'AAll People' as demo_desc, complex_name, screening_date, film_market.film_market_no, film_market_code, film_market_desc, complex.state_code, exhibitor_name, movie_history.country,  sum(attendance) as attendance
from complex, exhibitor, film_market, movie_history
where complex.exhibitor_id = exhibitor.exhibitor_id
and complex.film_market_no = film_market.film_market_no
and complex.complex_id = movie_history.complex_id
and screening_date > '1-jul-2011'
group by  complex_name, screening_date, film_market.film_market_no, film_market_code, film_market_desc, complex.state_code, exhibitor_name, movie_history.country
union all
select cinetam_reporting_demographics_desc, complex_name, screening_date, film_market.film_market_no, film_market_code, film_market_desc, complex.state_code, exhibitor_name, v_cinetam_movie_history_reporting_demos.country,  sum(attendance) as attendance
from complex, exhibitor, film_market, v_cinetam_movie_history_reporting_demos
where complex.exhibitor_id = exhibitor.exhibitor_id
and complex.film_market_no = film_market.film_market_no
and complex.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
and screening_date > '1-jul-2011'
group by  complex_name, screening_date, film_market.film_market_no, film_market_code, film_market_desc, complex.state_code, exhibitor_name, v_cinetam_movie_history_reporting_demos.country, cinetam_reporting_demographics_desc


GO
