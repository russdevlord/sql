/****** Object:  StoredProcedure [dbo].[p_cinetam_movie_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_movie_report]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_movie_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_cinetam_movie_report]			@movie_id					varchar(max), 
																			@report_markets_id	int,
																			@start_date					datetime,
																			@end_date					datetime,
																			@demo_id_1				int,
																			@demo_id_2				int,
																			@demo_id_3				int,
																			@demo_id_4				int,
																			@demo_id_5				int,
																			@demo_id_6				int

as

declare		@error											int,
					@screening_date						datetime,
					@demo_desc_1							varchar(100),
					@demo_desc_2							varchar(100),
					@demo_desc_3							varchar(100),
					@demo_desc_4							varchar(100),
					@demo_desc_5							varchar(100),
					@demo_desc_6							varchar(100),
					@demo_attendance_1				int,
					@demo_attendance_2				int,
					@demo_attendance_3				int,
					@demo_attendance_4				int,
					@demo_attendance_5				int,
					@demo_attendance_6				int

set nocount on

create table #movio_movie_data
(
movie_name					varchar(100)			null,
screening_date				datetime				null,
demo_id_1						int							null,
demo_desc_1					varchar(100)			null,
demo_attendance_1		int							null,
demo_id_2						int							null,
demo_desc_2					varchar(100)			null,
demo_attendance_2		int							null,
demo_id_3						int							null,
demo_desc_3					varchar(100)			null,
demo_attendance_3		int							null,
demo_id_4						int							null,
demo_desc_4					varchar(100)			null,
demo_attendance_4		int							null,
demo_id_5						int							null,
demo_desc_5					varchar(100)			null,
demo_attendance_5		int							null,
demo_id_6						int							null,
demo_desc_6					varchar(100)			null,
demo_attendance_6		int							null,
total_attendance				int							null
)

insert into  #movio_movie_data
					(screening_date, total_attendance)
select			screening_date, sum(attendance) 
from			movie, movie_history, complex, report_markets_xref
where			movie.movie_id = movie_history.movie_id
and				movie.movie_id in (select * from dbo.f_multivalue_parameter(@movie_id, ','))
and				screening_date between @start_date and @end_date
and				movie_history.complex_id = complex.complex_id
and				complex.film_market_no = report_markets_xref.film_market_no
and				report_markets_xref.report_markets_id = @report_markets_id
group by		screening_date

declare movio_movie_csr cursor for
select screening_date from  #movio_movie_data
order by screening_date
for read only

open movio_movie_csr
fetch movio_movie_csr into @screening_date
while(@@fetch_status=0)
begin

	if @demo_id_1 is null or @demo_id_1 = 0
	begin
		select	@demo_desc_1 = '',
					@demo_attendance_1 = 0
	end
	else
	begin
		select			@demo_desc_1 = cinetam_reporting_demographics.cinetam_reporting_demographics_desc,
							@demo_attendance_1 = sum(cinetam_movie_history.attendance)
		from			cinetam_movie_history, 
							cinetam_demographics,
							cinetam_reporting_demographics,
							cinetam_reporting_demographics_xref,
							complex, 
							report_markets_xref
		where			cinetam_movie_history.movie_id  in (select * from dbo.f_multivalue_parameter(@movie_id, ','))
		and				cinetam_movie_history.screening_date = @screening_date
		and				cinetam_movie_history.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
		and				cinetam_reporting_demographics.cinetam_reporting_demographics_id = @demo_id_1
		and				cinetam_reporting_demographics.cinetam_reporting_demographics_id = cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id
		and				cinetam_reporting_demographics_xref.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
		and				complex.complex_id  = cinetam_movie_history.complex_id
		and				complex.film_market_no = report_markets_xref.film_market_no
		and				report_markets_xref.report_markets_id = @report_markets_id
		group by		cinetam_reporting_demographics.cinetam_reporting_demographics_desc
	end
	
	if @demo_id_2 is null or @demo_id_2 = 0
	begin
		select	@demo_desc_2 = '',
					@demo_attendance_2 = 0
	end
	else
	begin
		select			@demo_desc_2 = cinetam_reporting_demographics.cinetam_reporting_demographics_desc,
							@demo_attendance_2 = sum(cinetam_movie_history.attendance)
		from			cinetam_movie_history, 
							cinetam_demographics,
							cinetam_reporting_demographics,
							cinetam_reporting_demographics_xref,
							complex, 
							report_markets_xref
		where			cinetam_movie_history.movie_id  in (select * from dbo.f_multivalue_parameter(@movie_id, ','))
		and				cinetam_movie_history.screening_date = @screening_date
		and				cinetam_movie_history.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
		and				cinetam_reporting_demographics.cinetam_reporting_demographics_id = @demo_id_2
		and				cinetam_reporting_demographics.cinetam_reporting_demographics_id = cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id
		and				cinetam_reporting_demographics_xref.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
		and				complex.film_market_no = report_markets_xref.film_market_no
		and				report_markets_xref.report_markets_id = @report_markets_id
		and				complex.complex_id  = cinetam_movie_history.complex_id
		group by		cinetam_reporting_demographics.cinetam_reporting_demographics_desc
	end

	if @demo_id_3 is null or @demo_id_3 = 0
	begin
		select	@demo_desc_3 = '',
					@demo_attendance_3 = 0
	end
	else
	begin
		select			@demo_desc_3 = cinetam_reporting_demographics.cinetam_reporting_demographics_desc,
							@demo_attendance_3 = sum(cinetam_movie_history.attendance)
		from			cinetam_movie_history, 
							cinetam_demographics,
							cinetam_reporting_demographics,
							cinetam_reporting_demographics_xref,
							complex, 
							report_markets_xref
		where			cinetam_movie_history.movie_id  in (select * from dbo.f_multivalue_parameter(@movie_id, ','))
		and				cinetam_movie_history.screening_date = @screening_date
		and				cinetam_movie_history.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
		and				cinetam_reporting_demographics.cinetam_reporting_demographics_id = @demo_id_3
		and				cinetam_reporting_demographics.cinetam_reporting_demographics_id = cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id
		and				cinetam_reporting_demographics_xref.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
		and				complex.film_market_no = report_markets_xref.film_market_no
		and				report_markets_xref.report_markets_id = @report_markets_id
		and				complex.complex_id  = cinetam_movie_history.complex_id
		group by		cinetam_reporting_demographics.cinetam_reporting_demographics_desc
	end

	if @demo_id_4 is null or @demo_id_4 = 0
	begin
		select	@demo_desc_4 = '',
					@demo_attendance_4 = 0
	end
	else
	begin
		select			@demo_desc_4 = cinetam_reporting_demographics.cinetam_reporting_demographics_desc,
							@demo_attendance_4 = sum(cinetam_movie_history.attendance)
		from			cinetam_movie_history, 
							cinetam_demographics,
							cinetam_reporting_demographics,
							cinetam_reporting_demographics_xref,
							complex, 
							report_markets_xref
		where			cinetam_movie_history.movie_id  in (select * from dbo.f_multivalue_parameter(@movie_id, ','))
		and				cinetam_movie_history.screening_date = @screening_date
		and				cinetam_movie_history.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
		and				cinetam_reporting_demographics.cinetam_reporting_demographics_id = @demo_id_4
		and				cinetam_reporting_demographics.cinetam_reporting_demographics_id = cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id
		and				cinetam_reporting_demographics_xref.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
		and				complex.film_market_no = report_markets_xref.film_market_no
		and				report_markets_xref.report_markets_id = @report_markets_id
		and				complex.complex_id  = cinetam_movie_history.complex_id
		group by		cinetam_reporting_demographics.cinetam_reporting_demographics_desc
	end

	if @demo_id_5 is null or @demo_id_5 = 0
	begin
		select	@demo_desc_5 = '',
					@demo_attendance_5 = 0
	end
	else
	begin
		select			@demo_desc_5 = cinetam_reporting_demographics.cinetam_reporting_demographics_desc,
							@demo_attendance_5 = sum(cinetam_movie_history.attendance)
		from			cinetam_movie_history, 
							cinetam_demographics,
							cinetam_reporting_demographics,
							cinetam_reporting_demographics_xref,
							complex, 
							report_markets_xref
		where			cinetam_movie_history.movie_id  in (select * from dbo.f_multivalue_parameter(@movie_id, ','))
		and				cinetam_movie_history.screening_date = @screening_date
		and				cinetam_movie_history.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
		and				cinetam_reporting_demographics.cinetam_reporting_demographics_id = @demo_id_5
		and				cinetam_reporting_demographics.cinetam_reporting_demographics_id = cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id
		and				cinetam_reporting_demographics_xref.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
		and				complex.film_market_no = report_markets_xref.film_market_no
		and				report_markets_xref.report_markets_id = @report_markets_id
		and				complex.complex_id  = cinetam_movie_history.complex_id
		group by		cinetam_reporting_demographics.cinetam_reporting_demographics_desc
	end

	if @demo_id_6 is null or @demo_id_6 = 0
	begin
		select	@demo_desc_6 = '',
					@demo_attendance_6 = 0
	end
	else
	begin
		select			@demo_desc_6 = cinetam_reporting_demographics.cinetam_reporting_demographics_desc,
							@demo_attendance_6 = sum(cinetam_movie_history.attendance)
		from			cinetam_movie_history, 
							cinetam_demographics,
							cinetam_reporting_demographics,
							cinetam_reporting_demographics_xref,
							complex, 
							report_markets_xref
		where			cinetam_movie_history.movie_id  in (select * from dbo.f_multivalue_parameter(@movie_id, ','))
		and				cinetam_movie_history.screening_date = @screening_date
		and				cinetam_movie_history.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
		and				cinetam_reporting_demographics.cinetam_reporting_demographics_id = @demo_id_6
		and				cinetam_reporting_demographics.cinetam_reporting_demographics_id = cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id
		and				cinetam_reporting_demographics_xref.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
		and				complex.film_market_no = report_markets_xref.film_market_no
		and				report_markets_xref.report_markets_id = @report_markets_id
		and				complex.complex_id  = cinetam_movie_history.complex_id
		group by		cinetam_reporting_demographics.cinetam_reporting_demographics_desc
	end

	update	#movio_movie_data
	set			demo_id_1 = @demo_id_1,
					demo_desc_1 = @demo_desc_1,
					demo_attendance_1 = @demo_attendance_1,
					demo_id_2 = @demo_id_2,
					demo_desc_2 = @demo_desc_2,
					demo_attendance_2 = @demo_attendance_2,
					demo_id_3 = @demo_id_3,
					demo_desc_3 = @demo_desc_3,
					demo_attendance_3 = @demo_attendance_3,
					demo_id_4 = @demo_id_4,
					demo_desc_4 = @demo_desc_4,
					demo_attendance_4 = @demo_attendance_4,
					demo_id_5 = @demo_id_5,
					demo_desc_5 = @demo_desc_5,
					demo_attendance_5 = @demo_attendance_5,
					demo_id_6 = @demo_id_6,
					demo_desc_6 = @demo_desc_6,
					demo_attendance_6 = @demo_attendance_6
	where		screening_date = @screening_date					
	fetch movio_movie_csr into @screening_date
end

select		movie_name,
				screening_date,
				demo_id_1,
				demo_desc_1,
				demo_attendance_1,
				demo_id_2,
				demo_desc_2,
				demo_attendance_2,
				demo_id_3,
				demo_desc_3,
				demo_attendance_3,
				demo_id_4,
				demo_desc_4,
				demo_attendance_4,
				demo_id_5,
				demo_desc_5,
				demo_attendance_5,
				demo_id_6,
				demo_desc_6,
				demo_attendance_6,
				total_attendance	
from		#movio_movie_data
order by screening_date

return 0
GO
