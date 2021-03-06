/****** Object:  StoredProcedure [dbo].[p_wk_rpt_revenue_rpt]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_wk_rpt_revenue_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_wk_rpt_revenue_rpt]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_wk_rpt_revenue_rpt]	@mode					char(1),
									@screening_date			datetime,
									@country_code			char(1)

as

declare	@error								int,
		@business_unit_id					int,
		@media_product_id					int,
		@branch_code						char(2),
		@gross_revenue						money,
		@agency_commission					money,
		@theatre_rent						money,
		@last_year_gross_revenue			money,
		@last_year_agency_commission		money,
		@last_year_theatre_rent				money,
		@mtd_gross_revenue					money,
		@mtd_agency_commission				money,
		@mtd_theatre_rent					money,
		@mtd_last_year_gross_revenue		money,
		@mtd_last_year_agency_commission	money,
		@mtd_last_year_theatre_rent			money,
		@ytd_gross_revenue					money,
		@ytd_agency_commission				money,
		@ytd_theatre_rent					money,
		@ytd_last_year_gross_revenue		money,
		@ytd_last_year_agency_commission	money,
		@ytd_last_year_theatre_rent			money,
		@revenue_source						char(1),
		@mtd_mode_desc						varchar(100),
		@prev_mtd_mode_desc					varchar(100),
		@prev_yr_scr_date					datetime,
		@year_start							datetime,
		@prev_year_start					datetime,
		@mtd_start							datetime,
		@mtd_end							datetime,
		@prev_mtd_start						datetime,
		@prev_mtd_end						datetime


set nocount on

/*
 * Create Temp Tables
 */

create table #billings
(
	billing_date						datetime		not null,
	country_code						char(1)			not null,
	business_unit_id					int				not null,
	media_product_id					int				not null,
	revenue_source						char(1)			not null,
	complex_id							int				not null,
	billings							money			not null,
	agency_commission					money			not null,
	net_billings						money			not null
)

create table #cag_entitlements
(	complex_id							int				not null,
	revenue_source						char(1)			not null,
	percentage_entitlement				numeric(6,4)	not null
)

