/****** Object:  StoredProcedure [dbo].[p_availability_randf_attendance_cost_estimate_ff]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_availability_randf_attendance_cost_estimate_ff]
GO
/****** Object:  StoredProcedure [dbo].[p_availability_randf_attendance_cost_estimate_ff]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc	[dbo].[p_availability_randf_attendance_cost_estimate_ff]			@result_id			int

as

declare		@error																	int,
				@country_code													char(1),
				@cinetam_reachfreq_mode_id							int,
				@screening_dates												varchar(max),
				@film_markets													varchar(max),
				@cinetam_reporting_demographics_str				varchar(max),
				@product_category_sub_concat_str					varchar(max),
				@cinetam_reachfreq_duration_str						varchar(max),
				@cinetam_reachfreq_duration_id						int,
				@exhibitor_ids													varchar(max),
				@manual_adjustment_factor								numeric(6,4),
				@premium_position												bit,
				@alcohol_gambling												bit,
				@ma15_above														bit,
				@exclude_children												bit,
				@movie_category_codes										varchar(max),
				@product_category_id										int,
				@product_subcategory_id									int,
				@cinetam_reporting_demographics_id				int,
				@manual_attendance											int,
				@manual_cpm														money,
				@manual_budget													money,
				@resultset_id														int,
				@product_category_sub_concat_id						int,
				@movie_ids															varchar(max),
				@agency_id															int,
				@business_unit_id												int,
				@cpm																	money

create table #randf_estimates_ff
(	
	demo_attendance									numeric(20,8)	not null,
	all_people_attendance							numeric(20,8)	not null,
	cost											money null	
)

set nocount on

select		@resultset_id	= resultset_id,
				@cinetam_reachfreq_mode_id = cinetam_reachfreq_mode_id,
				@product_category_id = product_category_id,
				@product_subcategory_id = product_subcategory_id,
				@cinetam_reachfreq_duration_id = cinetam_reachfreq_duration_id,
				@cinetam_reporting_demographics_id = cinetam_reporting_demographics_id,
				@premium_position = premium_position,
				@alcohol_gambling = alcohol_gambling,
				@ma15_above = ma15_above,
				@exclude_children = exclude_children,
				@manual_attendance = manual_attendance,
				@manual_cpm = manual_cpm,
				@manual_budget = manual_budget,
				@manual_adjustment_factor = manual_adjustment_factor
from			cinetam_reachfreq_results
where		result_id = @result_id		

select		@country_code = country_code
from			cinetam_reachfreq_resultset
where		resultset_id = @resultset_id

select		@product_category_sub_concat_id = product_category_sub_concat_id
from			product_category_sub_concat
where		product_category_id = @product_category_id
and			isnull(product_subcategory_id, 0) = isnull(@product_subcategory_id, 0)

select			@cinetam_reporting_demographics_str = convert(varchar(max), @cinetam_reporting_demographics_id),
					@product_category_sub_concat_str = convert(varchar(max), @product_category_sub_concat_id),
					@cinetam_reachfreq_duration_str = convert(varchar(max), @cinetam_reachfreq_duration_id)

--film markets
select			@film_markets = coalesce(@film_markets + ',','') + convert(varchar(max), film_market_no)
from				cinetam_reachfreq_results_mkt_xref
where			result_id = @result_id

--screening_dates
select			@screening_dates = coalesce(@screening_dates + ',','') + convert(varchar(max), screening_date, 106)
from				cinetam_reachfreq_results_fsd_xref
where			result_id = @result_id

--movies
select			@movie_ids = coalesce(@movie_ids + ',','') + convert(varchar(max), movie_id)
from				cinetam_reachfreq_movie_xref
where			result_id = @result_id

--exhibitors
select			@exhibitor_ids = coalesce(@exhibitor_ids + ',','') + convert(varchar(max), exhibitor_id)
from				exhibitor 
inner join		state on exhibitor.state_code = state.state_code 
where			country_code = @country_code 
and				exhibitor_status = 'A'

if @cinetam_reachfreq_mode_id = 3 or @cinetam_reachfreq_mode_id = 5
begin--movie_category codes
	select			@movie_category_codes = coalesce(@movie_category_codes + ',', '') + movie_category_code
	from				movie_category
end	
else
begin
	select			@movie_category_codes = coalesce(@movie_category_codes + ',', '') + movie_category_code
	from				cinetam_reachfreq_movcat_xref
	where			result_id = @result_id
end	

/*print 'country_code' + @country_code 	
print 'screening_dates' + @screening_dates
print 'film_markets' + @film_markets
print 'cinetam_reporting_demographics_str' + @cinetam_reporting_demographics_str
print 'product_category_sub_concat_str' + @product_category_sub_concat_str
print 'cinetam_reachfreq_duration_str' + @cinetam_reachfreq_duration_str
print 'movie_ids' + @movie_ids
print 'exhibitor_ids' + @exhibitor_ids
print 'manual_adjustment_factor' + convert(varchar(max), @manual_adjustment_factor)*/

insert into #randf_estimates_ff
exec p_availability_attendance_cost_ff_estimate		@country_code,
													@screening_dates,
													@film_markets,
													@cinetam_reporting_demographics_str,
													@product_category_sub_concat_str	,
													@cinetam_reachfreq_duration_str,
													@movie_ids,
													@exhibitor_ids,
													@manual_adjustment_factor


select * from #randf_estimates_ff

return 0
GO
