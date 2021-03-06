/****** Object:  View [dbo].[v_movie_history_all_demos]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_movie_history_all_demos]
GO
/****** Object:  View [dbo].[v_movie_history_all_demos]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_movie_history_all_demos]

as


select			cinetam_movie_history.movie_id,
					complex_id,
					screening_date,
					cinetam_reporting_demographics_id,
					inclusion_id,
					sum(attendance) as attendance  
from				cinetam_movie_history
inner join		cinetam_reporting_demographics_xref on cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
inner join		v_certificate_item_distinct on cinetam_movie_history.certificate_group_id = v_certificate_item_distinct.certificate_group
inner join		inclusion_campaign_spot_xref on v_certificate_item_distinct.spot_reference = inclusion_campaign_spot_xref.spot_id
where			cinetam_reporting_demographics_id <> 0
group by		cinetam_movie_history.movie_id,
					complex_id,
					screening_date,
					inclusion_id,
					cinetam_reporting_demographics_id
union all
select			movie_history.movie_id,
					complex_id,
					screening_date,
					0 as cinetam_reporting_demographics_id,
					inclusion_id,
					sum(attendance) as attendance
from				movie_history
inner join		v_certificate_item_distinct on movie_history.certificate_group = v_certificate_item_distinct.certificate_group
inner join		inclusion_campaign_spot_xref on v_certificate_item_distinct.spot_reference = inclusion_campaign_spot_xref.spot_id
group by		movie_history.movie_id,
					complex_id,
					screening_date,
					inclusion_id
GO
