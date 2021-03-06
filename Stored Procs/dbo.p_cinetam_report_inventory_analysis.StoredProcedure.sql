/****** Object:  StoredProcedure [dbo].[p_cinetam_report_inventory_analysis]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_report_inventory_analysis]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_report_inventory_analysis]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_cinetam_report_inventory_analysis]			@country_code				char(1),
                                                        @start_date					datetime,
                                                        @end_date					datetime,
                                                        @movie_mode					int
/*
 * Movie Mode
 * 0 = All movies included
 * 3 = Excluding Top 3 movies  
 * 5 = Excluding Top 5 movies   
 *
 */ 

/*
 * Reporting Lines
 * Revenue  
 * All Attendance
 * CineTam Reporting Demographics  
 */
 
   
as

declare			@revenue						money,
                @attendance_avail				int,
                @reporting_line_desc			varchar(30),
                @reporting_line_amount		    varchar(30),
                @attendance_sold				int,
                @time_sold						int,
                @time_avail						int
						
						
create table #results
(
screening_date					datetime			null,
reporting_line_sort				int						null,
reporting_line_desc			    varchar(100)		null,
reporting_line_amount		    decimal(16,4)	null
)

create table #used_time
(
screening_date		datetime,
complex_id				int,
movie_id					int,
occurence					int,
print_medium			char(1),
three_d_type				int,
time_used					decimal(16,4)
)

create table #avail_time
(
screening_date		datetime,
complex_id				int,
movie_id					int,
occurence					int,
print_medium			char(1),
three_d_type				int,
time_avail					decimal(16,4)
)


create table #cinetam_reporting_totals
(
screening_date		datetime,
complex_id				int,
movie_id					int,
occurence					int,
print_medium			char(1),
three_d_type				int,
attendance				int,
cinetam_desc			varchar(20)
)

insert		into #cinetam_reporting_totals
select		screening_date,
				complex_id,
				movie_id,
				occurence,
				print_medium,
				three_d_type,
				sum(isnull(attendance,0)),
				cinetam_reporting_demographics_desc
from		cinetam_movie_history,
				cinetam_reporting_demographics,
				cinetam_reporting_demographics_xref
where		cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
and			cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
and			screening_date between @start_date and @end_date
group by screening_date,
				complex_id,
				movie_id,
				occurence,
				print_medium,
				three_d_type,
				cinetam_reporting_demographics_desc

create table #avail_time_final
(
screening_date		datetime,
complex_id				int,
movie_id					int,
occurence					int,
print_medium			char(1),
three_d_type				int,
time_used					decimal(16,4),
time_total					decimal(16,4),
time_avail					decimal(16,4)
)


create table #avail_time_30seceqv
(
screening_date		datetime,
complex_id				int,
movie_id					int,
occurence					int,
print_medium			char(1),
three_d_type				int,
time_used					decimal(16,4),
time_total					decimal(16,4),
time_avail					decimal(16,4)
)

create table #attendance_30seceqv
(
screening_date					datetime,
complex_id							int,
movie_id								int,
occurence								int,
print_medium						char(1),
three_d_type							int,
attendance_used					decimal(16,4),
attendance_total					decimal(16,4),
attendance_avail					decimal(16,4)
)

create table #cinetam_attendance_30seceqv
(
cinetam_reporting_demograhics_desc			varchar(20),
screening_date													datetime,
complex_id															int,
movie_id																int,
occurence																int,
print_medium														char(1),
three_d_type															int,
attendance_used													decimal(16,4),
attendance_total													decimal(16,4),
attendance_avail													decimal(16,4)
)

insert			into #results
select 			screening_date,
					1,
					'Revenue',
					sum(rev)
from			v_statrev_agency_week
where			screening_date between @start_date and @end_date
and				country_code = @country_code
and				master_revenue_group_desc = 'OnScreen'
group by		screening_date

insert			into #results
select 			screening_date,
					10000,
					'All People Attendance',
					sum(attendance)
from			movie_history
where			screening_date between @start_date and @end_date
and				country = @country_code
group by		screening_date


insert			into	#used_time
select			screening_date,
					complex_id,
					movie_id,
					occurence,
					movie_history.print_medium,
					movie_history.three_d_type,
					sum(duration)
from			movie_history,
					certificate_item,
					film_print
