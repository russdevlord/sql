/****** Object:  View [dbo].[v_cinetam_film_campaign_digilite_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_film_campaign_digilite_detailed]
GO
/****** Object:  View [dbo].[v_cinetam_film_campaign_digilite_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



CREATE view [dbo].[v_cinetam_film_campaign_digilite_detailed]
as
select 			film_campaign.campaign_no, 
					convert(char(6), film_campaign.campaign_no) + ' - ' + film_campaign.product_desc as campaign_desc,
					cinetam_demographics.cinetam_demographics_desc,
					cinetam_movie_history.screening_date,
					sum(cinetam_movie_history.attendance) as attendance
from				film_campaign
inner join		v_cinelight_playlist_complexes on film_campaign.campaign_no = v_cinelight_playlist_complexes.campaign_no
inner join		cinetam_movie_history on v_cinelight_playlist_complexes.complex_id = cinetam_movie_history.complex_id and v_cinelight_playlist_complexes.screening_date = cinetam_movie_history.screening_date
inner join		cinetam_demographics on cinetam_movie_history.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
where			v_cinelight_playlist_complexes.screening_date  > '5-jul-2012'
group by 		film_campaign.campaign_no,
					film_campaign.product_desc,
					cinetam_demographics.cinetam_demographics_desc,
					cinetam_movie_history.screening_date
union
select 			film_campaign.campaign_no, 
					convert(char(6), film_campaign.campaign_no) + ' - ' + film_campaign.product_desc as campaign_desc,
					'All People' as cinetam_demographics_desc,
					movie_history.screening_date,
					sum(movie_history.attendance) as attendance
from				film_campaign
inner join		v_cinelight_playlist_complexes on film_campaign.campaign_no = v_cinelight_playlist_complexes.campaign_no
inner join		movie_history on v_cinelight_playlist_complexes.complex_id = movie_history.complex_id and v_cinelight_playlist_complexes.screening_date = movie_history.screening_date
where			movie_history.attendance is not null
and				movie_history.attendance > 0 
and				movie_history.screening_date  >  '5-jul-2012'
group by 		film_campaign.campaign_no,
					film_campaign.product_desc,
					movie_history.screening_date

GO
