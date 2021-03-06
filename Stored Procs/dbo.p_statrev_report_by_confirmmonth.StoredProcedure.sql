/****** Object:  StoredProcedure [dbo].[p_statrev_report_by_confirmmonth]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_report_by_confirmmonth]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_report_by_confirmmonth]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE       proc [dbo].[p_statrev_report_by_confirmmonth]
	@report_date		datetime,
	@delta_date		datetime,
	@PERIOD_START		datetime,
	@PERIOD_END		datetime,
	@branch_code		VARCHAR(1),
	@country_code		VARCHAR(1),
	@business_unit_id	INT,
	@revenue_group		INT,
	@master_revenue_group	INT
AS

DECLARE @ultimate_start_date	datetime
DECLARE @prev_report_date	datetime

CREATE TABLE #PERIODS (
	period_num		int		IDENTITY PRIMARY KEY CLUSTERED,
	period_no		int		not null,
	period_desc		varchar(30)	null,
	row_start_date		datetime	null,
	row_end_date		datetime	null,
)
--CREATE INDEX row_start_end_date_ind ON #PERIODS (row_start_date, row_end_date)

CREATE TABLE #OUTPUT (
	row_no	 	int		IDENTITY PRIMARY KEY CLUSTERED,
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
	statutory	decimal(12,4)	null DEFAULT 0.0, --money null,
	deferred	decimal(12,4)	null DEFAULT 0.0, --money null,
--	statdef		decimal(12,2)	null DEFAULT 0.0, --money null,
 	statdef		AS statutory + deferred,
	future		decimal(12,4)	null DEFAULT 0.0, --money null,
	row_rev_grp		int null,
	row_mast_rev_grp	int null,
	row_bus_unit_id		int null,
	row_country_code	varchar(1) null,
	row_branch_code		varchar(1) null,
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
	confirmmonthyear varchar(20),
	confirmmonth	int null,
	confirmyear	int null,
	row_start_date	datetime null,
	row_end_date	datetime null,
	row_report_date	datetime null,
	row_delta_date	datetime null,
)

-- Important to have the earlist first and the latest last
INSERT into #PERIODS( period_no, period_desc, row_start_date, row_end_date)
SELECT period_no, 'Period', benchmark_start, benchmark_end
FROM	accounting_period
WHERE	( benchmark_start <= @PERIOD_START AND benchmark_end >= @PERIOD_START) OR
	( benchmark_start >  @PERIOD_START AND benchmark_end <= @PERIOD_END)
ORDER BY 3,4

-- Important to have it ON to allow explicit identity to be inserted #PERIODS table
SET IDENTITY_INSERT #PERIODS ON

-- Insert Start/End dates for current and prior period
INSERT into #PERIODS( period_num, period_no, period_desc, row_start_date, row_end_date)
VALUES ( 100, 100, 'From To', @PERIOD_START, @PERIOD_END)

-- Set delta date unless specified
SELECT	@ultimate_start_date = '1-jan-1900'
SELECT	@prev_report_date = dateadd(yy, -1, @report_date)

--SELECT * FROM #PERIODS

-- Insert Total Actual Revenue
INSERT into #OUTPUT( 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, 
	confirmmonthyear,
	confirmmonth,
	confirmyear,
--	row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 1 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 2 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 3 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 4 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 5 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 6 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 7 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 8 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 9 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 10 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 11 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 12 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 100 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' AND ISNULL(revenue_period, p.row_end_date) >= p.row_start_date AND p.period_num = 100 Then COST ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > p.row_end_date AND p.period_num = 100 Then COST ELSE 0 END ),
	MIN(CASE WHEN p.period_num = 1 Then p.row_start_date Else NULL END),  MAX(CASE WHEN p.period_num = 1 Then p.row_end_date Else NULL END),
	MIN(CASE WHEN p.period_num = 2 Then p.row_start_date Else NULL END),  MAX(CASE WHEN p.period_num = 2 Then p.row_end_date Else NULL END),
	MIN(CASE WHEN p.period_num = 3 Then p.row_start_date Else NULL END),  MAX(CASE WHEN p.period_num = 3 Then p.row_end_date Else NULL END),
	MIN(CASE WHEN p.period_num = 4 Then p.row_start_date Else NULL END),  MAX(CASE WHEN p.period_num = 4 Then p.row_end_date Else NULL END),
	MIN(CASE WHEN p.period_num = 5 Then p.row_start_date Else NULL END),  MAX(CASE WHEN p.period_num = 5 Then p.row_end_date Else NULL END),
	MIN(CASE WHEN p.period_num = 6 Then p.row_start_date Else NULL END),  MAX(CASE WHEN p.period_num = 6 Then p.row_end_date Else NULL END),
	MIN(CASE WHEN p.period_num = 7 Then p.row_start_date Else NULL END),  MAX(CASE WHEN p.period_num = 7 Then p.row_end_date Else NULL END),
	MIN(CASE WHEN p.period_num = 8 Then p.row_start_date Else NULL END),  MAX(CASE WHEN p.period_num = 8 Then p.row_end_date Else NULL END),
	MIN(CASE WHEN p.period_num = 9 Then p.row_start_date Else NULL END),  MAX(CASE WHEN p.period_num = 9 Then p.row_end_date Else NULL END),
	MIN(CASE WHEN p.period_num = 10 Then p.row_start_date Else NULL END), MAX(CASE WHEN p.period_num = 10 Then p.row_end_date Else NULL END),
	MIN(CASE WHEN p.period_num = 11 Then p.row_start_date Else NULL END), MAX(CASE WHEN p.period_num = 11 Then p.row_end_date Else NULL END),
	MIN(CASE WHEN p.period_num = 12 Then p.row_start_date Else NULL END), MAX(CASE WHEN p.period_num = 12 Then p.row_end_date Else NULL END),
	MIN(CASE WHEN p.period_num = 100 Then p.row_start_date Else NULL END), MAX(CASE WHEN p.period_num = 100 Then p.row_end_date Else NULL END),
	datename ( year, statrev_campaign_revision.confirmation_date  ) + '-' + datename ( month, statrev_campaign_revision.confirmation_date  ),
	datepart ( mm, statrev_campaign_revision.confirmation_date),
	datepart ( yy, statrev_campaign_revision.confirmation_date),
--	@report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	v_statrev_report, #periods p,
	statrev_campaign_revision
WHERE	( v_statrev_report.campaign_no = statrev_campaign_revision.campaign_no ) and  
        ( v_statrev_report.revision_id = statrev_campaign_revision.revision_id ) and  
	( v_statrev_report.delta_date <= @report_date AND ISNULL(revenue_period, p.row_start_date) >= p.row_start_date )
	and ( v_statrev_report.branch_code = @branch_code or @branch_code = '')
	and ( v_statrev_report.country_code = @country_code or @country_code = '')
	and ( v_statrev_report.business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
	and ( v_statrev_report.revenue_group = @revenue_group or @revenue_group = 0)
	and ( v_statrev_report.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
GROUP BY  datename ( year, statrev_campaign_revision.confirmation_date  ) + '-' + datename ( month, statrev_campaign_revision.confirmation_date  ),
	datepart ( mm, statrev_campaign_revision.confirmation_date),
	datepart ( yy, statrev_campaign_revision.confirmation_date)

-- Output Data
SELECT	--o.row_no, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, 
	deferred,
	statdef,
	future,
	confirmmonthyear,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
--	row_start_date, row_end_date,
--	row_report_date, row_delta_date,
	o.row_rev_grp,
	o.row_mast_rev_grp,
	o.row_bus_unit_id,
	o.row_country_code,
	o.row_branch_code
FROM	#OUTPUT o
WHERE	revenue1 <> 0 OR revenue2 <> 0 OR revenue3 <> 0 OR revenue4 <> 0 OR revenue5 <> 0 OR revenue6 <> 0 OR 
	revenue7 <> 0 OR revenue8 <> 0 OR revenue9 <> 0 OR revenue10 <> 0 OR revenue11 <> 0 OR revenue12 <> 0
ORDER BY o.confirmyear desc, o.confirmmonth desc

DROP TABLE #PERIODS
DROP TABLE #OUTPUT
GO
