/****** Object:  StoredProcedure [dbo].[p_cinema_yield_analysis]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinema_yield_analysis]
GO
/****** Object:  StoredProcedure [dbo].[p_cinema_yield_analysis]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create proc [dbo].[p_cinema_yield_analysis]	@start_period			datetime,
											@end_period				datetime,
											@current_period			datetime,
											@country_code			char(1)

as

declare			@error						int,
				@ytd_or_future				varchar(20),
				@country_name				varchar(20),
				@business_unit_id			int,
				@business_unit_desc			varchar(50),
				@avail_audience				numeric(24,12),
				@sold_audience				numeric(24,12),
				@cpm						numeric(24,12),
				@revenue					numeric(24,12),
				@budget						numeric(24,12),		
				@screening_dates			varchar(max),
				@film_markets				varchar(max),
				@exhibitor_ids				varchar(max),
				@movie_category_codes		varchar(max),
				@cinetam_reporting_demographics_id	int

set nocount on

select @cinetam_reporting_demographics_id  = 0

create table #yield_analysis
(
	ytd_or_future			varchar(20)			not null,
	country_name			varchar(20)			not null,
	business_unit_id		int					not null,
	business_unit_desc		varchar(50)			not null,
	avail_audience			numeric(24,12)		not null,
	sold_audience			numeric(24,12)		not null,
	cpm						numeric(24,12)		not null,
	revenue					numeric(24,12)		not null,
	budget					numeric(24,12)		not null
)

create table #availability_attendance_yield
(
	screening_date							datetime			not null,
	generation_date							datetime			not null,
	country_code							char(1)				not null,
	film_market_no							int					not null,
	complex_id								int					not null,
	complex_name							varchar(50)			not null,
	cinetam_reporting_demographics_id		int					not null,
	cinetam_reachfreq_duration_id			int					not null,
	exhibitor_id							int					not null,
	product_category_sub_concat_id			int					not null,
	movie_category_code						char(2)				not null,
	demo_attendance							numeric(20,8)		not null,
	all_people_attendance					numeric(20,8)		not null,
	product_booked_percentage				numeric(20,8)		not null,
	current_booked_percentage				numeric(20,8)		not null,
	projected_booked_percentage				numeric(20,8)		not null,
	full_attendance							numeric(20,8)		not null
)


select			@country_name = country_name
from			country
where			country_code = @country_code

/*
 * Do YTD
 */

select			@ytd_or_future = 'YTD' 

select			@avail_audience = sum(convert(numeric(24,12), max_time + mg_max_time) / 30.000000000000 * convert(numeric(24,12), attendance))
from			movie_history
inner join		complex_date on movie_history.screening_date = complex_date.screening_date
and				movie_history.complex_id = complex_date.complex_id
inner join		film_screening_date_xref on	movie_history.screening_date = film_screening_date_xref.screening_date
where			country = @country_code
and				movie_history.movie_id <> 102
and				benchmark_end between @start_period and @current_period
and				attendance <> 0

select			@sold_audience = sum(convert(numeric(24,12), campaign_package.duration) / 30.000000000000 * convert(numeric(24,12), attendance)) 
from			campaign_spot
inner join		v_certificate_item_distinct on campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
inner join		film_screening_date_xref on campaign_spot.screening_date = film_screening_date_xref.screening_date
and				movie_history.screening_date = film_screening_date_xref.screening_date
inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id
inner join		film_campaign on campaign_spot.campaign_no = film_campaign.campaign_no
where			benchmark_end between @start_period and @current_period
and				movie_history.country = @country_code
and				movie_history.movie_id <> 102
and				film_campaign.campaign_type not in (4,9)

select			@revenue = sum(cost)
from			v_statrev_onscreen_no_def
inner join		film_campaign on v_statrev_onscreen_no_def.campaign_no = film_campaign.campaign_no
where			revenue_period between @start_period and @current_period
and				country_code = @country_code
and				film_campaign.campaign_type not in (4,9)

select			@budget = sum(budget)
from			statrev_budgets
inner join		branch on statrev_budgets.branch_code = branch.branch_code
where			business_unit_id in (2,3,5)
and				revenue_period between @start_period and @current_period
and				branch.country_code = @country_code
and				revenue_group in (1,2,3,7)


if @sold_audience <> 0 
	select			@cpm = @revenue / @sold_audience * 1000
else
	select			@cpm = -1

