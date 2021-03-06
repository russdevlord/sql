/****** Object:  StoredProcedure [dbo].[p_cinetam_post_analysis_package_randf]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_post_analysis_package_randf]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_post_analysis_package_randf]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--drop procedure p_cinetam_post_analysis_package_randf

create proc [dbo].[p_cinetam_post_analysis_package_randf]			@Package_code					int,
																								@report_screening_date		datetime,
																								@run_end_report						char(1)
as


declare				@error											int,
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
where			package_id = @Package_code

select			@active_count = count(*)
from				campaign_spot
where			package_id = @Package_code
and					spot_status = 'X'

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
					v_cinetam_campaign_package_post_analysis,
					cinetam_campaign_package_settings
where			v_cinetam_campaign_package_post_analysis.package_Id = 22957--@Package_code
and				v_cinetam_campaign_package_post_analysis.package_Id = cinetam_campaign_package_settings.package_id
and				cinetam_reporting_demographics_xref.cinetam_demographics_id = v_movio_data_post_analysis.cinetam_demographics_id
and				v_movio_data_post_analysis.cinetam_demographics_id = v_cinetam_campaign_package_post_analysis.cinetam_reporting_demographics_id
and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_campaign_package_settings.cinetam_reporting_demographics_id
and				v_movio_data_post_analysis.complex_id = v_cinetam_campaign_package_post_analysis.complex_id
and				v_movio_data_post_analysis.movie_code = v_cinetam_campaign_package_post_analysis.movie_code
and				v_movio_data_post_analysis.screening_date = v_cinetam_campaign_package_post_analysis.screening_date
and				v_movio_data_post_analysis.screening_date between @min_screening_date and @max_screening_date
group by		cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,
				v_cinetam_campaign_package_post_analysis.package_id

update	#cinetam_campaign_reachfreq_results
set			week_one_unique_people = temp_table.movio_unique_people,
				week_one_unique_transactions = temp_table.movio_unique_transactions 
from		(select cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id, 
										sum(isnull(unique_transactions,0) * isnull(occurence_adjuster,0)) as 'movio_unique_transactions',
										sum(isnull(unique_people,0) * isnull(occurence_adjuster,0))  as 'movio_unique_people'
					from			v_movio_data_post_analysis,
										cinetam_reporting_demographics_xref,
										v_cinetam_campaign_package_post_analysis,
										cinetam_campaign_package_settings
					where			v_cinetam_campaign_package_post_analysis.package_id = @Package_code
					and				v_cinetam_campaign_package_post_analysis.package_id = cinetam_campaign_package_settings.package_id
					and				cinetam_reporting_demographics_xref.cinetam_demographics_id = v_movio_data_post_analysis.cinetam_demographics_id
					and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = v_cinetam_campaign_package_post_analysis.cinetam_reporting_demographics_id
					and				v_movio_data_post_analysis.complex_id = v_cinetam_campaign_package_post_analysis.complex_id
					and				v_movio_data_post_analysis.movie_code = v_cinetam_campaign_package_post_analysis.movie_code
					and				v_movio_data_post_analysis.screening_date = v_cinetam_campaign_package_post_analysis.screening_date
					and				v_movio_data_post_analysis.screening_date = @min_screening_date
					group by		cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,
										v_cinetam_campaign_package_post_analysis.package_id) as temp_table
where			temp_table.cinetam_reporting_demographics_id = #cinetam_campaign_reachfreq_results.cinetam_reporting_demographics_id

select			@sum_charge = sum(charge_rate)
from			campaign_spot
where			package_id = @Package_code

update		#cinetam_campaign_reachfreq_results
set				week_one_frequency = week_one_unique_transactions / week_one_unique_people

update		#cinetam_campaign_reachfreq_results
set				frequency_modifier = 1 / week_one_frequency

update		#cinetam_campaign_reachfreq_results
set				frequency = week_one_unique_transactions / week_one_unique_people * frequency_modifier

update		#cinetam_campaign_reachfreq_results
set				attendance = v_cinetam_campaign_package_reporting_demographics.attendance
from			v_cinetam_campaign_package_reporting_demographics
where			v_cinetam_campaign_package_reporting_demographics.cinetam_reporting_demographics_id = #cinetam_campaign_reachfreq_results.cinetam_reporting_demographics_id	
and				package_id = @Package_code

update		#cinetam_campaign_reachfreq_results
set				rm_population = cinetam_reachfreq_population.movie_population
from			cinetam_reachfreq_population,
					cinetam_campaign_package_settings
where			cinetam_reachfreq_population.cinetam_reporting_demographics_id = #cinetam_campaign_reachfreq_results.cinetam_reporting_demographics_id
and				cinetam_campaign_package_settings.package_id = @Package_code
and				cinetam_reachfreq_population.cinetam_reporting_demographics_id = cinetam_campaign_package_settings.cinetam_reporting_demographics_id
and				cinetam_reachfreq_population.market = cinetam_campaign_package_settings.market
and				screening_date = @min_screening_date

update		#cinetam_campaign_reachfreq_results
set				reach = attendance / rm_population / frequency

update		#cinetam_campaign_reachfreq_results
set				cpm = @sum_charge / attendance * 1000

select * from #cinetam_campaign_reachfreq_results

return 0
GO
