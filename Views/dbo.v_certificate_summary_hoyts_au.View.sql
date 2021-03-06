/****** Object:  View [dbo].[v_certificate_summary_hoyts_au]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_certificate_summary_hoyts_au]
GO
/****** Object:  View [dbo].[v_certificate_summary_hoyts_au]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






create view [dbo].[v_certificate_summary_hoyts_au]
as
select		complex_name, 
				movie_history.complex_id, 
				movie_history.screening_date, 
				long_name, occurence, 
				print_medium, 
				three_d_type, 
				premium_cinema,
				movie_history.certificate_group, 
				complex_date.max_time + complex_date.mg_max_time as time_avail,
				(select	sum(duration)  as time_used 
				from		certificate_item, film_print
				where		certificate_item.print_id = film_print.print_id
				and			certificate_item.certificate_group = movie_history.certificate_group
				and			certificate_item.certificate_source <> 'C'
				and			film_print.print_type = 'C') as time_used  
from		movie_history, 
				complex, 
				movie, 
				complex_date
where		movie_history.complex_id = complex.complex_id
and			movie_history.complex_id = complex_date.complex_id
and			movie_history.screening_date = complex_date.screening_date
and			movie_history.movie_id = movie.movie_id
and			complex.exhibitor_id = 205
and			movie_history.movie_id <> 102





GO
