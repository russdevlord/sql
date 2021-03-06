/****** Object:  StoredProcedure [dbo].[p_wk_rpt_avg_rate_report_sub]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_wk_rpt_avg_rate_report_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_wk_rpt_avg_rate_report_sub]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_wk_rpt_avg_rate_report_sub]	@spot_type			varchar(100),
											@start_date			datetime,
											@end_date			datetime,
											@mode				char(1),
											@mode_id			int,
											@country_code		char(1),
											@regional_indicator	char(1),
                                            @avg                money OUTPUT,
											@count              money OUTPUT,
											@used_time			int OUTPUT,
											@avail_time			int OUTPUT,
											@attendance			int OUTPUT

as 

declare		@error				int

if @mode_id < 6 
begin
	select 	@avg = isnull(avg(cs.charge_rate),0),
			@count = isnull(count(cs.spot_id),0)
	from	campaign_spot cs,
			film_campaign fc,
			campaign_package cp,
			branch b,
			complex,
			complex_region_class
	where	cs.campaign_no = fc.campaign_no
	and		cs.package_id = cp.package_id
	and		fc.branch_code = b.branch_code
	and		b.country_code = @country_code
	and		cs.billing_date <= @end_date
	and		cs.billing_date >=  @start_date
	and		cs.complex_id = complex.complex_id
	and		complex_region_class.complex_region_class = complex.complex_region_class
	and		complex_region_class.regional_indicator = @regional_indicator
	and    	((@spot_type != 'All'
	and		cs.spot_type = @spot_type)
	or		(@spot_type = 'All'
	and		cs.spot_type in ('S','B','C','N')))
	and 	cs.spot_status != 'P'
	and		((@mode = 'B'
	and		fc.business_unit_id = @mode_id)
	or		(@mode = 'M'
	and		cp.media_product_id = @mode_id))
	
	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could not determine Avg/Count of spots.', 16, 1)
		return -1
	end
end
else
begin
	select 	@avg = isnull(avg(cs.charge_rate),0),
			@count = isnull(count(cs.spot_id),0)
	from	outpost_spot cs,
			film_campaign fc,
			outpost_package cp,
			branch b,
			outpost_panel,
			outpost_venue,
			outpost_venue_region_class
	where	cs.campaign_no = fc.campaign_no
	and		cs.package_id = cp.package_id
	and		fc.branch_code = b.branch_code
	and		b.country_code = @country_code
	and		cs.billing_date <= dateadd(dd, 3, @end_date)
	and		cs.billing_date >=  dateadd(dd, 3, @start_date)
	and		cs.outpost_panel_id = outpost_panel.outpost_panel_id
	and		outpost_panel.outpost_venue_id = outpost_venue.outpost_venue_id
	and		outpost_venue_region_class.region_class = outpost_venue.region_class
	and		outpost_venue_region_class.regional_indicator = @regional_indicator
	and    	((@spot_type != 'All'
	and		cs.spot_type = @spot_type)
	or		(@spot_type = 'All'
	and		cs.spot_type in ('S','B','C','N')))
	and 	cs.spot_status != 'P'
	and		((@mode = 'B'
	and		fc.business_unit_id = @mode_id)
	or		(@mode = 'M'
	and		cp.media_product_id = @mode_id))
	
	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could not determine Avg/Count of retail spots.', 16, 1)
		return -1
	end
end

if @mode_id < 6 and @mode = 'B' and @spot_type = 'All'
begin
	select 	@attendance = isnull(sum(movie_history.attendance),0)
	from	movie_history,
			(select distinct complex.complex_id
			from	complex,
					complex_region_class,
					branch
			where	complex.branch_code = branch.branch_code
			and		branch.country_code = @country_code
			and		complex_region_class.complex_region_class = complex.complex_region_class
			and		complex_region_class.regional_indicator = @regional_indicator)	as temp_complex_table
	where	movie_history.screening_date <= dateadd(dd, -7, @end_date)
	and		movie_history.screening_date  >=  dateadd(dd, -7, @start_date)
	and		movie_history.complex_id = temp_complex_table.complex_id
	
	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could not determine attendance.', 16, 1)
		return -1
	end

	select	@used_time = isnull(sum(cp.duration),0)
	from 	v_certificate_item_distinct ci,
			certificate_group cg,
			campaign_spot cs,
			campaign_package cp,
			film_campaign fc,
			(select distinct complex.complex_id
			from	complex,
					complex_region_class,
					branch
			where	complex.branch_code = branch.branch_code
			and		branch.country_code = @country_code
			and		complex_region_class.complex_region_class = complex.complex_region_class
			and		complex_region_class.regional_indicator = @regional_indicator)	as temp_complex_table
	where 	cg.certificate_group_id = ci.certificate_group
	and		cg.screening_date <= @end_date
	and		cg.screening_date >=  @start_date
	and		ci.spot_reference = cs.spot_id
	and		cs.campaign_no = fc.campaign_no
	and		fc.business_unit_id = @mode_id
	and		fc.campaign_no = cp.campaign_no
	and		cp.package_id = cs.package_id
	and		cs.complex_id = temp_complex_table.complex_id
	and		cg.complex_id = cs.complex_id
	and		cg.complex_id = temp_complex_table.complex_id

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could not used time.', 16, 1)
		return -1
	end
end

if @mode_id = 2 and @mode = 'B' and @spot_type = 'All'
begin 
	select 	@avail_time = isnull(sum(complex_date.max_time),0)
	from	complex_date,
			movie_history,
			(select distinct complex.complex_id
			from	complex,
					complex_region_class,
					branch
			where	complex.branch_code = branch.branch_code
			and		branch.country_code = @country_code
			and		complex_region_class.complex_region_class = complex.complex_region_class
			and		complex_region_class.regional_indicator = @regional_indicator)	as temp_complex_table
	where	complex_date.screening_date <= @end_date
	and		complex_date.screening_date  >=  @start_date
	and		movie_history.screening_date <= @end_date
	and		movie_history.screening_date  >=  @start_date
	and		complex_date.complex_id = movie_history.complex_id
	and		complex_date.complex_id = temp_complex_table.complex_id
	and		movie_history.complex_id = temp_complex_table.complex_id
	and		complex_date.screening_date = movie_history.screening_date
	and		movie_history.advertising_open = 'Y'

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could not determine avail time.', 16, 1)
		return -1
	end
end
else if (@mode_id = 3 or @mode_id = 5) and @mode = 'B' and @spot_type = 'All'
begin

	select 	@avail_time = isnull(sum(complex_date.mg_max_time),0)
	from	complex_date,
			movie_history,
			(select distinct complex.complex_id
			from	complex,
					complex_region_class,
					branch
			where	complex.branch_code = branch.branch_code
			and		branch.country_code = @country_code
			and		complex_region_class.complex_region_class = complex.complex_region_class
			and		complex_region_class.regional_indicator = @regional_indicator)	as temp_complex_table
	where	complex_date.screening_date <= @end_date
	and		complex_date.screening_date  >=  @start_date
	and		movie_history.screening_date <= @end_date
	and		movie_history.screening_date  >=  @start_date
	and		complex_date.complex_id = movie_history.complex_id
	and		complex_date.complex_id = temp_complex_table.complex_id
	and		movie_history.complex_id = temp_complex_table.complex_id
	and		complex_date.screening_date = movie_history.screening_date
	and		movie_history.advertising_open = 'Y'

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could not determine avail time.', 16, 1)
		return -1
	end
end
else if (@mode_id = 6) and @mode = 'B'
begin

	select 	@avail_time = 0,
			@used_time = 0/*isnull(sum(complex_date.mg_max_time),0)
	from	complex_date,
			movie_history,
			(select distinct complex.complex_id
			from	campaign_spot cs,
					film_campaign fc,
					campaign_package cp,
					branch b,
					complex,
					complex_region_class
			where	cs.campaign_no = fc.campaign_no
			and		cs.package_id = cp.package_id
			and		fc.branch_code = b.branch_code
			and		b.country_code = @country_code
			and		cs.billing_date <= @end_date
			and		cs.billing_date >=  @start_date
			and		cs.complex_id = complex.complex_id
			and		complex_region_class.complex_region_class = complex.complex_region_class
			and		complex_region_class.regional_indicator = @regional_indicator
			and		spot_status = 'X'
			and		fc.business_unit_id = @mode_id)	as temp_complex_table
	where	complex_date.screening_date <= @end_date
	and		complex_date.screening_date  >=  @start_date
	and		movie_history.screening_date <= @end_date
	and		movie_history.screening_date  >=  @start_date
	and		complex_date.complex_id = movie_history.complex_id
	and		complex_date.complex_id = temp_complex_table.complex_id
	and		movie_history.complex_id = temp_complex_table.complex_id
	and		complex_date.screening_date = movie_history.screening_date*/

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could not determine Avg/Count of spots.', 16, 1)
		return -1
	end
end

return 0
GO
