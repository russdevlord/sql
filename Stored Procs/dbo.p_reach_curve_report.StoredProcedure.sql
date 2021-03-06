/****** Object:  StoredProcedure [dbo].[p_reach_curve_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_reach_curve_report]
GO
/****** Object:  StoredProcedure [dbo].[p_reach_curve_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create proc [dbo].[p_reach_curve_report]		@arg_cinetam_reporting_demographics_id		integer,
												@arg_film_markets							varchar(max),
												@arg_start_date								datetime,
												@arg_end_date								datetime,
												@arg_adjustment_factor						numeric(30,20)
as

declare		@error										int,
			@count										int,
			@cinetam_reporting_demographics_desc		varchar(50),
			@screening_date								datetime,
			@attendance_estimate						numeric(30,20)   ,
			@attendance_pool							numeric(30,20)   ,
			@attendance_population						numeric(30,20)   ,
			@actual_population							numeric(30,20)   ,						
			@movio_unique_transactions					numeric(30,20)   ,
			@all_people_attendance						numeric(30,20),
			@lower_unique_people						numeric(30,20),
			@lower_unique_transactions					numeric(30,20),
			@higher_unique_people						numeric(30,20),
			@higher_unique_transactions					numeric(30,20),
			@frequency_week_one							numeric(30,20),
			@ldec_R1T									numeric(30,20),
			@ldec_R2T									numeric(30,20),
			@ldec_R1P									numeric(30,20),
			@ldec_R2P									numeric(30,20),
			@ldec_S6									numeric(30,20),
			@ldec_frequency_initial						numeric(30,20),
			@ldec_reach_initial							numeric(30,20),
			@freq_less_than_one							bit,
			@ldec_frequency_result						numeric(30,20),
			@ldec_reach_result							numeric(30,20),
			@ldec_reach_threshold						numeric(30,20),
			@weeknum									int,
			@cinetam_reporting_demographics_id			integer,
			@film_markets								varchar(max),
			@start_date									datetime,
			@end_date									datetime,
			@adjustment_factor							numeric(30,20)
																										
set nocount on

select		@cinetam_reporting_demographics_id = @arg_cinetam_reporting_demographics_id,
			@film_markets = @arg_film_markets,
			@start_date = @arg_start_date,
			@end_date = @arg_end_date,
			@adjustment_factor = @arg_adjustment_factor

select		@cinetam_reporting_demographics_desc = cinetam_reporting_demographics_desc
from		cinetam_reporting_demographics
where		cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

create table #film_markets                
(                
	film_market_no         int     not null                
)                
       

create table #reach_curve
(
	weeknum										int					null,
	cinetam_reporting_demographics_desc			varchar(50)			null,
	attendance_estimate							numeric(30,20)		null,
	lower_unique_people							numeric(30,20)		null,
	lower_unique_transactions					numeric(30,20)		null,
	higher_unique_people						numeric(30,20)		null,
	higher_unique_transactions					numeric(30,20)		null,
	attendance_population						numeric(30,20)		null,
	reach_threshold								numeric(30,20)		null,
	frequency_week_one							numeric(30,20)		null,
	frequency_modifier							numeric(30,20)		null,
	reach_initial								numeric(30,20)		null,
	reach_final									numeric(30,20)		null,
	frequency_initial							numeric(30,20)		null,
	frequency_final								numeric(30,20)		null,
	start_date									datetime			null,
	end_date									datetime			null
)

create table #screening_dates
(
	weeknum										int					null,
	start_date									datetime			null,
	end_date									datetime			null,
	prev_start_date								datetime			null,
	prev_end_date								datetime			null
)

create table #attendance_estimate
(
	weeknum										int					null,
	attendance_estimate							numeric(30,20)		null
)

create table #population
(
	weeknum										int					null,
	attendance_population						numeric(30,20)		null,
	reach_threshold								numeric(30,20)		null
)


create table #attendance_movio
(
	weeknum										int					null,
	unique_people								numeric(30,20)		null,
	movio_unique_transactions					numeric(30,20)		null
)

if len(@film_markets) > 0                
	insert into #film_markets                
	select * from dbo.f_multivalue_parameter(@film_markets,',')    

/*insert			into #screening_dates
select			ROW_NUMBER() over (order by screening_date),
				@start_date,
				screening_date,
				dbo.f_prev_attendance_screening_date(@start_date),
				dbo.f_prev_attendance_screening_date(screening_date) 
from			film_screening_dates
where			screening_date between @start_date and @end_date*/