create table #revenue
(
	mode_desc							varchar(50)		not null,
	detail_row_desc						varchar(50)		not null,
	detail_row_sort						int				not null,
	business_unit_id					int				not null,
	business_unit_desc					varchar(100)	not null,
	media_product_id					int				not null,
	media_product_desc					varchar(100)	not null,
	revenue_source						char(1)			not null,
	screening_date						datetime		not null,
	last_year_screening_date			datetime		not null,
	gross_revenue						money			not null,
	agency_commission					money			not null,
	theatre_rent						money			not null,
	last_year_gross_revenue				money			not null,
	last_year_agency_commission			money			not null,
	last_year_theatre_rent				money			not null,
	mtd_gross_revenue					money			not null,
	mtd_agency_commission				money			not null,
	mtd_theatre_rent					money			not null,
	mtd_last_year_gross_revenue			money			not null,
	mtd_last_year_agency_commission		money			not null,
	mtd_last_year_theatre_rent			money			not null,
	ytd_gross_revenue					money			not null,
	ytd_agency_commission				money			not null,
	ytd_theatre_rent					money			not null,
	ytd_last_year_gross_revenue			money			not null,
	ytd_last_year_agency_commission		money			not null,
	ytd_last_year_theatre_rent			money			not null
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

select 	@mtd_end = dateadd(dd, 6,  @screening_date)

select 	@prev_mtd_end = dateadd(dd, 6, @prev_yr_scr_date)

insert 	into #billings
select 	billing_date,
		country_code,
		business_unit_id,
		media_product_id,
		revenue_source,
		complex_id,
		billings,
		agency_commission,
		net_billings	 
from 	v_wk_rpt_billings 
where 	country_code = @country_code
and		billing_date between @prev_year_start and @mtd_end

if @mode = 'B'
begin
	insert 		into #revenue
	select		business_unit_desc,
				media_product_desc,
				media_product_id,
				business_unit_id, 
				business_unit_desc,
				media_product_id,
				media_product_desc,
				media_product.revenue_source,
				@screening_date,
				@prev_yr_scr_date,
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
	from		business_unit,
				media_product
	where 		business_unit_id != 4
	and			media_product_id != 4
	and			media_product_id != 6
	group by 	business_unit_id, 
				business_unit_desc,
				media_product_id,
				media_product_desc,
				media_product.revenue_source
end
else if @mode = 'M'
begin
	insert 		into #revenue
	select		media_product_desc,
				business_unit_desc,
				business_unit_id, 
				business_unit_id, 
				business_unit_desc,
				media_product_id,
				media_product_desc,
				media_product.revenue_source,
				@screening_date,
				@prev_yr_scr_date,
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
	from		business_unit,
				media_product
	where 		business_unit_id != 4
	and			media_product_id != 4
	and			media_product_id != 6
	group by 	business_unit_id, 
				business_unit_desc,
				media_product_id,
				media_product_desc,
				media_product.revenue_source
end
			
delete #revenue where business_unit_id = 1 and media_product_id != 5

insert 	into #cag_entitlements
select 	complex_id, 
		revenue_source, 
		isnull(dbo.f_cag_active_percent ('3-feb-2005', complex.complex_id, cinema_revenue_source.revenue_source),0)
from 	complex, 
		cinema_revenue_source 
where 	complex_id in (select distinct complex_id from #billings)
and		revenue_source in (select distinct revenue_source from	#revenue)

declare 	revenue_csr cursor forward_only static for
select 		business_unit_id, 
			media_product_id, 
			revenue_source
from		#revenue
order by    business_unit_id, 
			media_product_id
for			read only

open revenue_csr
fetch revenue_csr into @business_unit_id, @media_product_id, @revenue_source
while(@@fetch_status=0)
begin

	select 	@gross_revenue = 0.0,
			@agency_commission = 0.0,
			@last_year_gross_revenue = 0.0,
			@last_year_agency_commission = 0.0,
			@theatre_rent = 0.0,
			@last_year_theatre_rent = 0.0,
			@mtd_gross_revenue = 0.0,
			@mtd_agency_commission = 0.0,
			@mtd_last_year_gross_revenue = 0.0,
			@mtd_last_year_agency_commission = 0.0,
			@mtd_theatre_rent = 0.0,
			@mtd_last_year_theatre_rent = 0.0,
			@ytd_gross_revenue = 0.0,
			@ytd_agency_commission = 0.0,
			@ytd_last_year_gross_revenue = 0.0,
			@ytd_last_year_agency_commission = 0.0,
			@ytd_theatre_rent = 0.0,
			@ytd_last_year_theatre_rent = 0.0

	exec @error = p_wk_rpt_revenue_rpt_sub 	@screening_date, 
											@screening_date, 
											@prev_yr_scr_date, 
											@prev_yr_scr_date, 
											@business_unit_id, 
											@media_product_id, 
											@gross_revenue output, 
											@agency_commission output, 
											@last_year_gross_revenue output, 
											@last_year_agency_commission output,
											@theatre_rent output,
											@last_year_theatre_rent output
	if @error != 0
	begin
		raiserror ('Error: Could not get billing week average.' , 16, 1)
		return -1
	end

	exec @error = p_wk_rpt_revenue_rpt_sub 	@mtd_start, 
											@mtd_end, 
											@prev_mtd_start, 
											@prev_mtd_end, 
											@business_unit_id, 
											@media_product_id, 
											@mtd_gross_revenue output, 
											@mtd_agency_commission output, 
											@mtd_last_year_gross_revenue output, 
											@mtd_last_year_agency_commission output,
											@mtd_theatre_rent output,
											@mtd_last_year_theatre_rent output

	if @error != 0
	begin
		raiserror ('Error: Could not get billing mtd average.' , 16, 1)
		return -1
	end

	exec @error = p_wk_rpt_revenue_rpt_sub 	@year_start, 
											@screening_date, 
											@prev_year_start, 
											@prev_yr_scr_date, 
											@business_unit_id, 
											@media_product_id, 
											@ytd_gross_revenue output, 
											@ytd_agency_commission output, 
											@ytd_last_year_gross_revenue output, 
											@ytd_last_year_agency_commission output,
											@ytd_theatre_rent output,
											@ytd_last_year_theatre_rent output
	if @error != 0
	begin
		raiserror ('Error: Could not get billing ytd average.' , 16, 1)
		return -1
	end

	update 	#revenue 
	set		gross_revenue = isnull(@gross_revenue,0),
			agency_commission = -1 * isnull(@agency_commission,0),
			last_year_gross_revenue = isnull(@last_year_gross_revenue,0),
			last_year_agency_commission = -1 * isnull(@last_year_agency_commission,0),
			theatre_rent = isnull(-1 * @theatre_rent,0),
			last_year_theatre_rent = isnull(-1 * @last_year_theatre_rent,0),
			mtd_gross_revenue = isnull(@mtd_gross_revenue,0),
			mtd_agency_commission = -1 * isnull(@mtd_agency_commission,0),
			mtd_last_year_gross_revenue = isnull(@mtd_last_year_gross_revenue,0),
			mtd_last_year_agency_commission = -1 * isnull(@mtd_last_year_agency_commission,0),
			mtd_theatre_rent = isnull(-1 * @mtd_theatre_rent,0),
			mtd_last_year_theatre_rent = isnull(-1 * @mtd_last_year_theatre_rent,0),
			ytd_gross_revenue = isnull(@ytd_gross_revenue,0),
			ytd_agency_commission = -1 * isnull(@ytd_agency_commission,0),
			ytd_last_year_gross_revenue = isnull(@ytd_last_year_gross_revenue,0),
			ytd_last_year_agency_commission = -1 * isnull(@ytd_last_year_agency_commission,0),
			ytd_theatre_rent = isnull(-1 * @ytd_theatre_rent,0),
			ytd_last_year_theatre_rent = isnull(-1 * @ytd_last_year_theatre_rent,0)
	where 	business_unit_id = @business_unit_id
	and		media_product_id = @media_product_id


	fetch revenue_csr into @business_unit_id, @media_product_id, @revenue_source
end

select 		*,
			convert(varchar(15), @screening_date, 106) as billing_date_desc,
			convert(varchar(15), @prev_yr_scr_date, 106) as prev_billing_date_desc,
			convert(varchar(15), @mtd_start, 106) + ' - ' + convert(varchar(15), @mtd_end, 106) as mtd_desc,
			convert(varchar(15), @prev_mtd_start, 106) + ' - ' + convert(varchar(15), @prev_mtd_end, 106) as prev_mtd_desc,
			convert(varchar(15), @year_start, 106) + ' - ' + convert(varchar(15), dateadd(dd, 6, @screening_date), 106) as year_desc,
			convert(varchar(15), @prev_year_start, 106) + ' - ' + convert(varchar(15), dateadd(dd, 6, @prev_yr_scr_date), 106) as prev_year_desc
from 		#revenue 
where 		(gross_revenue !=0 
or			agency_commission != 0
or			theatre_rent != 0
or			mtd_gross_revenue !=0 
or			mtd_agency_commission != 0
or			mtd_theatre_rent != 0
or			ytd_gross_revenue !=0 
or			ytd_agency_commission != 0
or			ytd_theatre_rent != 0)
order by 	business_unit_id, media_product_id
return 0
GO
