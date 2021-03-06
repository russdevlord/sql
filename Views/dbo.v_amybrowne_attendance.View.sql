/****** Object:  View [dbo].[v_amybrowne_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_amybrowne_attendance]
GO
/****** Object:  View [dbo].[v_amybrowne_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_amybrowne_attendance]
as
select 		campaign_spot.campaign_no, 
					movie.long_name,
					cinetam_movie_history.screening_date,
					sum(cinetam_movie_history.attendance) as attendance
from			movie_history,
					v_certificate_item_distinct,
					campaign_spot,
					cinetam_movie_history,
					movie,
					cinetam_reporting_demographics_xref,
					cinetam_campaign_settings
where		campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history.certificate_group
and				movie.movie_id = movie_history.movie_id
and				movie_history.complex_id = cinetam_movie_history.complex_id
and				movie_history.movie_id = cinetam_movie_history.movie_id
and				movie_history.screening_date = cinetam_movie_history.screening_date
and				movie_history.occurence = cinetam_movie_history.occurence
and				movie_history.print_medium = cinetam_movie_history.print_medium
and				movie_history.three_d_type = cinetam_movie_history.three_d_type
and				cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
and				campaign_spot.campaign_no = cinetam_campaign_settings.campaign_no
and				campaign_spot.campaign_no in (207827,207828,207829)
group by 	cinetam_movie_history.screening_date,
					movie.long_name, campaign_spot.campaign_no



--select * from film_campaign where product_desc like '%amar%'
GO
