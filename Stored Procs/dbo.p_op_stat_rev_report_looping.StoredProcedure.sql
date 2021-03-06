/****** Object:  StoredProcedure [dbo].[p_op_stat_rev_report_looping]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_stat_rev_report_looping]
GO
/****** Object:  StoredProcedure [dbo].[p_op_stat_rev_report_looping]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_op_stat_rev_report_looping]		@report_date				datetime,
										@delta_date					datetime,
										@country_code				char(1),
										@branch_code				char(1),
										@business_unit_id			int,
										@revenue_group				int,
										@master_revenue_group		int,
										@start_period				datetime,
										@end_period					datetime,
										@budget_mode				int --3 for budget 4 for forecast

as

declare		@error					int,
			@errorode					int,
			@prev_report_date		datetime,
			@prev_delta_date		datetime,
			@prev_start_period		datetime,
			@prev_end_period		datetime,
			@future_start			datetime,
			@csr_report_date		datetime,
			@csr_start_date			datetime,
			@csr_end_date			datetime,
			@revenue_company		int,
			@mode					int,
			@ultimate_start_date	datetime,
			@ultimate_end_date		datetime,
			@row_start_rpt_date		datetime,
			@mode_desc			varchar(10)
/*
 * Create Temp Table
 */

create table #rows
(
	group_no			int				null,
	group_desc			varchar(30)		null,
	group_action_type	varchar(30)		null,
	row_no				int				null,
	row_desc			varchar(30)		null,
	row_action_type		varchar(30)		null,
	rowweight			int				null,
	rowformat			int				null,
	row_rpt_date		datetime		null,
	row_start_date		datetime		null,
	row_end_date		datetime		null,
	row_rev_grp			int				null,
	row_mast_rev_grp	int				null,
	row_bus_unit_id		int				null,
	row_country_code	char(1)			null,
	row_branch_code		char(1)			null,
	row_mode			int				null,
	row_start_rpt_date	datetime		null
)

/*
 * Initiliase Variables
 */

select 	@revenue_company = 1,
		@ultimate_start_date = '1-jan-1900',
		@ultimate_end_date = '1-jan-2999',
		@prev_report_date = dateadd(yy, -1, @report_date)

select @prev_start_period = benchmark_end from accounting_period where benchmark_end < @start_period and period_no in (select period_no from accounting_period where benchmark_end = @start_period)
select @prev_end_period = benchmark_end from accounting_period where benchmark_end < @end_period and period_no in (select period_no from accounting_period where benchmark_end = @end_period)
select @mode_desc = CASE @budget_mode WHEN 3 Then 'Budget' When 4 Then 'Forecast' Else 'Not Defined' END

/*
 *	Insert rows into temps
 */

insert into #rows values (10, 'Revenue', 'Revenue', 100, 'Actual', 'Current',700, 1, @report_date, @start_period, @end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, @branch_code, 1, @ultimate_start_date)
insert into #rows values (10, 'Revenue', 'Revenue', 200, '(+/-)', 'Current',400, 1, @report_date, @start_period, @end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, @branch_code, 1, @delta_date)
insert into #rows values (10, 'Revenue', 'Revenue', 300, 'As at ' + convert(varchar(20), @delta_date, 106) , 'Current',400, 1, @delta_date, @start_period, @end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, @branch_code, 1, @ultimate_start_date)

insert into #rows values (20, @mode_desc, @mode_desc, 400, 'Actual', 'Current',700, 1, @report_date, @start_period, @end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, @branch_code, @budget_mode, @ultimate_start_date)
insert into #rows values (20, @mode_desc, @mode_desc, 500, '(+/-)', 'Difference No',400, 2, @report_date, @start_period, @end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, @branch_code, @budget_mode, @ultimate_start_date)
insert into #rows values (20, @mode_desc, @mode_desc, 600, '(+/-) %', 'Difference %',400, 3, @report_date, @start_period, @end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, @branch_code, @budget_mode, @ultimate_start_date)

