/****** Object:  StoredProcedure [dbo].[rs_p_projrev_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[rs_p_projrev_report]
GO
/****** Object:  StoredProcedure [dbo].[rs_p_projrev_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE proc  [dbo].[rs_p_projrev_report]
	@report_date		datetime,
	@delta_date			datetime,
	@PERIOD_START		datetime,
	@PERIOD_END			datetime,
	@mode				integer, -- 3 - Budget, 4 - Forecast
	@branch_code		varchar(1),
	@country_code		varchar(1),
	@business_unit_id	int,
	@revision_group		int,
	@report_type		varchar(1) -- 'C' - cinema, 'O' - outpost/retail, '' - All
AS

DECLARE @ultimate_start_date	datetime
DECLARE @prev_report_date		datetime
DECLARE @prev_final_date		datetime

DECLARE @report_year			INT
DECLARE @prev_report_year		INT
DECLARE	@calendar				VARCHAR(2)

SELECT	@report_year = DATEPART(YEAR, calendar_end)
FROM	accounting_period
WHERE	benchmark_end = @PERIOD_END

SELECT	@prev_report_year = @report_year - 1
SELECT	@calendar = 'CY'

-- Set dates unless specified
SELECT	@ultimate_start_date = '1-JAN-1900'
SELECT	@prev_report_date = dateadd(dd, -365, @report_date)
SELECT	@prev_final_date = CONVERT(DATETIME, CONVERT(VARCHAR(4), datepart(yyyy, @report_date) - 1) + '-12-31 23:59:59.000')

CREATE TABLE #PERIODS (
		period_num			int			IDENTITY,
		period_no			int			NOT NULL,
		period_group		INT			NOT NULL,
		group_desc			varchar(30)	null,
		benchmark_start		datetime	null,
		benchmark_end		datetime	null,
)

CREATE TABLE #OUTPUT (
	group_no		int 		not null,
	group_desc		varchar(30)	null,
	row_no	 		int		not null,
	row_desc		varchar(60)	null,
	revenue1		money		null DEFAULT 0.0,
	revenue2		money		null DEFAULT 0.0,
	revenue3		money		null DEFAULT 0.0,
	revenue4		money		null DEFAULT 0.0,
	revenue5		money		null DEFAULT 0.0,
	revenue6		money		null DEFAULT 0.0,
	revenue7		money		null DEFAULT 0.0,
	revenue8		money		null DEFAULT 0.0,
	revenue9		money		null DEFAULT 0.0,
	revenue10		money		null DEFAULT 0.0,
	revenue11		money		null DEFAULT 0.0,
	revenue12		money		null DEFAULT 0.0,
 	total			AS revenue1 + revenue2 + revenue3 + revenue4 + revenue5 + revenue6 + revenue7 + revenue8 + revenue9 + revenue10 + revenue11 + revenue12,
 	totalpcnt		money		null DEFAULT 0.0,
	future			money		null DEFAULT 0.0,
	row_rev_grp			int 		null,
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
	row_delta_date		datetime	null,
)
CREATE INDEX group_no_row_no ON #OUTPUT (group_no, row_no)

CREATE TABLE #HEADERS(
	group_action		varchar(10)	not null,
	group_no		int 		not null,
	group_desc		varchar(30)	null,
	row_no	 		int		not null,
	row_desc		varchar(30)	null,
	row_mode		int		null,
	row_action		varchar(20)	null,
	rowweight		int		null,
	rowformat		int		null,
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
	--( benchmark_start <= @PERIOD_START AND benchmark_end >= @PERIOD_END) OR
	--( benchmark_start >  @PERIOD_START AND benchmark_end <= @PERIOD_END)
ORDER BY benchmark_start, benchmark_end

---- Important to have it ON to allow explicit identity to be inserted #PERIODS table
SET IDENTITY_INSERT #PERIODS ON

-- Insert prior year start/end dates (periods are different to current year)
INSERT	#PERIODS(period_num, period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT	#PERIODS.period_num, ap.period_no, 2, 'Prior', ap.benchmark_start, ap.benchmark_end
FROM	#PERIODS, accounting_period ap
WHERE	#PERIODS.period_no = ap.period_no AND
	DATEPART ( yy , #PERIODS.benchmark_start)- 1 = DATEPART ( yy , ap.benchmark_start)

--SELECT * FROM #PERIODS

-- Insert Total Actual Revenue
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
		future,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date,
		--row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id, row_country_code, row_branch_code	)
SELECT	10, 10,
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 1 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 2 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 3 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 4 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 5 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 6 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 7 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 8 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 9 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 10 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 11 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period > p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),		
		MIN(CASE WHEN p.period_num = 1 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 1 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 2 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 2 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 3 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 3 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 4 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 4 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 5 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 5 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 6 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 6 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 7 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 7 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 8 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 8 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 9 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 9 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 10 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 10 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 11 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 11 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 12 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 12 Then p.benchmark_end Else NULL END),
		--@report_date, @ultimate_start_date,
		@revision_group, @business_unit_id, @country_code, @branch_code
FROM	v_projrev_report,
		#PERIODS p
WHERE	( v_projrev_report.delta_date <= @report_date )
AND		( v_projrev_report.revenue_period >= @PERIOD_START )
AND		( v_projrev_report.branch_code = @branch_code OR @branch_code = '')
AND		( v_projrev_report.country_code = @country_code OR @country_code = '')
AND		( v_projrev_report.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
AND		( v_projrev_report.revision_group = @revision_group OR @revision_group = 0 )
AND		( v_projrev_report.report_type = @report_type OR @report_type = '')
and		p.period_group = 1

-- Insert As of Delta Revenue
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
		future,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date,
		--row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id, row_country_code, row_branch_code		)
SELECT	10, 30,
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 1 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 2 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 3 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 4 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 5 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 6 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 7 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 8 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 9 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 10 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 11 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period > p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
		MIN(CASE WHEN p.period_num = 1 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 1 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 2 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 2 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 3 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 3 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 4 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 4 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 5 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 5 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 6 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 6 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 7 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 7 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 8 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 8 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 9 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 9 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 10 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 10 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 11 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 11 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 12 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 12 Then p.benchmark_end Else NULL END),
		@revision_group, @business_unit_id, @country_code, @branch_code
FROM	v_projrev_report,
		#PERIODS p
WHERE	( v_projrev_report.delta_date <= @delta_date )
AND		( v_projrev_report.revenue_period >= @PERIOD_START )
AND		( v_projrev_report.branch_code = @branch_code OR @branch_code = '')
AND		( v_projrev_report.country_code = @country_code OR @country_code = '')
AND		( v_projrev_report.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
AND		( v_projrev_report.revision_group = @revision_group OR @revision_group = 0 )
AND		( v_projrev_report.report_type = @report_type OR @report_type = '')
and		p.period_group = 1
	
-- Insert Difference between Actual and As of Revenues
INSERT into #OUTPUT(group_no, row_no, 
 		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
 		future,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date, row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	10, 20,
		o1.revenue1 - o2.revenue1, o1.revenue2 - o2.revenue2, o1.revenue3 - o2.revenue3, o1.revenue4 - o2.revenue4, o1.revenue5 - o2.revenue5, o1.revenue6 - o2.revenue6,
		o1.revenue7 - o2.revenue7, o1.revenue8 - o2.revenue8, o1.revenue9 - o2.revenue9, o1.revenue10 - o2.revenue10, o1.revenue11 - o2.revenue11, o1.revenue12 - o2.revenue12,
		o1.future - o2.future,
		o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
		o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
		o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
		--o1.row_start_date, o1.row_end_date, @report_date, @delta_date,
		@revision_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 10 AND o2.row_no = 30)

--Insert Budget/Forecast
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
		future,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date,
		--row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id, row_country_code, row_branch_code	)
SELECT	20, 40,
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 1 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 2 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 3 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 4 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 5 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 6 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 7 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 8 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 9 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 10 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 11 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 12 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
		0.0,
		MIN(CASE WHEN p.period_num = 1 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 1 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 2 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 2 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 3 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 3 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 4 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 4 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 5 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 5 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 6 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 6 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 7 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 7 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 8 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 8 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 9 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 9 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 10 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 10 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 11 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 11 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 12 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 12 Then p.benchmark_end Else NULL END),
		@revision_group, @business_unit_id, @country_code, @branch_code
FROM	v_projrev_report,
		#PERIODS p
WHERE	( v_projrev_report.delta_date IS NULL )
AND		( v_projrev_report.revenue_period BETWEEN @PERIOD_START AND @PERIOD_END )
AND		( v_projrev_report.branch_code = @branch_code OR @branch_code = '')
AND		( v_projrev_report.country_code = @country_code OR @country_code = '')
AND		( v_projrev_report.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
AND		( v_projrev_report.revision_group = @revision_group OR @revision_group = 0 )
AND		( v_projrev_report.report_type = @report_type OR @report_type = '')
and		p.period_group = 1

-- Revenue and Budget difference
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
		future,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date, row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	20, 50, 
		o1.revenue1 - o2.revenue1, o1.revenue2 - o2.revenue2, o1.revenue3 - o2.revenue3, o1.revenue4 - o2.revenue4, o1.revenue5 - o2.revenue5, o1.revenue6 - o2.revenue6,
		o1.revenue7 - o2.revenue7, o1.revenue8 - o2.revenue8, o1.revenue9 - o2.revenue9, o1.revenue10 - o2.revenue10, o1.revenue11 - o2.revenue11, o1.revenue12 - o2.revenue12,
		o1.future - o2.future,
		o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
		o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
		o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
		--o1.row_start_date, o1.row_end_date, @report_date, @ultimate_start_date,
		@revision_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 20 AND o2.row_no = 40)

-- Revenue and Budget difference percentage
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
		future, totalpcnt,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date, row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	20, 60, 
		CASE o1.revenue1 When 0 Then 0 Else ( o1.revenue1 - o2.revenue1) / o1.revenue1 END, 
		CASE o1.revenue2 When 0 Then 0 Else ( o1.revenue2 - o2.revenue2) / o1.revenue2 END, 
		CASE o1.revenue3 When 0 Then 0 Else ( o1.revenue3 - o2.revenue3) / o1.revenue3 END, 
		CASE o1.revenue4 When 0 Then 0 Else ( o1.revenue4 - o2.revenue4) / o1.revenue4 END, 
		CASE o1.revenue5 When 0 Then 0 Else ( o1.revenue5 - o2.revenue5) / o1.revenue5 END, 
		CASE o1.revenue6 When 0 Then 0 Else ( o1.revenue6 - o2.revenue6) / o1.revenue6 END, 
		CASE o1.revenue7 When 0 Then 0 Else ( o1.revenue7 - o2.revenue7) / o1.revenue7 END, 
		CASE o1.revenue8 When 0 Then 0 Else ( o1.revenue8 - o2.revenue8) / o1.revenue8 END, 
		CASE o1.revenue9 When 0 Then 0 Else ( o1.revenue9 - o2.revenue9) / o1.revenue9 END, 
		CASE o1.revenue10 When 0 Then 0 Else ( o1.revenue10 - o2.revenue10) / o1.revenue10 END, 
		CASE o1.revenue11 When 0 Then 0 Else ( o1.revenue11 - o2.revenue11) / o1.revenue11 END, 
		CASE o1.revenue12 When 0 Then 0 Else ( o1.revenue12 - o2.revenue12) / o1.revenue12 END, 
		CASE o1.future When 0 Then 0 Else ( o1.future - o2.future) / o1.future END,
		CASE o1.total When 0 Then 0 Else ( o1.total - o2.total) / o1.total END,
		o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
		o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
		o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
		--o1.row_start_date, o1.row_end_date, @report_date, @ultimate_start_date,
		@revision_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 20 AND o2.row_no = 40)

--Prior Year
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
		future,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date,
		--row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id, row_country_code, row_branch_code )
SELECT	30, 70,
		SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 1 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 2 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 3 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 4 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 5 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 6 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 7 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 8 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 9 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 10 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 11 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period > p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
		MIN(CASE WHEN p.period_num = 1 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 1 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 2 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 2 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 3 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 3 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 4 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 4 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 5 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 5 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 6 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 6 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 7 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 7 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 8 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 8 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 9 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 9 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 10 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 10 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 11 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 11 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 12 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 12 Then p.benchmark_end Else NULL END),
		@revision_group, @business_unit_id, @country_code, @branch_code
FROM	v_projrev_report,
		#PERIODS p
WHERE	( v_projrev_report.delta_date <= @prev_report_date )
--AND		( v_projrev_report.revenue_period >= @PERIOD_START )
AND		( v_projrev_report.branch_code = @branch_code OR @branch_code = '')
AND		( v_projrev_report.country_code = @country_code OR @country_code = '')
AND		( v_projrev_report.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
AND		( v_projrev_report.revision_group = @revision_group OR @revision_group = 0 )
AND		( v_projrev_report.report_type = @report_type OR @report_type = '')
and		p.period_group = 2

--Prior Year Final Revenue
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
		future,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date,
		--row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id, row_country_code, row_branch_code		)
SELECT	40, 100,
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 1 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 2 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 3 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 4 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 5 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 6 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 7 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 8 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 9 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 10 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 11 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period > p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
		MIN(CASE WHEN p.period_num = 1 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 1 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 2 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 2 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 3 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 3 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 4 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 4 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 5 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 5 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 6 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 6 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 7 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 7 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 8 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 8 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 9 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 9 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 10 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 10 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 11 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 11 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 12 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 12 Then p.benchmark_end Else NULL END),
		@revision_group, @business_unit_id, @country_code, @branch_code
FROM	v_projrev_report,
		#PERIODS p
WHERE	( v_projrev_report.delta_date <= @prev_final_date )
--AND		( v_projrev_report.revenue_period >= @PERIOD_START )
AND		( v_projrev_report.branch_code = @branch_code OR @branch_code = '')
AND		( v_projrev_report.country_code = @country_code OR @country_code = '')
AND		( v_projrev_report.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
AND		( v_projrev_report.revision_group = @revision_group OR @revision_group = 0 )
AND		( v_projrev_report.report_type = @report_type OR @report_type = '')
and		p.period_group = 2

-- Prior Year and Revenue Difference
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
		future,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date, row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	30, 80, 
		o1.revenue1 - o2.revenue1, o1.revenue2 - o2.revenue2, o1.revenue3 - o2.revenue3, o1.revenue4 - o2.revenue4, o1.revenue5 - o2.revenue5, o1.revenue6 - o2.revenue6,
		o1.revenue7 - o2.revenue7, o1.revenue8 - o2.revenue8, o1.revenue9 - o2.revenue9, o1.revenue10 - o2.revenue10, o1.revenue11 - o2.revenue11, o1.revenue12 - o2.revenue12,
		o1.future - o2.future,
		o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
		o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
		o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
		--o2.row_start_date, o2.row_end_date, 
		--@prev_report_date, @ultimate_start_date,
		@revision_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 30 AND o2.row_no = 70)

-- Prior Year and Revenue Difference Percentage
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
		future, totalpcnt,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date, row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	30, 90,
		CASE o1.revenue1 When 0 Then 0 Else ( o1.revenue1 - o2.revenue1) / o1.revenue1 END, 
		CASE o1.revenue2 When 0 Then 0 Else ( o1.revenue2 - o2.revenue2) / o1.revenue2 END, 
		CASE o1.revenue3 When 0 Then 0 Else ( o1.revenue3 - o2.revenue3) / o1.revenue3 END, 
		CASE o1.revenue4 When 0 Then 0 Else ( o1.revenue4 - o2.revenue4) / o1.revenue4 END, 
		CASE o1.revenue5 When 0 Then 0 Else ( o1.revenue5 - o2.revenue5) / o1.revenue5 END, 
		CASE o1.revenue6 When 0 Then 0 Else ( o1.revenue6 - o2.revenue6) / o1.revenue6 END, 
		CASE o1.revenue7 When 0 Then 0 Else ( o1.revenue7 - o2.revenue7) / o1.revenue7 END, 
		CASE o1.revenue8 When 0 Then 0 Else ( o1.revenue8 - o2.revenue8) / o1.revenue8 END, 
		CASE o1.revenue9 When 0 Then 0 Else ( o1.revenue9 - o2.revenue9) / o1.revenue9 END, 
		CASE o1.revenue10 When 0 Then 0 Else ( o1.revenue10 - o2.revenue10) / o1.revenue10 END, 
		CASE o1.revenue11 When 0 Then 0 Else ( o1.revenue11 - o2.revenue11) / o1.revenue11 END, 
		CASE o1.revenue12 When 0 Then 0 Else ( o1.revenue12 - o2.revenue12) / o1.revenue12 END, 
		CASE o1.future When 0 Then 0 Else ( o1.future - o2.future) / o1.future END,
		CASE o1.total When 0 Then 0 Else ( o1.total - o2.total) / o1.total END,
		o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
		o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
		o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
		--o2.row_start_date, o2.row_end_date, 
		--@prev_report_date, @ultimate_start_date,
		@revision_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 30 AND o2.row_no = 70)

-- Prior Year Final and Revenue Difference
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
		future,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date, row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	40, 110,
		o1.revenue1 - o2.revenue1, o1.revenue2 - o2.revenue2, o1.revenue3 - o2.revenue3, o1.revenue4 - o2.revenue4, o1.revenue5 - o2.revenue5, o1.revenue6 - o2.revenue6,
		o1.revenue7 - o2.revenue7, o1.revenue8 - o2.revenue8, o1.revenue9 - o2.revenue9, o1.revenue10 - o2.revenue10, o1.revenue11 - o2.revenue11, o1.revenue12 - o2.revenue12,
		o1.future - o2.future,
		o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
		o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
		o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
		--o2.row_start_date, o2.row_end_date, 
		--@prev_report_date, @ultimate_start_date,
		@revision_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 40 AND o2.row_no = 100)

-- Prior Year Final and Revenue Difference percentage
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
		future, totalpcnt,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date, row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	40, 120,
		CASE o1.revenue1 When 0 Then 0 Else ( o1.revenue1 - o2.revenue1) / o1.revenue1 END, 
		CASE o1.revenue2 When 0 Then 0 Else ( o1.revenue2 - o2.revenue2) / o1.revenue2 END, 
		CASE o1.revenue3 When 0 Then 0 Else ( o1.revenue3 - o2.revenue3) / o1.revenue3 END, 
		CASE o1.revenue4 When 0 Then 0 Else ( o1.revenue4 - o2.revenue4) / o1.revenue4 END, 
		CASE o1.revenue5 When 0 Then 0 Else ( o1.revenue5 - o2.revenue5) / o1.revenue5 END, 
		CASE o1.revenue6 When 0 Then 0 Else ( o1.revenue6 - o2.revenue6) / o1.revenue6 END, 
		CASE o1.revenue7 When 0 Then 0 Else ( o1.revenue7 - o2.revenue7) / o1.revenue7 END, 
		CASE o1.revenue8 When 0 Then 0 Else ( o1.revenue8 - o2.revenue8) / o1.revenue8 END, 
		CASE o1.revenue9 When 0 Then 0 Else ( o1.revenue9 - o2.revenue9) / o1.revenue9 END, 
		CASE o1.revenue10 When 0 Then 0 Else ( o1.revenue10 - o2.revenue10) / o1.revenue10 END, 
		CASE o1.revenue11 When 0 Then 0 Else ( o1.revenue11 - o2.revenue11) / o1.revenue11 END, 
		CASE o1.revenue12 When 0 Then 0 Else ( o1.revenue12 - o2.revenue12) / o1.revenue12 END, 
		CASE o1.future When 0 Then 0 Else ( o1.future - o2.future) / o1.future END,
		CASE o1.total When 0 Then 0 Else ( o1.total - o2.total) / o1.total END,
		o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
		o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
		o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
		--o2.row_start_date, o2.row_end_date, 
		--@prev_report_date, @ultimate_start_date,
		@revision_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 40 AND o2.row_no = 100)

-- Revenue by Groups
INSERT into #OUTPUT(group_no, row_no, row_desc,
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
		future,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date, row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	50, v_projrev_report.revision_group * 10 + v_projrev_report.business_unit_id, revision_group.revision_group_desc + '-' + business_unit.business_unit_desc,
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 1 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 2 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 3 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 4 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 5 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 6 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 7 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 8 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 9 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 10 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 11 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period > p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
		MIN(CASE WHEN p.period_num = 1 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 1 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 2 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 2 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 3 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 3 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 4 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 4 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 5 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 5 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 6 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 6 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 7 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 7 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 8 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 8 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 9 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 9 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 10 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 10 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 11 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 11 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 12 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 12 Then p.benchmark_end Else NULL END),
		--@report_date, @ultimate_start_date,
		v_projrev_report.revision_group, v_projrev_report.business_unit_id,
		@country_code, @branch_code
FROM	v_projrev_report,
		revision_group,
		business_unit,
		#PERIODS p
WHERE	( v_projrev_report.revision_group = revision_group.revision_group )
AND		( v_projrev_report.business_unit_id = business_unit.business_unit_id )
AND		( v_projrev_report.delta_date <= @report_date )
AND		( v_projrev_report.revenue_period >= @PERIOD_START )
AND		( v_projrev_report.branch_code = @branch_code OR @branch_code = '')
AND		( v_projrev_report.country_code = @country_code OR @country_code = '')
AND		( v_projrev_report.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
AND		( v_projrev_report.revision_group = @revision_group OR @revision_group = 0 )
AND		( v_projrev_report.report_type = @report_type OR @report_type = '')
and		p.period_group = 1		
GROUP BY 	v_projrev_report.revision_group,
		revision_group.revision_group_desc,
		v_projrev_report.business_unit_id,
		business_unit.business_unit_desc
ORDER BY v_projrev_report.revision_group * 10 + v_projrev_report.business_unit_id

-- State Revenue
INSERT into #OUTPUT(group_no, row_no, row_desc,
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
		future,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date, row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code )
SELECT	60, branch.sort_order, branch.branch_name,
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 1 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 2 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 3 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 4 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 5 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 6 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 7 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 8 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 9 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 10 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 11 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
		SUM(CASE WHEN revenue_period > p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
		MIN(CASE WHEN p.period_num = 1 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 1 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 2 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 2 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 3 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 3 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 4 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 4 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 5 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 5 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 6 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 6 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 7 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 7 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 8 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 8 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 9 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 9 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 10 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 10 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 11 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 11 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 12 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 12 Then p.benchmark_end Else NULL END),
		--@report_date, @ultimate_start_date,
		@revision_group, @business_unit_id, v_projrev_report.country_code, v_projrev_report.branch_code
FROM	v_projrev_report,
		branch,
		#PERIODS p
WHERE	( v_projrev_report.branch_code = branch.branch_code )
AND		( v_projrev_report.delta_date <= @report_date )
AND		( v_projrev_report.revenue_period >= @PERIOD_START )
AND		( v_projrev_report.branch_code = @branch_code OR @branch_code = '')
AND		( v_projrev_report.country_code = @country_code OR @country_code = '')
AND		( v_projrev_report.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
AND		( v_projrev_report.revision_group = @revision_group OR @revision_group = 0 )
AND		( v_projrev_report.report_type = @report_type OR @report_type = '')
and		p.period_group = 1		
GROUP BY	v_projrev_report.country_code, 
			v_projrev_report.branch_code,
			branch.sort_order, 
			branch.branch_name
ORDER BY branch.sort_order

SET FMTONLY OFF

-- Output Data
SELECT	h.group_action, 
		o.group_no, 
		ISNULL(o.group_desc, h.group_desc) AS group_desc,
		o.row_no, 
		ISNULL(h.row_desc, o.row_desc) AS row_desc,
		h.row_mode, h.row_action, h.rowweight, h.rowformat, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
		--total,
		CASE When o.group_no IN (20, 30, 40) and o.row_no IN (60, 90, 120) Then totalpcnt Else total END AS total, 
		future,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		row_start_date, row_end_date, row_report_date, row_delta_date,
		o.row_rev_grp,
		o.row_bus_unit_id,
		o.row_country_code,
		o.row_branch_code
FROM	#OUTPUT o, #HEADERS h
WHERE	o.group_no = h.group_no AND (o.row_no = h.row_no OR h.row_no = 0)
ORDER BY o.group_no, 
				o.row_no

DROP TABLE #PERIODS
DROP TABLE #HEADERS
DROP TABLE #OUTPUT
GO
