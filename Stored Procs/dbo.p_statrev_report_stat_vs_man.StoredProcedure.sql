/****** Object:  StoredProcedure [dbo].[p_statrev_report_stat_vs_man]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_report_stat_vs_man]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_report_stat_vs_man]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE proc [dbo].[p_statrev_report_stat_vs_man]
	@report_date			datetime,
	@delta_date				datetime,
	@PERIOD_START			datetime,
	@PERIOD_END				datetime,
	@branch_code			VARCHAR(1),
	@country_code			VARCHAR(1),
	@business_unit_id		INT,
	@revenue_group			INT,
	@master_revenue_group	INT,
	@report_type			VARCHAR(1) -- 'C' - cinema, 'O' - outpost/retail
AS

DECLARE @ultimate_start_date	datetime
DECLARE @prev_report_date		datetime

CREATE TABLE #PERIODS 
(
    period_num			    int			    IDENTITY,
    period_no			    int			    NOT NULL,
    period_group		    INT			    NOT NULL,
    group_desc			    varchar(30)	    null,
    benchmark_start		    datetime	    null,
    benchmark_end		    datetime	    null
)
CREATE INDEX benchmark_start_end_ind ON #PERIODS (benchmark_start, benchmark_end)

CREATE TABLE #HEADERS(
	group_action	varchar(10)	not null,
	group_no	int 		not null,
	group_desc	varchar(30)	null,
	row_no	 	int		not null,
	row_desc	varchar(30)	null,
	row_mode	int		null,
	row_action	varchar(20)	null,
	rowweight	int		null,
	rowformat	int		null,
)

-- Insert Groups/Line headers such group desc, font, format..etc
INSERT INTO #HEADERS VALUES ( 'A', 10, 'Revenue', 10, 'Actual', 1, 'Statutory', 400, 1)
INSERT INTO #HEADERS VALUES ( 'A', 20, 'Revenue', 10, 'Actual', 1, 'Management', 400, 1)
INSERT INTO #HEADERS VALUES ( 'A', 90, 'Revenue', 10, 'Actual', 1, 'Difference', 700, 2)
INSERT INTO #HEADERS VALUES ( 'B', 30, 'Revenue Groups', 0, NULL, 1, 'Statutory',  400, 1)
INSERT INTO #HEADERS VALUES ( 'B', 40, 'Revenue Groups', 0, NULL, 1, 'Management',  400, 1)
INSERT INTO #HEADERS VALUES ( 'B', 90, 'Revenue Groups', 0, NULL, 1, 'Difference', 700, 2)
INSERT INTO #HEADERS VALUES ( 'C', 50, 'State Revenue', 0, NULL, 1, 'Statutory',  400, 1)
INSERT INTO #HEADERS VALUES ( 'C', 60, 'State Revenue', 0, NULL, 1, 'Management',  400, 1)
INSERT INTO #HEADERS VALUES ( 'C', 90, 'State Revenue', 0, NULL, 1, 'Difference', 700, 1)

CREATE TABLE #OUTPUT (
	group_action	varchar(1)	not null,
	group_no	int 		not null,
	group_desc	varchar(30)	null,
	row_no	 	int		not null,
	row_desc	varchar(30)	null,
	revenue1	decimal(12,4)	null DEFAULT 0.0, --money null,
	revenue2	decimal(12,4)	null DEFAULT 0.0, --money null,
	revenue3	decimal(12,4)	null DEFAULT 0.0, --money null,
	revenue4	decimal(12,4)	null DEFAULT 0.0, --money null,
	revenue5	decimal(12,4)	null DEFAULT 0.0, --money null,
	revenue6	decimal(12,4)	null DEFAULT 0.0, --money null,
	revenue7	decimal(12,4)	null DEFAULT 0.0, --money null,
	revenue8	decimal(12,4)	null DEFAULT 0.0, --money null,
	revenue9	decimal(12,4)	null DEFAULT 0.0, --money null,
	revenue10	decimal(12,4)	null DEFAULT 0.0, --money null,
	revenue11	decimal(12,4)	null DEFAULT 0.0, --money null,
	revenue12	decimal(12,4)	null DEFAULT 0.0, --money null,
	statutory	decimal(14,4)	null DEFAULT 0.0, --money null,
	deferred	decimal(14,4)	null DEFAULT 0.0, --money null,
 	statdef		AS statutory + deferred,
	future		decimal(14,4)	null DEFAULT 0.0, --money null,
	period01_start	datetime null,
	period02_start	datetime null,
	period03_start	datetime null,
	period04_start	datetime null,
	period05_start	datetime null,
	period06_start	datetime null,
	period07_start	datetime null,
	period08_start	datetime null,
	period09_start	datetime null,
	period10_start	datetime null,
	period11_start	datetime null,
	period12_start	datetime null,
	period01_end	datetime null,
	period02_end	datetime null,
	period03_end	datetime null,
	period04_end	datetime null,
	period05_end	datetime null,
	period06_end	datetime null,
	period07_end	datetime null,
	period08_end	datetime null,
	period09_end	datetime null,
	period10_end	datetime null,
	period11_end	datetime null,
	period12_end	datetime null,
	row_start_date	datetime null,
	row_end_date	datetime null,
)

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
AND		DATEPART(YEAR, #PERIODS.benchmark_end) - 1 = DATEPART(YEAR, ap.benchmark_end)

-- Insert Start/End dates for current and prior period
INSERT into #PERIODS( period_num, period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT	100, 100, period_group, 'From To', MIN(benchmark_end), MAX(benchmark_end)
FROM	#PERIODS
GROUP BY period_group
--SELECT * FROM #PERIODS

-- Set delta date unless specified
SELECT	@ultimate_start_date = '1-jan-1900'
SELECT	@prev_report_date = dateadd(yy, -1, @report_date)

-- Insert Total Actual Revenue
INSERT into #OUTPUT( group_action, group_no, row_no,
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date )
SELECT	'A', 10, 10,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 1 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 2 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 3 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 4 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 5 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 6 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 7 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 8 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 9 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 10 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 11 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num < 100 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' AND ISNULL(revenue_period, @PERIOD_START) >= p.benchmark_end Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > p.benchmark_end AND p.period_num = 100 Then COST ELSE 0 END ),
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
	MIN(CASE WHEN p.period_num = 100 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 100 Then p.benchmark_end Else NULL END)
FROM	v_statrev_report, #periods p
WHERE	( delta_date <= @report_date )
	and ( type1 = @report_type OR @report_type = '' )
	and ( branch_code = @branch_code or @branch_code = '')
	and ( country_code = @country_code or @country_code = '')
	and ( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
	and ( revenue_group = @revenue_group or @revenue_group = 0)
	and ( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
	AND	( revenue_period >= p.benchmark_start OR revenue_period IS NULL)
	AND p.period_group = 1
	and		business_unit_id not in (6,7,8)

-- Management Total Revenue
INSERT into #OUTPUT( group_action, group_no, row_no,
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date)
SELECT	'A', 20, 10,
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 1 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 2 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 3 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 4 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 5 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 6 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 7 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 8 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 9 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 10 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 11 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 12 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num < 100 Then revenue ELSE 0 END ),
	0,
	SUM(CASE WHEN revenue_period > p.benchmark_end and p.period_num = 100 Then revenue ELSE 0 END ),
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
	MIN(CASE WHEN p.period_num = 100 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 100 Then p.benchmark_end Else NULL END)
FROM	v_mgtrev, #periods p
WHERE	( delta_date <= @report_date )
and		( revenue_period >= @PERIOD_START) --AND ( revenue_period <= @PERIOD_END )
and		( branch_code = @branch_code or @branch_code = '')
and		( country_code = @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 )
AND		( type1 = @report_type OR @report_type = '' )
AND		p.period_group = 1
and		business_unit_id not in (6,7,8)

-- Revenue by Groups
INSERT into #OUTPUT(group_action, group_no, row_no, row_desc,
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date)
SELECT	'B', 30, master_revenue_group * 10, master_revenue_group_desc,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 1 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 2 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 3 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 4 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 5 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 6 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 7 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 8 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 9 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 10 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 11 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num < 100 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' AND ISNULL(revenue_period, @PERIOD_START) >= p.benchmark_end Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > p.benchmark_end AND p.period_num = 100 Then COST ELSE 0 END ),
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
	MIN(CASE WHEN p.period_num = 100 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 100 Then p.benchmark_end Else NULL END)
FROM	v_statrev_report, #periods p
WHERE	( delta_date <= @report_date )
	and ( type1 = @report_type OR @report_type = '' )
	and ( branch_code = @branch_code or @branch_code = '')
	and ( country_code = @country_code or @country_code = '')
	and ( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
	and ( revenue_group = @revenue_group or @revenue_group = 0)
	and ( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
	AND	( revenue_period >= p.benchmark_start 
	OR revenue_period IS NULL)
	AND p.period_group = 1
	and		business_unit_id not in (6,7,8)
GROUP BY master_revenue_group,master_revenue_group_desc

-- Management Total by Revision Group
INSERT into #OUTPUT( group_action, group_no, row_no, row_desc,
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date)
SELECT	'B', 40, revision_group * 10, revision_group_desc,
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 1 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 2 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 3 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 4 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 5 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 6 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 7 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 8 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 9 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 10 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 11 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 12 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num < 100 Then revenue ELSE 0 END ),
	0,
	SUM(CASE WHEN revenue_period > p.benchmark_end and p.period_num = 100 Then revenue ELSE 0 END ),
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
	MIN(CASE WHEN p.period_num = 100 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 100 Then p.benchmark_end Else NULL END)
FROM	v_mgtrev, #periods p
WHERE	( delta_date <= @report_date )
and		( revenue_period >= @PERIOD_START) --AND ( revenue_period <= @PERIOD_END )
and		( branch_code = @branch_code or @branch_code = '')
and		( country_code = @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 )
AND		( type1 = @report_type OR @report_type = '' )
AND		p.period_group = 1
and		business_unit_id not in (6,7,8)
GROUP BY revision_group, revision_group_desc

-- State Revenue 
INSERT into #OUTPUT( group_action, group_no, row_no, row_desc,
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date)
SELECT	'C', 50, branch_sort_order, branch_name,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 1 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 2 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 3 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 4 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 5 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 6 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 7 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 8 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 9 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 10 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 11 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = p.benchmark_end and p.period_num < 100 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' AND ISNULL(revenue_period, @PERIOD_START) >= p.benchmark_end Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > p.benchmark_end AND p.period_num = 100 Then COST ELSE 0 END ),
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
	MIN(CASE WHEN p.period_num = 100 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 100 Then p.benchmark_end Else NULL END)
FROM	v_statrev_report, #periods p
WHERE	( delta_date <= @report_date )
	and ( branch_code = @branch_code or @branch_code = '')
	and ( country_code = @country_code or @country_code = '')
	and ( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
	and ( revenue_group = @revenue_group or @revenue_group = 0)
	and ( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
 	and ( type1 = @report_type OR @report_type = '' )
 		AND	( revenue_period >= p.benchmark_start 
	OR revenue_period IS NULL)
	AND p.period_group = 1
	and		business_unit_id not in (6,7,8)
GROUP BY country_code, branch_code, branch_sort_order, branch_name
ORDER BY country_code, branch_code, branch_sort_order, branch_name

-- Management Total by State
INSERT into #OUTPUT( group_action, group_no, row_no, row_desc,
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date)
SELECT	'C', 60, b.sort_order, b.branch_name,
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 1 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 2 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 3 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 4 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 5 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 6 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 7 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 8 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 9 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 10 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 11 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num = 12 Then revenue ELSE 0 END ),
	SUM(CASE WHEN revenue_period = p.benchmark_end and p.period_num < 100 Then revenue ELSE 0 END ),
	0,
	SUM(CASE WHEN revenue_period > p.benchmark_end and p.period_num = 100 Then revenue ELSE 0 END ),
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
	MIN(CASE WHEN p.period_num = 100 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 100 Then p.benchmark_end Else NULL END)
FROM	v_mgtrev, #periods p, branch b
WHERE	( delta_date <= @report_date )
and		( revenue_period >= @PERIOD_START) --AND ( revenue_period <= @PERIOD_END )
and		( v_mgtrev.branch_code = @branch_code or @branch_code = '')
and		( v_mgtrev.country_code = @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 )
AND		( type1 = @report_type OR @report_type = '' )
AND		p.period_group = 1
AND		v_mgtrev.branch_code = b.branch_code
and		business_unit_id not in (6,7,8)
GROUP BY b.country_code, b.branch_code, b.sort_order, b.branch_name

INSERT into #OUTPUT(group_action, group_no, row_no, row_desc,
 	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
 	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date)
SELECT	o1.group_action, 90, o1.row_no, o1.row_desc,
	o1.revenue1 - o2.revenue1, o1.revenue2 - o2.revenue2, o1.revenue3 - o2.revenue3, o1.revenue4 - o2.revenue4, o1.revenue5 - o2.revenue5, o1.revenue6 - o2.revenue6,
	o1.revenue7 - o2.revenue7, o1.revenue8 - o2.revenue8, o1.revenue9 - o2.revenue9, o1.revenue10 - o2.revenue10, o1.revenue11 - o2.revenue11, o1.revenue12 - o2.revenue12,
	o1.statutory - o2.statutory, o1.deferred - o2.deferred, o1.future - o2.future,
	o1.period01_start, o1.period01_end, o1.period02_start, o1.period02_end, o1.period03_start, o1.period03_end, o1.period04_start, o1.period04_end, 
	o1.period05_start, o1.period05_end, o1.period06_start, o1.period06_end, o1.period07_start, o1.period07_end, o1.period08_start, o1.period08_end, 
	o1.period09_start, o1.period09_end, o1.period10_start, o1.period10_end, o1.period11_start, o1.period11_end, o1.period12_start, o1.period12_end,
	o1.row_start_date, o1.row_end_date
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	o1.row_no = o2.row_no AND o1.group_action = o2.group_action 
	AND (( o1.group_no = 10 and o2.group_no = 20 ) OR ( o1.group_no = 30 and o2.group_no = 40 ) OR ( o1.group_no = 50 and o2.group_no = 60 ))

SELECT	h.group_action, 
	o.group_no, 
	ISNULL(o.group_desc, h.group_desc) AS group_desc,
	o.row_no, 
	ISNULL(h.row_desc, o.row_desc) AS row_desc,
	h.row_mode, h.row_action, h.rowweight, h.rowformat, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, 
	deferred,
	statdef,
	future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date
FROM	#OUTPUT o, #HEADERS h
WHERE	( o.group_action = h.group_action AND o.group_no = h.group_no AND (o.row_no = h.row_no OR h.row_no = 0))
ORDER BY h.group_action, 
	o.row_no,
	o.group_no 

DROP TABLE #PERIODS
DROP TABLE #OUTPUT
DROP TABLE #HEADERS
GO