insert into #yield_analysis values (@ytd_or_future, @country_name, 0, 'All Business Units', isnull(@avail_audience,0), isnull(@sold_audience,0), isnull(@cpm,0), isnull(@revenue,0), isnull(@budget,0))

/*
 * Do Future
 */

--screening_dates
select			@screening_dates = coalesce(@screening_dates + ',','') + convert(varchar(max), screening_date, 106)
from			film_screening_date_xref
where			benchmark_end between dateadd(dd, 1, @current_period) and @end_period

--film markets
select			@film_markets = coalesce(@film_markets + ',','') + convert(varchar(max), film_market_no)
from			film_market 
where			country_code = @country_code

--exhibitors
select			@exhibitor_ids = coalesce(@exhibitor_ids + ',','') + convert(varchar(max), exhibitor_id)
from			exhibitor 
inner join		state on exhibitor.state_code = state.state_code 
where			country_code = @country_code 
and				exhibitor_status = 'A'

--movie_category codes
select			@movie_category_codes = coalesce(@movie_category_codes + ',', '') + movie_category_code
from			movie_category

insert into #availability_attendance_yield
exec @error = p_availability_attendance_estimate	@country_code, 
													5,
													@screening_dates,
													@film_markets,
													0,
													208, 
													1,
													@exhibitor_ids,
													1,
													0,
													0,
													0,
													0,
													@movie_category_codes	

if @error <> 0
begin		
	raiserror ('Error running availability procedure', 16, 1)
	return -1
end

select			@ytd_or_future = 'Future' 

select			@avail_audience = 0

select			@avail_audience = sum((convert(numeric(24,12), max_time + mg_max_time) / 30.000000000000) * convert(numeric(24,12), demo_attendance))
from			#availability_attendance_yield
inner join		complex_date on #availability_attendance_yield.complex_id = complex_date.complex_id
and				#availability_attendance_yield.screening_date = complex_date.screening_date

select			@sold_audience = 0

/*select			@sold_audience = sum((convert(numeric(24,12), max_time + mg_max_time) / 30.000000000000) * convert(numeric(24,12), demo_attendance * current_booked_percentage))
from			#availability_attendance_yield
inner join		complex_date on #availability_attendance_yield.complex_id = complex_date.complex_id
and				#availability_attendance_yield.screening_date = complex_date.screening_date
*/

select			@sold_audience = isnull(sum(convert(numeric(24,12), campaign_package.duration) / 30.000000000000 * convert(numeric(24,12), inclusion_cinetam_targets.target_attendance / case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end * case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end )),0)
from			inclusion_cinetam_targets
inner join		film_screening_date_xref on inclusion_cinetam_targets.screening_date = film_screening_date_xref.screening_date
inner join		inclusion_cinetam_package on inclusion_cinetam_targets.inclusion_id = inclusion_cinetam_package.inclusion_id
inner join		campaign_package on inclusion_cinetam_package.package_id = campaign_package.package_id
inner join		complex on inclusion_cinetam_targets.complex_id = complex.complex_id
inner join		branch on complex.branch_code = branch.branch_code
inner join		film_campaign on campaign_package.campaign_no = film_campaign.campaign_no
inner join		film_screening_date_attendance_prev on inclusion_cinetam_targets.screening_date = film_screening_date_attendance_prev.screening_date
inner join		availability_demo_matching as target_demo 
on				inclusion_cinetam_targets.cinetam_reporting_demographics_id = target_demo.cinetam_reporting_demographics_id
and				film_screening_date_attendance_prev.prev_screening_date = target_demo.screening_date
and				inclusion_cinetam_targets.complex_id = target_demo.complex_id
inner join		availability_demo_matching as criteria_demo 
on				@cinetam_reporting_demographics_id = criteria_demo.cinetam_reporting_demographics_id
and				film_screening_date_attendance_prev.prev_screening_date =  criteria_demo.screening_date
and				inclusion_cinetam_targets.complex_id = criteria_demo.complex_id
where			benchmark_end between dateadd(dd, 1, @current_period) and @end_period
and				branch.country_code = @country_code
and				film_campaign.campaign_type not in (4,9)
and				film_campaign.campaign_status <> 'P'

