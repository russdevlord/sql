/****** Object:  StoredProcedure [dbo].[p_cinetam_post_analysis_randf]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_post_analysis_randf]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_post_analysis_randf]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinetam_post_analysis_randf]			@campaign_no						int,
																												@report_screening_date		datetime,
																												@run_end_report						char(1)

as

declare				@error																				int,
							@min_screening_date												datetime,
							@max_screening_date												datetime,
							@active_count																int,
							@sum_charge																numeric(20,12),
							@country_code																char(1),
							@cinetam_reporting_demographics_id				int,
							@week_one_unique_people									numeric(20,12),
							@week_one_unique_transactions							numeric(20,12),
							@week_one_frequency												numeric(20,12),
							@frequency_modifier													numeric(20,12),
							@unique_people															numeric(20,12),
							@unique_transactions												numeric(20,12),
							@frequency																	numeric(20,12),
							@attendance																	numeric(20,12),
							@rm_population															numeric(20,12),
							@reach																			numeric(20,12),
							@cpm																				numeric(20,12),
							@unique_people_multi_occ										numeric(20,12),
							@unique_transactions_multi_occ							numeric(20,12),
							@total_multi_occ															int
							
						
create table #cinetam_campaign_reachfreq_results							
(
	cinetam_reporting_demographics_id				int								null,
	week_one_unique_people									numeric(20,12)		null,
	week_one_unique_transactions							numeric(20,12)		null,
	week_one_frequency												numeric(20,12)		null,
	frequency_modifier													numeric(20,12)		null,
	unique_people															numeric(20,12)		null,
	unique_transactions													numeric(20,12)		null,
	frequency																		numeric(20,12)		null,
	attendance																	numeric(20,12)		null,
	rm_population															numeric(20,12)		null,
	reach																				numeric(20,12)		null,
	cpm																				numeric(20,12)		null
)

/*
 * Select Min & Max Screening Date
 */ 

select			@min_screening_date = min(screening_date),
						@max_screening_date = max(screening_date)
from				campaign_spot 
where			campaign_no = @campaign_no 

if @campaign_no = 209187
begin
	select @min_screening_date = dateadd(wk, 1, @min_screening_date)
end
	
select			@active_count = count(*)
from				campaign_spot
where			campaign_no = @campaign_no
and					spot_status = 'A'

select			@country_code = country_code
from				film_campaign,
						branch
where			film_campaign.branch_code = branch.branch_code
and					film_campaign.campaign_no = @campaign_no

/*
 * If not running end of campaign_report return
 */

if   @run_end_report = 'N' --or @report_screening_date < @max_screening_date or @active_count > 0
begin

	select * from #cinetam_campaign_reachfreq_results

	return 0
end
	
select @cinetam_reporting_demographics_id = cinetam_reporting_demographics_id
from cinetam_campaign_settings where campaign_no = @campaign_no

