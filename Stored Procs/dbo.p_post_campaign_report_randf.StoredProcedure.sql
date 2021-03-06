/****** Object:  StoredProcedure [dbo].[p_post_campaign_report_randf]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_post_campaign_report_randf]
GO
/****** Object:  StoredProcedure [dbo].[p_post_campaign_report_randf]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_post_campaign_report_randf]	@campaign_no							int,
													@screening_date							datetime,
													@product								int,
													@cinetam_reporting_demographics_id		int,
													@override_sold_demo						int,
													@inclusion_id							int,
													@include_randf							int

--with recompile
																				
as

declare		@error										int,
			@inclusion_type								int,
			@multiple_demos								int,
			@product_desc								varchar(200),
			@cinetam_reporting_demographics_desc		varchar(50),
			@min_screening_date							datetime,
			@max_screening_date							datetime,
			@active_count								int,
			@sum_charge									numeric(20,12),
			@country_code								char(1),
			@week_one_unique_people						numeric(20,12),
			@week_one_unique_transactions				numeric(20,12),
			@week_one_frequency							numeric(20,12),
			@week_one_attendance						numeric(20,12),
			@week_fifty_two_unique_people				numeric(20,12),
			@week_fifty_two_unique_transactions			numeric(20,12),
			@week_fifty_two_frequency					numeric(20,12),
			@frequency_modifier							numeric(20,12),
			@unique_people								numeric(20,12),
			@unique_transactions						numeric(20,12),
			@frequency									numeric(20,12),
			@attendance									numeric(20,12),
			@rm_population								numeric(20,12),
			@reach										numeric(20,12),
			@unique_people_multi_occ					numeric(20,12),
			@unique_transactions_multi_occ				numeric(20,12),
			@total_multi_occ							int,
			@reach_threshold							numeric(20,12),
			@attendance_increment						numeric(20,12)



--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
set nocount on


create table #randf
(
	product_desc						varchar(200)		not null,
	demo_desc							varchar(100)		not null,
	week_one_unique_people				numeric(20,12)		null,
	week_one_unique_transactions		numeric(20,12)		null,
	week_one_frequency					numeric(20,12)		null,
	frequency_modifier					numeric(20,12)		null,
	unique_people						numeric(20,12)		null,
	unique_transactions					numeric(20,12)		null,
	frequency							numeric(20,12)		null,
	attendance							numeric(20,12)		null,
	rm_population						numeric(20,12)		null,
	reach								numeric(20,12)		null
)

if @include_randf = 0 or @product = 8
begin
	select			product_desc,
					demo_desc,
					week_one_unique_people,
					week_one_unique_transactions,
					week_one_frequency,
					frequency_modifier,
					unique_people,
					unique_transactions,
					frequency	,
					attendance,
					rm_population,
					reach
	from			#randf

	return 0
end

create table #weekly
(
	product_desc			varchar(200)			not null,
	demo_desc				varchar(100)			not null,
	actual_attendance		numeric(20,8)			not null,
	screening_date			datetime				not null
)

create table #inclusions
(
	inclusion_id		int			not null
)
	

/*
 * Products:
 * 1 Follow Film
 * 2 MAP
 * 3 TAP
 * 4 Roadblock 
 * 5 Digilite
 * 6 CineAsia
 * 7 First Run
 * 8 Campaign Summary
 */

if @product = 1 -- follow film
begin
	select @inclusion_type = 29
	select @product_desc = 'Follow Film'
end
else if @product = 2 -- MAP
begin
	select @inclusion_type = 32
	select @product_desc = 'MAP'
end
else if @product = 3 -- TAP
begin
	select @inclusion_type = 24
	select @product_desc = 'TAP'
end
else if @product = 4  -- Roadblock
begin
	select @inclusion_type = 30
	select @product_desc = 'Roadblock'
end
else if @product = 5 -- Digilite
begin
	select @product_desc = 'Digilite'
end
else if @product = 6 -- Cineasia
begin
	select @inclusion_type = 30
	select @product_desc = 'Access Asia'
end
else if @product = 7 --First Run
begin
	select @inclusion_type = 31
	select @product_desc = 'First Run'
end
else if @product = 8 -- Summary
begin
	select @product_desc = 'Entire Campaign Summary'
end

