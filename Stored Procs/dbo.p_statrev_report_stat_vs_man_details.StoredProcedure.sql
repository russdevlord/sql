/****** Object:  StoredProcedure [dbo].[p_statrev_report_stat_vs_man_details]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_report_stat_vs_man_details]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_report_stat_vs_man_details]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE    proc [dbo].[p_statrev_report_stat_vs_man_details]
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

CREATE TABLE #PERIODS (
	period_num			int		IDENTITY PRIMARY KEY CLUSTERED,
	period_no			int			not null,
	period_desc			varchar(30)	null,
	row_start_date		datetime	null,
	row_end_date		datetime	null,
)
CREATE INDEX row_start_end_date_ind ON #PERIODS (row_start_date, row_end_date)

CREATE TABLE #HEADERS(
	group_action	varchar(10)	not null,
	group_no		int 		not null,
	group_desc		varchar(30)	null,
	row_no	 		int			not null,
	row_desc		varchar(30)	null,
	row_mode		int			null,
	row_action		varchar(20)	null,
	rowweight		int			null,
	rowformat		int			null,
)

-- Insert Groups/Line headers such group desc, font, format..etc
-- Statutory - 'A', Management - 'B', Difference 'Z'
INSERT INTO #HEADERS VALUES ( 'A', 10, 'Revenue', 10, 'Actual', 1, 'A', 400, 1)
INSERT INTO #HEADERS VALUES ( 'A', 20, 'Revenue', 10, 'Actual', 1, 'B', 400, 1)
INSERT INTO #HEADERS VALUES ( 'A', 90, 'Revenue', 10, 'Actual', 1, 'Z', 700, 2)
INSERT INTO #HEADERS VALUES ( 'B', 30, 'Revenue Groups', 0, NULL, 1, 'A',  400, 1)
INSERT INTO #HEADERS VALUES ( 'B', 40, 'Revenue Groups', 0, NULL, 1, 'B',  400, 1)
INSERT INTO #HEADERS VALUES ( 'B', 90, 'Revenue Groups', 0, NULL, 1, 'Z',  700, 2)
INSERT INTO #HEADERS VALUES ( 'C', 50, 'State Revenue', 0, NULL, 1, 'A',  400, 1)
INSERT INTO #HEADERS VALUES ( 'C', 60, 'State Revenue', 0, NULL, 1, 'B',  400, 1)
INSERT INTO #HEADERS VALUES ( 'C', 90, 'State Revenue', 0, NULL, 1, 'Z',  700, 2)

CREATE TABLE #OUTPUT (
	group_action	varchar(1)	not null,
	group_no		int 		not null,
	group_desc		varchar(30)	null,
	row_no	 		int			not null,
	row_desc		varchar(30)	null,
	campaign_no		int			not null,
	product_desc	varchar(100)	not null,
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
 	statdef		AS statutory + deferred,
	future		decimal(12,4)	null DEFAULT 0.0, --money null,
)

-- Important to have the earlist first and the latest last
INSERT into #PERIODS( period_no, period_desc, row_start_date, row_end_date)
SELECT period_no, 'Period', benchmark_start, benchmark_end
FROM	accounting_period
WHERE	( benchmark_start <= @PERIOD_START AND benchmark_end >= @PERIOD_START) OR
	( benchmark_start >  @PERIOD_START AND benchmark_end <= @PERIOD_END)
ORDER BY benchmark_start, benchmark_end

-- Important to have it ON to allow explicit identity to be inserted #PERIODS table
SET IDENTITY_INSERT #PERIODS ON

-- Insert Start/End dates for current and prior period
INSERT into #PERIODS( period_num, period_no, period_desc, row_start_date, row_end_date)
VALUES ( 100, 100, 'From To', @PERIOD_START, @PERIOD_END)

-- Set delta date unless specified
SELECT	@ultimate_start_date = '1-jan-1900'
SELECT	@prev_report_date = dateadd(yy, -1, @report_date)

-- Insert Total Actual Revenue
INSERT into #OUTPUT( group_action, group_no, row_no, campaign_no, product_desc,
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, deferred, future)
SELECT	'A', 10, 10, campaign_no, product_desc,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 1 Then COST ELSE 0 END ),
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
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > p.row_end_date AND p.period_num = 100 Then COST ELSE 0 END )
FROM	v_statrev_report, #periods p
WHERE	( delta_date <= @report_date ) AND ( ISNULL(revenue_period, p.row_start_date) >= p.row_start_date)
	and ( type1 = @report_type OR @report_type = '' )
	and ( branch_code = @branch_code or @branch_code = '')
	and ( country_code = @country_code or @country_code = '')
	and ( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
	and ( revenue_group = @revenue_group or @revenue_group = 0)
	and ( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
	and		business_unit_id not in (6,7,8)
GROUP BY campaign_no, product_desc

-- Management Total Revenue
INSERT into #OUTPUT( group_action, group_no, row_no, campaign_no, product_desc,
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, deferred, future)
SELECT	'A', 20, 10, fc.campaign_no, fc.product_desc,
	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 1 Then COST ELSE 0 END ),
	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 2 Then COST ELSE 0 END ),
	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 3 Then COST ELSE 0 END ),
	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 4 Then COST ELSE 0 END ),
	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 5 Then COST ELSE 0 END ),
	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 6 Then COST ELSE 0 END ),
	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 7 Then COST ELSE 0 END ),
	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 8 Then COST ELSE 0 END ),
	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 9 Then COST ELSE 0 END ),
	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 10 Then COST ELSE 0 END ),
	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 11 Then COST ELSE 0 END ),
	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 12 Then COST ELSE 0 END ),
	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 100 Then COST ELSE 0 END ),
	0,
	SUM(CASE WHEN revenue_period > p.row_end_date and p.period_num = 100 Then COST ELSE 0 END )
from	film_campaign fc,
	campaign_revision cr,
	v_mgt_revision_transactions rtx,
	branch b,
	business_unit bu,
	#periods p
WHERE	fc.campaign_no = cr.campaign_no AND
	( report_type = @report_type OR @report_type = '' ) and
	fc.branch_code = b.branch_code and 
	fc.business_unit_id = bu.business_unit_id and
	cr.revision_id = rtx.revision_id
	AND ( rtx.delta_date <= @report_date )
	and ( rtx.revenue_period >= @PERIOD_START) AND ( rtx.revenue_period <= @PERIOD_END )
	and ( b.branch_code = @branch_code or @branch_code = '')
	and ( b.country_code = @country_code or @country_code = '')
	and ( bu.business_unit_id = @business_unit_id or @business_unit_id = 0 )
	and		bu.business_unit_id not in (6,7,8)
GROUP BY fc.campaign_no, product_desc

---- Revenue by Groups
--INSERT into #OUTPUT( group_action, group_no, row_no, campaign_no, row_desc, product_desc,
--	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
--	statutory, deferred, future)
--SELECT	'B', 30, master_revenue_group * 10, campaign_no, master_revenue_group_desc, product_desc,
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 1 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 2 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 3 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 4 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 5 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 6 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 7 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 8 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 9 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 10 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 11 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 12 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 100 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'D' AND ISNULL(revenue_period, p.row_end_date) >= p.row_start_date AND p.period_num = 100 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > p.row_end_date and p.period_num = 100 Then COST ELSE 0 END )
--FROM	v_statrev_report, #periods p
--WHERE	( delta_date <= @report_date ) AND ( ISNULL(revenue_period, p.row_start_date) >= p.row_start_date)
--	and ( type1 = @report_type OR @report_type = '' )
--	and ( branch_code = @branch_code or @branch_code = '')
--	and ( country_code = @country_code or @country_code = '')
--	and ( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
--	and ( revenue_group = @revenue_group or @revenue_group = 0)
--	and ( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
--GROUP BY master_revenue_group,master_revenue_group_desc, campaign_no, product_desc

---- Management Total by Revision Group
--INSERT into #OUTPUT( group_action, group_no, row_no, fc.campaign_no, row_desc, product_desc,
--	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
--	statutory, deferred, future)
--SELECT	'B', 40, rg.revision_group * 10, fc.campaign_no, rg.revision_group_desc, fc.product_desc,
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 1 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 2 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 3 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 4 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 5 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 6 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 7 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 8 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 9 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 10 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 11 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 12 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 100 Then COST ELSE 0 END ),
--	0,
--	SUM(CASE WHEN revenue_period > p.row_end_date and p.period_num = 100 Then COST ELSE 0 END )
--from	film_campaign fc,
--	campaign_revision cr,
--	revision_transaction_type rtt,
--	v_mgt_revision_transactions rtx,
--	revision_group rg,
--	branch b,
--	business_unit bu,
--	#periods p
--WHERE	fc.campaign_no = cr.campaign_no AND
--	fc.branch_code = b.branch_code and 
--	( report_type = @report_type OR @report_type = '' ) and
--	fc.business_unit_id = bu.business_unit_id and
--	cr.revision_id = rtx.revision_id and
--	rtx.revision_transaction_type = rtt.revision_transaction_type and
--	rtt.revision_group = rg.revision_group 
--	AND ( rtx.delta_date <= @report_date )
--	and ( rtx.revenue_period >= @PERIOD_START) AND ( rtx.revenue_period <= @PERIOD_END )
--	and ( b.branch_code = @branch_code or @branch_code = '')
--	and ( b.country_code = @country_code or @country_code = '')
--	and ( bu.business_unit_id = @business_unit_id or @business_unit_id = 0 )
--	and ( rg.revision_group = @revenue_group or @revenue_group = 0)
--GROUP BY rg.revision_group, rg.revision_group_desc, fc.campaign_no, fc.product_desc

---- State Revenue 
--INSERT into #OUTPUT( group_action, group_no, row_no, campaign_no, row_desc, product_desc,
--	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
--	statutory, deferred, future)
--SELECT	'C', 50, branch_sort_order, campaign_no, branch_name, product_desc,
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 1 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 2 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 3 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 4 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 5 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 6 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 7 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 8 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 9 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 10 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 11 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 12 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 100 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'D' AND ISNULL(revenue_period, p.row_end_date) >= p.row_start_date AND p.period_num = 100 Then COST ELSE 0 END ),
--	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > p.row_end_date and p.period_num = 100 Then COST ELSE 0 END )
--FROM	v_statrev_report, #periods p
--WHERE	( delta_date <= @report_date ) AND ( ISNULL(revenue_period, p.row_start_date) >= p.row_start_date)
-- 	and ( type1 = @report_type OR @report_type = '' )
--	and ( branch_code = @branch_code or @branch_code = '')
--	and ( country_code = @country_code or @country_code = '')
--	and ( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
--	and ( revenue_group = @revenue_group or @revenue_group = 0)
--	and ( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
--GROUP BY country_code, branch_code, branch_sort_order, branch_name, campaign_no, product_desc

---- Management Total by State
--INSERT into #OUTPUT( group_action, group_no, row_no, campaign_no, row_desc, product_desc,
--	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
--	statutory, deferred, future)
--SELECT	'C', 60, b.sort_order, fc.campaign_no, b.branch_name, product_desc,
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 1 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 2 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 3 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 4 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 5 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 6 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 7 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 8 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 9 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 10 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 11 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 12 Then COST ELSE 0 END ),
--	SUM(CASE WHEN revenue_period BETWEEN p.row_start_date and p.row_end_date and p.period_num = 100 Then COST ELSE 0 END ),
--	0,
--	SUM(CASE WHEN revenue_period > p.row_end_date and p.period_num = 100 Then COST ELSE 0 END )
--from	film_campaign fc,
--	campaign_revision cr,
--	revision_transaction_type rtt,
--	v_mgt_revision_transactions rtx,
--	revision_group rg,
--	branch b,
--	business_unit bu,
--	#periods p
--WHERE	fc.campaign_no = cr.campaign_no AND
--	fc.branch_code = b.branch_code and 
--	fc.business_unit_id = bu.business_unit_id and
--	( report_type = @report_type OR @report_type = '' ) and
--	cr.revision_id = rtx.revision_id and
--	rtx.revision_transaction_type = rtt.revision_transaction_type and
--	rtt.revision_group = rg.revision_group 
--	AND ( rtx.delta_date <= @report_date )
--	and ( rtx.revenue_period >= @PERIOD_START) AND ( rtx.revenue_period <= @PERIOD_END )
--	and ( b.branch_code = @branch_code or @branch_code = '')
--	and ( b.country_code = @country_code or @country_code = '')
--	and ( bu.business_unit_id = @business_unit_id or @business_unit_id = 0 )
--	and ( rg.revision_group = @revenue_group or @revenue_group = 0)
--GROUP BY b.country_code, b.branch_code, b.sort_order, b.branch_name, fc.campaign_no, fc.product_desc

-- Delete campaigns with 0 revenues, deferred and future amounts
DELETE FROM #OUTPUT
WHERE statutory = 0 AND deferred = 0 AND future = 0

-- Insert Diff for campaign existing in BOTH - Statutory and Management
INSERT into #OUTPUT( group_action, group_no, row_no, campaign_no, row_desc, product_desc, 
 	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
 	statutory, deferred, future)
SELECT	o1.group_action, 90, o1.row_no, o1.campaign_no, o1.row_desc, o1.product_desc,
	o1.revenue1 - o2.revenue1, o1.revenue2 - o2.revenue2, o1.revenue3 - o2.revenue3, o1.revenue4 - o2.revenue4, o1.revenue5 - o2.revenue5, o1.revenue6 - o2.revenue6,
	o1.revenue7 - o2.revenue7, o1.revenue8 - o2.revenue8, o1.revenue9 - o2.revenue9, o1.revenue10 - o2.revenue10, o1.revenue11 - o2.revenue11, o1.revenue12 - o2.revenue12,
	o1.statutory - o2.statutory, o1.deferred - o2.deferred, o1.future - o2.future
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	o1.group_action = o2.group_action AND o1.row_no = o2.row_no AND o1.campaign_no = o2.campaign_no 
	AND (( o1.group_no = 10 and o2.group_no = 20 ) OR ( o1.group_no = 30 and o2.group_no = 40 ) OR ( o1.group_no = 50 and o2.group_no = 60 ))

-- Insert Diff for campaign existing Statutory, BUT NOT in Management
INSERT into #OUTPUT( group_action, group_no, row_no, campaign_no, row_desc, product_desc, 
 	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
 	statutory, deferred, future)
SELECT	o1.group_action, 90, o1.row_no, o1.campaign_no, o1.row_desc, o1.product_desc,
	o1.revenue1, o1.revenue2, o1.revenue3, o1.revenue4, o1.revenue5, o1.revenue6,
	o1.revenue7, o1.revenue8, o1.revenue9, o1.revenue10, o1.revenue11, o1.revenue12,
	o1.statutory, o1.deferred, o1.future
FROM	#OUTPUT o1
WHERE	o1.group_no IN( 10, 30, 50 ) and o1.campaign_no NOT IN ( SELECT o2.campaign_no FROM #OUTPUT o2 WHERE o2.group_no IN ( 20, 40, 60 ))

-- Insert Diff for campaign existing Management, BUT NOT in Statutory
INSERT into #OUTPUT( group_action, group_no, row_no, campaign_no, row_desc, product_desc, 
 	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
 	statutory, deferred, future)
SELECT	o1.group_action, 90, o1.row_no, o1.campaign_no, o1.row_desc, o1.product_desc,
	o1.revenue1, o1.revenue2, o1.revenue3, o1.revenue4, o1.revenue5, o1.revenue6,
	o1.revenue7, o1.revenue8, o1.revenue9, o1.revenue10, o1.revenue11, o1.revenue12,
	o1.statutory, o1.deferred, o1.future
FROM	#OUTPUT o1
WHERE	o1.group_no IN ( 20, 40, 60 ) and o1.campaign_no NOT IN ( SELECT o2.campaign_no FROM #OUTPUT o2 WHERE o2.group_no IN( 10, 30, 50 ))

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
	(SELECT p.row_start_date FROM #periods p WHERE p.period_num = 1), (SELECT p.row_end_date FROM #periods p WHERE p.period_num = 1), 
	(SELECT p.row_start_date FROM #periods p WHERE p.period_num = 2), (SELECT p.row_end_date FROM #periods p WHERE p.period_num = 2), 
	(SELECT p.row_start_date FROM #periods p WHERE p.period_num = 3), (SELECT p.row_end_date FROM #periods p WHERE p.period_num = 3), 
	(SELECT p.row_start_date FROM #periods p WHERE p.period_num = 4), (SELECT p.row_end_date FROM #periods p WHERE p.period_num = 4), 
	(SELECT p.row_start_date FROM #periods p WHERE p.period_num = 5), (SELECT p.row_end_date FROM #periods p WHERE p.period_num = 5), 
	(SELECT p.row_start_date FROM #periods p WHERE p.period_num = 6), (SELECT p.row_end_date FROM #periods p WHERE p.period_num = 6), 
	(SELECT p.row_start_date FROM #periods p WHERE p.period_num = 7), (SELECT p.row_end_date FROM #periods p WHERE p.period_num = 7), 
	(SELECT p.row_start_date FROM #periods p WHERE p.period_num = 8), (SELECT p.row_end_date FROM #periods p WHERE p.period_num = 8), 
	(SELECT p.row_start_date FROM #periods p WHERE p.period_num = 9), (SELECT p.row_end_date FROM #periods p WHERE p.period_num = 9), 
	(SELECT p.row_start_date FROM #periods p WHERE p.period_num = 10), (SELECT p.row_end_date FROM #periods p WHERE p.period_num = 10), 
	(SELECT p.row_start_date FROM #periods p WHERE p.period_num = 11), (SELECT p.row_end_date FROM #periods p WHERE p.period_num = 11), 
	(SELECT p.row_start_date FROM #periods p WHERE p.period_num = 12), (SELECT p.row_end_date FROM #periods p WHERE p.period_num = 12), 
	(SELECT p.row_start_date FROM #periods p WHERE p.period_num = 100), (SELECT p.row_end_date FROM #periods p WHERE p.period_num = 100), 
	o.campaign_no,
	o.product_desc
FROM	#OUTPUT o, #HEADERS h
WHERE	o.group_action = h.group_action AND o.group_no = h.group_no AND (o.row_no = h.row_no OR h.row_no = 0)
ORDER BY h.group_action, o.row_no, o.product_desc, campaign_no, o.group_no

----DEBUG
--SELECT	sum(revenue1),
--		sum(revenue2),
--		sum(revenue3),
--		sum(revenue4),
--		sum(revenue5),
--		sum(revenue6),
--		sum(revenue7),
--		sum(revenue8),
--		sum(revenue9),
--		sum(revenue10),
--		sum(revenue11),
--		sum(revenue12),
--		sum(statutory),
--		sum(deferred),
--		sum(statdef),
--		sum(future)
--FROM #OUTPUT
--where group_action = 'A'
--group BY group_no
--ORDER BY GROUP_NO

DROP TABLE #PERIODS
DROP TABLE #OUTPUT
DROP TABLE #HEADERS
GO
