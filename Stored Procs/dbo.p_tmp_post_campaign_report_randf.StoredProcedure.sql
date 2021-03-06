/****** Object:  StoredProcedure [dbo].[p_tmp_post_campaign_report_randf]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_tmp_post_campaign_report_randf]
GO
/****** Object:  StoredProcedure [dbo].[p_tmp_post_campaign_report_randf]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_tmp_post_campaign_report_randf]	@campaign_no							int,
												@screening_date							datetime,
												@product								int,
												@cinetam_reporting_demographics_id		int,
												@override_sold_demo						int,
												@inclusion_id							int,
												@include_randf							int
																				
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
			@frequency_modifier							numeric(20,12),
			@unique_people								numeric(20,12),
			@unique_transactions						numeric(20,12),
			@frequency									numeric(20,12),
			@attendance									numeric(20,12),
			@rm_population								numeric(20,12),
			@reach										numeric(20,12),
			@unique_people_multi_occ					numeric(20,12),
			@unique_transactions_multi_occ				numeric(20,12),
			@total_multi_occ							int

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

if @include_randf = 0
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
	actual_attendance		numeric(20,8)			not null
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
			select @cinetam_reporting_demographics_id  = 0
		else
			select			@cinetam_reporting_demographics_id = max(cinetam_reporting_demographics_id)
			from			inclusion
			inner join		inclusion_cinetam_settings on inclusion.inclusion_id = inclusion_cinetam_settings.inclusion_id
			where			inclusion.campaign_no = @campaign_no
	end

	select			@cinetam_reporting_demographics_id = ISNULL(@cinetam_reporting_demographics_id, 0)

	select			@cinetam_reporting_demographics_desc = cinetam_reporting_demographics_desc
	from			cinetam_reporting_demographics
	where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	--digilite
	insert into		#weekly
	select			@product_desc,
					@cinetam_reporting_demographics_desc,
					sum(attendance)
	from			v_film_campaign_pcr_details	
	inner join		v_film_campaign_pcr_attendance_digilite on v_film_campaign_pcr_details.campaign_no = v_film_campaign_pcr_attendance_digilite.campaign_no
	inner join		v_film_campaign_pcr_digilite_details on v_film_campaign_pcr_attendance_digilite.package_id = v_film_campaign_pcr_digilite_details.package_id  and v_film_campaign_pcr_attendance_digilite.complex_id = v_film_campaign_pcr_digilite_details.complex_id and v_film_campaign_pcr_attendance_digilite.screening_date = v_film_campaign_pcr_digilite_details.screening_date
	where			v_film_campaign_pcr_details.campaign_no = @campaign_no
	and				v_film_campaign_pcr_attendance_digilite.screening_date <= @screening_date
	and				(@inclusion_id is null
	or				v_film_campaign_pcr_attendance_digilite.package_id = @inclusion_id)
	and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
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
			select @cinetam_reporting_demographics_id  = 0
		else
			select			@cinetam_reporting_demographics_id = max(cinetam_reporting_demographics_id)
			from			inclusion
			inner join		inclusion_cinetam_settings on inclusion.inclusion_id = inclusion_cinetam_settings.inclusion_id
			where			inclusion.campaign_no = @campaign_no
	end

	select			@cinetam_reporting_demographics_desc = cinetam_reporting_demographics_desc
	from			cinetam_reporting_demographics
	where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	insert into		#weekly
	select				@product_desc,
							@cinetam_reporting_demographics_desc,
							sum(attendance)
	from					(select 				sum(attendance) as attendance,
													convert(varchar(6), v_film_campaign_pcr_details.campaign_no) + ' - ' + product_desc as campaign_desc,
													client_name,
													client_product_desc,
													agency_name,
													sum(charge_rate_sum) as charge_rate_sum
							from					v_film_campaign_pcr_details	
							inner join			v_film_campaign_pcr_attendance_digilite on v_film_campaign_pcr_details.campaign_no = v_film_campaign_pcr_attendance_digilite.campaign_no
							inner join			v_film_campaign_pcr_digilite_details on v_film_campaign_pcr_attendance_digilite.package_id = v_film_campaign_pcr_digilite_details.package_id  and v_film_campaign_pcr_attendance_digilite.complex_id = v_film_campaign_pcr_digilite_details.complex_id and v_film_campaign_pcr_attendance_digilite.screening_date = v_film_campaign_pcr_digilite_details.screening_date
							where				v_film_campaign_pcr_details.campaign_no = @campaign_no
							and					v_film_campaign_pcr_attendance_digilite.screening_date <= @screening_date
							and					v_film_campaign_pcr_attendance_digilite.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
							group by			v_film_campaign_pcr_details.campaign_no,
													product_desc,
													client_name,
													client_product_desc,
													agency_name
							union all
							select 				sum(attendance) as attendance,
													convert(varchar(6), v_film_campaign_pcr_details.campaign_no) + ' - ' + product_desc as campaign_desc,
													client_name,
													client_product_desc,
													agency_name,
													max(charge_rate_sum) as charge_rate_sum
							from					v_film_campaign_pcr_details	
							inner join			v_inclusion_cinetam_attendance on v_film_campaign_pcr_details.campaign_no = v_inclusion_cinetam_attendance.campaign_no
							inner join			v_film_campaign_pcr_inclusion_details on v_inclusion_cinetam_attendance.inclusion_id = v_film_campaign_pcr_inclusion_details.inclusion_id
							where				v_film_campaign_pcr_details.campaign_no = @campaign_no
							and					v_inclusion_cinetam_attendance.screening_date <= @screening_date
							and					v_inclusion_cinetam_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
							group by			v_film_campaign_pcr_details.campaign_no,
													product_desc,
													client_name,
													client_product_desc,
													agency_name) as temp_summary_table
end
else
begin
	if @override_sold_demo = 0
	begin
		select			@multiple_demos = count(distinct cinetam_reporting_demographics_id)
		from				inclusion
		inner join		inclusion_cinetam_settings on inclusion.inclusion_id = inclusion_cinetam_settings.inclusion_id
		inner join		v_film_campaign_pcr_inclusion_details on inclusion.inclusion_id = v_film_campaign_pcr_inclusion_details.inclusion_id
		where			inclusion.campaign_no = @campaign_no
		and				(@inclusion_id is null
		or					inclusion_cinetam_settings.inclusion_id = @inclusion_id)
		and				inclusion.inclusion_type = @inclusion_type
		and				(@product in (1,2,3,5,7,8)
		or					(@product = 4
		and				cineasia_count = 0)
		or					(@product = 6
		and				cineasia_count > 0))

		if @multiple_demos > 1 and @override_sold_demo = 0
			select @cinetam_reporting_demographics_id  = 0
		else
			select			@cinetam_reporting_demographics_id = max(cinetam_reporting_demographics_id)
			from				inclusion
			inner join		inclusion_cinetam_settings on inclusion.inclusion_id = inclusion_cinetam_settings.inclusion_id
			inner join		v_film_campaign_pcr_inclusion_details on inclusion.inclusion_id = v_film_campaign_pcr_inclusion_details.inclusion_id
			where			inclusion.campaign_no = @campaign_no
			and				(@inclusion_id is null
			or					inclusion_cinetam_settings.inclusion_id = @inclusion_id)
			and				inclusion.inclusion_type = @inclusion_type
			and				(@product in (1,2,3,5,7,8)
			or					(@product = 4
			and				cineasia_count = 0)
			or					(@product = 6
			and				cineasia_count > 0))
	end
	
	insert into		#weekly
	select				@product_desc,
							cinetam_reporting_demographics_desc,
							sum(attendance)
	from					v_film_campaign_pcr_details	
	inner join			v_inclusion_cinetam_attendance on v_film_campaign_pcr_details.campaign_no = v_inclusion_cinetam_attendance.campaign_no
	inner join			v_film_campaign_pcr_inclusion_details on v_inclusion_cinetam_attendance.inclusion_id = v_film_campaign_pcr_inclusion_details.inclusion_id 
	inner join			cinetam_reporting_demographics on v_inclusion_cinetam_attendance.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
	where				v_film_campaign_pcr_details.campaign_no = @campaign_no
	and					v_inclusion_cinetam_attendance.screening_date <= @screening_date
	and					v_inclusion_cinetam_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and					(@inclusion_id is null
	or						v_inclusion_cinetam_attendance.inclusion_id = @inclusion_id)
	and					v_film_campaign_pcr_inclusion_details.inclusion_type = @inclusion_type
	and					(@product in (1,2,3,5,7,8)
	or						(@product = 4
	and					cineasia_count = 0)
	or						(@product = 6
	and					cineasia_count > 0))
	group by			cinetam_reporting_demographics_desc
end

select			@attendance  = sum(actual_attendance),
					@cinetam_reporting_demographics_desc = max(demo_desc)
from				#weekly 

select			@country_code = country_code
from				film_campaign,
					branch
where			film_campaign.branch_code = branch.branch_code
and				film_campaign.campaign_no = @campaign_no 


if @product = 5
begin
	--get start and end dates
	select			@min_screening_date = min(screening_date),
					@max_screening_date = max(screening_date)
	from			cinetam_cinelight_complex_attendance
	where			cinetam_cinelight_complex_attendance.campaign_no = @campaign_no
	and				(@inclusion_id is null
	or				cinetam_cinelight_complex_attendance.package_id = @inclusion_id)
	and				screening_date <= @screening_date

	--count total unique_people_across_campaign
	select			@unique_people = count(distinct membership_id),
					@unique_transactions = sum(isnull(unique_transactions,0))
	from			v_film_campaign_pcr_movio
	inner join		cinetam_cinelight_complex_attendance on	v_film_campaign_pcr_movio.complex_id = cinetam_cinelight_complex_attendance.complex_id
	and				v_film_campaign_pcr_movio.screening_date = cinetam_cinelight_complex_attendance.screening_date
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = cinetam_cinelight_complex_attendance.cinetam_reporting_demographics_id
	where			v_film_campaign_pcr_movio.country_code = @country_code
	and				cinetam_cinelight_complex_attendance.campaign_no = @campaign_no
	and				(@inclusion_id is null
	or				cinetam_cinelight_complex_attendance.package_id = @inclusion_id)
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				v_film_campaign_pcr_movio.screening_date between @min_screening_date and @max_screening_date

	--count total unique_people_across_campaign
	select 			@week_one_unique_people = count(distinct membership_id),
					@week_one_unique_transactions = isnull(sum(unique_transactions),0)
	from			v_film_campaign_pcr_movio
	inner join		cinetam_cinelight_complex_attendance on	v_film_campaign_pcr_movio.complex_id = cinetam_cinelight_complex_attendance.complex_id
	and				v_film_campaign_pcr_movio.screening_date = cinetam_cinelight_complex_attendance.screening_date
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = cinetam_cinelight_complex_attendance.cinetam_reporting_demographics_id
	where			v_film_campaign_pcr_movio.country_code = @country_code
	and				cinetam_cinelight_complex_attendance.campaign_no = @campaign_no
	and				(@inclusion_id is null
	or				cinetam_cinelight_complex_attendance.package_id = @inclusion_id)
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				v_film_campaign_pcr_movio.screening_date = @min_screening_date

	select			@rm_population = sum(cinetam_reachfreq_population.population)
	from			cinetam_reachfreq_population
	inner join		(select			film_market_no,
											cinetam_reporting_demographics_id,
											max(screening_date) as screening_date
						from				cinetam_cinelight_complex_attendance
						inner join		complex on cinetam_cinelight_complex_attendance.complex_id = complex.complex_id
						where			cinetam_cinelight_complex_attendance.campaign_no = @campaign_no
						and				(@inclusion_id is null
						or					cinetam_cinelight_complex_attendance.package_id = @inclusion_id)
						and				cinetam_cinelight_complex_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
						and				cinetam_cinelight_complex_attendance.screening_date between @min_screening_date and @max_screening_date
						group by		film_market_no,
											cinetam_reporting_demographics_id) as temp_table 
	on					cinetam_reachfreq_population.film_market_no = temp_table.film_market_no
	and				cinetam_reachfreq_population.cinetam_reporting_demographics_id = temp_table.cinetam_reporting_demographics_id
	and				cinetam_reachfreq_population.screening_date = temp_table.screening_date
	where			cinetam_reachfreq_population.country_code = @country_code
end
else
begin
	--get start and end dates
	select			@min_screening_date = min(screening_date),
					@max_screening_date = max(screening_date)
	from			inclusion_cinetam_complex_attendance
	where			inclusion_cinetam_complex_attendance.campaign_no = @campaign_no
	and				(@inclusion_id is null
	or				inclusion_cinetam_complex_attendance.inclusion_id = @inclusion_id)
	and				screening_date <= @screening_date

	--count total unique_people_across_campaign
	select			@unique_people = count(distinct membership_id),
					@unique_transactions = sum(isnull(unique_transactions,0))
	from			v_film_campaign_pcr_movio
	inner join		inclusion_cinetam_complex_attendance on	v_film_campaign_pcr_movio.complex_id = inclusion_cinetam_complex_attendance.complex_id
	and				v_film_campaign_pcr_movio.movie_id = inclusion_cinetam_complex_attendance.movie_id
	and				v_film_campaign_pcr_movio.screening_date = inclusion_cinetam_complex_attendance.screening_date
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = inclusion_cinetam_complex_attendance.cinetam_reporting_demographics_id
	inner join		v_film_campaign_pcr_inclusion_details on inclusion_cinetam_complex_attendance.inclusion_id = v_film_campaign_pcr_inclusion_details.inclusion_id
	where			v_film_campaign_pcr_movio.country_code = @country_code
	and				inclusion_cinetam_complex_attendance.campaign_no = @campaign_no
	and				(@inclusion_id is null
	or				inclusion_cinetam_complex_attendance.inclusion_id = @inclusion_id)
	and				v_film_campaign_pcr_inclusion_details.inclusion_type = @inclusion_type
	and				(@product in (1,2,3,5,7,8)
	or				(@product = 4
	and				cineasia_count = 0)
	or				(@product = 6
	and				cineasia_count > 0))
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				v_film_campaign_pcr_movio.screening_date between @min_screening_date and @max_screening_date

	--count total unique_people_across_campaign
	select 			@week_one_unique_people = count(distinct membership_id),
					@week_one_unique_transactions = isnull(sum(unique_transactions),0)
	from			v_film_campaign_pcr_movio
	inner join		inclusion_cinetam_complex_attendance on	v_film_campaign_pcr_movio.complex_id = inclusion_cinetam_complex_attendance.complex_id
	and				v_film_campaign_pcr_movio.movie_id = inclusion_cinetam_complex_attendance.movie_id
	and				v_film_campaign_pcr_movio.screening_date = inclusion_cinetam_complex_attendance.screening_date
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = inclusion_cinetam_complex_attendance.cinetam_reporting_demographics_id
	inner join		v_film_campaign_pcr_inclusion_details on inclusion_cinetam_complex_attendance.inclusion_id = v_film_campaign_pcr_inclusion_details.inclusion_id
	where			v_film_campaign_pcr_movio.country_code = @country_code
	and				inclusion_cinetam_complex_attendance.campaign_no = @campaign_no
	and				(@inclusion_id is null
	or				inclusion_cinetam_complex_attendance.inclusion_id = @inclusion_id)
	and				v_film_campaign_pcr_inclusion_details.inclusion_type = @inclusion_type
	and				(@product in (1,2,3,5,7,8)
	or				(@product = 4
	and				cineasia_count = 0)
	or				(@product = 6
	and				cineasia_count > 0))
	and				v_film_campaign_pcr_movio.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				v_film_campaign_pcr_movio.screening_date = @min_screening_date

	select			@rm_population = sum(cinetam_reachfreq_population.population)
	from			cinetam_reachfreq_population
	inner join		(select			film_market_no,
									cinetam_reporting_demographics_id,
									max(screening_date) as screening_date
					from			inclusion_cinetam_complex_attendance
					inner join		v_film_campaign_pcr_inclusion_details on inclusion_cinetam_complex_attendance.inclusion_id = v_film_campaign_pcr_inclusion_details.inclusion_id
					inner join		complex on inclusion_cinetam_complex_attendance.complex_id = complex.complex_id
					where			inclusion_cinetam_complex_attendance.campaign_no = @campaign_no
					and				(@inclusion_id is null
					or				inclusion_cinetam_complex_attendance.inclusion_id = @inclusion_id)
					and				v_film_campaign_pcr_inclusion_details.inclusion_type = @inclusion_type
					and				(@product in (1,2,3,5,7,8)
					or				(@product = 4
					and				cineasia_count = 0)
					or				(@product = 6
					and				cineasia_count > 0))
					and				inclusion_cinetam_complex_attendance.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
					and				inclusion_cinetam_complex_attendance.screening_date between @min_screening_date and @max_screening_date
					group by		film_market_no,
									cinetam_reporting_demographics_id) as temp_table 
	on				cinetam_reachfreq_population.film_market_no = temp_table.film_market_no
	and				cinetam_reachfreq_population.cinetam_reporting_demographics_id = temp_table.cinetam_reporting_demographics_id
	and				cinetam_reachfreq_population.screening_date = temp_table.screening_date
	where			cinetam_reachfreq_population.country_code = @country_code
end

if @week_one_unique_people > 0
	select			@week_one_frequency	= @week_one_unique_transactions / @week_one_unique_people
	
select			@week_one_frequency	= isnull(@week_one_frequency, 1)

select			@frequency_modifier		= 1 /  @week_one_frequency
		
select			@frequency						= (@unique_transactions / @unique_people) * @frequency_modifier


select			@reach = @attendance / @rm_population / @frequency

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