if @product = 5
begin
	if @override_sold_demo = 0
	begin
		select			@multiple_demos = count(distinct cinetam_reporting_demographics_id)
		from			inclusion
		inner join		inclusion_cinetam_settings on inclusion.inclusion_id = inclusion_cinetam_settings.inclusion_id
		where			inclusion.campaign_no = @campaign_no

		if @multiple_demos > 1 and @override_sold_demo = 0
		begin
			select @cinetam_reporting_demographics_id  = 0
		end
		else
		begin
			select			@cinetam_reporting_demographics_id = max(cinetam_reporting_demographics_id)
			from			inclusion
			inner join		inclusion_cinetam_settings on inclusion.inclusion_id = inclusion_cinetam_settings.inclusion_id
			where			inclusion.campaign_no = @campaign_no
		end
	end

	select			@cinetam_reporting_demographics_id = ISNULL(@cinetam_reporting_demographics_id, 0)

	select			@cinetam_reporting_demographics_desc = cinetam_reporting_demographics_desc
	from			cinetam_reporting_demographics
	where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	insert into		#inclusions
	select			package_id
	from			cinelight_package
	where			campaign_no = @campaign_no
	and				(@inclusion_id is null
	or				cinelight_package.package_id = @inclusion_id)

	--digilite
	insert into		#weekly
	select			@product_desc,
					@cinetam_reporting_demographics_desc,
					sum(attendance),
					screening_date
	from			v_film_campaign_pcr_details	
	inner join		v_film_campaign_pcr_attendance_digilite on v_film_campaign_pcr_details.campaign_no = v_film_campaign_pcr_attendance_digilite.campaign_no
	inner join		#inclusions on v_film_campaign_pcr_attendance_digilite.package_id = #inclusions.inclusion_id
	where			v_film_campaign_pcr_details.campaign_no = @campaign_no
	and				v_film_campaign_pcr_attendance_digilite.screening_date <= @screening_date
	and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	group by		v_film_campaign_pcr_attendance_digilite.screening_date
end
else if @product = 8
begin
	if @override_sold_demo = 0
	begin

		select			@multiple_demos = count(distinct cinetam_reporting_demographics_id)
		from			inclusion
		inner join		inclusion_cinetam_settings on inclusion.inclusion_id = inclusion_cinetam_settings.inclusion_id
		where			inclusion.campaign_no = @campaign_no

		if @multiple_demos > 1 and @override_sold_demo = 0
		begin
			select @cinetam_reporting_demographics_id  = 0
		end
		else
		begin
			select			@cinetam_reporting_demographics_id = max(cinetam_reporting_demographics_id)
			from			inclusion
			inner join		inclusion_cinetam_settings on inclusion.inclusion_id = inclusion_cinetam_settings.inclusion_id
			where			inclusion.campaign_no = @campaign_no
		end
	end
	
	select			@cinetam_reporting_demographics_desc = cinetam_reporting_demographics_desc
	from			cinetam_reporting_demographics
	where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	insert into		#weekly
	select			@product_desc,
					@cinetam_reporting_demographics_desc,
					sum(attendance),
					screening_date
	from			(select			v_film_campaign_pcr_attendance_digilite.screening_date,
									sum(attendance) as attendance
					from			v_film_campaign_pcr_attendance_digilite 
					where			v_film_campaign_pcr_attendance_digilite.campaign_no = @campaign_no
					and				v_film_campaign_pcr_attendance_digilite.screening_date <= @screening_date
					and				v_film_campaign_pcr_attendance_digilite.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
					group by		v_film_campaign_pcr_attendance_digilite.screening_date
					union all
					select 			inclusion_cinetam_attendance.screening_date,
									sum(attendance) as attendance
					from			inclusion_cinetam_attendance
					where			inclusion_cinetam_attendance.campaign_no = @campaign_no
					and				inclusion_cinetam_attendance.screening_date <= @screening_date
					and				inclusion_cinetam_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
					group by		inclusion_cinetam_attendance.screening_date) as temp_summary_table
	group by		screening_date
