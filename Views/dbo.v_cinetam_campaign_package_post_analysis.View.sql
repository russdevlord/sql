/****** Object:  View [dbo].[v_cinetam_campaign_package_post_analysis]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_campaign_package_post_analysis]
GO
/****** Object:  View [dbo].[v_cinetam_campaign_package_post_analysis]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view [dbo].[v_cinetam_campaign_package_post_analysis]
as
select 			   campaign_spot.package_id, 
					data_translate_movie.movie_code, 
					v_cinetam_movie_history_Details.complex_id,
					cinetam_reporting_demographics_id,
					v_cinetam_movie_history_Details.screening_date,
					convert(Decimal, count(distinct v_cinetam_movie_history_Details.occurence))/ Convert(DECIMAL, max(v_cinetam_movie_history_Details.occurence)) as occurence_adjuster
from			movie_history,
					v_certificate_item_distinct,
					campaign_spot,
					v_cinetam_movie_history_Details,
					data_translate_movie,
					data_translate_complex
where			campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history.certificate_group
and				v_certificate_item_distinct.certificate_group = v_cinetam_movie_history_Details.certificate_group
and				data_translate_movie.movie_id = movie_history.movie_id
and				data_translate_movie.movie_id = v_cinetam_movie_history_Details.movie_id
and				movie_history.complex_id = v_cinetam_movie_history_Details.complex_id
and				movie_history.movie_id = v_cinetam_movie_history_Details.movie_id
and				movie_history.screening_date = v_cinetam_movie_history_Details.screening_date
and				movie_history.occurence = v_cinetam_movie_history_Details.occurence
and				movie_history.print_medium = v_cinetam_movie_history_Details.print_medium
and				movie_history.three_d_type = v_cinetam_movie_history_Details.three_d_type
and				data_translate_movie.data_provider_id in  ( 1, 4)
and				movie_history.complex_id = data_translate_complex.complex_id
and				data_translate_complex.data_provider_id  in  ( 1, 4)
group by 	campaign_spot.package_id,
					data_translate_movie.movie_code, 
					v_cinetam_movie_history_Details.complex_id,
					cinetam_reporting_demographics_id,
					v_cinetam_movie_history_Details.screening_date
GO
