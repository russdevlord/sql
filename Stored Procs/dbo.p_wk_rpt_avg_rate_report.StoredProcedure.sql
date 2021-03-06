/****** Object:  StoredProcedure [dbo].[p_wk_rpt_avg_rate_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_wk_rpt_avg_rate_report]
GO
/****** Object:  StoredProcedure [dbo].[p_wk_rpt_avg_rate_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
 * Report Modes/Types are as follows:
 * Modes:	
 * B = Business Unit Level Report
 * M = Media Product Level Report
 * 
 */ 

create proc [dbo].[p_wk_rpt_avg_rate_report]	@mode					char(1),
										@screening_date			datetime,
										@country_code			char(1)

as

declare 	@error					int,
			@mtd_mode_desc			varchar(100),
			@prev_mtd_mode_desc		varchar(100),
			@ytd_avg				money,
			@mtd_avg				money,
			@prev_ytd_avg			money,
			@prev_mtd_avg			money,
			@weekly_avg				money,
			@prev_weekly_avg		money,
			@detail_row_select		varchar(50),
			@ytd_count				money,
			@mtd_count				money,
			@prev_ytd_count			money,
			@prev_mtd_count			money,
			@weekly_count			money,
			@prev_weekly_count		money,
			@mode_id				money,
			@prev_yr_scr_date		datetime,
			@year_start				datetime,
			@prev_year_start		datetime,
			@mtd_start				datetime,
			@mtd_end				datetime,
			@prev_mtd_start			datetime,
			@prev_mtd_end			datetime,
			@mode_title				varchar(100),
			@regional_indicator		char(1),
			@ytd_avail_time			int,
			@mtd_avail_time		int,
			@prev_ytd_avail_time	int,
			@prev_mtd_avail_time	int,
			@weekly_avail_time		int,
			@prev_weekly_avail_time	int,
			@ytd_used_time			int,
			@mtd_used_time			int,
			@prev_ytd_used_time		int,
			@prev_mtd_used_time		int,
			@weekly_used_time		int,
			@prev_weekly_used_time	int,
			@ytd_attendance			int,
			@mtd_attendance			int,
			@prev_ytd_attendance	int,
			@prev_mtd_attendance	int,
			@weekly_attendance		int,
			@prev_weekly_attendance	int

set nocount on

/*
 * Create Temp Tables
 */

create table #avg_spots
(
mode_desc				varchar(50)			not null,
mtd_mode_desc			varchar(100)		not null,
prev_mtd_mode_desc		varchar(100)		not null,
ytd_avg					money				not null,
mtd_avg					money				not null,
prev_ytd_avg			money				not null,
prev_mtd_avg			money				not null,
weekly_avg				money				not null,
prev_weekly_avg			money				not null,
detail_row_desc			varchar(50)			not null,
detail_row_select		varchar(50)			not null,
ytd_count				money				not null,
mtd_count				money				not null,
prev_ytd_count			money				not null,
prev_mtd_count			money				not null,
weekly_count			money				not null,
prev_weekly_count		money				not null,
detail_sort_order		money				not null,
mode_id					int					not null,
regional_indicator		char(1)				not null,
ytd_avail_time			int					not null,
mtd_avail_time		int					not null,
prev_ytd_avail_time		int					not null,
prev_mtd_avail_time		int					not	null,
weekly_avail_time		int					not null,
prev_weekly_avail_time	int					not null,
ytd_used_time			int					not null,
mtd_used_time			int					not null,
prev_ytd_used_time		int					not null,
prev_mtd_used_time		int					not null,
weekly_used_time		int					not null,
prev_weekly_used_time	int					not null,
ytd_attendance			int					not null,
mtd_attendance			int					not null,
prev_ytd_attendance		int					not null,
prev_mtd_attendance		int					not null,
weekly_attendance		int					not null,
prev_weekly_attendance	int					not null
)

create table #detail_desc
(
detail_row_select		varchar(50)			not null,
detail_sort_order		int					not null,
detail_row_desc			varchar(500)		not null
)


/*
 * Initialise Variables
 */

select 	@prev_yr_scr_date = screening_date 
from 	film_screening_dates 
where 	period_no = (	select 	period_no 
						from 	film_screening_dates 
						where 	screening_date = @screening_date) 
and 	finyear_end = (	select 	dateadd(yy, -1, finyear_end) 
						from 	film_screening_dates
						where 	screening_date = @screening_date) 
                        