end
else
begin
	insert into		#inclusions
	select			inclusion_id
	from			v_film_campaign_pcr_inclusion_details
	where			campaign_no = @campaign_no
	and				(@inclusion_id is null
	or				v_film_campaign_pcr_inclusion_details.inclusion_id = @inclusion_id)
	and				inclusion_type = @inclusion_type
	and				(@product in (1,2,3,5,7,8)
	or				(@product = 4
	and				cineasia_count = 0)
	or				(@product = 6
	and				cineasia_count > 0))

	if @override_sold_demo = 0
	begin
		select			@multiple_demos = count(distinct cinetam_reporting_demographics_id)
		from			inclusion_cinetam_settings 
		inner join		#inclusions on inclusion_cinetam_settings.inclusion_id = #inclusions.inclusion_id

		if @multiple_demos > 1 and @override_sold_demo = 0
		begin
			select @cinetam_reporting_demographics_id  = 0
		end
		else
		begin
			select			@cinetam_reporting_demographics_id = max(cinetam_reporting_demographics_id)
			from			inclusion_cinetam_settings
			inner join		#inclusions on inclusion_cinetam_settings.inclusion_id = #inclusions.inclusion_id
		end
	end

	select			@cinetam_reporting_demographics_desc = cinetam_reporting_demographics_desc
	from			cinetam_reporting_demographics
	where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	insert into		#weekly
	select			@product_desc,
					@cinetam_reporting_demographics_desc,
					sum(attendance),
					screening_date
	from			inclusion_cinetam_attendance
	inner join		#inclusions on inclusion_cinetam_attendance.inclusion_id = #inclusions.inclusion_id
	where			inclusion_cinetam_attendance.screening_date <= @screening_date
	and				inclusion_cinetam_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	group by		inclusion_cinetam_attendance.screening_date
end

select			@attendance  = sum(actual_attendance),
				@cinetam_reporting_demographics_desc = max(demo_desc)
from			#weekly

select			@week_one_attendance = SUM(actual_attendance)
from			#weekly 
group by		screening_date			
having			screening_date = MIN(screening_date)

select			@country_code = country_code
from			film_campaign,
				branch
where			film_campaign.branch_code = branch.branch_code
and				film_campaign.campaign_no = @campaign_no 


if @product = 5
begin
	--get start and end dates
	select			@min_screening_date = min(screening_date),
					@max_screening_date = max(screening_date)
	from			#weekly

	--count total unique_people_across_campaign
	select			@unique_people = count(distinct membership_id),
					@unique_transactions = sum(isnull(unique_transactions,0))
	from			v_film_campaign_pcr_movio
	inner join		cinetam_cinelight_complex_attendance on	v_film_campaign_pcr_movio.complex_id = cinetam_cinelight_complex_attendance.complex_id
	and				v_film_campaign_pcr_movio.screening_date = cinetam_cinelight_complex_attendance.screening_date
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = cinetam_cinelight_complex_attendance.cinetam_reporting_demographics_id
	inner join		#inclusions on cinetam_cinelight_complex_attendance.package_id = #inclusions.inclusion_id
	where			v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				cinetam_cinelight_complex_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				v_film_campaign_pcr_movio.screening_date between @min_screening_date and @max_screening_date
	and				cinetam_cinelight_complex_attendance.screening_date between @min_screening_date and @max_screening_date

	--count total unique_people_across_campaign
	select 			@week_one_unique_people = count(distinct membership_id),
					@week_one_unique_transactions = isnull(sum(unique_transactions),0)
	from			v_film_campaign_pcr_movio
	inner join		cinetam_cinelight_complex_attendance on	v_film_campaign_pcr_movio.complex_id = cinetam_cinelight_complex_attendance.complex_id
	and				v_film_campaign_pcr_movio.screening_date = cinetam_cinelight_complex_attendance.screening_date
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = cinetam_cinelight_complex_attendance.cinetam_reporting_demographics_id
	inner join		#inclusions on cinetam_cinelight_complex_attendance.package_id = #inclusions.inclusion_id
	where			v_film_campaign_pcr_movio.country_code = @country_code
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				v_film_campaign_pcr_movio.screening_date = @min_screening_date
	and				cinetam_cinelight_complex_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				cinetam_cinelight_complex_attendance.screening_date = @min_screening_date


	select			@rm_population = sum(cinetam_reachfreq_population.population),
					@reach_threshold = avg(cinetam_reachfreq_population.reach_threshold)
	from			cinetam_reachfreq_population
	inner join		(select			distinct film_market_no
					from			v_film_campaign_pcr_details	
					inner join		v_film_campaign_pcr_attendance_digilite on v_film_campaign_pcr_details.campaign_no = v_film_campaign_pcr_attendance_digilite.campaign_no
					inner join		#inclusions on v_film_campaign_pcr_attendance_digilite.package_id = #inclusions.inclusion_id
					inner join		complex on v_film_campaign_pcr_attendance_digilite.complex_id = complex.complex_id
					where			v_film_campaign_pcr_details.campaign_no = @campaign_no
					and				v_film_campaign_pcr_attendance_digilite.screening_date <= @screening_date
					and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
					group by		film_market_no) as temp_table 
	on				cinetam_reachfreq_population.film_market_no = temp_table.film_market_no
	and				cinetam_reachfreq_population.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	where			cinetam_reachfreq_population.country_code = @country_code
	and				cinetam_reachfreq_population.screening_date = @max_screening_date
