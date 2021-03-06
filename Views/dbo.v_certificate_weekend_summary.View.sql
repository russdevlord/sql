/****** Object:  View [dbo].[v_certificate_weekend_summary]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_certificate_weekend_summary]
GO
/****** Object:  View [dbo].[v_certificate_weekend_summary]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





create view [dbo].[v_certificate_weekend_summary]
as
select		complex_name, 
				movie_history_weekend_prerun.complex_id, 
				movie_history_weekend_prerun.screening_date, 
				long_name, occurence, 
				print_medium, 
				three_d_type, 
				premium_cinema,
				movie_history_weekend_prerun.certificate_group, 
				complex_date.max_time + complex_date.mg_max_time as time_avail,
				(select	sum(duration)  as time_used 
				from		certificate_item_weekend, film_print
				where		certificate_item_weekend.print_id = film_print.print_id
				and			certificate_item_weekend.certificate_group = movie_history_weekend_prerun.certificate_group
				and			certificate_item_weekend.spot_reference is not null
				and			certificate_item_weekend.certificate_source <> 'C') as time_used  
from		movie_history_weekend_prerun, 
				complex, 
				movie, 
				complex_date
where		movie_history_weekend_prerun.complex_id = complex.complex_id
and			movie_history_weekend_prerun.complex_id = complex_date.complex_id
and			movie_history_weekend_prerun.screening_date = complex_date.screening_date
and			movie_history_weekend_prerun.movie_id = movie.movie_id










GO
