/****** Object:  View [dbo].[v_cinetam_film_campaign_detailed_film_market]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_film_campaign_detailed_film_market]
GO
/****** Object:  View [dbo].[v_cinetam_film_campaign_detailed_film_market]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



CREATE view [dbo].[v_cinetam_film_campaign_detailed_film_market]
as
select 		 film_campaign.campaign_no, 
					convert(char(6), film_campaign.campaign_no) + ' - ' + film_campaign.product_desc as campaign_desc,
					cinetam_demographics.cinetam_demographics_desc,
					cinetam_movie_history.screening_date,
					movie.long_name,
					sum(cinetam_movie_history.attendance) as attendance,
					film_market.film_market_no,
					film_market_desc
from			film_campaign,
					movie_history,
					v_certificate_item_distinct,
					campaign_spot,
					cinetam_movie_history,
					cinetam_demographics,
					movie,
					complex,
					film_market
where			film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history.certificate_group
and				cinetam_movie_history.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
and				movie.movie_id = movie_history.movie_id
and				movie.movie_id = cinetam_movie_history.movie_id
and				movie_history.attendance is not null
and				movie_history.attendance > 0 
and				campaign_spot.screening_date  > '5-jul-2012'
and				movie_history.screening_date  >  '5-jul-2012'
and				movie_history.complex_id = cinetam_movie_history.complex_id
and				complex.complex_id = movie_history.complex_id
and				complex.complex_id = cinetam_movie_history.complex_id
and				complex.film_market_no = film_market.film_market_no
and				movie_history.movie_id = cinetam_movie_history.movie_id
and				movie_history.screening_date = cinetam_movie_history.screening_date
and				movie_history.occurence = cinetam_movie_history.occurence
and				movie_history.print_medium = cinetam_movie_history.print_medium
and				movie_history.three_d_type = cinetam_movie_history.three_d_type
group by 	film_campaign.campaign_no,
					film_campaign.product_desc,
					movie.long_name,
					cinetam_demographics.cinetam_demographics_desc,
					cinetam_movie_history.screening_date,
					film_market.film_market_no,
					film_market_desc
union
select 			film_campaign.campaign_no, 
					convert(char(6), film_campaign.campaign_no) + ' - ' + film_campaign.product_desc as campaign_desc,
					'All People' as cinetam_demographics_desc,
					movie_history.screening_date,
					movie.long_name,
					sum(movie_history.attendance) as attendance,
					film_market.film_market_no,
					film_market_desc
from			film_campaign,
					movie_history,
					v_certificate_item_distinct,
					campaign_spot,
					movie,
					complex,
					film_market
where			film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history.certificate_group
and				movie.movie_id = movie_history.movie_id
and				complex.complex_id = movie_history.complex_id
and				complex.film_market_no = film_market.film_market_no
and				movie_history.attendance is not null
and				movie_history.attendance > 0 
and				campaign_spot.screening_date  > '5-jul-2012'
and				movie_history.screening_date  >  '5-jul-2012'
group by 	film_campaign.campaign_no,
					film_campaign.product_desc,
					movie.long_name,movie_history.screening_date,
					film_market.film_market_no,
					film_market_desc


GO
