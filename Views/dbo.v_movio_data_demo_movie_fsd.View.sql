/****** Object:  View [dbo].[v_movio_data_demo_movie_fsd]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_movio_data_demo_movie_fsd]
GO
/****** Object:  View [dbo].[v_movio_data_demo_movie_fsd]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_movio_data_demo_movie_fsd] 
as
select		movio_data.membership_id, 
				movio_data.movie_code, 
				movio_data.film_name, 
				movio_data.complex_name,
				movio_data.country_code, 
				sum(movio_data.unique_transactions) as unique_transactions, 
				sum(adult_tickets) as adult_tickets, 
				sum(child_tickets) as child_tickets,
				cinetam_demographics.cinetam_demographics_id,
				cinetam_demographics.cinetam_demographics_desc, 
				movio_data.screening_date, 
				movio_complex_xref.complex_id,
				data_translate_movie.movie_id
from		movio_data, 
				cinetam_demographics, movio_complex_xref,
				data_translate_movie
where		real_age > 13
and			movio_data.gender in ('Female','Male')
and			left(movio_data.gender,1) = cinetam_demographics.gender
and			movio_data.real_age between min_age and max_age
and			movio_complex_xref.complex_name = movio_data.complex_name
and			data_translate_movie.data_provider_id = 1
and			country_code = 'A'
and			data_translate_movie.movie_code = movio_data.movie_code
group by membership_id, 
				movio_data.movie_code, 
				film_name,
				movio_data.complex_name, 
				country_code, 
				cinetam_demographics_id, 
				cinetam_demographics_desc, 
				movio_data.screening_date, 
				movio_complex_xref.complex_id,
				data_translate_movie.movie_id
union
select		movio_data.membership_id, 
				movio_data.movie_code, 
				movio_data.film_name, 
				movio_data.complex_name,
				movio_data.country_code, 
				sum(movio_data.unique_transactions) as unique_transactions, 
				sum(adult_tickets) as adult_tickets, 
				sum(child_tickets) as child_tickets,
				cinetam_demographics.cinetam_demographics_id,
				cinetam_demographics.cinetam_demographics_desc, 
				movio_data.screening_date, 
				movio_complex_xref.complex_id,
				data_translate_movie.movie_id
from		movio_data, 
				cinetam_demographics, movio_complex_xref,
				data_translate_movie
where		real_age > 13
and			movio_data.gender in ('Female','Male')
and			left(movio_data.gender,1) = cinetam_demographics.gender
and			movio_data.real_age between min_age and max_age
and			movio_complex_xref.complex_name = movio_data.complex_name
and			data_translate_movie.data_provider_id = 4
and			country_code = 'Z'
and			data_translate_movie.movie_code = movio_data.movie_code
group by membership_id, 
				movio_data.movie_code, 
				film_name,
				movio_data.complex_name, 
				country_code, 
				cinetam_demographics_id, 
				cinetam_demographics_desc, 
				movio_data.screening_date, 
				movio_complex_xref.complex_id,
				data_translate_movie.movie_id
GO