if @country_code = 'A'
begin							
	/*
	 * Get Total Frequency
	 */

	insert				into	#cinetam_campaign_reachfreq_results
							(
							cinetam_reporting_demographics_id,
							unique_transactions,
							unique_people
							)						
	select 			cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id, 
							sum(isnull(unique_transactions,0) * isnull(occurence_adjuster,0)) as 'movio_unique_transactions',
							sum(isnull(unique_people,0) * isnull(occurence_adjuster,0))  as 'movio_unique_people'
	from				v_movio_data_post_analysis,
							cinetam_reporting_demographics_xref,
							v_cinetam_campaign_post_analysis,
							cinetam_campaign_settings
	where			v_movio_data_post_analysis.country_code = @country_code
	and					v_cinetam_campaign_post_analysis.country_code = @country_code
	and					v_movio_data_post_analysis.country_code = v_cinetam_campaign_post_analysis.country_code
	and					v_cinetam_campaign_post_analysis.campaign_no = @campaign_no
	and					v_cinetam_campaign_post_analysis.campaign_no = cinetam_campaign_settings.campaign_no
	and					cinetam_reporting_demographics_xref.cinetam_demographics_id = v_movio_data_post_analysis.cinetam_demographics_id
	and					v_movio_data_post_analysis.cinetam_demographics_id = v_cinetam_campaign_post_analysis.cinetam_demographics_id
	and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
	and					v_movio_data_post_analysis.complex_id = v_cinetam_campaign_post_analysis.complex_id
	and					v_movio_data_post_analysis.movie_code = v_cinetam_campaign_post_analysis.movie_code
	and					v_movio_data_post_analysis.screening_date = v_cinetam_campaign_post_analysis.screening_date
	and					v_movio_data_post_analysis.screening_date between @min_screening_date and @max_screening_date
	group by		cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,
							v_cinetam_campaign_post_analysis.campaign_no


	update	#cinetam_campaign_reachfreq_results
	set			week_one_unique_people = temp_table.movio_unique_people,
					week_one_unique_transactions = temp_table.movio_unique_transactions 
	from		(select 				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id, 
												sum(isnull(unique_transactions,0) * isnull(occurence_adjuster,0)) as 'movio_unique_transactions',
												sum(isnull(unique_people,0) * isnull(occurence_adjuster,0))  as 'movio_unique_people'
						from				v_movio_data_post_analysis,
												cinetam_reporting_demographics_xref,
												v_cinetam_campaign_post_analysis,
												cinetam_campaign_settings
						where			v_movio_data_post_analysis.country_code = @country_code
						and					v_cinetam_campaign_post_analysis.country_code = @country_code
						and					v_movio_data_post_analysis.country_code = v_cinetam_campaign_post_analysis.country_code
						and					v_cinetam_campaign_post_analysis.campaign_no = @campaign_no
						and					v_cinetam_campaign_post_analysis.campaign_no = cinetam_campaign_settings.campaign_no
						and					cinetam_reporting_demographics_xref.cinetam_demographics_id = v_movio_data_post_analysis.cinetam_demographics_id
						and					v_movio_data_post_analysis.cinetam_demographics_id = v_cinetam_campaign_post_analysis.cinetam_demographics_id
						and					v_movio_data_post_analysis.complex_id = v_cinetam_campaign_post_analysis.complex_id
						and					v_movio_data_post_analysis.movie_code = v_cinetam_campaign_post_analysis.movie_code
						and					v_movio_data_post_analysis.screening_date = v_cinetam_campaign_post_analysis.screening_date
						and					v_movio_data_post_analysis.screening_date = @min_screening_date
						group by		cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,
												v_cinetam_campaign_post_analysis.campaign_no) as temp_table
	where			temp_table.cinetam_reporting_demographics_id = #cinetam_campaign_reachfreq_results.cinetam_reporting_demographics_id

	select		@sum_charge = sum(charge_rate)
	from			campaign_spot
	where		campaign_no = @campaign_no

	update		#cinetam_campaign_reachfreq_results
	set				week_one_frequency = week_one_unique_transactions / week_one_unique_people

	update		#cinetam_campaign_reachfreq_results
	set				frequency_modifier = 1 / week_one_frequency

	update		#cinetam_campaign_reachfreq_results
	set				frequency = unique_transactions / unique_people * frequency_modifier

	update		#cinetam_campaign_reachfreq_results
	set				attendance = v_cinetam_campaign_repoting_demographics.attendance
	from			v_cinetam_campaign_repoting_demographics
	where		v_cinetam_campaign_repoting_demographics.cinetam_reporting_demographics_id = #cinetam_campaign_reachfreq_results.cinetam_reporting_demographics_id	
	and				campaign_no = @campaign_no

	update		#cinetam_campaign_reachfreq_results
	set				rm_population = temp_table.population
	from				(select			sum(cinetam_reachfreq_population.population) as population
						from				cinetam_reachfreq_population,
											cinetam_campaign_settings,
											cinetam_reachfreq_market_xref
						where			cinetam_reachfreq_population.country_code = @country_code
						and				cinetam_reachfreq_population.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
						and				cinetam_campaign_settings.campaign_no = @campaign_no
						and				cinetam_reachfreq_population.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
						and				cinetam_reachfreq_population.film_market_no = cinetam_reachfreq_market_xref.film_market_no
						and				cinetam_reachfreq_market_xref.market = cinetam_campaign_settings.market
						and				screening_date = @min_screening_date) as temp_table

	update		#cinetam_campaign_reachfreq_results
	set				reach = attendance / rm_population / frequency

	update		#cinetam_campaign_reachfreq_results
	set				cpm = @sum_charge / attendance * 1000
