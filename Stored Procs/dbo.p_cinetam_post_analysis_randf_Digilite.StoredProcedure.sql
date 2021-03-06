/****** Object:  StoredProcedure [dbo].[p_cinetam_post_analysis_randf_Digilite]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_post_analysis_randf_Digilite]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_post_analysis_randf_Digilite]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec  [dbo].[p_cinetam_post_analysis_randf_Digilite] 214141,'2018-09-06 00:00:00','2018-09-06 00:00:00'  

CREATE proc [dbo].[p_cinetam_post_analysis_randf_Digilite]			@campaign_no						int,
																								@report_screening_date		datetime,
																								@run_end_report						char(1)
																						

as


declare						@error											int,
							@min_screening_date			datetime,
							@max_screening_date			datetime,
							@active_count							int,
							@sum_charge							numeric(20,12)

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

select			@active_count = count(*)
from				campaign_spot
where			campaign_no = @campaign_no
and					spot_status = 'A'

/*
 * If not running end of campaign_report return
 */

if   @run_end_report = 'N' --or @report_screening_date < @max_screening_date or @active_count > 0
begin

	select * from #cinetam_campaign_reachfreq_results

	return 0
end
	
							
/*
 * Get Total Frequency
 */
insert			into	#cinetam_campaign_reachfreq_results
					(
					cinetam_reporting_demographics_id,
					unique_transactions,
					unique_people
					)						
select 			cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id, 
					sum(isnull(unique_transactions,0) * isnull(occurence_adjuster,0)) as 'movio_unique_transactions',
					sum(isnull(unique_people,0) * isnull(occurence_adjuster,0))  as 'movio_unique_people'
from			v_movio_data_post_analysis,
					cinetam_reporting_demographics_xref,
					v_cinetam_campaign_post_analysis,
					cinetam_campaign_settings
where			v_cinetam_campaign_post_analysis.campaign_no = @campaign_no
and				v_cinetam_campaign_post_analysis.campaign_no = cinetam_campaign_settings.campaign_no
and				cinetam_reporting_demographics_xref.cinetam_demographics_id = v_movio_data_post_analysis.cinetam_demographics_id
and				v_movio_data_post_analysis.cinetam_demographics_id = v_cinetam_campaign_post_analysis.cinetam_demographics_id
and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
and				v_movio_data_post_analysis.complex_id = v_cinetam_campaign_post_analysis.complex_id
and				v_movio_data_post_analysis.movie_code = v_cinetam_campaign_post_analysis.movie_code
and				v_movio_data_post_analysis.screening_date = v_cinetam_campaign_post_analysis.screening_date
and				v_movio_data_post_analysis.screening_date between @min_screening_date and @max_screening_date
group by		cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,
					v_cinetam_campaign_post_analysis.campaign_no


update	#cinetam_campaign_reachfreq_results
set			week_one_unique_people = temp_table.movio_unique_people,
				week_one_unique_transactions = temp_table.movio_unique_transactions 
from		(select 			cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id, 
										sum(isnull(unique_transactions,0) * isnull(occurence_adjuster,0)) as 'movio_unique_transactions',
										sum(isnull(unique_people,0) * isnull(occurence_adjuster,0))  as 'movio_unique_people'
					from			v_movio_data_post_analysis,
										cinetam_reporting_demographics_xref,
										v_cinetam_campaign_post_analysis,
										cinetam_campaign_settings
					where			v_cinetam_campaign_post_analysis.campaign_no = @campaign_no
					and				v_cinetam_campaign_post_analysis.campaign_no = cinetam_campaign_settings.campaign_no
					and				cinetam_reporting_demographics_xref.cinetam_demographics_id = v_movio_data_post_analysis.cinetam_demographics_id
					and				v_movio_data_post_analysis.cinetam_demographics_id = v_cinetam_campaign_post_analysis.cinetam_demographics_id					
					and				v_movio_data_post_analysis.complex_id = v_cinetam_campaign_post_analysis.complex_id
					and				v_movio_data_post_analysis.movie_code = v_cinetam_campaign_post_analysis.movie_code
					and				v_movio_data_post_analysis.screening_date = v_cinetam_campaign_post_analysis.screening_date
					and				v_movio_data_post_analysis.screening_date = @min_screening_date
					group by		cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,
										v_cinetam_campaign_post_analysis.campaign_no) as temp_table
