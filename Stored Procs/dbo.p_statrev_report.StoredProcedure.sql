/****** Object:  StoredProcedure [dbo].[p_statrev_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_report]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO



CREATE proc [dbo].[p_statrev_report]	@report_date					datetime,
										@delta_date						datetime,
										@PERIOD_START					datetime,
										@PERIOD_END						datetime,
										@mode							integer, -- 3 - Budget, 4 - Forecast
										@branch_code					varchar(1),
										@country_code					varchar(1),
										@business_unit_id				int,
										@revenue_group					int,
										@master_revenue_group			int,
										@report_type					varchar(1), -- 'C' - cinema, 'O' - outpost/retail, '' - All, 'F' = FANDOM/VM Digital
										@company						varchar(1) --'V' = Val Morgan, 'A' = all, 'C' = CineAds, 'F' = FANDOM/VM Digital
WITH RECOMPILE
AS

set nocount on

DECLARE @ultimate_start_date		datetime
DECLARE @prev_report_date			datetime
DECLARE @prev_final_date			datetime

DECLARE	@ultimate_start				datetime
DECLARE @startexec					datetime
SELECT	@startexec = GetDate()
SELECT	@ultimate_start = @startexec

-- Set dates unless specified
SELECT	@ultimate_start_date = '1-JAN-1900'
SELECT	@prev_report_date = DATEADD(DAY, -365, @report_date)
SELECT	@prev_final_date = CONVERT(DATETIME, CONVERT(VARCHAR(4), DATEPART(YEAR, @report_date) - 1) + '-12-31 23:59:59.000')

DECLARE     @period01		        datetime,
			@period02		        datetime,
			@period03		        datetime,
			@period04		        datetime,
			@period05		        datetime,
			@period06		        datetime,
			@period07		        datetime,
			@period08		        datetime,
			@period09		        datetime,
			@period10		        datetime,
			@period11		        datetime,
			@period12		        datetime,
			@period01_prev		    datetime,
			@period02_prev		    datetime,
			@period03_prev		    datetime,
			@period04_prev		    datetime,
			@period05_prev		    datetime,
			@period06_prev		    datetime,
			@period07_prev		    datetime,
			@period08_prev		    datetime,
			@period09_prev		    datetime,
			@period10_prev		    datetime,
			@period11_prev		    datetime,
			@period12_prev		    datetime,
			@row_start_date		    datetime,
			@row_end_date		    datetime,
			@row_start_date_prev	datetime,
			@row_end_date_prev		datetime


CREATE TABLE #PERIODS (
		period_num			int			IDENTITY,
		period_no			int			NOT NULL,
		period_group		INT			NOT NULL,
		group_desc			varchar(30)	null,
		benchmark_start		datetime	NOT null,
		benchmark_end		datetime	NOT null,
)
CREATE INDEX benchmark_start_ind ON #PERIODS (benchmark_start)
CREATE INDEX benchmark_end_ind ON #PERIODS (benchmark_end)
CREATE INDEX period_group_ind  ON #PERIODS (period_group)
CREATE INDEX periods_ind  ON #PERIODS (period_group, period_num, benchmark_start, benchmark_end)
CREATE STATISTICS periods_stats ON #PERIODS(period_group, period_num, benchmark_start, benchmark_end)

CREATE TABLE #OUTPUT (
	group_no			int 		not null,
	group_desc			varchar(30)	null,
	row_no	 			int		not null,
	row_desc			varchar(30)	null,
	revenue1			money		null DEFAULT 0.0,
	revenue2			money		null DEFAULT 0.0,
	revenue3			money		null DEFAULT 0.0,
	revenue4			money		null DEFAULT 0.0,
	revenue5			money		null DEFAULT 0.0,
	revenue6			money		null DEFAULT 0.0,
	revenue7			money		null DEFAULT 0.0,
	revenue8			money		null DEFAULT 0.0,
	revenue9			money		null DEFAULT 0.0,
	revenue10			money		null DEFAULT 0.0,
	revenue11			money		null DEFAULT 0.0,
	revenue12			money		null DEFAULT 0.0,
	statutory			money		null DEFAULT 0.0,
	deferred			money		null DEFAULT 0.0,
 	statdef				AS statutory + deferred,
 	statdefpcnt			money		null DEFAULT 0.0,
	future				money		null DEFAULT 0.0,
	row_rev_grp			int 		null,
	row_mast_rev_grp	int		null,
	row_bus_unit_id		int 		null,
	row_country_code	varchar(1)	null,
	row_branch_code		varchar(1)	null,
	period01_start		datetime	null,
	period02_start		datetime 	null,
	period03_start		datetime	null,
	period04_start		datetime	null,
	period05_start		datetime	null,
	period06_start		datetime	null,
	period07_start		datetime	null,
	period08_start		datetime	null,
	period09_start		datetime	null,
	period10_start		datetime	null,
	period11_start		datetime	null,
	period12_start		datetime 	null,
	period01_end		datetime 	null,
	period02_end		datetime 	null,
	period03_end		datetime 	null,
	period04_end		datetime 	null,
	period05_end		datetime 	null,
	period06_end		datetime 	null,
	period07_end		datetime 	null,
	period08_end		datetime 	null,
	period09_end		datetime 	null,
	period10_end		datetime 	null,
	period11_end		datetime 	null,
	period12_end		datetime 	null,
	row_start_date		datetime 	null,
	row_end_date		datetime	null,
	row_report_date		datetime	null,
	row_delta_date		datetime	null
	)
CREATE INDEX group_no_row_no ON #OUTPUT (group_no, row_no)

CREATE TABLE #HEADERS(
	group_action		varchar(10)	not null,
	group_no			int 		not null,
	group_desc			varchar(30)	null,
	row_no	 			int			not null,
	row_desc			varchar(30)	null,
	row_mode			int			null,
	row_action			varchar(20)	null,
	rowweight			int			null,
	rowformat			int			null
	)
	
-- Insert Groups/Line headers such group desc, font, format..etc
INSERT INTO #HEADERS VALUES ( 'Revenue', 10, 'Revenue', 10, 'Actual', 1, 'Current', 700, 1)
INSERT INTO #HEADERS VALUES ( 'Revenue', 10, 'Revenue', 30, 'As of ' + CONVERT(varchar(20), @delta_date, 107), 1, 'Current', 400, 1)
INSERT INTO #HEADERS VALUES ( 'Revenue', 10, 'Revenue', 20, '(+/-)', 1, 'Current', 400, 2)
INSERT INTO #HEADERS VALUES ( 'Budget',  20, CASE @mode When 3 Then 'Budget' Else 'Forecast' END, 40, 'Actual', 3, 'Current', 700, 1)
INSERT INTO #HEADERS VALUES ( 'Budget',  20, CASE @mode When 3 Then 'Budget' Else 'Forecast' END, 50, '(+/-)', 3, 'Difference No', 400, 2)
INSERT INTO #HEADERS VALUES ( 'Budget',  20, CASE @mode When 3 Then 'Budget' Else 'Forecast' END, 60, '(+/-) %', 3, 'Difference %', 400, 3)
INSERT INTO #HEADERS VALUES ( 'Revenue', 30, 'Prior Year', 70, 'Actual', 1, 'Current',  700, 1)
INSERT INTO #HEADERS VALUES ( 'Revenue', 30, 'Prior Year', 80, '(+/-)', 1, 'Difference No',  400, 2)
INSERT INTO #HEADERS VALUES ( 'Revenue', 30, 'Prior Year', 90, '(+/-) %', 1, 'Difference %',  400, 3)
INSERT INTO #HEADERS VALUES ( 'Revenue', 40, 'Prior Year Final', 100, 'Actual', 1, 'Current',  700, 1)
INSERT INTO #HEADERS VALUES ( 'Revenue', 40, 'Prior Year Final', 110, '(+/-)', 1, 'Difference No',  400, 2)
INSERT INTO #HEADERS VALUES ( 'Revenue', 40, 'Prior Year Final', 120, '(+/-) %', 1, 'Difference %',  400, 3)
INSERT INTO #HEADERS VALUES ( 'Revenue', 50, 'Revenue Groups', 0, NULL, 1, 'Current',  400, 1)
INSERT INTO #HEADERS VALUES ( 'Revenue', 60, 'State Revenue', 0, NULL, 1, 'Current',  400, 1)

-- Important to have the earlist first and the latest last
INSERT	#PERIODS(period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT	period_no, 1, 'Current', benchmark_start, benchmark_end
FROM	accounting_period
WHERE	benchmark_end BETWEEN @PERIOD_START AND @PERIOD_END
ORDER BY benchmark_start, benchmark_end

---- Important to have it ON to allow explicit identity to be inserted #PERIODS table
SET IDENTITY_INSERT #PERIODS ON

-- Insert prior year start/end dates (periods are different to current year)
INSERT	#PERIODS(period_num, period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT	#PERIODS.period_num, ap.period_no, 2, 'Prior', ap.benchmark_start, ap.benchmark_end
FROM	#PERIODS, accounting_period ap
WHERE	#PERIODS.period_no = ap.period_no 
AND		DATEPART(YEAR, #PERIODS.benchmark_start) - 1 = DATEPART(YEAR, ap.benchmark_start)

-- insert periods into variables
select @period01            = benchmark_end from #periods where period_num = 1 and period_group = 1
select @period02            = benchmark_end from #periods where period_num = 2 and period_group = 1
select @period03            = benchmark_end from #periods where period_num = 3 and period_group = 1
select @period04            = benchmark_end from #periods where period_num = 4 and period_group = 1
select @period05            = benchmark_end from #periods where period_num = 5 and period_group = 1
select @period06            = benchmark_end from #periods where period_num = 6 and period_group = 1
select @period07            = benchmark_end from #periods where period_num = 7 and period_group = 1
select @period08            = benchmark_end from #periods where period_num = 8 and period_group = 1
select @period09            = benchmark_end from #periods where period_num = 9 and period_group = 1
select @period10            = benchmark_end from #periods where period_num = 10 and period_group = 1
select @period11            = benchmark_end from #periods where period_num = 11 and period_group = 1
select @period12            = benchmark_end from #periods where period_num = 12 and period_group = 1
select @period01_prev       = benchmark_end from #periods where period_num = 1 and period_group = 2
select @period02_prev       = benchmark_end from #periods where period_num = 2 and period_group = 2
select @period03_prev       = benchmark_end from #periods where period_num = 3 and period_group = 2
select @period04_prev       = benchmark_end from #periods where period_num = 4 and period_group = 2
select @period05_prev       = benchmark_end from #periods where period_num = 5 and period_group = 2
select @period06_prev       = benchmark_end from #periods where period_num = 6 and period_group = 2
select @period07_prev       = benchmark_end from #periods where period_num = 7 and period_group = 2
select @period08_prev       = benchmark_end from #periods where period_num = 8 and period_group = 2
select @period09_prev       = benchmark_end from #periods where period_num = 9 and period_group = 2
select @period10_prev       = benchmark_end from #periods where period_num = 10 and period_group = 2
select @period11_prev       = benchmark_end from #periods where period_num = 11 and period_group = 2
select @period12_prev       = benchmark_end from #periods where period_num = 12 and period_group = 2
select @row_start_date	    = min(benchmark_end) from #periods where period_group = 1
select @row_end_date		= max(benchmark_end) from #periods where period_group = 1
select @row_start_date_prev = min(benchmark_end) from #periods where period_group = 2
select @row_end_date_prev   = max(benchmark_end) from #periods where period_group = 2

-- Insert Total Actual Revenue
INSERT into #OUTPUT(group_no, row_no, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, 
	row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	10, 10,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period01 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period02 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period03 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period04 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period05 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period06 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period07 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period08 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period09 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period10 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period11 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period12 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' THEN COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @row_end_date THEN COST ELSE 0 END ),
    @period01, @period01, @period02, @period02, @period03, @period03, @period04, @period04, @period05, @period05, @period06, @period06,
    @period07, @period07, @period08, @period08, @period09, @period09, @period10, @period10, @period11, @period11, @period12, @period12,
    @row_start_date,@row_end_date,
    @report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	v_statrev_report
WHERE	delta_date <= @report_date 
AND		ISNULL(revenue_period, GetDate()) >= @row_start_date
and		cost <> 0  
and		( type1 = @report_type OR @report_type = '' )
and		( branch_code = @branch_code or @branch_code = '')
and		( country_code =  @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			(@company = 'A'
or			(@company = 'V' and business_unit_id in (2,3,5))
or			(@company = 'C' and business_unit_id in (9))
or			(@company = 'F' and business_unit_id in (11)))
and		business_unit_id not in (6,7,8)

-- Insert Total Delta Revenue
INSERT into #OUTPUT(group_no, row_no, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, 
	row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)      
SELECT	10, 30,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period01 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period02 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period03 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period04 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period05 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period06 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period07 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period08 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period09 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period10 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period11 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period12 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' THEN COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @row_end_date THEN COST ELSE 0 END ),
    @period01, @period01, @period02, @period02, @period03, @period03, @period04, @period04, @period05, @period05, @period06, @period06,
    @period07, @period07, @period08, @period08, @period09, @period09, @period10, @period10, @period11, @period11, @period12, @period12,
    @row_start_date,@row_end_date,
    @delta_date, @report_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	v_statrev_report
WHERE	delta_date <= @delta_date
AND		ISNULL(revenue_period, GetDate()) >= @row_start_date
and		cost <> 0  
and		( type1 = @report_type OR @report_type = '' )
and		( branch_code = @branch_code or @branch_code = '')
and		( country_code =  @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			(@company = 'A'
or			(@company = 'V' and business_unit_id in (2,3,5))
or			(@company = 'C' and business_unit_id in (9))
or			(@company = 'O' and business_unit_id in (6,7,8))
or			(@company = 'F' and business_unit_id in (11)))
and		business_unit_id not in (6,7,8)


-- Insert Difference between Actual and As of Revenues
INSERT into #OUTPUT(group_no, row_no, 
 	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
 	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	10, 20,
	o1.revenue1 - o2.revenue1, o1.revenue2 - o2.revenue2, o1.revenue3 - o2.revenue3, o1.revenue4 - o2.revenue4, o1.revenue5 - o2.revenue5, o1.revenue6 - o2.revenue6,
	o1.revenue7 - o2.revenue7, o1.revenue8 - o2.revenue8, o1.revenue9 - o2.revenue9, o1.revenue10 - o2.revenue10, o1.revenue11 - o2.revenue11, o1.revenue12 - o2.revenue12,
	o1.statutory - o2.statutory, o1.deferred - o2.deferred, o1.future - o2.future,
	o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
	o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
	o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
	o1.row_start_date, o1.row_end_date, @report_date, @delta_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 10 AND o2.row_no = 30)

-- Insert Budget/Forecast
INSERT into #OUTPUT(group_no, row_no, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	20, 40,
		SUM(CASE WHEN revenue_period = @period01 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period = @period02 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period = @period03 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period = @period04 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period = @period05 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period = @period06 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period = @period07 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period = @period08 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period = @period09 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period = @period10 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period = @period11 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period = @period12 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period between @row_start_date and @row_end_date Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
 		0,
 		SUM(CASE WHEN revenue_period > @row_end_date Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		@period01, @period01, @period02, @period02, @period03, @period03, @period04, @period04, @period05, @period05, @period06, @period06,
		@period07, @period07, @period08, @period08, @period09, @period09, @period10, @period10, @period11, @period11, @period12, @period12,
		@row_start_date,@row_end_date,
		@report_date, @ultimate_start_date,
		@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	statrev_budgets sb,
		statrev_revenue_group srg,
		statrev_revenue_master_group srmg,
		branch b
WHERE	sb.branch_code = b.branch_code
AND		sb.revenue_group = srg.revenue_group
AND		srg.master_revenue_group = srmg.master_revenue_group
and		( b.branch_code = @branch_code or @branch_code = '')
and		( b.country_code = @country_code or @country_code = '')
and		( sb.business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( srg.revenue_group = @revenue_group or @revenue_group = 0)
AND		( srmg.company = case when @company = 'C' then 'V' else @company end or @company = 'A')
--AND		( srmg.master_revenue_group < ( CASE @report_type When 'C' Then 50 Else 2000 End ))
and		( srmg.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
AND		( sb.revenue_period >= @row_start_date)
and			(@company = 'A'
or			(@company = 'V' and business_unit_id in (2,3,5))
or			(@company = 'C' and business_unit_id in (9))
or			(@company = 'O' and business_unit_id in (6,7,8))
or			(@company = 'F' and business_unit_id in (11)))
and		business_unit_id not in (6,7,8)


-- Revenue and Budget difference
INSERT into #OUTPUT(group_no, row_no, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	20, 50, 
	o1.revenue1 - o2.revenue1, o1.revenue2 - o2.revenue2, o1.revenue3 - o2.revenue3, o1.revenue4 - o2.revenue4, o1.revenue5 - o2.revenue5, o1.revenue6 - o2.revenue6,
	o1.revenue7 - o2.revenue7, o1.revenue8 - o2.revenue8, o1.revenue9 - o2.revenue9, o1.revenue10 - o2.revenue10, o1.revenue11 - o2.revenue11, o1.revenue12 - o2.revenue12,
	o1.statutory - o2.statutory, 
	0,
	o1.future - o2.future,
	o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
	o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
	o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
	o1.row_start_date, o1.row_end_date, @report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 20 AND o2.row_no = 40)

-- Revenue and Budget difference percentage
INSERT into #OUTPUT(group_no, row_no, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
	statutory, deferred, future, statdefpcnt,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	20, 60, 
	CASE o2.revenue1 When 0 Then 0 Else ( o1.revenue1 - o2.revenue1) / o2.revenue1 END, 
	CASE o2.revenue2 When 0 Then 0 Else ( o1.revenue2 - o2.revenue2) / o2.revenue2 END, 
	CASE o2.revenue3 When 0 Then 0 Else ( o1.revenue3 - o2.revenue3) / o2.revenue3 END, 
	CASE o2.revenue4 When 0 Then 0 Else ( o1.revenue4 - o2.revenue4) / o2.revenue4 END, 
	CASE o2.revenue5 When 0 Then 0 Else ( o1.revenue5 - o2.revenue5) / o2.revenue5 END, 
	CASE o2.revenue6 When 0 Then 0 Else ( o1.revenue6 - o2.revenue6) / o2.revenue6 END, 
	CASE o2.revenue7 When 0 Then 0 Else ( o1.revenue7 - o2.revenue7) / o2.revenue7 END, 
	CASE o2.revenue8 When 0 Then 0 Else ( o1.revenue8 - o2.revenue8) / o2.revenue8 END, 
	CASE o2.revenue9 When 0 Then 0 Else ( o1.revenue9 - o2.revenue9) / o2.revenue9 END, 
	CASE o2.revenue10 When 0 Then 0 Else ( o1.revenue10 - o2.revenue10) / o2.revenue10 END, 
	CASE o2.revenue11 When 0 Then 0 Else ( o1.revenue11 - o2.revenue11) / o2.revenue11 END, 
	CASE o2.revenue12 When 0 Then 0 Else ( o1.revenue12 - o2.revenue12) / o2.revenue12 END, 
	CASE o2.statutory When 0 Then 0 Else ( o1.statutory - o2.statutory) / o2.statutory END, 
	0,
	CASE o2.future When 0 Then 0 Else ( o1.future - o2.future) / o2.future END,
	CASE o2.statdef When 0 Then 0 Else ( o1.statdef - o2.statdef) / o2.statdef END,
	o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
	o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
	o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
	o1.row_start_date, o1.row_end_date, @report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 20 AND o2.row_no = 40)

--SELECT  7, DATEDIFF ( ms, @startexec, GetDate() ) / 1000.0
--SELECT @startexec = GetDate()

--Prior Year Revenue
INSERT into #OUTPUT(group_no, row_no, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, 
	row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)      
SELECT	30, 70,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period01_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period02_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period03_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period04_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period05_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period06_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period07_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period08_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period09_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period10_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period11_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period12_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date_prev and @row_end_date_prev THEN COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' THEN COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @row_end_date_prev THEN COST ELSE 0 END ),
    @period01_prev, @period01_prev, @period02_prev, @period02_prev, @period03_prev, @period03_prev, @period04_prev, @period04_prev, @period05_prev, @period05_prev, @period06_prev, @period06_prev,
    @period07_prev, @period07_prev, @period08_prev, @period08_prev, @period09_prev, @period09_prev, @period10_prev, @period10_prev, @period11_prev, @period11_prev, @period12_prev, @period12_prev,
    @row_start_date_prev,@row_end_date_prev,
    @prev_report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	v_statrev_report
WHERE	delta_date <= @prev_report_date
AND		ISNULL(revenue_period, GetDate()) >= @row_start_date_prev
and		cost <> 0  
and		( type1 = @report_type OR @report_type = '' )
and		( branch_code = @branch_code or @branch_code = '')
and		( country_code =  @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			(@company = 'A'
or			(@company = 'V' and business_unit_id in (2,3,5))
or			(@company = 'C' and business_unit_id in (9))
or			(@company = 'O' and business_unit_id in (6,7,8))
or			(@company = 'F' and business_unit_id in (11)))
and		business_unit_id not in (6,7,8)



--SELECT  8, DATEDIFF ( ms, @startexec, GetDate() ) / 1000.0
--SELECT @startexec = GetDate()

-- Prior Year and Revenue Difference
INSERT into #OUTPUT(group_no, row_no, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	30, 80, 
	o1.revenue1 - o2.revenue1, o1.revenue2 - o2.revenue2, o1.revenue3 - o2.revenue3, o1.revenue4 - o2.revenue4, o1.revenue5 - o2.revenue5, o1.revenue6 - o2.revenue6,
	o1.revenue7 - o2.revenue7, o1.revenue8 - o2.revenue8, o1.revenue9 - o2.revenue9, o1.revenue10 - o2.revenue10, o1.revenue11 - o2.revenue11, o1.revenue12 - o2.revenue12,
	o1.statutory - o2.statutory, o1.deferred - o2.deferred, o1.future - o2.future,
	o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
	o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
	o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
	o2.row_start_date, o2.row_end_date, 
	@prev_report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 30 AND o2.row_no = 70)

--SELECT  9, DATEDIFF ( ms, @startexec, GetDate() ) / 1000.0
--SELECT @startexec = GetDate()

-- Prior Year and Revenue Difference Percentage
INSERT into #OUTPUT(group_no, row_no, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
	statutory, deferred, future, statdefpcnt,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	30, 90,
	CASE o2.revenue1 When 0 Then 0 Else ( o1.revenue1 - o2.revenue1) / o2.revenue1 END, 
	CASE o2.revenue2 When 0 Then 0 Else ( o1.revenue2 - o2.revenue2) / o2.revenue2 END, 
	CASE o2.revenue3 When 0 Then 0 Else ( o1.revenue3 - o2.revenue3) / o2.revenue3 END, 
	CASE o2.revenue4 When 0 Then 0 Else ( o1.revenue4 - o2.revenue4) / o2.revenue4 END, 
	CASE o2.revenue5 When 0 Then 0 Else ( o1.revenue5 - o2.revenue5) / o2.revenue5 END, 
	CASE o2.revenue6 When 0 Then 0 Else ( o1.revenue6 - o2.revenue6) / o2.revenue6 END, 
	CASE o2.revenue7 When 0 Then 0 Else ( o1.revenue7 - o2.revenue7) / o2.revenue7 END, 
	CASE o2.revenue8 When 0 Then 0 Else ( o1.revenue8 - o2.revenue8) / o2.revenue8 END, 
	CASE o2.revenue9 When 0 Then 0 Else ( o1.revenue9 - o2.revenue9) / o2.revenue9 END, 
	CASE o2.revenue10 When 0 Then 0 Else ( o1.revenue10 - o2.revenue10) / o2.revenue10 END, 
	CASE o2.revenue11 When 0 Then 0 Else ( o1.revenue11 - o2.revenue11) / o2.revenue11 END, 
	CASE o2.revenue12 When 0 Then 0 Else ( o1.revenue12 - o2.revenue12) / o2.revenue12 END, 
	CASE o2.statutory When 0 Then 0 Else ( o1.statutory - o2.statutory) / o2.statutory END, 
	CASE o2.deferred When 0 Then 0 Else ( o1.deferred - o2.deferred) / o2.deferred END,
	CASE o2.future When 0 Then 0 Else ( o1.future - o2.future) / o2.future END,
	CASE o2.statdef When 0 Then 0 Else ( o1.statdef - o2.statdef) / o2.statdef END,
	o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
	o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
	o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
	o2.row_start_date, o2.row_end_date, 
	@prev_report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 30 AND o2.row_no = 70)

--SELECT  10, DATEDIFF ( ms, @startexec, GetDate() ) / 1000.0
--SELECT @startexec = GetDate()

--Prior Year Final Revenue
INSERT into #OUTPUT(group_no, row_no, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, 
	row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)      
SELECT	40, 100,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period01_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period02_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period03_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period04_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period05_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period06_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period07_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period08_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period09_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period10_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period11_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period12_prev Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date_prev and @row_end_date_prev THEN COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' THEN COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @row_end_date_prev THEN COST ELSE 0 END ),
    @period01_prev, @period01_prev, @period02_prev, @period02_prev, @period03_prev, @period03_prev, @period04_prev, @period04_prev, @period05_prev, @period05_prev, @period06_prev, @period06_prev,
    @period07_prev, @period07_prev, @period08_prev, @period08_prev, @period09_prev, @period09_prev, @period10_prev, @period10_prev, @period11_prev, @period11_prev, @period12_prev, @period12_prev,
    @row_start_date_prev,@row_end_date_prev,
    @report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	v_statrev_report
WHERE	delta_date <= @report_date
AND		ISNULL(revenue_period, GetDate()) >= @row_start_date_prev
and		cost <> 0
and		( type1 = @report_type OR @report_type = '' )
and		( branch_code = @branch_code or @branch_code = '')
and		( country_code =  @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			(@company = 'A'
or			(@company = 'V' and business_unit_id in (2,3,5))
or			(@company = 'C' and business_unit_id in (9))
or			(@company = 'O' and business_unit_id in (6,7,8))
or			(@company = 'F' and business_unit_id in (11)))
and		business_unit_id not in (6,7,8)



--SELECT  11, DATEDIFF ( ms, @startexec, GetDate() ) / 1000.0
--SELECT @startexec = GetDate()

-- Prior Year and Revenue Difference
INSERT into #OUTPUT(group_no, row_no, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	40, 110, 
	o1.revenue1 - o2.revenue1, o1.revenue2 - o2.revenue2, o1.revenue3 - o2.revenue3, o1.revenue4 - o2.revenue4, o1.revenue5 - o2.revenue5, o1.revenue6 - o2.revenue6,
	o1.revenue7 - o2.revenue7, o1.revenue8 - o2.revenue8, o1.revenue9 - o2.revenue9, o1.revenue10 - o2.revenue10, o1.revenue11 - o2.revenue11, o1.revenue12 - o2.revenue12,
	o1.statutory - o2.statutory, o1.deferred - o2.deferred, o1.future - o2.future,
	o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
	o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
	o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
	o2.row_start_date, o2.row_end_date, 
	@prev_report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 40 AND o2.row_no = 100)

--SELECT  12, DATEDIFF ( ms, @startexec, GetDate() ) / 1000.0
--SELECT @startexec = GetDate()

-- Prior Year and Revenue Difference Percentage
INSERT into #OUTPUT(group_no, row_no, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
	statutory, deferred, future, statdefpcnt,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	40, 120,
	CASE o2.revenue1 When 0 Then 0 Else ( o1.revenue1 - o2.revenue1) / o2.revenue1 END, 
	CASE o2.revenue2 When 0 Then 0 Else ( o1.revenue2 - o2.revenue2) / o2.revenue2 END, 
	CASE o2.revenue3 When 0 Then 0 Else ( o1.revenue3 - o2.revenue3) / o2.revenue3 END, 
	CASE o2.revenue4 When 0 Then 0 Else ( o1.revenue4 - o2.revenue4) / o2.revenue4 END, 
	CASE o2.revenue5 When 0 Then 0 Else ( o1.revenue5 - o2.revenue5) / o2.revenue5 END, 
	CASE o2.revenue6 When 0 Then 0 Else ( o1.revenue6 - o2.revenue6) / o2.revenue6 END, 
	CASE o2.revenue7 When 0 Then 0 Else ( o1.revenue7 - o2.revenue7) / o2.revenue7 END, 
	CASE o2.revenue8 When 0 Then 0 Else ( o1.revenue8 - o2.revenue8) / o2.revenue8 END, 
	CASE o2.revenue9 When 0 Then 0 Else ( o1.revenue9 - o2.revenue9) / o2.revenue9 END, 
	CASE o2.revenue10 When 0 Then 0 Else ( o1.revenue10 - o2.revenue10) / o2.revenue10 END, 
	CASE o2.revenue11 When 0 Then 0 Else ( o1.revenue11 - o2.revenue11) / o2.revenue11 END, 
	CASE o2.revenue12 When 0 Then 0 Else ( o1.revenue12 - o2.revenue12) / o2.revenue12 END, 
	CASE o2.statutory When 0 Then 0 Else ( o1.statutory - o2.statutory) / o2.statutory END, 
	CASE o2.deferred When 0 Then 0 Else ( o1.deferred - o2.deferred) / o2.deferred END,
	CASE o2.future When 0 Then 0 Else ( o1.future - o2.future) / o2.future END,
	CASE o2.statdef When 0 Then 0 Else ( o1.statdef - o2.statdef) / o2.statdef END,
	o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
	o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
	o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
	o2.row_start_date, o2.row_end_date, 
	@prev_report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 40 AND o2.row_no = 100)

--SELECT  13, DATEDIFF ( ms, @startexec, GetDate() ) / 1000.0
--SELECT @startexec = GetDate()

-- Revenue by Groups
INSERT into #OUTPUT(group_no, row_no, row_desc,
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	50, revenue_group * 10, revenue_group_desc,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period01 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period02 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period03 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period04 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period05 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period06 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period07 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period08 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period09 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period10 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period11 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period12 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' THEN COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @row_end_date THEN COST ELSE 0 END ),
    @period01, @period01, @period02, @period02, @period03, @period03, @period04, @period04, @period05, @period05, @period06, @period06,
    @period07, @period07, @period08, @period08, @period09, @period09, @period10, @period10, @period11, @period11, @period12, @period12,
    @row_start_date,@row_end_date,
    @report_date, @ultimate_start_date,
	revenue_group,	master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	v_statrev_report
WHERE	delta_date <= @report_date 
AND		ISNULL(revenue_period, GetDate()) >= @row_start_date
and		cost <> 0  
and		( type1 = @report_type OR @report_type = '' )
and		( branch_code = @branch_code or @branch_code = '')
and		( country_code =  @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			(@company = 'A'
or			(@company = 'V' and business_unit_id in (2,3,5))
or			(@company = 'C' and business_unit_id in (9))
or			(@company = 'O' and business_unit_id in (6,7,8))
or			(@company = 'F' and business_unit_id in (11)))
and		business_unit_id not in (6,7,8)
GROUP BY revenue_group, master_revenue_group, revenue_group_desc


--SELECT  14, DATEDIFF ( ms, @startexec, GetDate() ) / 1000.0
--SELECT @startexec = GetDate()

-- State Revenue
INSERT into #OUTPUT(group_no, row_no, row_desc,
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	60, branch_sort_order, branch_name,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period01 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period02 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period03 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period04 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period05 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period06 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period07 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period08 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period09 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period10 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period11 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period12 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' THEN COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @row_end_date THEN COST ELSE 0 END ),
    @period01, @period01, @period02, @period02, @period03, @period03, @period04, @period04, @period05, @period05, @period06, @period06,
    @period07, @period07, @period08, @period08, @period09, @period09, @period10, @period10, @period11, @period11, @period12, @period12,
    @row_start_date, @row_end_date,
    @report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, country_code, branch_code
FROM	v_statrev_report
WHERE	delta_date <= @report_date 
AND		ISNULL(revenue_period, GetDate()) >= @row_start_date
and		cost <> 0  
and		( type1 = @report_type OR @report_type = '' )
and		( branch_code = @branch_code or @branch_code = '')
and		( country_code =  @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			(@company = 'A'
or			(@company = 'V' and business_unit_id in (2,3,5))
or			(@company = 'C' and business_unit_id in (9))
or			(@company = 'O' and business_unit_id in (6,7,8))
or			(@company = 'F' and business_unit_id in (11)))
and		business_unit_id not in (6,7,8)
GROUP BY branch_sort_order, country_code, branch_code, branch_name


--SELECT  15, DATEDIFF ( ms, @startexec, GetDate() ) / 1000.0
--SELECT @startexec = GetDate()

-- Output Data
SELECT	h.group_action, 
	o.group_no, 
	ISNULL(o.group_desc, h.group_desc) AS group_desc,
	o.row_no, 
	ISNULL(h.row_desc, o.row_desc) AS row_desc,
	h.row_mode, h.row_action, h.rowweight, h.rowformat, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, 
	deferred,
	CASE When o.group_no IN (20, 30, 40) and o.row_no IN (60, 90, 120) Then statdefpcnt Else statdef END AS statdeftotal, 
	future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	o.row_rev_grp,
	o.row_mast_rev_grp,
	o.row_bus_unit_id,
	o.row_country_code,
	o.row_branch_code
FROM	#OUTPUT o, #HEADERS h
WHERE	o.group_no = h.group_no AND (o.row_no = h.row_no OR h.row_no = 0)
ORDER BY o.group_no, 
	o.row_no

--SELECT  99, DATEDIFF ( ms, @ultimate_start, GetDate() ) / 1000.0

DROP TABLE #OUTPUT
DROP TABLE #PERIODS
DROP TABLE #HEADERS
GO
