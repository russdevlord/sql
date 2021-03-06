/****** Object:  StoredProcedure [dbo].[p_rf_curve_report_2021_no_thres]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rf_curve_report_2021_no_thres]
GO
/****** Object:  StoredProcedure [dbo].[p_rf_curve_report_2021_no_thres]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_rf_curve_report_2021_no_thres]  @no_weeks								numeric(30,20),
									@start_date								datetime,
									@cinetam_reporting_demographics_id		int,
									@attendance								numeric(30,20),
									@country_code							char(1),
									@film_markets							varchar(max),
									@curves									varchar(max)

as

declare			@error										int,
				@cinetam_reporting_demographics_desc		varchar(50),
				@attendance_estimate						numeric(30,20),
				@lower_unique_people						numeric(30,20),
				@lower_unique_transactions					numeric(30,20),
				@higher_unique_people						numeric(30,20),
				@higher_unique_transactions					numeric(30,20),
				@lower_unique_people_2plus					numeric(30,20),
				@lower_unique_transactions_2plus			numeric(30,20),
				@higher_unique_people_2plus					numeric(30,20),
				@higher_unique_transactions_2plus			numeric(30,20),
				@lower_unique_people_3plus					numeric(30,20),
				@lower_unique_transactions_3plus			numeric(30,20),
				@higher_unique_people_3plus					numeric(30,20),
				@higher_unique_transactions_3plus			numeric(30,20),
				@attendance_population						numeric(30,20),
				@reach_threshold							numeric(30,20),
				@frequency_week_one							numeric(30,20),
				@frequency_modifier							numeric(30,20),
				@reach_initial								numeric(30,20),
				@reach_final								numeric(30,20),
				@frequency_initial							numeric(30,20),
				@frequency_final							numeric(30,20),
				@frequency_week_one_2plus					numeric(30,20),
				@frequency_modifier_2plus					numeric(30,20),
				@reach_initial_2plus						numeric(30,20),
				@reach_final_2plus							numeric(30,20),
				@frequency_initial_2plus					numeric(30,20),
				@frequency_final_2plus						numeric(30,20),
				@frequency_week_one_3plus					numeric(30,20),
				@frequency_modifier_3plus					numeric(30,20),
				@reach_initial_3plus						numeric(30,20),
				@reach_final_3plus							numeric(30,20),
				@frequency_initial_3plus					numeric(30,20),
				@frequency_final_3plus						numeric(30,20),
				@national_count								int,
				@metro_count								int,
				@regional_count								int,
				@curve_1plus								int,
				@curve_2plus								int,
				@curve_3plus								int


create table #rf_curve_results
(
	weeknum										int					null,
	start_week									datetime			null,
	end_week									datetime			null,
	cinetam_reporting_demographics_desc			varchar(50)			null,
	attendance_estimate							numeric(30,20)		null,
	lower_unique_people							numeric(30,20)		null,
	lower_unique_transactions					numeric(30,20)		null,
	higher_unique_people						numeric(30,20)		null,
	higher_unique_transactions					numeric(30,20)		null,
	lower_unique_people_2plus					numeric(30,20)		null,
	lower_unique_transactions_2plus				numeric(30,20)		null,
	higher_unique_people_2plus					numeric(30,20)		null,
	higher_unique_transactions_2plus			numeric(30,20)		null,
	lower_unique_people_3plus					numeric(30,20)		null,
	lower_unique_transactions_3plus				numeric(30,20)		null,
	higher_unique_people_3plus					numeric(30,20)		null,
	higher_unique_transactions_3plus			numeric(30,20)		null,
	attendance_population						numeric(30,20)		null,
	reach_threshold								numeric(30,20)		null,
	frequency_week_one							numeric(30,20)		null,
	frequency_modifier							numeric(30,20)		null,
	reach_initial								numeric(30,20)		null,
	reach_final									numeric(30,20)		null,
	frequency_initial							numeric(30,20)		null,
	frequency_final								numeric(30,20)		null,
	frequency_week_one_2plus					numeric(30,20)		null,
	frequency_modifier_2plus					numeric(30,20)		null,
	reach_initial_2plus							numeric(30,20)		null,
	reach_final_2plus							numeric(30,20)		null,
	frequency_initial_2plus						numeric(30,20)		null,
	frequency_final_2plus						numeric(30,20)		null,
	frequency_week_one_3plus					numeric(30,20)		null,
	frequency_modifier_3plus					numeric(30,20)		null,
	reach_initial_3plus							numeric(30,20)		null,
	reach_final_3plus							numeric(30,20)		null,
	frequency_initial_3plus						numeric(30,20)		null,
	frequency_final_3plus						numeric(30,20)		null
)

create table #film_markets                
(                
	film_market_no								int     not null                
)     

create table #curves
(                
	curve_no									int     not null                
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

create table #attendance_movio_2plus
(
	weeknum										int					null,
	unique_people								numeric(30,20)		null,
	movio_unique_transactions					numeric(30,20)		null
)
create table #attendance_movio_3plus
(
	weeknum										int					null,
	unique_people								numeric(30,20)		null,
	movio_unique_transactions					numeric(30,20)		null
)

if len(@curves) > 0                
	insert into #curves                
	select * from dbo.f_multivalue_parameter(@curves,',')

select			@curve_1plus = count(curve_no)
from			#curves
where			curve_no = 1

select			@curve_2plus = count(curve_no)
from			#curves
where			curve_no = 2

select			@curve_3plus = count(curve_no)
from			#curves
where			curve_no = 3

if len(@film_markets) > 0                
	insert into #film_markets                
	select * from dbo.f_multivalue_parameter(@film_markets,',')

select			@national_count = count(*)                
from			#film_markets                
where			film_market_no = -100                
                
select			@metro_count = count(*)                
from			#film_markets                
where			film_market_no = -50                
        
select			@regional_count = count(*)                
from			#film_markets                
where			film_market_no = -25                
                
if @metro_count >= 1                
begin                
	delete			#film_markets                
	from			film_market                
	where			#film_markets.film_market_no = film_market.film_market_no                
	and				country_code = @country_code                
	and				regional = 'N'                
                
	insert into		#film_markets                
	select			film_market_no                
	from			film_market                
	where			country_code = @country_code                
	and				regional = 'N'                
end                
                
if @regional_count >= 1                
begin                
	delete			#film_markets                
	from			film_market                
	where			#film_markets.film_market_no = film_market.film_market_no                
	and				country_code = @country_code                
	and				regional = 'Y'                
                
	insert into		#film_markets                
	select			film_market_no                
	from			film_market                
	where			country_code = @country_code                
	and				regional = 'Y'                
end                
          
                
if @national_count >= 1                
begin                
	delete			#film_markets                
	from			film_market                
	where			#film_markets.film_market_no = film_market.film_market_no                
	and				country_code = @country_code                
                
	insert into		#film_markets                
	select			film_market_no                
	from			film_market                
	where			country_code = @country_code                
end     

select			@attendance_estimate = @attendance / @no_weeks

select			@cinetam_reporting_demographics_desc = cinetam_reporting_demographics_desc
from			cinetam_reporting_demographics
where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id


insert into		#rf_curve_results
(				weeknum,
				start_week,
				end_week,
				cinetam_reporting_demographics_desc
)
select			ROW_NUMBER() over (order by screening_date),
				@start_date,
				screening_date,
				@cinetam_reporting_demographics_desc
from			film_screening_dates
where			screening_date between @start_date and dateadd(wk, 51, @start_date)


update			#rf_curve_results
set				attendance_estimate = @attendance_estimate * weeknum

insert into		#population
select			weeknum,
				sum(cinetam_reachfreq_population.population),
				avg(cinetam_reachfreq_population.reach_threshold)
from			cinetam_reachfreq_population
inner join		#rf_curve_results on cinetam_reachfreq_population.screening_date = #rf_curve_results.end_week
inner join		#film_markets on cinetam_reachfreq_population.film_market_no = #film_markets.film_market_no
where			cinetam_reachfreq_population.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
group by		weeknum

insert into		#attendance_movio
select			weeknum,
				count(distinct membership_id),
				sum(unique_transactions)
from			movio_data_randf_summary
inner join		#rf_curve_results on movio_data_randf_summary.screening_date between #rf_curve_results.start_week and #rf_curve_results.end_week
inner join		#film_markets on movio_data_randf_summary.film_market_no = #film_markets.film_market_no
where			movio_data_randf_summary.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
group by		weeknum

insert into		#attendance_movio_2plus
select			weeknum,
				count(distinct membership_id),
				sum(unique_transactions)
from			movio_data_randf_summary
inner join		#rf_curve_results on movio_data_randf_summary.screening_date between #rf_curve_results.start_week and #rf_curve_results.end_week
inner join		#film_markets on movio_data_randf_summary.film_market_no = #film_markets.film_market_no
where			movio_data_randf_summary.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
and				weeknum = 1
and				membership_id in (select			membership_id
									from			movio_data_randf_summary
									inner join		#film_markets on movio_data_randf_summary.film_market_no = #film_markets.film_market_no
									where			movio_data_randf_summary.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
									and				movio_data_randf_summary.screening_date = @start_date
									group by		membership_id
									having			sum(unique_transactions) > 1)
group by		weeknum

insert into		#attendance_movio_3plus
select			weeknum,
				count(distinct membership_id),
				sum(unique_transactions)
from			movio_data_randf_summary
inner join		#rf_curve_results on movio_data_randf_summary.screening_date between #rf_curve_results.start_week and #rf_curve_results.end_week
inner join		#film_markets on movio_data_randf_summary.film_market_no = #film_markets.film_market_no
where			movio_data_randf_summary.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
and				weeknum = 1
and				membership_id in (select			membership_id
									from			movio_data_randf_summary
									inner join		#film_markets on movio_data_randf_summary.film_market_no = #film_markets.film_market_no
									where			movio_data_randf_summary.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
									and				movio_data_randf_summary.screening_date = @start_date
									group by		membership_id
									having			sum(unique_transactions) > 2)
group by		weeknum

insert into		#attendance_movio_2plus
select			weeknum,
				count(distinct membership_id),
				sum(unique_transactions)
from			movio_data_randf_summary
inner join		#rf_curve_results on movio_data_randf_summary.screening_date between #rf_curve_results.start_week and #rf_curve_results.end_week
inner join		#film_markets on movio_data_randf_summary.film_market_no = #film_markets.film_market_no
where			movio_data_randf_summary.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
and				weeknum = 52
and				membership_id in (select			membership_id
									from			movio_data_randf_summary
									inner join		#film_markets on movio_data_randf_summary.film_market_no = #film_markets.film_market_no
									where			movio_data_randf_summary.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
									and				movio_data_randf_summary.screening_date between @start_date and dateadd(wk, 51, @start_date)
									group by		membership_id
									having			sum(unique_transactions) > 1)
group by		weeknum

insert into		#attendance_movio_3plus
select			weeknum,
				count(distinct membership_id),
				sum(unique_transactions)
from			movio_data_randf_summary
inner join		#rf_curve_results on movio_data_randf_summary.screening_date between #rf_curve_results.start_week and #rf_curve_results.end_week
inner join		#film_markets on movio_data_randf_summary.film_market_no = #film_markets.film_market_no
where			movio_data_randf_summary.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
and				weeknum = 52
and				membership_id in (select			membership_id
									from			movio_data_randf_summary
									inner join		#film_markets on movio_data_randf_summary.film_market_no = #film_markets.film_market_no
									where			movio_data_randf_summary.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
									and				movio_data_randf_summary.screening_date between @start_date and dateadd(wk, 51, @start_date)
									group by		membership_id
									having			sum(unique_transactions) > 2)
group by		weeknum

update			#rf_curve_results
set				attendance_estimate = @attendance_estimate * weeknum

/*select			@lower_unique_people = #attendance_movio.unique_people,
				@lower_unique_transactions = #attendance_movio.movio_unique_transactions
from			#attendance_movio
where			weeknum = 1

select			@lower_unique_people_2plus = #attendance_movio_2plus.unique_people,
				@lower_unique_transactions_2plus = #attendance_movio_2plus.movio_unique_transactions
from			#attendance_movio_2plus
where			weeknum = 1

select			@lower_unique_people_3plus = #attendance_movio_3plus.unique_people,
				@lower_unique_transactions_3plus = #attendance_movio_3plus.movio_unique_transactions
from			#attendance_movio_3plus
where			weeknum = 1

select			@higher_unique_people = #attendance_movio.unique_people,
				@higher_unique_transactions = #attendance_movio.movio_unique_transactions
from			#attendance_movio
where			weeknum = @no_weeks

select			@higher_unique_people_2plus = #attendance_movio_2plus.unique_people,
				@higher_unique_transactions_2plus = #attendance_movio_2plus.movio_unique_transactions
from			#attendance_movio_2plus
where			weeknum = @no_weeks

select			@higher_unique_people_3plus = #attendance_movio_3plus.unique_people,
				@higher_unique_transactions_3plus = #attendance_movio_3plus.movio_unique_transactions
from			#attendance_movio_3plus
where			weeknum = @no_weeks*/

