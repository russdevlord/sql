/****** Object:  View [dbo].[v_weekend_cinetam_film_campaign_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_weekend_cinetam_film_campaign_detailed]
GO
/****** Object:  View [dbo].[v_weekend_cinetam_film_campaign_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO




CREATE view [dbo].[v_weekend_cinetam_film_campaign_detailed]
as
select 		 film_campaign.campaign_no, 
					convert(char(6), film_campaign.campaign_no) + ' - ' + film_campaign.product_desc as campaign_desc,
					cinetam_demographics.cinetam_demographics_desc,
					cinetam_movie_history_weekend.screening_date,
					movie.long_name,
					sum(cinetam_movie_history_weekend.full_attendance) as attendance,
					sum(cinetam_movie_history_weekend.attendance) as weekend_attendance
from			film_campaign,
					movie_history_weekend,
					v_certificate_item_distinct,
					campaign_spot,
					cinetam_movie_history_weekend,
					cinetam_demographics,
					movie
where		film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history_weekend.certificate_group
and				cinetam_movie_history_weekend.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
and				movie.movie_id = movie_history_weekend.movie_id
and				movie.movie_id = cinetam_movie_history_weekend.movie_id
and				movie_history_weekend.attendance is not null
and				movie_history_weekend.attendance > 0 
and				campaign_spot.screening_date  > '5-jul-2012'
and				movie_history_weekend.screening_date  >  '5-jul-2012'
and				movie_history_weekend.complex_id = cinetam_movie_history_weekend.complex_id
and				movie_history_weekend.movie_id = cinetam_movie_history_weekend.movie_id
and				movie_history_weekend.screening_date = cinetam_movie_history_weekend.screening_date
and				movie_history_weekend.occurence = cinetam_movie_history_weekend.occurence
and				movie_history_weekend.print_medium = cinetam_movie_history_weekend.print_medium
and				movie_history_weekend.three_d_type = cinetam_movie_history_weekend.three_d_type
group by 	film_campaign.campaign_no,
					film_campaign.product_desc,
					movie.long_name,
					cinetam_demographics.cinetam_demographics_desc,
					cinetam_movie_history_weekend.screening_date
union
select 		 film_campaign.campaign_no, 
					convert(char(6), film_campaign.campaign_no) + ' - ' + film_campaign.product_desc as campaign_desc,
					'All People' as cinetam_demographics_desc,
					movie_history_weekend.screening_date,
					movie.long_name,
					sum(movie_history_weekend.full_attendance) as attendance,
					sum(movie_history_weekend.attendance) as weekend_attendance
from			film_campaign,
					movie_history_weekend,
					v_certificate_item_distinct,
					campaign_spot,
					movie
where		film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history_weekend.certificate_group
and				movie.movie_id = movie_history_weekend.movie_id
and				movie_history_weekend.attendance is not null
and				movie_history_weekend.attendance > 0 
and				campaign_spot.screening_date  > '5-jul-2012'
and				movie_history_weekend.screening_date  >  '5-jul-2012'
group by 	film_campaign.campaign_no,
					film_campaign.product_desc,
					movie.long_name,movie_history_weekend.screening_date

GO
