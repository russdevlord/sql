/****** Object:  View [dbo].[v_cinetam_mkt_exhib_complex_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_mkt_exhib_complex_attendance]
GO
/****** Object:  View [dbo].[v_cinetam_mkt_exhib_complex_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE VIEW [dbo].[v_cinetam_mkt_exhib_complex_attendance]
AS
SELECT			cinetam_demographics.cinetam_demographics_desc, 
						complex.complex_name, 
						cinetam_movie_history.screening_date, 
						SUM(ISNULL(cinetam_movie_history.attendance, 0)) AS attendance,
						cinetam_movie_history.country_code,
						exhibitor_name,
						film_market.film_market_no,
						film_market.film_market_desc,
						film_market.film_market_code
FROM				cinetam_movie_history INNER JOIN
						cinetam_demographics ON  
						cinetam_demographics.cinetam_demographics_id = cinetam_movie_history.cinetam_demographics_id inner join
						complex ON
						cinetam_movie_history.complex_id = complex.complex_id inner join
						exhibitor on
						exhibitor.exhibitor_id = complex.exhibitor_id inner join
						film_market on
						film_market.film_market_no = complex.film_market_no
where				cinetam_movie_history.screening_date > '1-jan-2015'						
GROUP BY		cinetam_demographics.cinetam_demographics_desc, 
						complex.complex_name, 
						cinetam_movie_history.screening_date, 
						cinetam_movie_history.country_code,
						exhibitor_name,
						film_market.film_market_no,
						film_market.film_market_desc,
						film_market.film_market_code
GO