update			#rf_curve_results
set				attendance_population = #population.attendance_population,
				reach_threshold = #population.reach_threshold	
from			#rf_curve_results
cross join		#population
where			#population.weeknum = 52

update			#rf_curve_results
set				lower_unique_people = #attendance_movio.unique_people,
				lower_unique_transactions = #attendance_movio.movio_unique_transactions,
				higher_unique_people = #attendance_movio.unique_people,
				higher_unique_transactions = #attendance_movio.movio_unique_transactions
from			#attendance_movio
where			#attendance_movio.weeknum in (1, 52)
and				#attendance_movio.weeknum = #rf_curve_results.weeknum

update			#rf_curve_results
set				lower_unique_people_2plus = #attendance_movio_2plus.unique_people,
				lower_unique_transactions_2plus = #attendance_movio_2plus.movio_unique_transactions,
				higher_unique_people_2plus = #attendance_movio_2plus.unique_people,
				higher_unique_transactions_2plus = #attendance_movio_2plus.movio_unique_transactions
from			#attendance_movio_2plus
where			#attendance_movio_2plus.weeknum in (1, 52)
and				#attendance_movio_2plus.weeknum = #rf_curve_results.weeknum

update			#rf_curve_results
set				lower_unique_people_3plus = #attendance_movio_3plus.unique_people,
				lower_unique_transactions_3plus = #attendance_movio_3plus.movio_unique_transactions,
				higher_unique_people_3plus = #attendance_movio_3plus.unique_people,
				higher_unique_transactions_3plus = #attendance_movio_3plus.movio_unique_transactions
