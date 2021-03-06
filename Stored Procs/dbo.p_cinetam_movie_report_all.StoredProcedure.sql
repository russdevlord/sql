/****** Object:  StoredProcedure [dbo].[p_cinetam_movie_report_all]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_movie_report_all]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_movie_report_all]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_cinetam_movie_report_all]			@movie_id					varchar(max), 
																					@report_markets_id	int,
																					@start_date					datetime,
																					@end_date					datetime

as

declare		@error											int,
					@screening_date						datetime,
					@demo_id									int

set nocount on

create table #movio_movie_data
(
movie_name					varchar(100)			null,
screening_date				datetime				null,
demo_id							int							null,
demo_desc						varchar(100)			null,
demo_attendance			int							null,
total_attendance				int							null
)

insert into  #movio_movie_data
					(screening_date, total_attendance, demo_id)
select			screening_date, sum(attendance), cinetam_reporting_demographics_id 
from			movie, movie_history, complex, report_markets_xref, cinetam_reporting_demographics
where			movie.movie_id = movie_history.movie_id
and				movie.movie_id in (select * from dbo.f_multivalue_parameter(@movie_id, ','))
and				screening_date between @start_date and @end_date
and				movie_history.complex_id = complex.complex_id
and				complex.film_market_no = report_markets_xref.film_market_no
and				report_markets_xref.report_markets_id = @report_markets_id
group by		long_name, movie.movie_id, screening_date, cinetam_reporting_demographics_id

update		#movio_movie_data
set				demo_desc = temp_table.demo_desc_tmp,
					demo_attendance = temp_table.demo_attendance_tmp
from			(select		cinetam_reporting_demographics.cinetam_reporting_demographics_desc as demo_desc_tmp,
										sum(cinetam_movie_history.attendance) as demo_attendance_tmp,
										cinetam_movie_history.screening_date, 
										cinetam_reporting_demographics.cinetam_reporting_demographics_id
					from			cinetam_movie_history, 
										cinetam_demographics,
										cinetam_reporting_demographics,
										cinetam_reporting_demographics_xref,
										complex, 
										report_markets_xref
					where			cinetam_movie_history.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
					and				cinetam_reporting_demographics.cinetam_reporting_demographics_id = cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id
					and				cinetam_reporting_demographics_xref.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
					and				complex.complex_id  = cinetam_movie_history.complex_id
					and				complex.film_market_no = report_markets_xref.film_market_no
					and				report_markets_xref.report_markets_id = @report_markets_id
					and				cinetam_movie_history.movie_id in  (select * from dbo.f_multivalue_parameter(@movie_id, ','))
					group by		cinetam_reporting_demographics.cinetam_reporting_demographics_desc,
										cinetam_movie_history.movie_id, 
										cinetam_movie_history.screening_date, 
										cinetam_reporting_demographics.cinetam_reporting_demographics_id) as temp_table
where			temp_table.screening_date = #movio_movie_data.screening_date
and				temp_table.cinetam_reporting_demographics_id = #movio_movie_data.demo_id

select		movie_name,
				screening_date,
				demo_id,
				demo_desc,
				demo_attendance,
				total_attendance	
from		#movio_movie_data
order by demo_desc, screening_date

return 0
GO
