/****** Object:  View [dbo].[v_cinetam_campaign_post_analysis_nz]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_campaign_post_analysis_nz]
GO
/****** Object:  View [dbo].[v_cinetam_campaign_post_analysis_nz]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



create view [dbo].[v_cinetam_campaign_post_analysis_nz]
as
select 			campaign_spot.campaign_no, 
					data_translate_movie.movie_code, 
					cinetam_movie_history.complex_id,
					cinetam_demographics_id,
					cinetam_movie_history.screening_date,
					cinetam_movie_history.country_code,
					1 / max(cinetam_movie_history.occurence) as occurence_adjuster
from			movie_history,
					v_certificate_item_distinct,
					campaign_spot,
					cinetam_movie_history,
					data_translate_movie,
					data_translate_complex
where			campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history.certificate_group
and				data_translate_movie.movie_id = movie_history.movie_id
and				data_translate_movie.movie_id = cinetam_movie_history.movie_id
and				movie_history.complex_id = cinetam_movie_history.complex_id
and				movie_history.movie_id = cinetam_movie_history.movie_id
and				movie_history.screening_date = cinetam_movie_history.screening_date
and				movie_history.occurence = cinetam_movie_history.occurence
and				movie_history.print_medium = cinetam_movie_history.print_medium
and				movie_history.three_d_type = cinetam_movie_history.three_d_type
and				data_translate_movie.data_provider_id in (1,4)
and				movie_history.complex_id = data_translate_complex.complex_id
and				data_translate_complex.data_provider_id in (1,4)
group by 	campaign_spot.campaign_no,
					data_translate_movie.movie_code, 
					cinetam_movie_history.complex_id,
					cinetam_movie_history.country_code,
					cinetam_demographics_id,
					cinetam_movie_history.screening_date


GO