from			#attendance_movio_3plus
where			#attendance_movio_3plus.weeknum in (1, 52)
and				#attendance_movio_3plus.weeknum = #rf_curve_results.weeknum

update			#rf_curve_results
set				lower_unique_people = #attendance_movio.unique_people,
				lower_unique_transactions = #attendance_movio.movio_unique_transactions
from			#attendance_movio
where			#attendance_movio.weeknum = 1
and				#rf_curve_results.weeknum = 52

update			#rf_curve_results
set				lower_unique_people_2plus = #attendance_movio_2plus.unique_people,
				lower_unique_transactions_2plus = #attendance_movio_2plus.movio_unique_transactions
from			#attendance_movio_2plus
where			#attendance_movio_2plus.weeknum = 1
and				#rf_curve_results.weeknum = 52

update			#rf_curve_results
set				lower_unique_people_3plus = #attendance_movio_3plus.unique_people,
				lower_unique_transactions_3plus = #attendance_movio_3plus.movio_unique_transactions
from			#attendance_movio_3plus
where			#attendance_movio_3plus.weeknum = 1
and				#rf_curve_results.weeknum = 52

/*if @no_weeks > 1
begin
	select			@higher_unique_people = (@higher_unique_people - @lower_unique_people) / (@no_weeks - 1),
					@higher_unique_transactions = (@higher_unique_transactions - @lower_unique_transactions) / (@no_weeks - 1),
					@higher_unique_people_2plus = (@higher_unique_people_2plus - @lower_unique_people_2plus) / (@no_weeks - 1),
					@higher_unique_transactions_2plus = (@higher_unique_transactions_2plus - @lower_unique_transactions_2plus) / (@no_weeks - 1),
					@higher_unique_people_3plus = (@higher_unique_people_3plus - @lower_unique_people_3plus) / (@no_weeks - 1),
					@higher_unique_transactions_3plus = (@higher_unique_transactions_3plus - @lower_unique_transactions_3plus) / (@no_weeks - 1)

	update			#rf_curve_results
	set				higher_unique_people = lower_unique_people,
					higher_unique_transactions = lower_unique_transactions, 
					higher_unique_people_2plus = lower_unique_people_2plus,
					higher_unique_transactions_2plus = lower_unique_transactions_2plus,
					higher_unique_people_3plus = lower_unique_people_3plus,
					higher_unique_transactions_3plus = lower_unique_transactions_3plus
	where			weeknum = 1

	update			#rf_curve_results
	set				higher_unique_people = lower_unique_people + (@higher_unique_people * (weeknum - 1)),
					higher_unique_transactions = lower_unique_transactions + (@higher_unique_transactions * (weeknum - 1)),
					higher_unique_people_2plus = lower_unique_people_2plus + (@higher_unique_people_2plus * (weeknum - 1)),
					higher_unique_transactions_2plus = lower_unique_transactions_2plus + (@higher_unique_transactions_2plus * (weeknum - 1)),
					higher_unique_people_3plus = lower_unique_people_3plus + (@higher_unique_people_3plus * (weeknum - 1)),
					higher_unique_transactions_3plus = lower_unique_transactions_3plus + (@higher_unique_transactions_3plus * (weeknum - 1))
	where			weeknum > 1
end*/