where			temp_table.cinetam_reporting_demographics_id = #cinetam_campaign_reachfreq_results.cinetam_reporting_demographics_id

select			@sum_charge = sum(charge_rate)
from			campaign_spot
where			campaign_no = @campaign_no

update		#cinetam_campaign_reachfreq_results
set				week_one_frequency = case when week_one_unique_people = 0 then 0 else week_one_unique_transactions / week_one_unique_people end

update		#cinetam_campaign_reachfreq_results
set				frequency_modifier = case when week_one_frequency = 0 then 0 else 1 / week_one_frequency end

update		#cinetam_campaign_reachfreq_results
set				frequency = case when week_one_unique_people * frequency_modifier = 0 then 0 else week_one_unique_transactions / week_one_unique_people * frequency_modifier end

update		#cinetam_campaign_reachfreq_results
set				attendance = 
(Select Sum(v_cinetam_post_campaign_analysis_weeks_Digilite.demo_Attendance)  --v_cinetam_campaign_repoting_demographics.attendance
from			v_cinetam_post_campaign_analysis_weeks_Digilite
where			--v_cinetam_campaign_repoting_demographics.cinetam_reporting_demographics_id = #cinetam_campaign_reachfreq_results.cinetam_reporting_demographics_id	
campaign_no = @campaign_no)

--update			#cinetam_campaign_reachfreq_results
--set				rm_population = cinetam_reachfreq_population.population
--from				cinetam_reachfreq_population,
--					cinetam_campaign_settings,
--					cinetam_reachfreq_market_xref
--where			cinetam_reachfreq_population.cinetam_reporting_demographics_id = #cinetam_campaign_reachfreq_results.cinetam_reporting_demographics_id
--and				cinetam_campaign_settings.campaign_no = @campaign_no
--and				cinetam_reachfreq_population.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
--and				cinetam_reachfreq_population.film_market_no = cinetam_reachfreq_market_xref.film_market_no
--and				cinetam_reachfreq_market_xref.market = cinetam_campaign_settings.market
--and				screening_date = @min_screening_date

update			#cinetam_campaign_reachfreq_results
set				rm_population = temp_table.totalPopulation
from			(select cinetam_reachfreq_population.cinetam_reporting_demographics_id,
						sum(cinetam_reachfreq_population.population) as totalPopulation
				from				cinetam_reachfreq_population,
									cinetam_campaign_settings,
									cinetam_reachfreq_market_xref
				where							
				cinetam_campaign_settings.campaign_no = @campaign_no
				and				cinetam_reachfreq_population.cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
				and				cinetam_reachfreq_population.film_market_no = cinetam_reachfreq_market_xref.film_market_no
				and				cinetam_reachfreq_market_xref.market = cinetam_campaign_settings.market
				and				screening_date = @min_screening_date 
				group by		cinetam_reachfreq_population.cinetam_reporting_demographics_id,
										cinetam_campaign_settings.campaign_no) as temp_table
where			temp_table.cinetam_reporting_demographics_id = #cinetam_campaign_reachfreq_results.cinetam_reporting_demographics_id

update		#cinetam_campaign_reachfreq_results
set				reach = case when rm_population = 0 then 0 when frequency = 0 then 0 else attendance / rm_population / frequency end

update		#cinetam_campaign_reachfreq_results
set				cpm = case when attendance * 1000 = 0 then 0 else @sum_charge / attendance * 1000 end

select * from #cinetam_campaign_reachfreq_results

return 0
GO
