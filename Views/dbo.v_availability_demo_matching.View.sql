/****** Object:  View [dbo].[v_availability_demo_matching]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_availability_demo_matching]
GO
/****** Object:  View [dbo].[v_availability_demo_matching]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_availability_demo_matching]
as
select			complex_id,
					screening_date,
					cinetam_reporting_demographics_id,
					temp_table.attendance / (select sum(attendance) from movie_history where complex_id = temp_table.complex_id and screening_date = temp_table.screening_date) as attendance_share
from				(select				complex_id,
											screening_date,
											0 as cinetam_reporting_demographics_id,
											convert(numeric(30,15), sum(attendance)) as attendance
					from					movie_history
					where				attendance <> 0
					group by			complex_id,
											screening_date
					union all
					select				complex_id,
											screening_date,
											cinetam_reporting_demographics_id,
											convert(numeric(30,15), sum(attendance)) as attendance
					from					cinetam_movie_history
					inner join			cinetam_reporting_demographics_xref on cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
					where				attendance <> 0
					and					cinetam_reporting_demographics_id <> 0
					group by			complex_id,
											screening_date,
											cinetam_reporting_demographics_id) as temp_table
GO