/*update			#rf_curve_results
set				higher_unique_people = #attendance_movio.unique_people,
				higher_unique_transactions = #attendance_movio.movio_unique_transactions
from			#rf_curve_results
inner join		#attendance_movio on #rf_curve_results.weeknum = #attendance_movio.weeknum

update			#rf_curve_results
set				higher_unique_people_2plus = #attendance_movio_2plus.unique_people,
				higher_unique_transactions_2plus = #attendance_movio_2plus.movio_unique_transactions
from			#rf_curve_results
inner join		#attendance_movio_2plus on #rf_curve_results.weeknum = #attendance_movio_2plus.weeknum

update			#rf_curve_results
set				higher_unique_people_3plus = #attendance_movio_3plus.unique_people,
				higher_unique_transactions_3plus = #attendance_movio_3plus.movio_unique_transactions
from			#rf_curve_results
inner join		#attendance_movio_3plus on #rf_curve_results.weeknum = #attendance_movio_3plus.weeknum*/

update			#rf_curve_results
set				frequency_week_one = isnull(lower_unique_transactions / lower_unique_people, 1),
				frequency_week_one_2plus = isnull(lower_unique_transactions_2plus / lower_unique_people_2plus, 1),
				frequency_week_one_3plus = isnull(lower_unique_transactions_3plus / lower_unique_people_3plus, 1)
