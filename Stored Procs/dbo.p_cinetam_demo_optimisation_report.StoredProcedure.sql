/****** Object:  StoredProcedure [dbo].[p_cinetam_demo_optimisation_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_demo_optimisation_report]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_demo_optimisation_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinetam_demo_optimisation_report]		@cinetam_reporting_demographics_id				int,
																								@report_markets_id												int,
																								@no_screens															int,
																								@start_date																datetime,
																								@end_date																datetime

as

declare			@screening_date													datetime,
						@attendance															int,
						@complex_id															int, 
						@complex_name													varchar(50), 
						@movie_id																int, 
						@long_name															varchar(50),
						@loop																		int,
						@cinetam_reporting_demographics_desc		varchar(50),
						@report_markets_desc											varchar(50),
						@all_people_attendance										int,
						@occurence																int,
						@print_medium														char(1),
						@three_d_type															int
						
select			@cinetam_reporting_demographics_desc = cinetam_reporting_demographics_desc			
from			cinetam_reporting_demographics
where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

select			@report_markets_desc = report_markets_desc
from			report_markets
where			report_markets_id = @report_markets_id
						
/*
 * Create Temp Table
 */

create table #optimised_attendance
(
	screening_date					datetime		null,
	complex_id							int					null,
	complex_name					varchar(50)	null,
	movie_id								int					null,
	movie_name						varchar(50)	null,
	attendance							int					null,
	occurence								int					null,
	print_medium						char(1)			null,
	three_d_type							int					null,
	all_people_attendance		int					null				
) 

/*
 * Declare Screening Date Cursor
 */ 

declare	screening_date_csr cursor for
select		screening_date
from		film_screening_dates
where		screening_date between  @start_date and @end_date
order by screening_date

/*
 * Open Cursor and process
 */

open screening_date_csr
fetch screening_date_csr into @screening_date
while(@@fetch_status = 0)
begin

	select @loop = 0
	
	/*
	 * Declare movie & location cursor desc order by attendance
	 */
	 
	 declare		cinetam_attendance_csr cursor for
	 select			complex.complex_id,
						complex_name,
						movie.movie_id,
						long_name,
						occurence,
						print_medium,
						three_d_type,
						sum(attendance) as attendance
	from			cinetam_movie_history,
						complex, 
						movie
	where			cinetam_movie_history.cinetam_demographics_id in (select cinetam_reporting_demographics_xref.cinetam_demographics_id from cinetam_reporting_demographics_xref where cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id)
	and				complex.film_market_no in (select film_market_no from report_markets_xref where report_markets_id = @report_markets_id) 
	and				cinetam_movie_history.complex_id = complex.complex_id
	and				cinetam_movie_history.movie_id = movie.movie_id
	and				screening_date = @screening_date
	group by		complex.complex_id,
						complex_name,
						movie.movie_id,
						long_name,
						occurence,
						print_medium,
						three_d_type				
	order by		sum(attendance) DESC
	
	open cinetam_attendance_csr
	fetch cinetam_attendance_csr  into @complex_id, @complex_name, @movie_id, @long_name, @occurence, @print_medium, @three_d_type, @attendance						
	while(@@fetch_status = 0 and @loop < @no_screens)
	begin
	
		select @loop = @loop +1
		
		select		@all_people_attendance = sum(attendance)
		from		movie_history
		where		screening_date = @screening_date
		and			movie_id = @movie_id
		and			complex_id = @complex_id
		and			occurence = @occurence
		and			print_medium = @print_medium
		and			three_d_type = @three_d_type
		
		insert into #optimised_attendance values (@screening_date, @complex_id, @complex_name, @movie_id, @long_name, @attendance, @occurence, @print_medium, @three_d_type, @all_people_attendance)
	
	fetch cinetam_attendance_csr  into @complex_id, @complex_name, @movie_id, @long_name, @occurence, @print_medium, @three_d_type, @attendance						
	end
	
	deallocate cinetam_attendance_csr

	fetch screening_date_csr into @screening_date
end

deallocate screening_date_csr

select		@cinetam_reporting_demographics_id as 'cinetam_reporting_demographics_id',
				@cinetam_reporting_demographics_desc as 'cinetam_reporting_demographics_desc',
				@report_markets_id as 'report_markets_id',
				@report_markets_desc as 'report_market_desc',
				@no_screens as 'no_screens',
				@start_date as 'start_date',
				@end_date as 'end_date',
				screening_date,
				complex_id,
				complex_name,
				movie_id,
				movie_name,
				attendance,
				occurence,
				print_medium,
				three_d_type	,
				all_people_attendance	
from		#optimised_attendance
  
return 0
GO
