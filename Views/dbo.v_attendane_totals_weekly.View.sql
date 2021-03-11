USE [production]
GO
/****** Object:  View [dbo].[v_attendane_totals_weekly]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_attendane_totals_weekly]
as
select regional_indicator, screening_date, country, sum(attendance) as attendance
from complex, movie_history, complex_region_class
where complex.complex_id = movie_history.complex_id
and complex_region_class.complex_region_class = complex.complex_region_class and movie_id <> 102
group by regional_indicator, screening_date, country


GO