insert into #rows values (30, 'Prior Year', 'Revenue', 700, 'Actual', 'Current',700, 1, @prev_report_date, @prev_start_period, @prev_end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, @branch_code, 1, @ultimate_start_date)
insert into #rows values (30, 'Prior Year', 'Revenue', 800, '(+/-)', 'Difference No',400, 2, @prev_report_date, @prev_start_period, @prev_end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, @branch_code, 1, @ultimate_start_date)
insert into #rows values (30, 'Prior Year', 'Revenue', 900, '(+/-) %', 'Difference %',400, 3, @prev_report_date, @prev_start_period, @prev_end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, @branch_code, 1, @ultimate_start_date)

insert into #rows values (40, 'Prior Year Final', 'Revenue', 1000, 'Actual', 'Current',700, 1, @report_date, @prev_start_period, @prev_end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, @branch_code, 1, @ultimate_start_date)
insert into #rows values (40, 'Prior Year Final', 'Revenue', 1100, '(+/-)', 'Difference No',400, 2, @report_date, @prev_start_period, @prev_end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, @branch_code, 1, @ultimate_start_date)
insert into #rows values (40, 'Prior Year Final', 'Revenue', 1200, '(+/-) %', 'Difference %',400, 3, @report_date, @prev_start_period, @prev_end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, @branch_code, 1, @ultimate_start_date)

insert into #rows values (50, 'Revenue Groups', 'Revenue', 1300, 'Retail Panels', 'Current',400, 1, @report_date, @start_period, @end_period, 50, 50, @business_unit_id, @country_code, @branch_code, 1, @ultimate_start_date)
insert into #rows values (50, 'Revenue Groups', 'Revenue', 1400, 'Retail Walls', 'Current',400, 1, @report_date, @start_period, @end_period, 51, 51, @business_unit_id, @country_code, @branch_code, 1, @ultimate_start_date)
insert into #rows values (50, 'Revenue Groups', 'Revenue', 1500, 'Retail Misc', 'Current',400, 1, @report_date, @start_period, @end_period, 52, 52, @business_unit_id, @country_code, @branch_code, 1, @ultimate_start_date)
insert into #rows values (50, 'Revenue Groups', 'Revenue', 1600, 'Retail Super Wall', 'Current',400, 1, @report_date, @start_period, @end_period, 53, 53, @business_unit_id, @country_code, @branch_code, 1, @ultimate_start_date)


if @country_code = 'A'
begin
	insert into #rows values (60, 'State Revenue', 'Revenue', 1700, 'NSW', 'Current',400, 1, @report_date, @start_period, @end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, 'N', 1, @ultimate_start_date)
	insert into #rows values (60, 'State Revenue', 'Revenue', 1800, 'VIC', 'Current',400, 1, @report_date, @start_period, @end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, 'V', 1, @ultimate_start_date)
	insert into #rows values (60, 'State Revenue', 'Revenue', 1900, 'QLD', 'Current',400, 1, @report_date, @start_period, @end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, 'Q', 1, @ultimate_start_date)
	insert into #rows values (60, 'State Revenue', 'Revenue', 2000, 'SA', 'Current',400, 1, @report_date, @start_period, @end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, 'S', 1, @ultimate_start_date)
	insert into #rows values (60, 'State Revenue', 'Revenue', 2100, 'WA', 'Current',400, 1, @report_date, @start_period, @end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, 'W', 1, @ultimate_start_date)
end
else if @country_code = 'Z'
begin
	insert into #rows values (60, 'State Revenue', 'Revenue', 1700, 'NZ', 'Current',400, 1, @report_date, @start_period, @end_period, @revenue_group, @master_revenue_group, @business_unit_id, @country_code, 'Z', 1, @ultimate_start_date)
end

select * from #rows

return 0
GO
