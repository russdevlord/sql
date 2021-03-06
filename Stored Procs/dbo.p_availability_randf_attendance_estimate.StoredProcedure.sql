/****** Object:  StoredProcedure [dbo].[p_availability_randf_attendance_estimate]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_availability_randf_attendance_estimate]
GO
/****** Object:  StoredProcedure [dbo].[p_availability_randf_attendance_estimate]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE proc	[dbo].[p_availability_randf_attendance_estimate]			@result_id			int

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
				@cost																	money,
				@agency_id_cpm													int	

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

select		@country_code = country_code, @agency_id=agency_id, @business_unit_id=business_unit_id
from			cinetam_reachfreq_resultset
where		resultset_id = @resultset_id

select		@product_category_sub_concat_id = product_category_sub_concat_id
from			product_category_sub_concat
where		product_category_id = @product_category_id
and			isnull(product_subcategory_id, 0) = isnull(@product_subcategory_id, 0)

create table #randf_attendance
(
	screening_date									datetime			not null,
	demo_attendance									numeric(20,8)	not null,
	all_people_attendance							numeric(20,8)	not null,
	--demo_cpm											money				not null,
	full_attendance									numeric(20,8)	not null
)

create table #randf_cpm
(
	screening_date									datetime			not null,
	demo_cpm											money				not null	
)

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

--select @movie_category_codes

create table #availability_attendance_randf
(
	screening_date									datetime			not null,
	generation_date									datetime			not null,
	country_code										char(1)				not null,
	film_market_no									int					not null,
	complex_id											int					not null,
	complex_name										varchar(50)		not null,
	cinetam_reporting_demographics_id	int					not null,
	cinetam_reachfreq_duration_id			int					not null,
	exhibitor_id											int					not null,
	product_category_sub_concat_id		int					not null,
	movie_category_code							char(2)				not null,
	demo_attendance									numeric(20,8)	not null,
	all_people_attendance							numeric(20,8)	not null,
	product_booked_percentage				numeric(20,8)	not null,
	current_booked_percentage				numeric(20,8)	not null,
	projected_booked_percentage			numeric(20,8)	not null,
	full_attendance									numeric(20,8)	not null
)

create table #availability_attendance_randf_ff
(
	screening_date									datetime			not null,
	generation_date									datetime			not null,
	country_code										char(1)				not null,
	film_market_no									int					not null,
	complex_id											int					not null,
	complex_name										varchar(50)		not null,
	cinetam_reporting_demographics_id	int					not null,
	cinetam_reachfreq_duration_id			int					not null,
	exhibitor_id											int					not null,
	product_category_sub_concat_id		int					not null,
	movie_id												int					not null,
	demo_attendance									numeric(20,8)	not null,
	all_people_attendance							numeric(20,8)	not null,
	product_booked_percentage				numeric(20,8)	not null,
	current_booked_percentage				numeric(20,8)	not null,
	projected_booked_percentage			numeric(20,8)	not null	
)

if @cinetam_reachfreq_mode_id = 1
begin
	insert into #availability_attendance_randf_ff
	exec @error = p_availability_attendance_ff_estimate	@country_code,
																			@screening_dates,
																			@film_markets,
																			@cinetam_reporting_demographics_str,
																			@product_category_sub_concat_str	,
																			@cinetam_reachfreq_duration_str,
																			@movie_ids,
																			@exhibitor_ids,
																			@manual_adjustment_factor

	if @error <> 0
	begin		
		raiserror ('Error running availability procedure', 16, 1)
		return -1
	end

	insert		into #randf_attendance
	select		screening_date,
					isnull(sum(case when current_booked_percentage = 1 then 0 when projected_booked_percentage = 1 then 0 else (1 - product_booked_percentage) * demo_attendance end),0),
					isnull(sum(case when current_booked_percentage = 1 then 0 when projected_booked_percentage = 1 then 0 else (1 - product_booked_percentage) * all_people_attendance end),0),
					--100.0,
					10000
	from			#availability_attendance_randf_ff
	group by	screening_date
	order by screening_date
end
else
begin
	--print 'country_code' + @country_code 
	--print 'cinetam_reachfreq_mode_id' + convert(varchar(max), @cinetam_reachfreq_mode_id)
	--print 'screening_dates' + @screening_dates
	--print 'film_markets' + @film_markets
	--print 'cinetam_reporting_demographics_str' + @cinetam_reporting_demographics_str
	--print 'product_category_sub_concat_str' + @product_category_sub_concat_str
	--print 'cinetam_reachfreq_duration_str' + @cinetam_reachfreq_duration_str
	--print 'exhibitor_ids' + @exhibitor_ids
	--print 'manual_adjustment_factor' + convert(varchar(max), @manual_adjustment_factor)
	--print 'premium_position' + convert(varchar(max), @premium_position)
	--print 'alcohol_gambling' + convert(varchar(max), @alcohol_gambling)
	--print 'ma15_above' + convert(varchar(max), @ma15_above)
	--print 'exclude_children' + convert(varchar(max), @exclude_children)
	--print 'movie_category_codes' + isnull(@movie_category_codes, '')
	--print 'agency_id' + convert(varchar(max), @agency_id)                                                         
 --   print 'business_unit_id' + convert(varchar(max), @business_unit_id)


	insert into #availability_attendance_randf
	exec @error = p_availability_attendance_estimate									@country_code, 
																			@cinetam_reachfreq_mode_id,
																			@screening_dates,
																			@film_markets,
																			@cinetam_reporting_demographics_id,
																			@product_category_sub_concat_id, 
																			@cinetam_reachfreq_duration_id,
																			@exhibitor_ids,
																			@manual_adjustment_factor,
																			@premium_position,
																			@alcohol_gambling,
																			@ma15_above,
																			@exclude_children,
																			@movie_category_codes	

	if @error <> 0
	begin		
		raiserror ('Error running availability procedure', 16, 1)
		return -1
	end

	--select * from #availability_attendance_randf

	insert		into #randf_attendance
	select		screening_date,
					isnull(sum(case when current_booked_percentage = 1 then 0 else (1 - product_booked_percentage) * demo_attendance * 0.9 end),0),
					isnull(sum(case when current_booked_percentage = 1 then 0 else (1 - product_booked_percentage) * all_people_attendance * 0.9 end),0),
					--100.0,
					full_attendance
	from			#availability_attendance_randf
	group by	screening_date,
	full_attendance
	order by screening_date



/*ORINGAL*/
/*insert		into #randf_attendance
	select		screening_date, 
					sum(((1 - current_booked_percentage) * demo_attendance)),
					sum(((1 - current_booked_percentage) * all_people_attendance)),
					--@cost,
					full_attendance
	from			#availability_attendance_randf
	group by	screening_date,full_attendance*/


	/*
	 * Determine Cost - MM ,TAP
	 */

	if @cinetam_reachfreq_mode_id = 2 or @cinetam_reachfreq_mode_id = 3
	begin
		set @agency_id_cpm=(SELECT (CASE 
							WHEN EXISTS (SELECT * FROM agency_cpm where agency_id= @agency_id) THEN @agency_id
							WHEN @country_code='A' THEN 1 
							WHEN @country_code='Z' THEN 2 ELSE '1'END)) 

		select param as screening_date into #ScreeningDates from dbo.f_multivalue_parameter(@screening_dates,',') 		

		select film_market_no,regional into #FilmMarkets from 
		(select * from film_market fm inner join dbo.f_multivalue_parameter(@film_markets,',') as selected_markets 
		on fm.film_market_no=selected_markets.param) as selected_markets
		
		insert into #randf_cpm		
		select peaktime.screening_date,cpm from agency_cpm as cpm 
		inner join availability_peak_time_xref as peaktime
		on cpm.availability_peak_time_id = peaktime.attendance_availability_peak_time_id
		inner join #ScreeningDates as dates
		on dates.screening_date =peaktime.screening_date
		where  agency_id= @agency_id_cpm
		and business_unit_id = @business_unit_id
		and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
		and cinetam_reachfreq_duration_id = @cinetam_reachfreq_duration_id
		and cinetam_reachfreq_mode_id = @cinetam_reachfreq_mode_id				

		update   #randf_cpm                  
		set    demo_cpm  = (demo_cpm +  temp_table.MarketLoading)
		from    
		(select peaktime.screening_date,isnull(cpm,0) as MarketLoading from agency_cpm_market_loading as cpmMarket 
		inner join availability_peak_time_xref as peaktime
		on cpmMarket.availability_peak_time_id = peaktime.attendance_availability_peak_time_id
		inner join #ScreeningDates as dates
		on dates.screening_date =peaktime.screening_date
		where  
		cpmMarket.agency_id = @agency_id_cpm
		and metro_or_regional = (SELECT (CASE 
								WHEN NOT EXISTS(SELECT * from #FilmMarkets where regional='Y') THEN 'Y'
								WHEN NOT EXISTS(SELECT * from #FilmMarkets where regional='N') THEN 'N'	
								ELSE '' END)) 
		and cpmMarket.business_unit_id=@business_unit_id
		and cpmMarket.cinetam_reachfreq_mode_id=@cinetam_reachfreq_mode_id
		)		
		as temp_table where temp_table.screening_date = #randf_cpm.screening_date

		if(@premium_position = 1)
		begin                  
			update   #randf_cpm                  
			set    demo_cpm  = (demo_cpm +  temp_table.PremiumLoading)
			from    
			(select peaktime.screening_date,isnull(cpm,0) as PremiumLoading from  agency_cpm_premium_loading as cpmPremium 
			inner join availability_peak_time_xref as peaktime
			on cpmPremium.availability_peak_time_id = peaktime.attendance_availability_peak_time_id
			inner join #ScreeningDates as dates
			on dates.screening_date =peaktime.screening_date
			where  cpmPremium.agency_id = @agency_id_cpm
			and cpmPremium.business_unit_id = @business_unit_id
			and cpmPremium.cinetam_reachfreq_mode_id = @cinetam_reachfreq_mode_id
			)			
			as temp_table where temp_table.screening_date = #randf_cpm.screening_date
		end

		IF OBJECT_ID('tempdb..#ScreeningDates') IS NOT NULL
			DROP TABLE #ScreeningDates
		
		IF OBJECT_ID('tempdb..#FilmMarkets') IS NOT NULL
			DROP TABLE #FilmMarkets
	end		

end

select atttendance_items.screening_date,atttendance_items.demo_attendance,
atttendance_items.all_people_attendance,cpm_items.demo_cpm,atttendance_items.full_attendance
from #randf_attendance as atttendance_items 
left join #randf_cpm as cpm_items
on atttendance_items.screening_date=cpm_items.screening_date

return 0
GO
