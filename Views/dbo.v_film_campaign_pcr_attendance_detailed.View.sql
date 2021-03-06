/****** Object:  View [dbo].[v_film_campaign_pcr_attendance_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_film_campaign_pcr_attendance_detailed]
GO
/****** Object:  View [dbo].[v_film_campaign_pcr_attendance_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create view  [dbo].[v_film_campaign_pcr_attendance_detailed]
as
select			spot_reference,
					inclusion.inclusion_id,
					inclusion.inclusion_desc,
					inclusion.inclusion_type,
					inclusion.campaign_no,
					movie_history.complex_id, 
					movie_history.screening_date,
					movie_history.movie_id,
					long_name, 
					film_market.film_market_no,
					film_market_desc,
					0 as cinetam_reporting_demographics_id,
					'All People' as cinetam_reporting_demographics_desc,
					sum(attendance) as attendance
from				v_certificate_item_distinct
inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
inner join		movie on movie_history.movie_id = movie.movie_id
inner join		complex on movie_history.complex_id = complex.complex_id
inner join		film_market on complex.film_market_no = film_market.film_market_no
inner join		inclusion_campaign_spot_xref on v_certificate_item_distinct.spot_reference = inclusion_campaign_spot_xref.spot_id
inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
group by		spot_reference,
					inclusion.inclusion_id,
					inclusion.inclusion_desc,
					inclusion.inclusion_type,
					inclusion.campaign_no,
					movie_history.complex_id, 
					movie_history.screening_date,
					movie_history.movie_id,
					long_name, 
					film_market.film_market_no,
					film_market_desc
union all
select			spot_reference,
					inclusion.inclusion_id,
					inclusion.inclusion_desc,
					inclusion.inclusion_type,
					inclusion.campaign_no,
					cinetam_movie_history.complex_id, 
					cinetam_movie_history.screening_date,
					cinetam_movie_history.movie_id,
					long_name, 
					film_market.film_market_no,
					film_market_desc,
					cinetam_reporting_demographics.cinetam_reporting_demographics_id,
					cinetam_reporting_demographics.cinetam_reporting_demographics_desc,
					sum(attendance) as attendance
from				v_certificate_item_distinct
inner join		cinetam_movie_history on v_certificate_item_distinct.certificate_group = cinetam_movie_history.certificate_group_id
inner join		cinetam_reporting_demographics_xref on cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
inner join		cinetam_reporting_demographics on cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
inner join		movie on cinetam_movie_history.movie_id = movie.movie_id
inner join		complex on cinetam_movie_history.complex_id = complex.complex_id
inner join		film_market on complex.film_market_no = film_market.film_market_no
inner join		inclusion_campaign_spot_xref on v_certificate_item_distinct.spot_reference = inclusion_campaign_spot_xref.spot_id
inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
where			cinetam_reporting_demographics.cinetam_reporting_demographics_id <> 0
group by		spot_reference,
					inclusion.inclusion_id,
					inclusion.inclusion_desc,
					inclusion.inclusion_type,
					inclusion.campaign_no,
					cinetam_movie_history.complex_id, 
					cinetam_movie_history.screening_date,
					cinetam_movie_history.movie_id,
					cinetam_reporting_demographics.cinetam_reporting_demographics_id,
					cinetam_reporting_demographics.cinetam_reporting_demographics_desc,
					long_name, 
					film_market.film_market_no,
					film_market_desc
GO