end
else
begin
	--get start and end dates
	select			@min_screening_date = min(screening_date),
					@max_screening_date = max(screening_date)
	from			inclusion_cinetam_complex_attendance
	inner join		#inclusions on inclusion_cinetam_complex_attendance.inclusion_id = #inclusions.inclusion_id
	and				screening_date <= @screening_date

	--count total unique_people_across_campaign
	select			@unique_people = count(distinct membership_id),
					@unique_transactions = sum(isnull(unique_transactions,0))
	from			v_film_campaign_pcr_movio
	inner join		(select			complex_id, 
									movie_id,
									screening_date, 
									cinetam_reporting_demographics_id
					from			inclusion_cinetam_complex_attendance
					inner join		#inclusions on inclusion_cinetam_complex_attendance.inclusion_id = #inclusions.inclusion_id
					group by		complex_id, 
									movie_id,
									screening_date, 
									cinetam_reporting_demographics_id) as temp_inclusions
	on				v_film_campaign_pcr_movio.complex_id = temp_inclusions.complex_id
	and				v_film_campaign_pcr_movio.movie_id = temp_inclusions.movie_id
	and				v_film_campaign_pcr_movio.screening_date = temp_inclusions.screening_date
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = temp_inclusions.cinetam_reporting_demographics_id
	where			v_film_campaign_pcr_movio.country_code = @country_code
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				v_film_campaign_pcr_movio.screening_date between @min_screening_date and @max_screening_date
	and				temp_inclusions.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				temp_inclusions.screening_date between @min_screening_date and @max_screening_date
	
/*	select			@unique_people = count(distinct membership_id),
					@unique_transactions = sum(isnull(unique_transactions,0))
	from			v_film_campaign_pcr_movio
	inner join		inclusion_cinetam_complex_attendance on	v_film_campaign_pcr_movio.complex_id = inclusion_cinetam_complex_attendance.complex_id
	and				v_film_campaign_pcr_movio.movie_id = inclusion_cinetam_complex_attendance.movie_id
	and				v_film_campaign_pcr_movio.screening_date = inclusion_cinetam_complex_attendance.screening_date
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = inclusion_cinetam_complex_attendance.cinetam_reporting_demographics_id
	inner join		v_film_campaign_pcr_inclusion_details on inclusion_cinetam_complex_attendance.inclusion_id = v_film_campaign_pcr_inclusion_details.inclusion_id
	inner join		#inclusions on inclusion_cinetam_complex_attendance.inclusion_id = #inclusions.inclusion_id
	where			v_film_campaign_pcr_movio.country_code = @country_code
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				v_film_campaign_pcr_movio.screening_date between @min_screening_date and @max_screening_date
	and				inclusion_cinetam_complex_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				inclusion_cinetam_complex_attendance.screening_date between @min_screening_date and @max_screening_date
*/

	--count total unique_people_across_campaign
	select			@week_one_unique_people = count(distinct membership_id),
					@week_one_unique_transactions = sum(isnull(unique_transactions,0))
	from			v_film_campaign_pcr_movio
	inner join		(select			complex_id, 
									movie_id,
									screening_date, 
									cinetam_reporting_demographics_id
					from			inclusion_cinetam_complex_attendance
					inner join		#inclusions on inclusion_cinetam_complex_attendance.inclusion_id = #inclusions.inclusion_id
					group by		complex_id, 
									movie_id,
									screening_date, 
									cinetam_reporting_demographics_id) as temp_inclusions
	on				v_film_campaign_pcr_movio.complex_id = temp_inclusions.complex_id
	and				v_film_campaign_pcr_movio.movie_id = temp_inclusions.movie_id
	and				v_film_campaign_pcr_movio.screening_date = temp_inclusions.screening_date
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = temp_inclusions.cinetam_reporting_demographics_id
	where			v_film_campaign_pcr_movio.country_code = @country_code
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				v_film_campaign_pcr_movio.screening_date between @min_screening_date and @max_screening_date
	and				temp_inclusions.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				temp_inclusions.screening_date = @min_screening_date