where			weeknum in (1, 52)

update			#rf_curve_results
set				frequency_modifier = 1 / frequency_week_one,
				frequency_modifier_2plus = 2 / frequency_week_one_2plus,
				frequency_modifier_3plus = 3 / frequency_week_one_3plus
where			weeknum in (1, 52)

update			#rf_curve_results
set				frequency_initial = (higher_unique_transactions / higher_unique_people) * frequency_modifier,
				frequency_initial_2plus = (higher_unique_transactions_2plus / higher_unique_people_2plus) * frequency_modifier_2plus,
				frequency_initial_3plus = (higher_unique_transactions_3plus / higher_unique_people_3plus) * frequency_modifier_3plus
where			weeknum in (1, 52)

update			#rf_curve_results
set				reach_initial = attendance_estimate / attendance_population / frequency_initial,
				reach_initial_2plus = attendance_estimate / attendance_population / frequency_initial_2plus,
				reach_initial_3plus = attendance_estimate / attendance_population / frequency_initial_3plus
where			weeknum in (1, 52)

update			#rf_curve_results
set				reach_final = reach_initial,
				frequency_final = frequency_initial,
				reach_final_2plus = reach_initial_2plus,
				frequency_final_2plus = frequency_initial_2plus,
				reach_final_3plus = reach_initial_3plus,
				frequency_final_3plus = frequency_initial_3plus
where			weeknum in (1, 52)

