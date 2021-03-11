USE [production]
GO
/****** Object:  View [dbo].[v_cinetam_movie_history_rfmkt]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_cinetam_movie_history_rfmkt]
as
SELECT cinetam_reporting_demographics_desc, screening_date, sum(attendance) as total_attendance, cinetam_reporting_demographics_id, country, film_market_no, complex_region_class
FROM v_cinetam_movie_history_reporting_demos, 
complex
where complex.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
group by cinetam_reporting_demographics_desc, screening_date, cinetam_reporting_demographics_id, country, film_market_no, complex_region_class
GO