/*	select 			@week_one_unique_people = count(distinct membership_id),
					@week_one_unique_transactions = isnull(sum(unique_transactions),0)
	from			v_film_campaign_pcr_movio
	inner join		inclusion_cinetam_complex_attendance on	v_film_campaign_pcr_movio.complex_id = inclusion_cinetam_complex_attendance.complex_id
	and				v_film_campaign_pcr_movio.movie_id = inclusion_cinetam_complex_attendance.movie_id
	and				v_film_campaign_pcr_movio.screening_date = inclusion_cinetam_complex_attendance.screening_date
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = inclusion_cinetam_complex_attendance.cinetam_reporting_demographics_id
	inner join		v_film_campaign_pcr_inclusion_details on inclusion_cinetam_complex_attendance.inclusion_id = v_film_campaign_pcr_inclusion_details.inclusion_id
	inner join		#inclusions on inclusion_cinetam_complex_attendance.inclusion_id = #inclusions.inclusion_id
	where			v_film_campaign_pcr_movio.country_code = @country_code
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				v_film_campaign_pcr_movio.screening_date = @min_screening_date
	and				inclusion_cinetam_complex_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				inclusion_cinetam_complex_attendance.screening_date = @min_screening_date
*/

	select			@rm_population = sum(cinetam_reachfreq_population.population),
					@reach_threshold = avg(cinetam_reachfreq_population.reach_threshold)
	from			cinetam_reachfreq_population
	inner join		(select			film_market_no
					from			inclusion_cinetam_complex_attendance
					inner join		v_film_campaign_pcr_inclusion_details on inclusion_cinetam_complex_attendance.inclusion_id = v_film_campaign_pcr_inclusion_details.inclusion_id
					inner join		complex on inclusion_cinetam_complex_attendance.complex_id = complex.complex_id
					inner join		#inclusions on v_film_campaign_pcr_inclusion_details.inclusion_id = #inclusions.inclusion_id
					where			inclusion_cinetam_complex_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
					and				inclusion_cinetam_complex_attendance.screening_date between @min_screening_date and @max_screening_date
					group by		film_market_no) as temp_table 
	on				cinetam_reachfreq_population.film_market_no = temp_table.film_market_no
	where			cinetam_reachfreq_population.country_code = @country_code
	and				cinetam_reachfreq_population.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				cinetam_reachfreq_population.screening_date = @max_screening_date
end


if @week_one_unique_people > 0
	select			@week_one_frequency	= @week_one_unique_transactions / @week_one_unique_people
	
select			@week_one_frequency	= isnull(@week_one_frequency, 1)

select			@frequency_modifier		= 1 /  @week_one_frequency

select			@frequency				= (@unique_transactions / @unique_people) * @frequency_modifier

select			@reach = @attendance / @rm_population / @frequency

if @reach > @reach_threshold
begin
	select			@reach = @reach_threshold
	select			@frequency = @attendance / @rm_population / @reach
end

select			@attendance_increment = (@attendance - @week_one_attendance) / 51	


insert into	#randf
values			(
					@product_desc,
					@cinetam_reporting_demographics_desc,
					@week_one_unique_people,
					@week_one_unique_transactions,
					@week_one_frequency,
					@frequency_modifier,
					@unique_people,
					@unique_transactions,
					@frequency	,
					@attendance,
					@rm_population,
					@reach
					)	


select			product_desc,
					demo_desc,
					week_one_unique_people,
					week_one_unique_transactions,
					week_one_frequency,
					frequency_modifier,
					unique_people,
					unique_transactions,
					frequency	,
					attendance,
					rm_population,
					reach
from				#randf

return 0
GO
