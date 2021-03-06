/****** Object:  View [dbo].[v_hoyts_sessions]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_hoyts_sessions]
GO
/****** Object:  View [dbo].[v_hoyts_sessions]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view	[dbo].[v_hoyts_sessions]
as

select			movie_history_sessions.movie_id,
					movie_history_sessions.complex_id,
					screening_date,
					print_medium,
					three_d_type,
					session_time,
					occurence,
					premium_cinema,
					cinema_no,
					advertising_open,
					show_category,
					complex_name,
					complex_code,
					movie_code,
					movie_name
from			movie_history_sessions
inner join	data_translate_complex on movie_history_sessions.complex_id = data_translate_complex.complex_id
inner join	data_translate_movie on movie_history_sessions.movie_id = data_translate_movie.movie_id
where			data_translate_movie.data_provider_id = 1
and				data_translate_complex.data_provider_id = 1
GO
