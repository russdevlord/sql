USE [production]
GO
/****** Object:  View [dbo].[v_movie_history_dates]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_movie_history_dates] 
as
select film_screening_dates.screening_date, attendance_period_no, sum(attendance) as attendance from movie_history, film_screening_dates where film_screening_dates.screening_date = movie_history.screening_Date
group by film_screening_dates.screening_date, attendance_period_no
GO