end
else if @country_code = 'Z'
begin
	--count total unique_people_across_campaign
	select 			@unique_people = count(distinct membership_id)
	from				v_movio_data_post_analysis_nz,
							cinetam_reporting_demographics_xref,
							v_cinetam_campaign_post_analysis,
							cinetam_campaign_settings
	where			v_movio_data_post_analysis_nz.country_code = @country_code
	and					v_cinetam_campaign_post_analysis.country_code = @country_code
	and					v_movio_data_post_analysis_nz.country_code = v_cinetam_campaign_post_analysis.country_code
	and					v_cinetam_campaign_post_analysis.campaign_no = @campaign_no
	and					v_cinetam_campaign_post_analysis.campaign_no = cinetam_campaign_settings.campaign_no
	and					cinetam_reporting_demographics_xref.cinetam_demographics_id = v_movio_data_post_analysis_nz.cinetam_demographics_id
	and					v_movio_data_post_analysis_nz.cinetam_demographics_id = v_cinetam_campaign_post_analysis.cinetam_demographics_id
	and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
	and					v_movio_data_post_analysis_nz.complex_id = v_cinetam_campaign_post_analysis.complex_id
	and					v_movio_data_post_analysis_nz.movie_code = v_cinetam_campaign_post_analysis.movie_code
	and					v_movio_data_post_analysis_nz.screening_date = v_cinetam_campaign_post_analysis.screening_date
	and					v_movio_data_post_analysis_nz.screening_date between @min_screening_date and @max_screening_date
	group by		cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,
							v_cinetam_campaign_post_analysis.campaign_no
	
	--total transactions
	select 			@cinetam_reporting_demographics_id = cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id, 
							@unique_transactions = sum(isnull(unique_transactions,0))
	from				v_movio_data_post_analysis_nz,
							cinetam_reporting_demographics_xref,
							v_cinetam_campaign_post_analysis,
							cinetam_campaign_settings
	where			v_movio_data_post_analysis_nz.country_code = @country_code
	and					v_cinetam_campaign_post_analysis.country_code = @country_code
	and					v_movio_data_post_analysis_nz.country_code = v_cinetam_campaign_post_analysis.country_code
	and					v_cinetam_campaign_post_analysis.campaign_no = @campaign_no
	and					v_cinetam_campaign_post_analysis.campaign_no = cinetam_campaign_settings.campaign_no
	and					cinetam_reporting_demographics_xref.cinetam_demographics_id = v_movio_data_post_analysis_nz.cinetam_demographics_id
	and					v_movio_data_post_analysis_nz.cinetam_demographics_id = v_cinetam_campaign_post_analysis.cinetam_demographics_id
	and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
	and					v_movio_data_post_analysis_nz.complex_id = v_cinetam_campaign_post_analysis.complex_id
	and					v_movio_data_post_analysis_nz.movie_code = v_cinetam_campaign_post_analysis.movie_code
	and					v_movio_data_post_analysis_nz.screening_date = v_cinetam_campaign_post_analysis.screening_date
	and					v_movio_data_post_analysis_nz.screening_date between @min_screening_date and @max_screening_date
	group by		cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,
							v_cinetam_campaign_post_analysis.campaign_no

	--count total unique_people_across_campaign
	select 			@week_one_unique_people = count(distinct membership_id)
	from				v_movio_data_post_analysis_nz,
							cinetam_reporting_demographics_xref,
							v_cinetam_campaign_post_analysis,
							cinetam_campaign_settings
	where			v_movio_data_post_analysis_nz.country_code = @country_code
	and					v_cinetam_campaign_post_analysis.country_code = @country_code
	and					v_movio_data_post_analysis_nz.country_code = v_cinetam_campaign_post_analysis.country_code
	and					v_cinetam_campaign_post_analysis.campaign_no = @campaign_no
	and					v_cinetam_campaign_post_analysis.campaign_no = cinetam_campaign_settings.campaign_no
	and					cinetam_reporting_demographics_xref.cinetam_demographics_id = v_movio_data_post_analysis_nz.cinetam_demographics_id
	and					v_movio_data_post_analysis_nz.cinetam_demographics_id = v_cinetam_campaign_post_analysis.cinetam_demographics_id
	and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
	and					v_movio_data_post_analysis_nz.complex_id = v_cinetam_campaign_post_analysis.complex_id
	and					v_movio_data_post_analysis_nz.movie_code = v_cinetam_campaign_post_analysis.movie_code
	and					v_movio_data_post_analysis_nz.screening_date = v_cinetam_campaign_post_analysis.screening_date
	and					v_movio_data_post_analysis_nz.screening_date = @min_screening_date
	group by		cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,
							v_cinetam_campaign_post_analysis.campaign_no
	
	--total transactions
	select 			@week_one_unique_transactions = sum(isnull(unique_transactions,0))
	from				v_movio_data_post_analysis_nz,
							cinetam_reporting_demographics_xref,
							v_cinetam_campaign_post_analysis,
							cinetam_campaign_settings
	where			v_movio_data_post_analysis_nz.country_code = @country_code
	and					v_cinetam_campaign_post_analysis.country_code = @country_code
	and					v_movio_data_post_analysis_nz.country_code = v_cinetam_campaign_post_analysis.country_code
	and					v_cinetam_campaign_post_analysis.campaign_no = @campaign_no
	and					v_cinetam_campaign_post_analysis.campaign_no = cinetam_campaign_settings.campaign_no
	and					cinetam_reporting_demographics_xref.cinetam_demographics_id = v_movio_data_post_analysis_nz.cinetam_demographics_id
	and					v_movio_data_post_analysis_nz.cinetam_demographics_id = v_cinetam_campaign_post_analysis.cinetam_demographics_id
	and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
	and					v_movio_data_post_analysis_nz.complex_id = v_cinetam_campaign_post_analysis.complex_id
	and					v_movio_data_post_analysis_nz.movie_code = v_cinetam_campaign_post_analysis.movie_code
	and					v_movio_data_post_analysis_nz.screening_date = v_cinetam_campaign_post_analysis.screening_date
	and					v_movio_data_post_analysis_nz.screening_date = @min_screening_date
	group by		cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,
							v_cinetam_campaign_post_analysis.campaign_no

	select					@week_one_frequency = 			@week_one_unique_transactions / @week_one_unique_people
	
	select					@frequency_modifier = 				1 /  @week_one_frequency
		
	select					@frequency = 								(@unique_transactions / @unique_people) * @frequency_modifier

	select 		@attendance = v_cinetam_campaign_repoting_demographics.attendance
	from			v_cinetam_campaign_repoting_demographics
	where		v_cinetam_campaign_repoting_demographics.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				campaign_no = @campaign_no

	select		@rm_population = sum(cinetam_reachfreq_population.population)
	from			cinetam_reachfreq_population,
						cinetam_campaign_settings,
						cinetam_reachfreq_market_xref
	where		cinetam_reachfreq_population.country_code = @country_code
	and				cinetam_reachfreq_population.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				cinetam_campaign_settings.campaign_no = @campaign_no
	and				cinetam_reachfreq_population.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
	and				cinetam_reachfreq_population.film_market_no = cinetam_reachfreq_market_xref.film_market_no
	and				cinetam_reachfreq_market_xref.market = cinetam_campaign_settings.market
	and				screening_date = @min_screening_date
	
	select		@reach = @attendance / @rm_population / @frequency

	insert into	#cinetam_campaign_reachfreq_results 
	values		(	@cinetam_reporting_demographics_id,
							@week_one_unique_people,
							@week_one_unique_transactions,
							@week_one_frequency,
							@frequency_modifier,
							@unique_people,
							@unique_transactions,
							@frequency,
							@attendance,
							@rm_population,
							@reach,
							@cpm)									
		
end

select * from #cinetam_campaign_reachfreq_results

return 0
GO