/*update			#rf_curve_results
set				reach_final = reach_threshold,
				frequency_final = attendance_estimate / attendance_population / reach_threshold
where			reach_initial > reach_threshold
and				weeknum in (1, 52)

update			#rf_curve_results
set				reach_final_2plus = reach_threshold,
				frequency_final_2plus = attendance_estimate / attendance_population / reach_threshold
where			reach_initial_2plus > reach_threshold
and				weeknum in (1, 52)

update			#rf_curve_results
set				reach_final_3plus = reach_threshold,
				frequency_final_3plus = attendance_estimate / attendance_population / reach_threshold
where			reach_initial_3plus > reach_threshold
and				weeknum in (1, 52)*/

select			@frequency_week_one = frequency_final,
				@frequency_week_one_2plus = frequency_final_2plus,
				@frequency_week_one_3plus = frequency_final_3plus
from			#rf_curve_results
where			weeknum = 1

select			@frequency_final = frequency_final,
				@frequency_final_2plus = frequency_final_2plus,
				@frequency_final_3plus = frequency_final_3plus
from			#rf_curve_results
where			weeknum = 52

select			@frequency_final = (@frequency_final - @frequency_week_one)  / 51,
				@frequency_final_2plus = (@frequency_final_2plus - @frequency_week_one_2plus) / 51,
				@frequency_final_3plus = (@frequency_final_3plus - @frequency_week_one_3plus) / 51

update			#rf_curve_results
set				frequency_initial = @frequency_week_one + (@frequency_final * (weeknum - 1)),
				frequency_initial_2plus = @frequency_week_one_2plus + (@frequency_final_2plus * (weeknum - 1)),
				frequency_initial_3plus = @frequency_week_one_3plus + (@frequency_final_3plus * (weeknum - 1))
where			weeknum between 2 and 51

update			#rf_curve_results
set				reach_initial = attendance_estimate / attendance_population / frequency_initial,
				reach_initial_2plus = attendance_estimate / attendance_population / frequency_initial_2plus,
				reach_initial_3plus = attendance_estimate / attendance_population / frequency_initial_3plus
where			weeknum > 1

update			#rf_curve_results
set				reach_final = reach_initial,
				frequency_final = frequency_initial,
				reach_final_2plus = reach_initial_2plus,
				frequency_final_2plus = frequency_initial_2plus,
				reach_final_3plus = reach_initial_3plus,
				frequency_final_3plus = frequency_initial_3plus
where			weeknum > 1

update			#rf_curve_results
set				reach_final = reach_threshold,
				frequency_final = attendance_estimate / attendance_population / reach_threshold
where			reach_initial > reach_threshold
and				weeknum > 1

update			#rf_curve_results
set				reach_final_2plus = reach_threshold,
				frequency_final_2plus = attendance_estimate / attendance_population / reach_threshold
where			reach_initial_2plus > reach_threshold
and				weeknum > 1

update			#rf_curve_results
set				reach_final_3plus = reach_threshold,
				frequency_final_3plus = attendance_estimate / attendance_population / reach_threshold
where			reach_initial_3plus > reach_threshold
and				weeknum > 1

if @curve_1plus = 0
begin
	update			#rf_curve_results
	set				frequency_week_one = null,
					frequency_modifier = null,
					reach_initial = null,
					reach_final = null,
					frequency_initial = null,
					frequency_final = null,
					lower_unique_people = null,
					lower_unique_transactions = null,
					higher_unique_people = null,
					higher_unique_transactions = null
end

if @curve_2plus = 0
begin
	update			#rf_curve_results
	set				frequency_week_one_2plus = null,
					frequency_modifier_2plus = null,
					reach_initial_2plus = null,
					reach_final_2plus = null,
					frequency_initial_2plus = null,
					frequency_final_2plus = null,
					lower_unique_people_2plus = null,
					lower_unique_transactions_2plus = null,
					higher_unique_people_2plus = null,
					higher_unique_transactions_2plus = null
end

if @curve_3plus = 0
begin
	update			#rf_curve_results
	set				frequency_week_one_3plus = null,
					frequency_modifier_3plus = null,
					reach_initial_3plus = null,
					reach_final_3plus = null,
					frequency_initial_3plus = null,
					frequency_final_3plus = null,
					lower_unique_people_3plus = null,
					lower_unique_transactions_3plus = null,
					higher_unique_people_3plus = null,
					higher_unique_transactions_3plus = null
end

select			* 
from			#rf_curve_results
where			weeknum <= @no_weeks

return 0
GO
