/****** Object:  View [dbo].[v_cinetam_matched_movie]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_matched_movie]
GO
/****** Object:  View [dbo].[v_cinetam_matched_movie]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_cinetam_matched_movie]
as
select			current_movie.movie_id as current_movie_id,
					current_movie.country_code,
					current_movie.release_date as current_release_date,
					matched_movie.movie_id as matched_movie_id,
					matched_movie.release_date as matched_release_date
from				(select				movie.movie_id, 
											country_code, 
											release_date 
					from					movie 
					inner join			movie_country on movie.movie_id = movie_country.movie_id) as current_movie
inner join		cinetam_movie_matches on current_movie.movie_id = cinetam_movie_matches.movie_id and current_movie.country_code = cinetam_movie_matches.country_code
inner join		(select				movie.movie_id, 
											country_code, 
											release_date 
					from					movie 
					inner join			movie_country on movie.movie_id = movie_country.movie_id) as matched_movie on matched_movie.movie_id = cinetam_movie_matches.matched_movie_id and  matched_movie.country_code = cinetam_movie_matches.country_code
GO
