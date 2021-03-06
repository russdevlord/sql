/****** Object:  View [dbo].[v_movie_history_all_rpt_demos]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_movie_history_all_rpt_demos]
GO
/****** Object:  View [dbo].[v_movie_history_all_rpt_demos]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_movie_history_all_rpt_demos]

as


select			cinetam_movie_history.movie_id,
					complex_id,
					screening_date,
					cinetam_reporting_demographics_id,
					sum(attendance) as attendance  
from				cinetam_movie_history
inner join		cinetam_reporting_demographics_xref on cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
where			cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id <> 0
group by		cinetam_movie_history.movie_id,
					complex_id,
					screening_date,
					cinetam_reporting_demographics_id
union all
select			movie_history.movie_id,
					complex_id,
					screening_date,
					0 as cinetam_reporting_demographics_id,
					sum(attendance) as attendance
from				movie_history
group by		movie_history.movie_id,
					complex_id,
					screening_date
GO