where			movie_history.certificate_group = certificate_item.certificate_group
and				certificate_item.print_id = film_print.print_id
and				spot_reference is not null			
and				screening_date between @start_date and @end_date
and				country = @country_code			
and				movie_history.movie_id not in (select top (@movie_mode) movie_id from movie_history mh where mh.screening_date = movie_history.screening_date and country = @country_code group by movie_id order by sum(attendance) desc)				
group by		screening_date,
					complex_id,
					movie_id,
					occurence,
					movie_history.print_medium,
					movie_history.three_d_type
					
insert			into	#avail_time
select			movie_history.screening_date,
					movie_history.complex_id,
					movie_id,
					occurence,
					movie_history.print_medium,
					movie_history.three_d_type,
					max_time + mg_max_time
from			movie_history,
					complex_date
where			movie_history.complex_id = complex_date.complex_id
and				movie_history.screening_date = complex_date.screening_date
and				movie_history.screening_date between @start_date and @end_date
and				country = @country_code							
and				movie_history.movie_id not in (select top (@movie_mode) movie_id from movie_history mh where mh.screening_date = movie_history.screening_date and country = @country_code group by movie_id order by sum(attendance) desc)				

insert			into	#avail_time_final
select			#avail_time.screening_date,
					#avail_time.complex_id,
					#avail_time.movie_id,
					#avail_time.occurence,
					#avail_time.print_medium,
					#avail_time.three_d_type,
					round((isnull(#used_time.time_used,0)), 0),
					round((#avail_time.time_avail), 0),
					round((#avail_time.time_avail - isnull(#used_time.time_used,0)), 0)
from			#avail_time left outer join #used_time
on				#avail_time.screening_date = #used_time.screening_date
and				#avail_time.complex_id = #used_time.complex_id
and				#avail_time.movie_id = #used_time.movie_id
and				#avail_time.occurence = #used_time.occurence
and				#avail_time.print_medium = #used_time.print_medium
and				#avail_time.three_d_type = #used_time.three_d_type				

insert		into	#avail_time_30seceqv
select		#avail_time.screening_date,
				#avail_time.complex_id,
				#avail_time.movie_id,
				#avail_time.occurence,
				#avail_time.print_medium,
				#avail_time.three_d_type,
				round((isnull(#used_time.time_used,0)) / 30, 0),
				round((#avail_time.time_avail) / 30, 0),
				round((#avail_time.time_avail - isnull(#used_time.time_used,0)) / 30, 0)
from			#avail_time left outer join #used_time
on				#avail_time.screening_date = #used_time.screening_date
and				#avail_time.complex_id = #used_time.complex_id
and				#avail_time.movie_id = #used_time.movie_id
and				#avail_time.occurence = #used_time.occurence
and				#avail_time.print_medium = #used_time.print_medium
and				#avail_time.three_d_type = #used_time.three_d_type				

insert			into #attendance_30seceqv
select			#avail_time_30seceqv.screening_date,
					#avail_time_30seceqv.complex_id,
					#avail_time_30seceqv.movie_id,
					#avail_time_30seceqv.occurence,
					#avail_time_30seceqv.print_medium,
					#avail_time_30seceqv.three_d_type,
					isnull(#avail_time_30seceqv.time_used,0) * isnull(attendance,0),
					isnull(#avail_time_30seceqv.time_total,0) * isnull(attendance,0),
					isnull(#avail_time_30seceqv.time_avail,0) * isnull(attendance,0)	
from			#avail_time_30seceqv inner join movie_history
on				#avail_time_30seceqv.screening_date = movie_history.screening_date
and				#avail_time_30seceqv.complex_id = movie_history.complex_id
and				#avail_time_30seceqv.movie_id = movie_history.movie_id
and				#avail_time_30seceqv.occurence = movie_history.occurence
and				#avail_time_30seceqv.print_medium = movie_history.print_medium
and				#avail_time_30seceqv.three_d_type = movie_history.three_d_type 

insert			into #cinetam_attendance_30seceqv
select			cinetam_desc, 
					#avail_time_30seceqv.screening_date,
					#avail_time_30seceqv.complex_id,
					#avail_time_30seceqv.movie_id,
					#avail_time_30seceqv.occurence,
					#avail_time_30seceqv.print_medium,
					#avail_time_30seceqv.three_d_type,
					isnull(#avail_time_30seceqv.time_used,0) * isnull(attendance,0),
					isnull(#avail_time_30seceqv.time_total,0) * isnull(attendance,0),
					isnull(#avail_time_30seceqv.time_avail,0) * isnull(attendance,0)	
from			#avail_time_30seceqv,
					#cinetam_reporting_totals
where			#avail_time_30seceqv.screening_date = #cinetam_reporting_totals.screening_date
and				#avail_time_30seceqv.complex_id = #cinetam_reporting_totals.complex_id
and				#avail_time_30seceqv.movie_id = #cinetam_reporting_totals.movie_id
and				#avail_time_30seceqv.occurence = #cinetam_reporting_totals.occurence
and				#avail_time_30seceqv.print_medium = #cinetam_reporting_totals.print_medium
and				#avail_time_30seceqv.three_d_type = #cinetam_reporting_totals.three_d_type 

insert			into #results
select 			screening_date,
					2,
					'Metro All People Attendance % Sold',
					sum(isnull(attendance_used,0)) / sum(isnull(attendance_total,0)) * 100
from			#attendance_30seceqv
where			complex_id in (select complex_id from complex where complex_region_class = 'M')
group by		screening_date

insert			into #results
select 			screening_date,
					3,
					'Metro ' + cinetam_reporting_demograhics_desc + ' % Sold',
					sum(isnull(attendance_used,0)) / sum(isnull(attendance_total,0)) * 100
from			#cinetam_attendance_30seceqv
where			complex_id in (select complex_id from complex where complex_region_class = 'M')
group by		screening_date, cinetam_reporting_demograhics_desc

insert			into #results
select 			screening_date,
					50,
					'Metro 30 Sec Eqv. Inventory % Sold',
					sum(isnull(time_used,0)) / sum(isnull(time_total,0)) * 100
from			#avail_time_30seceqv
where			complex_id in (select complex_id from complex where complex_region_class = 'M')
group by		screening_date


insert			into #results
select 			screening_date,
					49,
					'Metro Inventory % Sold',
					sum(isnull(time_used,0)) / sum(isnull(time_total,0)) * 100
from			#avail_time_final
where			complex_id in (select complex_id from complex where complex_region_class = 'M')
group by		screening_date


insert			into #results
select 			screening_date,
					102,
					'Regional All People Attendance % Sold',
					sum(isnull(attendance_used,0)) / sum(isnull(attendance_total,0)) * 100
from			#attendance_30seceqv
where			complex_id in (select complex_id from complex where complex_region_class != 'M')
group by		screening_date

insert			into #results
select 			screening_date,
					103,
					'Regional ' + cinetam_reporting_demograhics_desc + ' % Sold',
					sum(isnull(attendance_used,0)) / sum(isnull(attendance_total,0)) * 100
from			#cinetam_attendance_30seceqv
where			complex_id in (select complex_id from complex where complex_region_class != 'M')
group by		screening_date, cinetam_reporting_demograhics_desc

insert			into #results
select 			screening_date,
					150,
					'Regional 30 Sec Eqv. Inventory % Sold',
					sum(isnull(time_used,0)) / sum(isnull(time_total,0)) * 100
from			#avail_time_30seceqv
where			complex_id in (select complex_id from complex where complex_region_class != 'M')
group by		screening_date


insert			into #results
select 			screening_date,
					149,
					'Regional Inventory % Sold',
					sum(isnull(time_used,0)) / sum(isnull(time_total,0)) * 100
from			#avail_time_final
where			complex_id in (select complex_id from complex where complex_region_class != 'M')
group by		screening_date



insert			into #results
select 			screening_date,
					202,
					'National All People Attendance % Sold',
					sum(isnull(attendance_used,0)) / sum(isnull(attendance_total,0)) * 100
from			#attendance_30seceqv
group by		screening_date

insert			into #results
select 			screening_date,
					203,
					'National ' + cinetam_reporting_demograhics_desc + ' % Sold',
					sum(isnull(attendance_used,0)) / sum(isnull(attendance_total,0)) * 100
from			#cinetam_attendance_30seceqv
group by		screening_date, cinetam_reporting_demograhics_desc

insert			into #results
select 			screening_date,
					250,
					'National 30 Sec Eqv. Inventory % Sold',
					sum(isnull(time_used,0)) / sum(isnull(time_total,0)) * 100
from			#avail_time_30seceqv
group by		screening_date


insert			into #results
select 			screening_date,
					249,
					'National Inventory % Sold',
					sum(isnull(time_used,0)) / sum(isnull(time_total,0)) * 100
from			#avail_time_final
group by		screening_date

select * from #results order by screening_date, reporting_line_sort

return 0
--go
GO