select			@sold_audience = @sold_audience + isnull(sum(convert(numeric(24,12), campaign_package.duration) / 30.000000000000 * convert(numeric(24,12), inclusion_follow_film_targets.original_target_attendance / case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end * case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end )),0)
from			inclusion_follow_film_targets
inner join		film_screening_date_xref on inclusion_follow_film_targets.screening_date = film_screening_date_xref.screening_date
inner join		inclusion_cinetam_package on inclusion_follow_film_targets.inclusion_id = inclusion_cinetam_package.inclusion_id
inner join		campaign_package on inclusion_cinetam_package.package_id = campaign_package.package_id
inner join		complex on inclusion_follow_film_targets.complex_id = complex.complex_id
inner join		branch on complex.branch_code = branch.branch_code
inner join		film_screening_date_attendance_prev on inclusion_follow_film_targets.screening_date = film_screening_date_attendance_prev.screening_date
inner join		film_campaign on campaign_package.campaign_no = film_campaign.campaign_no
inner join		availability_demo_matching as target_demo 
on				inclusion_follow_film_targets.cinetam_reporting_demographics_id = target_demo.cinetam_reporting_demographics_id
and				film_screening_date_attendance_prev.prev_screening_date = target_demo.screening_date
and				inclusion_follow_film_targets.complex_id = target_demo.complex_id
inner join		availability_demo_matching as criteria_demo 
on				@cinetam_reporting_demographics_id = criteria_demo.cinetam_reporting_demographics_id
and				film_screening_date_attendance_prev.prev_screening_date =  criteria_demo.screening_date
and				inclusion_follow_film_targets.complex_id = criteria_demo.complex_id
where			benchmark_end between dateadd(dd, 1, @current_period) and @end_period
and				branch.country_code = @country_code
and				film_campaign.campaign_type not in (4,9)
and				film_campaign.campaign_status <> 'P'

/*select			@sold_audience = @sold_audience + (demo_attendance * duration_factor /** 0.75*/)
from			#availability_attendance_yield
inner join		(select				inclusion_spot.screening_date,
									inclusion_cinetam_settings.complex_id,
									sum(convert(numeric(30,18) , campaign_package.duration / 30)) as duration_factor
				from				inclusion_cinetam_settings
				inner join			inclusion_spot on inclusion_cinetam_settings.inclusion_id = inclusion_spot.inclusion_id
				inner join			inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
				inner join			campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id
				inner join			film_screening_date_xref on inclusion_spot.screening_date = film_screening_date_xref.screening_date
				inner join			film_campaign on campaign_package.campaign_no = film_campaign.campaign_no
				where				campaign_package.campaign_package_status <> 'P'							
				and					inclusion_cinetam_settings.inclusion_id in (select inclusion_id from inclusion where inclusion_type = 30)                
				and					benchmark_end between dateadd(dd, 1, @current_period) and @end_period
				and					film_campaign.campaign_type not in (4,9)
				group by			inclusion_spot.screening_date,                 
									inclusion_cinetam_settings.complex_id) as temp_table                
on				#availability_attendance_yield.screening_date = temp_table.screening_date                
and				#availability_attendance_yield.complex_id = temp_table.complex_id*/

select			@revenue = 0

select			@revenue = sum(cost)
from			v_statrev_onscreen_no_def
inner join		film_campaign on v_statrev_onscreen_no_def.campaign_no = film_campaign.campaign_no
where			revenue_period between dateadd(dd, 1, @current_period) and @end_period
and				country_code = @country_code
and				film_campaign.campaign_type not in (4,9)

select			@budget = 0

select			@budget = sum(budget)
from			statrev_budgets
inner join		branch on statrev_budgets.branch_code = branch.branch_code
where			business_unit_id in (2,3,5)
and				revenue_period between dateadd(dd, 1, @current_period) and @end_period
and				branch.country_code = @country_code
and				revenue_group in (1,2,3,7)


select			@cpm = 0
if @sold_audience <> 0 
	select			@cpm = @revenue / @sold_audience * 1000
else
	select			@cpm = -1

insert into #yield_analysis values (@ytd_or_future, @country_name, 0, 'All Business Units', isnull(@avail_audience,0), isnull(@sold_audience,0), isnull(@cpm,0), isnull(@revenue,0), isnull(@budget,0))

insert into #yield_analysis 
select		'Total',
			country_name,
			business_unit_id,
			business_unit_desc,
			sum(avail_audience),
			sum(sold_audience),
			sum(revenue) / sum(sold_audience) * 1000,
			sum(revenue),
			sum(budget)
from		#yield_analysis
group by	country_name,
			business_unit_id,
			business_unit_desc
			
			
select * from #yield_analysis

return 0
GO
