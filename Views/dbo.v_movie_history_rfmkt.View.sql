/****** Object:  View [dbo].[v_movie_history_rfmkt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_movie_history_rfmkt]
GO
/****** Object:  View [dbo].[v_movie_history_rfmkt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_movie_history_rfmkt]
as
SELECT screening_date, sum(attendance) as total_attendance, country, film_market_no, complex_region_class
FROM movie_history, 
complex
where complex.complex_id = movie_history.complex_id
group by  screening_date,  country, film_market_no, complex_region_class
GO
