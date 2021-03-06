/****** Object:  StoredProcedure [dbo].[p_cinetam_report_inventory_analmovband]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_report_inventory_analmovband]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_report_inventory_analmovband]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_cinetam_report_inventory_analmovband]			@country_code				char(1),
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
movie_band                      int                 null,
reporting_line_sort				int					null,
reporting_line_desc			    varchar(100)		null,
reporting_line_amount		    decimal(16,4)	    null
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
create table #top_movies
(
movie_rank						int				null,
movie_id						int				null
)

insert into	#top_movies
select	    1, 
			movie_id
from		movie_history where country = @country_code and screening_date between @start_date and @end_date 
and         movie_id in (select movie_id from movie_history where country = @country_code and screening_date between @start_date and @end_date group by movie_id having sum(attendance) > 1000000)
group by	movie_id 
order by	sum(attendance) desc

insert into	#top_movies
select	    2, 
			movie_id
from		movie_history where country = @country_code and screening_date between @start_date and @end_date 
and         movie_id in (select movie_id from movie_history where country = @country_code and screening_date between @start_date and @end_date group by movie_id having sum(attendance) between 500000 and 999999)
group by	movie_id 
order by	sum(attendance) desc
            
insert into	#top_movies
select	    3, 
			movie_id
from		movie_history where country = @country_code and screening_date between @start_date and @end_date 
and         movie_id in (select movie_id from movie_history where country = @country_code and screening_date between @start_date and @end_date group by movie_id having sum(attendance) between 250000 and 499999)
group by	movie_id 
order by	sum(attendance) desc

insert into	#top_movies
select	    4, 
			movie_id
from		movie_history where country = @country_code and screening_date between @start_date and @end_date 
and         movie_id in (select movie_id from movie_history where country = @country_code and screening_date between @start_date and @end_date group by movie_id having sum(attendance) between 100000 and 249999)
group by	movie_id 
order by	sum(attendance) desc
            
insert into	#top_movies
select	    5, 
			movie_id
from		movie_history where country = @country_code and screening_date between @start_date and @end_date 
and         movie_id in (select movie_id from movie_history where country = @country_code and screening_date between @start_date and @end_date group by movie_id having sum(attendance) between 50000 and 99999)
group by	movie_id 
order by	sum(attendance) desc

insert into	#top_movies
select	    6, 
			movie_id
from		movie_history where country = @country_code and screening_date between @start_date and @end_date 
and         movie_id in (select movie_id from movie_history where country = @country_code and screening_date between @start_date and @end_date group by movie_id having sum(attendance) between 25000 and 49999)
group by	movie_id 
order by	sum(attendance) desc
            
insert into	#top_movies
select	    7, 
			movie_id
from		movie_history where country = @country_code and screening_date between @start_date and @end_date 
and         movie_id in (select movie_id from movie_history where country = @country_code and screening_date between @start_date and @end_date group by movie_id having sum(attendance) between 10000 and 24999)
group by	movie_id 
order by	sum(attendance) desc

insert into	#top_movies
select	    8, 
			movie_id
from		movie_history where country = @country_code and screening_date between @start_date and @end_date 
and         movie_id in (select movie_id from movie_history where country = @country_code and screening_date between @start_date and @end_date group by movie_id having sum(attendance) between 5000 and 9999)
group by	movie_id 
order by	sum(attendance) desc
            
insert into	#top_movies
select	    9,
			movie_id
from		movie_history where country = @country_code and screening_date between @start_date and @end_date 
and         movie_id in (select movie_id from movie_history where country = @country_code and screening_date between @start_date and @end_date group by movie_id having sum(attendance) between 1000 and 4999)
group by	movie_id 
order by	sum(attendance) desc

insert into	#top_movies
select	    10, 
			movie_id
from		movie_history where country = @country_code and screening_date between @start_date and @end_date 
and         movie_id in (select movie_id from movie_history where country = @country_code and screening_date between @start_date and @end_date group by movie_id having sum(attendance) between 500 and 999)
group by	movie_id 
order by	sum(attendance) desc
            
insert into	#top_movies
select	    11, 
			movie_id
from		movie_history where country = @country_code and screening_date between @start_date and @end_date 
and         movie_id in (select movie_id from movie_history where country = @country_code and screening_date between @start_date and @end_date group by movie_id having sum(attendance) between 0 and 499)
group by	movie_id 
order by	sum(attendance) desc

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
select 			screening_date,1,
					1,
					'Revenue',
					sum(rev)
from			v_statrev_agency_week
where			screening_date between @start_date and @end_date
and				country_code = @country_code
and				master_revenue_group_desc = 'OnScreen'
group by		screening_date

insert			into #results
select 			screening_date,1,
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
                movie_Rank,
					2,
					'Metro All People Attendance % Sold',
					sum(isnull(attendance_used,0)) / sum(isnull(attendance_total,0)) * 100
from			#attendance_30seceqv, #top_movies
where			complex_id in (select complex_id from complex where complex_region_class = 'M')
and             #attendance_30seceqv.movie_id = #top_movies.movie_id    
group by		screening_date,
                movie_Rank
having          sum(isnull(attendance_total,0)) <> 0

insert			into #results
select 			screening_date,
                movie_Rank,
					3,
					'Metro ' + cinetam_reporting_demograhics_desc + ' % Sold',
					sum(isnull(attendance_used,0)) / sum(isnull(attendance_total,0)) * 100
from			#cinetam_attendance_30seceqv, #top_movies
where			complex_id in (select complex_id from complex where complex_region_class = 'M')
and             #cinetam_attendance_30seceqv.movie_id = #top_movies.movie_id    
group by		screening_date, cinetam_reporting_demograhics_desc,
                movie_Rank
having          sum(isnull(attendance_total,0)) <> 0

insert			into #results
select 			screening_date,
                movie_Rank,
					50,
					'Metro 30 Sec Eqv. Inventory % Sold',
					sum(isnull(time_used,0)) / sum(isnull(time_total,0)) * 100
from			#avail_time_30seceqv, #top_movies
where			complex_id in (select complex_id from complex where complex_region_class = 'M')
and             #avail_time_30seceqv.movie_id = #top_movies.movie_id    
group by		screening_date,
                movie_Rank
having          sum(isnull(time_total,0)) <> 0


insert			into #results
select 			screening_date,
                movie_Rank,
					49,
					'Metro Inventory % Sold',
					sum(isnull(time_used,0)) / sum(isnull(time_total,0)) * 100
from			#avail_time_final, #top_movies
where			complex_id in (select complex_id from complex where complex_region_class = 'M')
and             #avail_time_final.movie_id = #top_movies.movie_id    
group by		screening_date,
                movie_Rank
having          sum(isnull(time_total,0)) <> 0


insert			into #results
select 			screening_date,
                movie_Rank,
					102,
					'Regional All People Attendance % Sold',
					sum(isnull(attendance_used,0)) / sum(isnull(attendance_total,0)) * 100
from			#attendance_30seceqv, #top_movies
where			complex_id in (select complex_id from complex where complex_region_class != 'M')
and             #attendance_30seceqv.movie_id = #top_movies.movie_id    
group by		screening_date,
                movie_Rank
having          sum(isnull(attendance_total,0)) <> 0

insert			into #results
select 			screening_date,
                movie_Rank,
					103,
					'Regional ' + cinetam_reporting_demograhics_desc + ' % Sold',
					sum(isnull(attendance_used,0)) / sum(isnull(attendance_total,0)) * 100
from			#cinetam_attendance_30seceqv, #top_movies
where			complex_id in (select complex_id from complex where complex_region_class != 'M')
and             #cinetam_attendance_30seceqv.movie_id = #top_movies.movie_id    
group by		screening_date, cinetam_reporting_demograhics_desc,
                movie_Rank
having          sum(isnull(attendance_total,0)) <> 0

insert			into #results
select 			screening_date,
                movie_Rank,
					150,
					'Regional 30 Sec Eqv. Inventory % Sold',
					sum(isnull(time_used,0)) / sum(isnull(time_total,0)) * 100
from			#avail_time_30seceqv, #top_movies
where			complex_id in (select complex_id from complex where complex_region_class != 'M')
and             #avail_time_30seceqv.movie_id = #top_movies.movie_id    
group by		screening_date,
                movie_Rank
having          sum(isnull(time_total,0)) <> 0


insert			into #results
select 			screening_date,
                movie_Rank,
					149,
					'Regional Inventory % Sold',
					sum(isnull(time_used,0)) / sum(isnull(time_total,0)) * 100
from			#avail_time_final, #top_movies
where			complex_id in (select complex_id from complex where complex_region_class != 'M')
and             #avail_time_final.movie_id = #top_movies.movie_id    
group by		screening_date,
                movie_Rank
having          sum(isnull(time_total,0)) <> 0


insert			into #results
select 			screening_date,
                movie_Rank,
					202,
					'National All People Attendance % Sold',
					sum(isnull(attendance_used,0)) / sum(isnull(attendance_total,0)) * 100
from			#attendance_30seceqv, #top_movies
where            #attendance_30seceqv.movie_id = #top_movies.movie_id    
group by		screening_date,
                movie_Rank
having          sum(isnull(attendance_total,0)) <> 0


insert			into #results
select 			screening_date,
                movie_Rank,
					203,
					'National ' + cinetam_reporting_demograhics_desc + ' % Sold',
					sum(isnull(attendance_used,0)) / sum(isnull(attendance_total,0)) * 100
from			#cinetam_attendance_30seceqv, #top_movies
where             #cinetam_attendance_30seceqv.movie_id = #top_movies.movie_id    
group by		screening_date, cinetam_reporting_demograhics_desc,
                movie_Rank
having          sum(isnull(attendance_total,0)) <> 0
                

insert			into #results
select 			screening_date,
                movie_Rank,
					250,
					'National 30 Sec Eqv. Inventory % Sold',
					sum(isnull(time_used,0)) / sum(isnull(time_total,0)) * 100
from			#avail_time_30seceqv, #top_movies
where             #avail_time_30seceqv.movie_id = #top_movies.movie_id    
group by		screening_date,
                movie_Rank
having          sum(isnull(time_total,0)) <> 0


insert			into #results
select 			screening_date,
                movie_Rank,
					249,
					'National Inventory % Sold',
					sum(isnull(time_used,0)) / sum(isnull(time_total,0)) * 100
from			#avail_time_final, #top_movies
where             #avail_time_final.movie_id = #top_movies.movie_id    
group by		screening_date,
                movie_Rank
having          sum(isnull(time_total,0)) <> 0

select * from #results order by screening_date, reporting_line_sort

return 0
--go
GO