select	@year_start = dateadd(dd, 1, max(end_date))
from	accounting_period
where 	end_date < @screening_date
and     period_no = 6

select	@prev_year_start = dateadd(dd, 1, max(end_date))
from	accounting_period
where 	end_date < @prev_yr_scr_date
and     period_no = 6

select 	@mtd_start = ap.benchmark_start
from 	accounting_period ap,
		film_screening_date_xref fsd
where	ap.benchmark_end = fsd.benchmark_end
and 	fsd.screening_date = @screening_date

select 	@prev_mtd_start = ap.benchmark_start
from 	accounting_period ap,
		film_screening_date_xref fsd
where	ap.benchmark_end = fsd.benchmark_end
and 	fsd.screening_date = @prev_yr_scr_date

select 	@mtd_end 	= dateadd(dd, 6,  @screening_date)


select 	@prev_mtd_end 	=  dateadd(dd, 6, @prev_yr_scr_date)

if @screening_date > '1-jul-2010'
    select  @prev_yr_scr_date = dateadd(wk, -1, @prev_yr_scr_date),
            @prev_mtd_end = dateadd(wk, -1, @prev_mtd_end),
            @prev_mtd_start = dateadd(wk, -1, @prev_mtd_start),
            @prev_year_start = dateadd(wk, -1, @prev_year_start)
    
    
select 	@mtd_mode_desc 		= 	convert(varchar(15), @mtd_start, 106) + ' - ' + convert(varchar(15), @mtd_end, 106)
select 	@prev_mtd_mode_desc = 	convert(varchar(15), @prev_mtd_start, 106) + ' - ' + convert(varchar(15), @prev_mtd_end, 106)

/*
 * Populate Temp Tables
 */

insert 	into #detail_desc 
values('All', 1, 'All Spots')
insert 	into #detail_desc 
values('S', 2, 'Paid Spots')

if @mode = 'B'
begin

	select @mode_title = 'Business Unit Mode'	

	insert 	into #avg_spots
	(mode_desc,
	mtd_mode_desc,
	prev_mtd_mode_desc,
	ytd_avg,
	mtd_avg,
	prev_ytd_avg,
	prev_mtd_avg,
	weekly_avg,
	prev_weekly_avg,
	detail_row_desc,
	detail_row_select,
	ytd_count,
	mtd_count,
	prev_ytd_count,
	prev_mtd_count,
	weekly_count,
	prev_weekly_count,
	detail_sort_order,
	mode_id,
	regional_indicator,
	ytd_avail_time,
	mtd_avail_time,
	prev_ytd_avail_time,
	prev_mtd_avail_time,
	weekly_avail_time,
	prev_weekly_avail_time,
	ytd_used_time,
	mtd_used_time,
	prev_ytd_used_time,
	prev_mtd_used_time,
	weekly_used_time,
	prev_weekly_used_time,
	ytd_attendance,
	mtd_attendance,
	prev_ytd_attendance,
	prev_mtd_attendance,
	weekly_attendance,
	prev_weekly_attendance
	)
	select 	business_unit_desc,
			@mtd_mode_desc,
			@prev_mtd_mode_desc,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			detail_row_desc,
			detail_row_select,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			detail_sort_order,
			business_unit_id,
			regional_indicator,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0
	from	business_unit,
			#detail_desc,
			complex_region_class
	where 	system_use_only = 'N'
	group by business_unit_desc,
			detail_row_desc,
			detail_row_select,
			detail_sort_order,
			business_unit_id,
			regional_indicator
	order by business_unit_desc,
			regional_indicator
