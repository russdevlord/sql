/****** Object:  View [dbo].[v_cinetam_movie_report]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_movie_report]
GO
/****** Object:  View [dbo].[v_cinetam_movie_report]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_cinetam_movie_report]
as

select			movie.long_name, 
					cinetam_movie_history.movie_id,
					cinetam_movie_history.screening_date,
					datepart(yy,cinetam_movie_history.screening_date) as screening_year,
					datepart(wk, cinetam_movie_history.screening_date) as screening_week,
					cinetam_movie_history.occurence,
					cinetam_movie_history.print_medium,
					cinetam_movie_history.three_d_type,
					(	select		sum(attendance) 
						from		movie_history 
						where		movie_id = cinetam_movie_history.movie_id
						and			screening_date  = cinetam_movie_history.screening_date
						and			occurence = cinetam_movie_history.occurence
						and			print_medium = cinetam_movie_history.print_medium
						and			three_d_type = cinetam_movie_history.three_d_type
						and			country = 'A') as 'All People',
					sum(cinetam_movie_history.attendance) as 'All 14+',
					sum((case cinetam_movie_history.cinetam_demographics_id when 9 then cinetam_movie_history.attendance else 0 end)) as 'Female 14-17',
					sum((case cinetam_movie_history.cinetam_demographics_id when 10 then cinetam_movie_history.attendance else 0 end)) as 'Female 18-24',
					sum((case cinetam_movie_history.cinetam_demographics_id when 11 then cinetam_movie_history.attendance else 0 end)) as 'Female 25-29',
					sum((case cinetam_movie_history.cinetam_demographics_id when 12 then cinetam_movie_history.attendance else 0 end)) as 'Female 30-39',
					sum((case cinetam_movie_history.cinetam_demographics_id when 13 then cinetam_movie_history.attendance else 0 end)) as 'Female 40-54',
					sum((case cinetam_movie_history.cinetam_demographics_id when 14 then cinetam_movie_history.attendance else 0 end)) as 'Female 55-64',
					sum((case cinetam_movie_history.cinetam_demographics_id when 15 then cinetam_movie_history.attendance else 0 end)) as 'Female 65-74',
					sum((case cinetam_movie_history.cinetam_demographics_id when 16 then cinetam_movie_history.attendance else 0 end)) as 'Female 75+',
					sum((case cinetam_movie_history.cinetam_demographics_id when 1 then cinetam_movie_history.attendance else 0 end)) as 'Male 14-17',
					sum((case cinetam_movie_history.cinetam_demographics_id when 2 then cinetam_movie_history.attendance else 0 end)) as 'Male 18-24',
					sum((case cinetam_movie_history.cinetam_demographics_id when 3 then cinetam_movie_history.attendance else 0 end)) as 'Male 25-29',
					sum((case cinetam_movie_history.cinetam_demographics_id when 4 then cinetam_movie_history.attendance else 0 end)) as 'Male 30-39',
					sum((case cinetam_movie_history.cinetam_demographics_id when 5 then cinetam_movie_history.attendance else 0 end)) as 'Male 40-54',
					sum((case cinetam_movie_history.cinetam_demographics_id when 6 then cinetam_movie_history.attendance else 0 end)) as 'Male 55-64',
					sum((case cinetam_movie_history.cinetam_demographics_id when 7 then cinetam_movie_history.attendance else 0 end)) as 'Male 65-74',
					sum((case cinetam_movie_history.cinetam_demographics_id when 8 then cinetam_movie_history.attendance else 0 end)) as 'Male 75+',
					sum((case cinetam_movie_history.cinetam_demographics_id when 9 then cinetam_movie_history.attendance when 10 then cinetam_movie_history.attendance else 0 end)) as 'Female 14-24',
					sum((case cinetam_movie_history.cinetam_demographics_id when 10 then cinetam_movie_history.attendance when 11 then cinetam_movie_history.attendance when 12 then cinetam_movie_history.attendance else 0 end)) as 'Female 18-39',
					sum((case cinetam_movie_history.cinetam_demographics_id when 11 then cinetam_movie_history.attendance when 12 then cinetam_movie_history.attendance when 13 then cinetam_movie_history.attendance else 0 end)) as 'Female 25-54',
					sum((case cinetam_movie_history.cinetam_demographics_id when 1 then cinetam_movie_history.attendance when 2 then cinetam_movie_history.attendance else 0 end)) as 'Male 14-24',
					sum((case cinetam_movie_history.cinetam_demographics_id when 2 then cinetam_movie_history.attendance when 3 then cinetam_movie_history.attendance when 4 then cinetam_movie_history.attendance else 0 end)) as 'Male 18-39',
					sum((case cinetam_movie_history.cinetam_demographics_id when 3 then cinetam_movie_history.attendance when 4 then cinetam_movie_history.attendance when 5 then cinetam_movie_history.attendance else 0 end)) as 'Male 25-54',
					sum((case cinetam_movie_history.cinetam_demographics_id when 1 then cinetam_movie_history.attendance when 9 then cinetam_movie_history.attendance else 0 end)) as 'All 14-17',
					sum((case cinetam_movie_history.cinetam_demographics_id when 2 then cinetam_movie_history.attendance when 10 then cinetam_movie_history.attendance else 0 end)) as 'All 18-24',
					sum((case cinetam_movie_history.cinetam_demographics_id when 3 then cinetam_movie_history.attendance when 11 then cinetam_movie_history.attendance else 0 end)) as 'All 25-29',
					sum((case cinetam_movie_history.cinetam_demographics_id when 4 then cinetam_movie_history.attendance when 12 then cinetam_movie_history.attendance else 0 end)) as 'All 30-39',
					sum((case cinetam_movie_history.cinetam_demographics_id when 5 then cinetam_movie_history.attendance when 13 then cinetam_movie_history.attendance else 0 end)) as 'All 40-54',
					sum((case cinetam_movie_history.cinetam_demographics_id when 6 then cinetam_movie_history.attendance when 14 then cinetam_movie_history.attendance else 0 end)) as 'All 55-64',
					sum((case cinetam_movie_history.cinetam_demographics_id when 7 then cinetam_movie_history.attendance when 15 then cinetam_movie_history.attendance else 0 end))as 'All 65-74',
					sum((case cinetam_movie_history.cinetam_demographics_id when 8 then cinetam_movie_history.attendance when 16 then cinetam_movie_history.attendance else 0 end)) as 'All 75+',
					sum((case cinetam_movie_history.cinetam_demographics_id when 1 then cinetam_movie_history.attendance when 2 then cinetam_movie_history.attendance when 9 then cinetam_movie_history.attendance when 10 then cinetam_movie_history.attendance else 0 end)) as 'All 14-24',
					sum((case cinetam_movie_history.cinetam_demographics_id when 2 then cinetam_movie_history.attendance when 3 then cinetam_movie_history.attendance when 4 then cinetam_movie_history.attendance when 10 then cinetam_movie_history.attendance when 11 then cinetam_movie_history.attendance when 12 then cinetam_movie_history.attendance else 0 end)) as 'All 18-39',
					sum((case cinetam_movie_history.cinetam_demographics_id when 3 then cinetam_movie_history.attendance when 4 then cinetam_movie_history.attendance when 5 then cinetam_movie_history.attendance when 11 then cinetam_movie_history.attendance when 12 then cinetam_movie_history.attendance when 13 then cinetam_movie_history.attendance else 0 end)) as 'All 25-54',
						(	select		count(movie_id) 
						from		movie_history 
						where		movie_id = cinetam_movie_history.movie_id
						and			screening_date  = cinetam_movie_history.screening_date
						and			occurence = cinetam_movie_history.occurence
						and			print_medium = cinetam_movie_history.print_medium
						and			three_d_type = cinetam_movie_history.three_d_type
						and			country = 'A')  as no_movies
from			cinetam_movie_history, 
					movie,
					cinetam_demographics
where			cinetam_movie_history.movie_id = movie.movie_id
and				cinetam_movie_history.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
and				screening_date  > '1-jun-2010'

group by		movie.long_name, 
					cinetam_movie_history.movie_id,
					cinetam_movie_history.screening_date,
					cinetam_movie_history.occurence,
					cinetam_movie_history.print_medium,
					cinetam_movie_history.three_d_type
GO
