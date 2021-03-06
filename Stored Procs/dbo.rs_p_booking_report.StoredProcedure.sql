/****** Object:  StoredProcedure [dbo].[rs_p_booking_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[rs_p_booking_report]
GO
/****** Object:  StoredProcedure [dbo].[rs_p_booking_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE proc  [dbo].[rs_p_booking_report]
	@PERIOD_START		datetime,
	@PERIOD_END			datetime,
	@team_id			INT,
	@rep_id				INT,
	@branch_code		varchar(1),
	@country_code		varchar(1),
	@business_unit_id	int,
	@revision_group		int,
	@report_type		varchar(1) -- 'C' - cinema, 'O' - outpost/retail, '' - All
AS
SET NOCOUNT ON

DECLARE @ultimate_start_date	datetime
DECLARE @prev_report_date		datetime
DECLARE @prev_final_date		datetime

DECLARE @report_year			INT
DECLARE @prev_report_year		INT

-- Set dates unless specified
SELECT	@ultimate_start_date = '1-JAN-1900'
--SELECT	@prev_report_date = dateadd(dd, -365, @report_date)
--SELECT	@prev_final_date = CONVERT(DATETIME, CONVERT(VARCHAR(4), datepart(yyyy, @report_date) - 1) + '-12-31 23:59:59.000')

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
	group_action	varchar(10)	not null,
	group_no		int 		not null,
	group_desc		varchar(30)	null,
	row_no	 		int			not null,
	row_desc		varchar(60)	null,
	row_mode		int			null,
	row_action		varchar(20)	null,
	rowweight		int			null,
	rowformat		int			null,
)

-- Insert Groups/Line headers such group desc, font, format..etc
INSERT INTO #HEADERS VALUES ( 'Sales', 10, 'Booking',	10, 'Actual',		1,	'Current',		700, 1)
INSERT INTO #HEADERS VALUES ( 'Sales', 10, 'Booking',	20, 'Adjustment',	1,	'Current',		700, 1)
INSERT INTO #HEADERS VALUES ( 'Sales', 10, 'Booking',	30, 'Total',		1,	'Current',		400, 2)
INSERT INTO #HEADERS VALUES ( 'Sales', 10, 'Target',	40, '(+/-) %',		1,	'Difference %',	400, 3)
INSERT INTO #HEADERS VALUES ( 'Sales', 20, 'Target',	10, 'Target',		1,	'Current',		700, 1)
INSERT INTO #HEADERS VALUES ( 'Sales', 20, 'Target',	20, '(+/-)',		1,	'Difference $',	400, 1)
INSERT INTO #HEADERS VALUES ( 'Sales', 30, 'Prior Year',	10,	'Booking',	1,	'Current',		700, 1)
INSERT INTO #HEADERS VALUES ( 'Sales', 40, 'Revenue Group', 0,	NULL,		1,	'Current',		400, 1)
	
--INSERT INTO #HEADERS VALUES ( 'Booking', 30, 'Prior Year', 70, 'Actual', 1, 'Current',  700, 1)
--INSERT INTO #HEADERS VALUES ( 'Booking', 30, 'Prior Year', 80, '(+/-)', 1, 'Difference No',  400, 2)
--INSERT INTO #HEADERS VALUES ( 'Booking', 30, 'Prior Year', 90, '(+/-) %', 1, 'Difference %',  400, 3)
--INSERT INTO #HEADERS VALUES ( 'Booking', 40, 'Prior Year Final', 100, 'Actual', 1, 'Current',  700, 1)
--INSERT INTO #HEADERS VALUES ( 'Booking', 40, 'Prior Year Final', 110, '(+/-)', 1, 'Difference No',  400, 2)
--INSERT INTO #HEADERS VALUES ( 'Booking', 40, 'Prior Year Final', 120, '(+/-) %', 1, 'Difference %',  400, 3)
--INSERT INTO #HEADERS VALUES ( 'Booking', 60, 'State Booking', 0, NULL, 1, 'Current',  400, 1)


-- Important to have the earlist first and the latest last
INSERT	#PERIODS(period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT	period_no, 1, 'Current', period_start, sales_period
FROM	film_sales_period
WHERE	sales_period BETWEEN @PERIOD_START AND @PERIOD_END
	--( benchmark_start <= @PERIOD_START AND benchmark_end >= @PERIOD_END) OR
	--( benchmark_start >  @PERIOD_START AND benchmark_end <= @PERIOD_END)
ORDER BY period_start, sales_period

---- Important to have it ON to allow explicit identity to be inserted #PERIODS table
SET IDENTITY_INSERT #PERIODS ON

-- Insert prior year start/end dates (periods are different to current year)
INSERT	#PERIODS(period_num, period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT	#PERIODS.period_num, sp.period_no, 2, 'Prior', sp.period_start, sp.sales_period
FROM	#PERIODS, film_sales_period sp
WHERE	#PERIODS.period_no = sp.period_no AND
	DATEPART ( yy , #PERIODS.benchmark_start)- 1 = DATEPART ( yy , sp.sales_period)

--SELECT * FROM #PERIODS

-- Insert Actual Booking
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date,
		--row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id, row_country_code, row_branch_code	)
SELECT	10, 10,
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 1 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 2 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 3 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 4 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 5 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 6 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 7 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 8 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 9 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 10 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 11 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 12 Then nett_amount ELSE 0 END ),
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
FROM	booking_figures,
		film_campaign,
		branch,
		#PERIODS p
WHERE	( booking_figures.branch_code = @branch_code OR @branch_code = '')
AND		( branch.country_code = @country_code OR @country_code = '')
AND		( film_campaign.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
AND		( booking_figures.revision_group = @revision_group OR @revision_group = 0 )
AND		( booking_figures.rep_id = @rep_id OR @rep_id = 0 )
AND		( @team_id = 0 OR EXISTS ( SELECT * FROM booking_figure_team_xref bx
									WHERE	bx.figure_id = booking_figures.figure_id
									AND		bx.team_id = @team_id))
AND		booking_figures.campaign_no = film_campaign.campaign_no
and		booking_figures.branch_code = branch.branch_code
and		booking_figures.figure_type <> 'A'
AND		( booking_figures.revision_group >= ( CASE @report_type When 'O' Then 50 Else 0 End )
AND		  booking_figures.revision_group < ( CASE @report_type When 'C' Then 50 Else 1000 End ))
and		p.period_group = 1

-- Insert Adjustments
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date,
		--row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id, row_country_code, row_branch_code	)
SELECT	10, 20,
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 1 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 2 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 3 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 4 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 5 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 6 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 7 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 8 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 9 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 10 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 11 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 12 Then nett_amount ELSE 0 END ),
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
FROM	booking_figures,
		film_campaign,
		branch,
		#PERIODS p
WHERE	( booking_figures.branch_code = @branch_code OR @branch_code = '')
AND		( branch.country_code = @country_code OR @country_code = '')
AND		( film_campaign.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
AND		( booking_figures.revision_group = @revision_group OR @revision_group = 0 )
AND		( booking_figures.rep_id = @rep_id OR @rep_id = 0 )
AND		( @team_id = 0 OR EXISTS ( SELECT * FROM booking_figure_team_xref bx
									WHERE	bx.figure_id = booking_figures.figure_id
									AND		bx.team_id = @team_id))
AND		booking_figures.campaign_no = film_campaign.campaign_no
and		booking_figures.branch_code = branch.branch_code
and		booking_figures.figure_type = 'A'
AND		( booking_figures.revision_group >= ( CASE @report_type When 'O' Then 50 Else 0 End )
AND		  booking_figures.revision_group < ( CASE @report_type When 'C' Then 50 Else 1000 End ))		
and		p.period_group = 1

-- Insert Target
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date,
		--row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id, row_country_code, row_branch_code	)
SELECT	20, 10,
		SUM(CASE WHEN booking_target.sales_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 1 Then target ELSE 0 END ),
		SUM(CASE WHEN booking_target.sales_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 2 Then target ELSE 0 END ),
		SUM(CASE WHEN booking_target.sales_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 3 Then target ELSE 0 END ),
		SUM(CASE WHEN booking_target.sales_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 4 Then target ELSE 0 END ),
		SUM(CASE WHEN booking_target.sales_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 5 Then target ELSE 0 END ),
		SUM(CASE WHEN booking_target.sales_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 6 Then target ELSE 0 END ),
		SUM(CASE WHEN booking_target.sales_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 7 Then target ELSE 0 END ),
		SUM(CASE WHEN booking_target.sales_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 8 Then target ELSE 0 END ),
		SUM(CASE WHEN booking_target.sales_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 9 Then target ELSE 0 END ),
		SUM(CASE WHEN booking_target.sales_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 10 Then target ELSE 0 END ),
		SUM(CASE WHEN booking_target.sales_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 11 Then target ELSE 0 END ),
		SUM(CASE WHEN booking_target.sales_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 12 Then target ELSE 0 END ),
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
FROM	booking_target,
		branch,
		#PERIODS p
WHERE	 booking_target.branch_code = branch.branch_code
AND		( branch.country_code = @country_code OR @country_code = '')
AND		( booking_target.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
AND		( ISNULL(booking_target.rep_id, 0) = @rep_id OR @rep_id = 0 )
AND		( ISNULL(booking_target.team_id, 0) = @team_id OR @team_id = 0)
AND		( ISNULL(booking_target.branch_code, '') = @branch_code OR @branch_code = '')
AND		(( booking_target.revision_group = @revision_group) 
OR		( booking_target.revision_group >= ( CASE @report_type When 'O' Then 50 Else 0 End )
AND		  booking_target.revision_group < ( CASE @report_type When 'C' Then 50 Else 1000 End )))
and		p.period_group = 1

-- Insert Totals
INSERT into #OUTPUT(group_no, row_no, 
 		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date, row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	10, 30,
		o1.revenue1 + o2.revenue1, o1.revenue2 + o2.revenue2, o1.revenue3 + o2.revenue3, o1.revenue4 + o2.revenue4, o1.revenue5 + o2.revenue5, o1.revenue6 + o2.revenue6,
		o1.revenue7 + o2.revenue7, o1.revenue8 + o2.revenue8, o1.revenue9 + o2.revenue9, o1.revenue10 + o2.revenue10, o1.revenue11 + o2.revenue11, o1.revenue12 + o2.revenue12,
		o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
		o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
		o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
		--o1.row_start_date, o1.row_end_date, @report_date, @delta_date,
		@revision_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 10 AND o2.row_no = 20)

-- Difference between Actual and Target
INSERT into #OUTPUT(group_no, row_no, 
 		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date, row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	20, 20,
		o1.revenue1 - o2.revenue1, o1.revenue2 - o2.revenue2, o1.revenue3 - o2.revenue3, o1.revenue4 - o2.revenue4, o1.revenue5 - o2.revenue5, o1.revenue6 - o2.revenue6,
		o1.revenue7 - o2.revenue7, o1.revenue8 - o2.revenue8, o1.revenue9 - o2.revenue9, o1.revenue10 - o2.revenue10, o1.revenue11 - o2.revenue11, o1.revenue12 - o2.revenue12,
		o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
		o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
		o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
		--o1.row_start_date, o1.row_end_date, @report_date, @delta_date,
		@revision_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 30) AND (o2.group_no = 20 AND o2.row_no = 10)

-- Difference between Actual and Target percentage
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
		totalpcnt,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date, row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	10, 40, 
		CASE o1.revenue1 When 0 Then 0 Else o2.revenue1 / o1.revenue1 END,
		CASE o1.revenue2 When 0 Then 0 Else o2.revenue2 / o1.revenue2 END,
		CASE o1.revenue3 When 0 Then 0 Else o2.revenue3 / o1.revenue3 END,
		CASE o1.revenue4 When 0 Then 0 Else o2.revenue4 / o1.revenue4 END,
		CASE o1.revenue5 When 0 Then 0 Else o2.revenue5 / o1.revenue5 END,
		CASE o1.revenue6 When 0 Then 0 Else o2.revenue6 / o1.revenue6 END,
		CASE o1.revenue7 When 0 Then 0 Else o2.revenue7 / o1.revenue7 END,
		CASE o1.revenue8 When 0 Then 0 Else o2.revenue8 / o1.revenue8 END,
		CASE o1.revenue9 When 0 Then 0 Else o2.revenue9 / o1.revenue9 END,
		CASE o1.revenue10 When 0 Then 0 Else o2.revenue10 / o1.revenue10 END,
		CASE o1.revenue11 When 0 Then 0 Else o2.revenue11 / o1.revenue11 END,
		CASE o1.revenue12 When 0 Then 0 Else o2.revenue12 / o1.revenue12 END,
		CASE o1.total When 0 Then 0 Else o2.total / o1.total END,
		o2.period01_start, o2.period01_end, o2.period02_start, o2.period02_end, o2.period03_start, o2.period03_end, o2.period04_start, o2.period04_end, 
		o2.period05_start, o2.period05_end, o2.period06_start, o2.period06_end, o2.period07_start, o2.period07_end, o2.period08_start, o2.period08_end, 
		o2.period09_start, o2.period09_end, o2.period10_start, o2.period10_end, o2.period11_start, o2.period11_end, o2.period12_start, o2.period12_end,
		--o1.row_start_date, o1.row_end_date, @report_date, @ultimate_start_date,
		@revision_group, @business_unit_id, @country_code, @branch_code
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 20 AND o1.row_no = 10) AND (o2.group_no = 10 AND o2.row_no = 30)

----Prior Year
INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date,
		--row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id, row_country_code, row_branch_code	)
SELECT	30, 10,
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 1 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 2 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 3 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 4 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 5 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 6 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 7 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 8 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 9 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 10 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 11 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 12 Then nett_amount ELSE 0 END ),
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
FROM	booking_figures,
		film_campaign,
		branch,
		#PERIODS p
WHERE	( booking_figures.branch_code = @branch_code OR @branch_code = '')
AND		( branch.country_code = @country_code OR @country_code = '')
AND		( film_campaign.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
AND		( booking_figures.revision_group = @revision_group OR @revision_group = 0 )
AND		( booking_figures.rep_id = @rep_id OR @rep_id = 0 )
AND		( @team_id = 0 OR EXISTS ( SELECT * FROM booking_figure_team_xref bx
									WHERE	bx.figure_id = booking_figures.figure_id
									AND		bx.team_id = @team_id))
AND		booking_figures.campaign_no = film_campaign.campaign_no
and		booking_figures.branch_code = branch.branch_code
--and		booking_figures.figure_type <> 'A'
AND		( booking_figures.revision_group >= ( CASE @report_type When 'O' Then 50 Else 0 End )
AND		  booking_figures.revision_group < ( CASE @report_type When 'C' Then 50 Else 1000 End ))
and		p.period_group = 2

---- Revision by Groups
INSERT into #OUTPUT(group_no, row_no, row_desc,
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		--row_start_date, row_end_date,
		--row_report_date, row_delta_date,
		row_rev_grp, row_bus_unit_id, row_country_code, row_branch_code	)
SELECT	40,
		film_campaign.business_unit_id * 10 + booking_figures.revision_group,
		business_unit.business_unit_desc + '-' + revision_group.revision_group_desc,
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 1 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 2 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 3 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 4 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 5 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 6 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 7 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 8 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 9 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 10 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 11 Then nett_amount ELSE 0 END ),
		SUM(CASE WHEN booking_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_num = 12 Then nett_amount ELSE 0 END ),
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
FROM	booking_figures,
		film_campaign,
		branch,
		revision_group,
		business_unit,
		#PERIODS p
WHERE	( booking_figures.revision_group = revision_group.revision_group )
AND		( booking_figures.campaign_no = film_campaign.campaign_no )
AND		( film_campaign.business_unit_id = business_unit.business_unit_id )
AND		( booking_figures.branch_code = @branch_code OR @branch_code = '')
AND		( branch.country_code = @country_code OR @country_code = '')
AND		( film_campaign.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
--AND		( booking_figures.revision_group = @revision_group OR @revision_group = 0 )
AND		( booking_figures.rep_id = @rep_id OR @rep_id = 0 )
AND		( @team_id = 0 OR EXISTS ( SELECT * FROM booking_figure_team_xref bx
									WHERE	bx.figure_id = booking_figures.figure_id
									AND		bx.team_id = @team_id))
AND		booking_figures.campaign_no = film_campaign.campaign_no
and		booking_figures.branch_code = branch.branch_code
--and		booking_figures.figure_type <> 'A'
AND		(( booking_figures.revision_group = @revision_group ) 
OR      (( booking_figures.revision_group >= ( CASE When @report_type = 'O' AND @revision_group = 0 Then 50 Else 0 End )
AND		  booking_figures.revision_group < ( CASE When @report_type = 'C' AND @revision_group = 0  Then 50 Else 1000 End ))))
and		p.period_group = 1
GROUP BY 	booking_figures.revision_group,
		revision_group.revision_group_desc,
		film_campaign.business_unit_id,
		business_unit.business_unit_desc
ORDER BY film_campaign.business_unit_id * 10 + booking_figures.revision_group

---- State Revenue
--INSERT into #OUTPUT(group_no, row_no, row_desc,
--		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
--		future,
--		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
--		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
--		--row_start_date, row_end_date, row_report_date, row_delta_date,
--		row_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code )
--SELECT	60, branch.sort_order, branch.branch_name,
--		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 1 Then COST ELSE 0 END ),
--		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 2 Then COST ELSE 0 END ),
--		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 3 Then COST ELSE 0 END ),
--		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 4 Then COST ELSE 0 END ),
--		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 5 Then COST ELSE 0 END ),
--		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 6 Then COST ELSE 0 END ),
--		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 7 Then COST ELSE 0 END ),
--		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 8 Then COST ELSE 0 END ),
--		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 9 Then COST ELSE 0 END ),
--		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 10 Then COST ELSE 0 END ),
--		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 11 Then COST ELSE 0 END ),
--		SUM(CASE WHEN revenue_period BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
--		SUM(CASE WHEN revenue_period > p.benchmark_end and p.period_num = 12 Then COST ELSE 0 END ),
--		MIN(CASE WHEN p.period_num = 1 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 1 Then p.benchmark_end Else NULL END),
--		MIN(CASE WHEN p.period_num = 2 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 2 Then p.benchmark_end Else NULL END),
--		MIN(CASE WHEN p.period_num = 3 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 3 Then p.benchmark_end Else NULL END),
--		MIN(CASE WHEN p.period_num = 4 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 4 Then p.benchmark_end Else NULL END),
--		MIN(CASE WHEN p.period_num = 5 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 5 Then p.benchmark_end Else NULL END),
--		MIN(CASE WHEN p.period_num = 6 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 6 Then p.benchmark_end Else NULL END),
--		MIN(CASE WHEN p.period_num = 7 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 7 Then p.benchmark_end Else NULL END),
--		MIN(CASE WHEN p.period_num = 8 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 8 Then p.benchmark_end Else NULL END),
--		MIN(CASE WHEN p.period_num = 9 Then p.benchmark_start Else NULL END),  MAX(CASE WHEN p.period_num = 9 Then p.benchmark_end Else NULL END),
--		MIN(CASE WHEN p.period_num = 10 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 10 Then p.benchmark_end Else NULL END),
--		MIN(CASE WHEN p.period_num = 11 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 11 Then p.benchmark_end Else NULL END),
--		MIN(CASE WHEN p.period_num = 12 Then p.benchmark_start Else NULL END), MAX(CASE WHEN p.period_num = 12 Then p.benchmark_end Else NULL END),
--		--@report_date, @ultimate_start_date,
--		@revision_group, @business_unit_id, v_projrev_report.country_code, v_projrev_report.branch_code
--FROM	v_projrev_report,
--		branch,
--		#PERIODS p
--WHERE	( v_projrev_report.branch_code = branch.branch_code )
--AND		( v_projrev_report.delta_date <= @report_date )
--AND		( v_projrev_report.revenue_period >= @PERIOD_START )
--AND		( v_projrev_report.branch_code = @branch_code OR @branch_code = '')
--AND		( v_projrev_report.country_code = @country_code OR @country_code = '')
--AND		( v_projrev_report.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
--AND		( v_projrev_report.revision_group = @revision_group OR @revision_group = 0 )
--AND		( v_projrev_report.report_type = @report_type OR @report_type = '')
--and		p.period_group = 1		
--GROUP BY	v_projrev_report.country_code, 
--			v_projrev_report.branch_code,
--			branch.sort_order, 
--			branch.branch_name
--ORDER BY 2

SET FMTONLY OFF

-- Output Data
SELECT	h.group_action, 
		o.group_no, 
		ISNULL(o.group_desc, h.group_desc) AS group_desc,
		o.row_no, 
		ISNULL(h.row_desc, o.row_desc) AS row_desc,
		h.row_mode, h.row_action, h.rowweight, h.rowformat, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
		total = CASE When o.group_no IN (10) and o.row_no IN (40) Then totalpcnt Else total END,
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

--DROP TABLE #PERIODS
--DROP TABLE #HEADERS
--DROP TABLE #OUTPUT
GO