end	
else if @mode = 'M'
begin

	select @mode_title = 'Media Product Mode'	

	insert 	into #avg_spots
	(mode_desc,
	mtd_mode_desc,
	prev_mtd_mode_desc,
	ytd_avg,
	mtd_avg,
	prev_ytd_avg,
	prev_mtd_avg,
	weekly_avg,
	prev_weekly_avg,
	detail_row_desc,
	detail_row_select,
	ytd_count,
	mtd_count,
	prev_ytd_count,
	prev_mtd_count,
	weekly_count,
	prev_weekly_count,
	detail_sort_order,
	mode_id,
	regional_indicator,
	ytd_avail_time,
	mtd_avail_time,
	prev_ytd_avail_time,
	prev_mtd_avail_time,
	weekly_avail_time,
	prev_weekly_avail_time,
	ytd_used_time,
	mtd_used_time,
	prev_ytd_used_time,
	prev_mtd_used_time,
	weekly_used_time,
	prev_weekly_used_time,
	ytd_attendance,
	mtd_attendance,
	prev_ytd_attendance,
	prev_mtd_attendance,
	weekly_attendance,
	prev_weekly_attendance	)
	select 	media_product_desc,
			@mtd_mode_desc,
			@prev_mtd_mode_desc,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			detail_row_desc,
			detail_row_select,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			detail_sort_order,
			media_product_id,
			regional_indicator,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0
	from	media_product,
			#detail_desc,
			complex_region_class
	where 	system_use_only = 'N'
	and		media = 'Y'
	group by media_product_desc,
			detail_row_desc,
			detail_row_select,
			detail_sort_order,
			media_product_id,
			regional_indicator
	order by media_product_desc,
			regional_indicator
end
else
begin
	raiserror ('Error: Unsupported mode - must be run with either B for business unit or M for media product', 16, 1)
end

declare		report_csr cursor forward_only static for
select 		mode_id,
			detail_row_select,
			regional_indicator
from 		#avg_spots
order by 	mode_id,
			regional_indicator,
			detail_row_select
for			read only

