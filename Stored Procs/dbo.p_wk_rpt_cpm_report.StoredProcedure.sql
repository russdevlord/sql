/****** Object:  StoredProcedure [dbo].[p_wk_rpt_cpm_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_wk_rpt_cpm_report]
GO
/****** Object:  StoredProcedure [dbo].[p_wk_rpt_cpm_report]    Script Date: 12/03/2021 10:03:50 AM ******/
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

create proc [dbo].[p_wk_rpt_cpm_report]	@mode					char(1),
                                @screening_date			datetime,
                                @country_code			char(1)

as

declare 	@error					int,
			@mtd_mode_desc			varchar(100),
			@prev_mtd_mode_desc		varchar(100),
			@ytd_cpm				money,
			@mtd_cpm				money,
			@prev_ytd_cpm			money,
			@prev_mtd_cpm			money,
			@weekly_cpm				money,
			@prev_weekly_cpm		money,
			@detail_row_select		varchar(50),
			@ytd_impacts			integer,
			@mtd_impacts			integer,
			@prev_ytd_impacts		integer,
			@prev_mtd_impacts		integer,
			@weekly_impacts			integer,
			@prev_weekly_impacts	integer,
			@mode_id				money,
			@prev_yr_scr_date		datetime,
			@year_start				datetime,
			@prev_year_start		datetime,
			@mtd_start				datetime,
			@mtd_end				datetime,
			@prev_mtd_start			datetime,
			@prev_mtd_end			datetime,
			@mode_title				varchar(100),
			@regional_indicator		char(1)

set nocount on

/*
 * Create Temp Tables
 */

