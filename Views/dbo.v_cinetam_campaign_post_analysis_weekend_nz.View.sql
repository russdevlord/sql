/****** Object:  View [dbo].[v_cinetam_campaign_post_analysis_weekend_nz]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_campaign_post_analysis_weekend_nz]
GO
/****** Object:  View [dbo].[v_cinetam_campaign_post_analysis_weekend_nz]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_cinetam_campaign_post_analysis_weekend_nz]
as
select 			campaign_spot.campaign_no, 
					data_translate_movie.movie_code, 
					cinetam_movie_history_weekend.complex_id,
					cinetam_demographics_id,
					cinetam_movie_history_weekend.screening_date,
					cinetam_movie_history_weekend.country_code,
					1 / max(cinetam_movie_history_weekend.occurence) as occurence_adjuster
from			movie_history_weekend,
					v_certificate_item_distinct,
					campaign_spot,
					cinetam_movie_history_weekend,
					data_translate_movie,
					data_translate_complex
where			campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history_weekend.certificate_group
and				data_translate_movie.movie_id = movie_history_weekend.movie_id
and				data_translate_movie.movie_id = cinetam_movie_history_weekend.movie_id
and				movie_history_weekend.complex_id = cinetam_movie_history_weekend.complex_id
and				movie_history_weekend.movie_id = cinetam_movie_history_weekend.movie_id
and				movie_history_weekend.screening_date = cinetam_movie_history_weekend.screening_date
and				movie_history_weekend.occurence = cinetam_movie_history_weekend.occurence
and				movie_history_weekend.print_medium = cinetam_movie_history_weekend.print_medium
and				movie_history_weekend.three_d_type = cinetam_movie_history_weekend.three_d_type
and				data_translate_movie.data_provider_id in (1,4)
and				movie_history_weekend.complex_id = data_translate_complex.complex_id
and				data_translate_complex.data_provider_id in (1,4)
group by 	campaign_spot.campaign_no,
					data_translate_movie.movie_code, 
					cinetam_movie_history_weekend.complex_id,
					cinetam_movie_history_weekend.country_code,
					cinetam_demographics_id,
					cinetam_movie_history_weekend.screening_date
GO
