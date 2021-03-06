/****** Object:  View [dbo].[v_cinatt_by_movie]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_by_movie]
GO
/****** Object:  View [dbo].[v_cinatt_by_movie]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[v_cinatt_by_movie]
AS

select  country,
        movie_id,
        movie_name,
        screening_date,
		year(screening_date) as screening_year, 
		film_market_no,
		film_market_desc,
        sum(attendance) 'total_attendance',
        sum(number_of_prints) 'total_prints',
        sum(attendance)/sum(number_of_prints) 'average_per_print'
from v_cinatt_by_movie_complex 
group by country,
        movie_id,
        movie_name,
        screening_date, 
		film_market_no,
		film_market_desc
GO
