/****** Object:  View [dbo].[v_movie_release_week]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_movie_release_week]
GO
/****** Object:  View [dbo].[v_movie_release_week]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_movie_release_week]
as
select			movie_history.movie_id, 
					movie_history.country,
					1 as week_num,
					sum(isnull(attendance,0)) as attendance,
					count(*) as no_prints
from			movie_history,
					movie_country
where			movie_country.movie_id = movie_history.movie_id
and				movie_country.country_code = movie_history.country
and				dateadd(wk, 0, movie_country.release_date) = movie_history.screening_date
and				screening_date >= '31-dec-2009'
group by		movie_history.movie_id, 
					movie_history.country
union
select			movie_history.movie_id, 
					movie_history.country,
					2 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			movie_history,
					movie_country
where			movie_country.movie_id = movie_history.movie_id
and				movie_country.country_code = movie_history.country
and				dateadd(wk, 1, movie_country.release_date) = movie_history.screening_date
and				screening_date >= '31-dec-2009'
group by		movie_history.movie_id, 
					movie_history.country
union
select			movie_history.movie_id, 
					movie_history.country,
					3 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			movie_history,
					movie_country
where			movie_country.movie_id = movie_history.movie_id
and				movie_country.country_code = movie_history.country
and				dateadd(wk, 2, movie_country.release_date) = movie_history.screening_date
and				screening_date >= '31-dec-2009'
group by		movie_history.movie_id, 
					movie_history.country
union
select			movie_history.movie_id, 
					movie_history.country,
					4 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			movie_history,
					movie_country
where			movie_country.movie_id = movie_history.movie_id
and				movie_country.country_code = movie_history.country
and				dateadd(wk, 3, movie_country.release_date) = movie_history.screening_date
and				screening_date >= '31-dec-2009'
group by		movie_history.movie_id, 
					movie_history.country
union
select			movie_history.movie_id, 
					movie_history.country,
					5 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			movie_history,
					movie_country
where			movie_country.movie_id = movie_history.movie_id
and				movie_country.country_code = movie_history.country
and				dateadd(wk, 4, movie_country.release_date) = movie_history.screening_date
and				screening_date >= '31-dec-2009'
group by		movie_history.movie_id, 
					movie_history.country
union
select			movie_history.movie_id, 
					movie_history.country,
					6 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			movie_history,
					movie_country
where			movie_country.movie_id = movie_history.movie_id
and				movie_country.country_code = movie_history.country
and				dateadd(wk, 5, movie_country.release_date) = movie_history.screening_date
and				screening_date >= '31-dec-2009'
group by		movie_history.movie_id, 
					movie_history.country
union
select			movie_history.movie_id, 
					movie_history.country,
					7 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			movie_history,
					movie_country
where			movie_country.movie_id = movie_history.movie_id
and				movie_country.country_code = movie_history.country
and				dateadd(wk, 7, movie_country.release_date) = movie_history.screening_date
and				screening_date >= '31-dec-2009'
group by		movie_history.movie_id, 
					movie_history.country
union
select			movie_history.movie_id, 
					movie_history.country,
					8 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			movie_history,
					movie_country
where			movie_country.movie_id = movie_history.movie_id
and				movie_country.country_code = movie_history.country
and				dateadd(wk, 7, movie_country.release_date) = movie_history.screening_date
and				screening_date >= '31-dec-2009'
group by		movie_history.movie_id, 
					movie_history.country
union
select			movie_history.movie_id, 
					movie_history.country,
					9 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			movie_history,
					movie_country
where			movie_country.movie_id = movie_history.movie_id
and				movie_country.country_code = movie_history.country
and				dateadd(wk, 8, movie_country.release_date) = movie_history.screening_date
and				screening_date >= '31-dec-2009'
group by		movie_history.movie_id, 
					movie_history.country
union
select			movie_history.movie_id, 
					movie_history.country,
					10 as week_num,
					sum(isnull(attendance,0)),
					count(*) as no_prints
from			movie_history,
					movie_country
where			movie_country.movie_id = movie_history.movie_id
and				movie_country.country_code = movie_history.country
and				dateadd(wk, 9, movie_country.release_date) = movie_history.screening_date
and				screening_date >= '31-dec-2009'
group by		movie_history.movie_id, 
					movie_history.country		
GO
