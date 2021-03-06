/****** Object:  View [dbo].[v_availability_avg_mm_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_availability_avg_mm_attendance]
GO
/****** Object:  View [dbo].[v_availability_avg_mm_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_availability_avg_mm_attendance]
as
select complex.complex_id, movie_history.screening_date, avg(attendance) as avg_mm_attendance, 0 as cinetam_reporting_demographics_id
from movie_history
inner join v_certificate_item_distinct on movie_history.certificate_group = v_certificate_item_distinct.certificate_group
inner join campaign_spot on v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
inner join complex on movie_history.complex_id = complex.complex_id
where spot_type not in ('A','F','K','T')
and attendance is not null
and movie_id <> 102
and advertising_open <> 'N'
and premium_cinema <> 'Y'
group by complex.complex_id,  movie_history.screening_date
union all
select temp_table.complex_id, temp_table.screening_date, avg(combo_attendance) as avg_mm_attendance, cinetam_reporting_demographics_id
from	(select cinetam_movie_history.complex_id, cinetam_movie_history.screening_date, spot_reference, sum(attendance) as combo_attendance, cinetam_reporting_demographics_id
from cinetam_movie_history
inner join cinetam_reporting_demographics_xref on cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
inner join v_certificate_item_distinct on cinetam_movie_history.certificate_group_id = v_certificate_item_distinct.certificate_group
inner join campaign_spot on v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
where spot_type not in ('A','F','K','T')
group by cinetam_movie_history.complex_id, cinetam_movie_history.screening_date, spot_reference, cinetam_reporting_demographics_id) as temp_table
group by temp_table.complex_id, temp_table.screening_date, cinetam_reporting_demographics_id
GO