open report_csr
fetch report_csr into @mode_id, @detail_row_select, @regional_indicator			
while(@@fetch_status=0)
begin

	select 	@ytd_avg = 0.0,
			@mtd_avg = 0.0,
			@prev_ytd_avg = 0.0,
			@prev_mtd_avg = 0.0,
			@weekly_avg = 0.0,
			@prev_weekly_avg = 0.0,
			@ytd_count = 0,
			@mtd_count = 0,
			@prev_ytd_count = 0,
			@prev_mtd_count = 0,
			@weekly_count = 0,
			@prev_weekly_count = 0,
			@ytd_avail_time = 0,
			@mtd_avail_time = 0,
			@prev_ytd_avail_time = 0,
			@prev_mtd_avail_time = 0,
			@weekly_avail_time = 0,
			@prev_weekly_avail_time = 0,
			@ytd_used_time = 0,
			@mtd_used_time = 0,
			@prev_ytd_used_time = 0,
			@prev_mtd_used_time = 0,
			@weekly_used_time = 0,
			@prev_weekly_used_time = 0,
			@ytd_attendance = 0,
			@mtd_attendance = 0,
			@prev_ytd_attendance = 0,
			@prev_mtd_attendance = 0,
			@weekly_attendance = 0,
			@prev_weekly_attendance = 0

	-- get screening week averge	
	exec @error = p_wk_rpt_avg_rate_report_sub		@detail_row_select,
												 	@screening_date, 
													@screening_date, 
													@mode, 
													@mode_id, 
													@country_code,
													@regional_indicator,
													@weekly_avg OUTPUT,
													@weekly_count OUTPUT,
													@weekly_used_time OUTPUT,
													@weekly_avail_time OUTPUT,
													@weekly_attendance OUTPUT
	if @error != 0
	begin
		raiserror ('Error: Could not get billing week average.' , 16, 1)
		return -1
	end


	-- get mtd month averge	
	exec @error = p_wk_rpt_avg_rate_report_sub		@detail_row_select,
												 	@mtd_start, 
												 	@mtd_end, 
													@mode, 
													@mode_id, 
													@country_code,
													@regional_indicator,
													@mtd_avg OUTPUT,
													@mtd_count OUTPUT,
													@mtd_used_time OUTPUT,
													@mtd_avail_time OUTPUT,
													@mtd_attendance OUTPUT

	if @error != 0
	begin
		raiserror ('Error: Could not get mtd month average.' , 16, 1)
		return -1
	end


	-- get mtd month averge	
	exec @error = p_wk_rpt_avg_rate_report_sub		@detail_row_select,
												 	@year_start, 
												 	@screening_date, 
													@mode, 
													@mode_id, 
													@country_code,
													@regional_indicator,
													@ytd_avg OUTPUT,
													@ytd_count OUTPUT,
													@ytd_used_time OUTPUT,
													@ytd_avail_time OUTPUT,
													@ytd_attendance OUTPUT

	if @error != 0
	begin
		raiserror ('Error: Could not get ytd average.' , 16, 1)
		return -1
	end

	-- get screening week averge	
	exec @error = p_wk_rpt_avg_rate_report_sub		@detail_row_select,
												 	@prev_yr_scr_date, 
													@prev_yr_scr_date, 
													@mode, 
													@mode_id, 
													@country_code,
													@regional_indicator,
													@prev_weekly_avg OUTPUT,
													@prev_weekly_count OUTPUT,
													@prev_weekly_used_time OUTPUT,
													@prev_weekly_avail_time OUTPUT,
													@prev_weekly_attendance OUTPUT
	if @error != 0
	begin
		raiserror ('Error: Could not get prev billing week average.' , 16, 1)
		return -1
	end


	-- get mtd month averge	
	exec @error = p_wk_rpt_avg_rate_report_sub		@detail_row_select,
												 	@prev_mtd_start, 
												 	@prev_mtd_end, 
													@mode, 
													@mode_id, 
													@country_code,
													@regional_indicator,
													@prev_mtd_avg OUTPUT,
													@prev_mtd_count OUTPUT,
													@prev_mtd_used_time OUTPUT,
													@prev_mtd_avail_time OUTPUT,
													@prev_mtd_attendance OUTPUT

	if @error != 0
	begin
		raiserror ('Error: Could not get prev mtd month average.' , 16, 1)
		return -1
	end


	-- get mtd month averge	
	exec @error = p_wk_rpt_avg_rate_report_sub		@detail_row_select,
												 	@prev_year_start, 
												 	@prev_yr_scr_date, 
													@mode, 
													@mode_id, 
													@country_code,
													@regional_indicator,
													@prev_ytd_avg OUTPUT,
													@prev_ytd_count OUTPUT,
													@prev_ytd_used_time OUTPUT,
													@prev_ytd_avail_time OUTPUT,
													@prev_ytd_attendance OUTPUT

	if @error != 0
	begin
		raiserror ('Error: Could not get prev ytd average.' , 16, 1)
		return -1
	end

	update #avg_spots
	set 	ytd_avg = @ytd_avg,
			mtd_avg = @mtd_avg,
			prev_ytd_avg = @prev_ytd_avg,
			prev_mtd_avg= @prev_mtd_avg,
			weekly_avg= @weekly_avg,
			prev_weekly_avg =@prev_weekly_avg,
			ytd_count = @ytd_count,
			mtd_count = @mtd_count,
			prev_ytd_count = @prev_ytd_count,
			prev_mtd_count = @prev_mtd_count,
			weekly_count = @weekly_count,
			prev_weekly_count = @prev_weekly_count,
			ytd_avail_time = @ytd_avail_time,
			mtd_avail_time = @mtd_avail_time,
			prev_ytd_avail_time = @prev_ytd_avail_time,
			prev_mtd_avail_time = @prev_mtd_avail_time,
			weekly_avail_time = @weekly_avail_time,
			prev_weekly_avail_time = @prev_weekly_avail_time,
			ytd_used_time = @ytd_used_time,
			mtd_used_time = @mtd_used_time,
			prev_ytd_used_time = @prev_ytd_used_time,
			prev_mtd_used_time = @prev_mtd_used_time,
			weekly_used_time = @weekly_used_time,
			prev_weekly_used_time = @prev_weekly_used_time,
			ytd_attendance = @ytd_attendance,
			mtd_attendance = @mtd_attendance,
			prev_ytd_attendance = @prev_ytd_attendance,
			prev_mtd_attendance = @prev_mtd_attendance,
			weekly_attendance = @weekly_attendance,
			prev_weekly_attendance = @prev_weekly_attendance
	where 	mode_id = @mode_id
	and		detail_row_select = @detail_row_select
	and		regional_indicator = @regional_indicator

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could not update temp table.' , 16, 1)
		return -1
	end

	fetch report_csr into @mode_id, @detail_row_select, @regional_indicator
end

deallocate report_csr

select 		*,
			convert(varchar(15), @screening_date, 106) as billing_date_desc,
			convert(varchar(15), @prev_yr_scr_date, 106) as prev_billing_date_desc,
			convert(varchar(15), @year_start, 106) + ' - ' + convert(varchar(15), dateadd(dd, 6, @screening_date), 106) as year_desc,
			convert(varchar(15), @prev_year_start, 106) + ' - ' + convert(varchar(15), dateadd(dd, 6, @prev_yr_scr_date), 106) as prev_year_desc,
			@mode_title
from 		#avg_spots 
order by	mode_id, 
			detail_sort_order

return 0
GO