create table #cpm_spots
(
mode_desc				varchar(50)			not null,
mtd_mode_desc			varchar(100)		not null,
prev_mtd_mode_desc		varchar(100)		not null,
ytd_cpm					money				not null,
mtd_cpm					money				not null,
prev_ytd_cpm			money				not null,
prev_mtd_cpm			money				not null,
weekly_cpm				money				not null,
prev_weekly_cpm			money				not null,
detail_row_desc			varchar(50)			not null,
detail_row_select		varchar(50)			not null,
ytd_impacts				int 				not null,
mtd_impacts				int 				not null,
prev_ytd_impacts		int 				not null,
prev_mtd_impacts		int 				not null,
weekly_impacts			int 				not null,
prev_weekly_impacts		int 				not null,
detail_sort_order		int 				not null,
mode_id					int					not null,
regional_indicator		char(1)				not null,
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

select	@year_start = financial_year.finyear_start
from	film_screening_date_xref,
        financial_year
where 	screening_date = @screening_date
and     financial_year.finyear_end = film_screening_date_xref.finyear_end

select	@prev_year_start = financial_year.finyear_start
from	film_screening_date_xref,
        financial_year
where 	screening_date = @prev_yr_scr_date 
and     financial_year.finyear_end = film_screening_date_xref.finyear_end

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

select 	@mtd_mode_desc 		= 	convert(varchar(15), @mtd_start, 106) + ' - ' + convert(varchar(15), @mtd_end, 106)
select 	@prev_mtd_mode_desc = 	convert(varchar(15), @prev_mtd_start, 106) + ' - ' + convert(varchar(15), @prev_mtd_end, 106)

if @screening_date > '1-jul-2010'
    select  @prev_yr_scr_date = dateadd(wk, 1, @prev_yr_scr_date),
            @prev_mtd_end = dateadd(wk, 1, @prev_mtd_end),
            @prev_mtd_start = dateadd(wk, 1, @prev_mtd_start),
            @prev_year_start = dateadd(wk, 1, @prev_year_start)

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

	insert 	into #cpm_spots
	(mode_desc,
	mtd_mode_desc,
	prev_mtd_mode_desc,
	ytd_cpm,
	mtd_cpm,
	prev_ytd_cpm,
	prev_mtd_cpm,
	weekly_cpm,
	prev_weekly_cpm,
	detail_row_desc,
	detail_row_select,
	ytd_impacts,
	mtd_impacts,
	prev_ytd_impacts,
	prev_mtd_impacts,
	weekly_impacts,
	prev_weekly_impacts,
	detail_sort_order,
	mode_id,
	regional_indicator
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
			regional_indicator
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

	insert 	into #cpm_spots
	(mode_desc,
	mtd_mode_desc,
	prev_mtd_mode_desc,
	ytd_cpm,
	mtd_cpm,
	prev_ytd_cpm,
	prev_mtd_cpm,
	weekly_cpm,
	prev_weekly_cpm,
	detail_row_desc,
	detail_row_select,
	ytd_impacts,
	mtd_impacts,
	prev_ytd_impacts,
	prev_mtd_impacts,
	weekly_impacts,
	prev_weekly_impacts,
	detail_sort_order,
	mode_id,
	regional_indicator	)
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
			regional_indicator
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
from 		#cpm_spots
order by 	mode_id,
			regional_indicator,
			detail_row_select
for			read only

open report_csr
fetch report_csr into @mode_id, @detail_row_select, @regional_indicator			
while(@@fetch_status=0)
begin

	select 	@ytd_cpm = 0.0,
			@mtd_cpm = 0.0,
			@prev_ytd_cpm = 0.0,
			@prev_mtd_cpm = 0.0,
			@weekly_cpm = 0.0,
			@prev_weekly_cpm = 0.0,
			@ytd_impacts = 0,
			@mtd_impacts = 0,
			@prev_ytd_impacts = 0,
			@prev_mtd_impacts = 0,
			@weekly_impacts = 0,
			@prev_weekly_impacts = 0
			

	-- get screening week averge	
	exec @error = p_wk_rpt_cpm_report_sub		@detail_row_select,
                                                @screening_date, 
                                                @screening_date, 
                                                @mode, 
                                                @mode_id, 
                                                @country_code,
                                                @regional_indicator,
                                                @weekly_cpm OUTPUT,
                                                @weekly_impacts OUTPUT
	if @error != 0
	begin
		raiserror ('Error: Could not get billing week average.' , 16, 1)
		return -1
	end


	-- get mtd month averge	
	exec @error = p_wk_rpt_cpm_report_sub		@detail_row_select,
                                                @mtd_start, 
                                                @mtd_end, 
                                                @mode, 
                                                @mode_id, 
                                                @country_code,
                                                @regional_indicator,
                                                @mtd_cpm OUTPUT,
                                                @mtd_impacts OUTPUT
	if @error != 0
	begin
		raiserror ('Error: Could not get mtd month average.' , 16, 1)
		return -1
	end


	-- get mtd month averge	
	exec @error = p_wk_rpt_cpm_report_sub		@detail_row_select,
                                                @year_start, 
                                                @screening_date, 
                                                @mode, 
                                                @mode_id, 
                                                @country_code,
                                                @regional_indicator,
                                                @ytd_cpm OUTPUT,
                                                @ytd_impacts OUTPUT

	if @error != 0
	begin
		raiserror ('Error: Could not get ytd average.' , 16, 1)
		return -1
	end

	-- get screening week averge	
	exec @error = p_wk_rpt_cpm_report_sub		@detail_row_select,
                                                @prev_yr_scr_date, 
                                                @prev_yr_scr_date, 
                                                @mode, 
                                                @mode_id, 
                                                @country_code,
                                                @regional_indicator,
                                                @prev_weekly_cpm OUTPUT,
                                                @prev_weekly_impacts OUTPUT
	if @error != 0
	begin
		raiserror ('Error: Could not get prev billing week average.' , 16, 1)
		return -1
	end


	-- get mtd month averge	
	exec @error = p_wk_rpt_cpm_report_sub		@detail_row_select,
                                                @prev_mtd_start, 
                                                @prev_mtd_end, 
                                                @mode, 
                                                @mode_id, 
                                                @country_code,
                                                @regional_indicator,
                                                @prev_mtd_cpm OUTPUT,
                                                @prev_mtd_impacts OUTPUT

	if @error != 0
	begin
		raiserror ('Error: Could not get prev mtd month average.' , 16, 1)
		return -1
	end


	-- get mtd month averge	
	exec @error = p_wk_rpt_cpm_report_sub		@detail_row_select,
                                                @prev_year_start, 
                                                @prev_yr_scr_date, 
                                                @mode, 
                                                @mode_id, 
                                                @country_code,
                                                @regional_indicator,
                                                @prev_ytd_cpm OUTPUT,
                                                @prev_ytd_impacts OUTPUT

	if @error != 0
	begin
		raiserror ('Error: Could not get prev ytd average.' , 16, 1)
		return -1
	end

	update #cpm_spots
	set 	ytd_cpm = @ytd_cpm,
			mtd_cpm = @mtd_cpm,
			prev_ytd_cpm = @prev_ytd_cpm,
			prev_mtd_cpm= @prev_mtd_cpm,
			weekly_cpm= @weekly_cpm,
			prev_weekly_cpm =@prev_weekly_cpm,
			ytd_impacts = @ytd_impacts,
			mtd_impacts = @mtd_impacts,
			prev_ytd_impacts = @prev_ytd_impacts,
			prev_mtd_impacts = @prev_mtd_impacts,
			weekly_impacts = @weekly_impacts,
			prev_weekly_impacts = @prev_weekly_impacts
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
from 		#cpm_spots 
order by	mode_id, 
			detail_sort_order

return 0
GO