insert			into #screening_dates
select			ROW_NUMBER() over (order by screening_date),
				@start_date,
				screening_date,
				@start_date,
				screening_date
from			film_screening_dates
where			screening_date between @start_date and @end_date

insert into		#attendance_estimate
select			#screening_dates.weeknum,
				sum(isnull(attendance,0)) * @adjustment_factor
from			v_cinetam_movie_history_reporting_demos
inner join		complex on v_cinetam_movie_history_reporting_demos.complex_id = complex.complex_id
inner join		#film_markets on complex.film_market_no = #film_markets.film_market_no
inner join		#screening_dates on v_cinetam_movie_history_reporting_demos.screening_date between #screening_dates.prev_start_date and #screening_dates.prev_end_date
where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
group by		weeknum

insert into		#population
select			weeknum,
				sum(cinetam_reachfreq_population.population),
				avg(cinetam_reachfreq_population.reach_threshold)
from			cinetam_reachfreq_population
inner join		#screening_dates on cinetam_reachfreq_population.screening_date = #screening_dates.prev_end_date
inner join		#film_markets on cinetam_reachfreq_population.film_market_no = #film_markets.film_market_no
where			cinetam_reachfreq_population.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
group by		weeknum

insert into		#attendance_movio
select			weeknum,
				count(distinct membership_id),
				sum(unique_transactions)
from			v_movio_data_demo_fsd
inner join		cinetam_reporting_demographics_xref on v_movio_data_demo_fsd.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
inner join		complex on v_movio_data_demo_fsd.complex_id = complex.complex_id
inner join		#screening_dates on v_movio_data_demo_fsd.screening_date between #screening_dates.prev_start_date and #screening_dates.prev_end_date
inner join		#film_markets on complex.film_market_no = #film_markets.film_market_no
where			cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
group by		weeknum


insert into		#reach_curve
(
				weeknum,
				cinetam_reporting_demographics_desc,
				attendance_estimate,
				lower_unique_people,
				lower_unique_transactions,
				higher_unique_people,
				higher_unique_transactions,
				attendance_population,
				reach_threshold,
				frequency_week_one,
				frequency_modifier,
				reach_initial,
				reach_final,
				frequency_initial,
				frequency_final,
				start_date,
				end_date				
)
select			dates.weeknum,
				@cinetam_reporting_demographics_desc,
				estimate.attendance_estimate,
				(select unique_people from #attendance_movio where weeknum = 1),
				(select movio_unique_transactions from #attendance_movio where weeknum = 1),
				loyalty.unique_people,
				loyalty.movio_unique_transactions,
				people.attendance_population,
				people.reach_threshold,
				0.0,
				0.0,
				0.0,
				0.0,
				0.0,
				0.0,
				@start_date,
				@end_date
from			#screening_dates dates
inner join		#attendance_estimate estimate on dates.weeknum = estimate.weeknum
inner join		#attendance_movio loyalty on dates.weeknum = loyalty.weeknum
inner join		#population people on dates.weeknum = people.weeknum
order by		dates.weeknum

update			#reach_curve
set				frequency_week_one = isnull(lower_unique_transactions / lower_unique_people, 1)

update			#reach_curve
set				frequency_modifier = 1 / frequency_week_one

update			#reach_curve
set				frequency_initial = (higher_unique_transactions / higher_unique_people) * frequency_modifier

update			#reach_curve
set				reach_initial = attendance_estimate / attendance_population / frequency_initial

update			#reach_curve
set				reach_final = reach_initial,
				frequency_final = frequency_initial

update			#reach_curve
set				reach_final = reach_threshold,
				frequency_final = attendance_estimate / attendance_population / reach_threshold
where			reach_initial > reach_threshold

select * from #reach_curve
return 0

GO
