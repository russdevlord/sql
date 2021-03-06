/****** Object:  StoredProcedure [dbo].[p_Tableau_statrev_report_lv]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_Tableau_statrev_report_lv]
GO
/****** Object:  StoredProcedure [dbo].[p_Tableau_statrev_report_lv]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--drop proc p_Tableau_statrev_report_lv
CREATE     proc [dbo].[p_Tableau_statrev_report_lv]                                             	    @delta_date								datetime,
																								@PERIOD_START					datetime,
																								@PERIOD_END						datetime,
																								@mode										integer, -- 3 - Budget, 4 - Forecast
																								@branch_code							varchar(4),
																								@country_code							varchar(1),
																								@business_unit_id					int,
																								@revenue_group						int,
																								@master_revenue_group		int,
																								@report_type								varchar(1), -- 'C' - cinema, 'O' - outpost/retail, 'A' - All
																								@company									char(1),
																								@report_date							datetime
AS

set nocount on

--SET DATEFORMAT mdy

DECLARE @prev_report_date		datetime,
        @prev_end_period        datetime,
        @prev_start_period      datetime,
        @ultimate_start_date	datetime,
        @row_start_date		    datetime,
        @row_end_date		    datetime,
        @row_start_date_prev	datetime,
        @row_end_date_prev		datetime

SET DATEFORMAT dmy
        
--select @report_date = getdate()

-- Set dates unless specified
-- Set dates unless specified
SELECT      @ultimate_start_date = '1-JAN-1900'
SELECT      @prev_report_date = DATEADD(DAY, -365, @report_date);

Print @report_date

select @PERIOD_START = min(benchmark_end) from accounting_period where benchmark_end >= @PERIOD_START
select @PERIOD_END = max(benchmark_end) from accounting_period where benchmark_end <= @PERIOD_END

select @prev_start_period = benchmark_end from accounting_period where benchmark_end < @PERIOD_START and period_no in (select period_no from accounting_period where benchmark_end = @PERIOD_START)
select @prev_end_period = benchmark_end from accounting_period where benchmark_end < @PERIOD_END and period_no in (select period_no from accounting_period where benchmark_end = @PERIOD_END)

Print @prev_start_period
Print @prev_end_period
	        
CREATE TABLE #PERIODS (
            period_num              int               IDENTITY,
            period_no               int               NOT NULL,
            period_group            INT               NOT NULL,
            group_desc              varchar(30) null,
            benchmark_start         datetime    NOT null,
            benchmark_end           datetime    NOT null,
)


CREATE TABLE #OUTPUT (
      group_no						int         not null,
      group_desc					varchar(30) null,
      row_no							int         not null,
      row_desc						varchar(30) null,
      revenue_period			Datetime, 
      revenue           money       null DEFAULT 0.0,
      statutory         money       null DEFAULT 0.0,
      deferred          money       null DEFAULT 0.0,
     statdef                 AS statutory + deferred,
     statdefpcnt       money       null DEFAULT 0.0,
      future                  money       null DEFAULT 0.0,
      row_rev_grp       int         null,
      row_mast_rev_grp  int         null,
      row_bus_unit_id         int         null,
      row_country_code  varchar(1)  null,
      row_branch_code         varchar(4)  null,
      period01_start          datetime    null,
      period12_end            datetime    null,
      row_start_date          datetime    null,
      row_end_date            datetime    null,
      row_report_date         datetime    null,
      row_delta_date          datetime    null
      )
      
create table #revenue_data
(
    revenue_period						datetime			null,
    revenue_group						int						null,
    master_revenue_group		int						null,
    business_unit_id					int						null,
    country_code							char(1)				null,
    branch_code							char(2)				null,
    revenue									money				null,
    report_date								datetime			null,
    type1											char(1)				null,
    type2											char(1)				null,
    branch_name							varchar(30)     null,
    branch_sort_order				int						null,
    revenue_group_desc			varchar(30)     null    
)
CREATE INDEX revenue_data ON #revenue_data (report_date,branch_code,country_code,business_unit_id,revenue_group,master_revenue_group)


CREATE TABLE #HEADERS
(
	group_action		    varchar(10)				not null,
	group_no					int 								not null,
	group_desc		    varchar(30)				null,
	row_no	 					int								not null,
	row_desc					varchar(30)				null,
	row_mode		        int								null,
	row_action		        varchar(20)				null,
	rowweight					int								null,
	rowformat					int								null
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

INSERT      #PERIODS(period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT      period_no, 1, 'Current', benchmark_start, benchmark_end
FROM  accounting_period WITH (nolock)
WHERE benchmark_end BETWEEN @PERIOD_START AND @PERIOD_END
ORDER BY benchmark_start, benchmark_end

---- Important to have it ON to allow explicit identity to be inserted #PERIODS table
SET IDENTITY_INSERT #PERIODS ON

-- Insert prior year start/end dates (periods are different to current year)
INSERT      #PERIODS(period_num, period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT      #PERIODS.period_num, ap.period_no, 2, 'Prior', ap.benchmark_start, ap.benchmark_end
FROM  #PERIODS, accounting_period ap WITH (nolock)
WHERE #PERIODS.period_no = ap.period_no 
AND         DATEPART(YEAR, #PERIODS.benchmark_start) - 1 = DATEPART(YEAR, ap.benchmark_start)


select @row_start_date = min(benchmark_end) from #periods where period_group = 1
select @row_end_date = max(benchmark_end) from #periods where period_group = 1
select @row_start_date_prev = min(benchmark_end) from #periods where period_group = 2
select @row_end_date_prev = max(benchmark_end) from #periods where period_group = 2

/*
 * Insert Data
 */

if @report_type = 'C' or @report_type = 'A'
begin
	print '1'
    insert into #revenue_data
    select		statrev_cinema_normal_transaction.revenue_period, 
                statrev_revenue_group.revenue_group,
                statrev_revenue_master_group.master_revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,    
                sum(statrev_cinema_normal_transaction.cost),
                @report_date,
                'C',
                'N',
                branch_name, 
                sort_order,
                revenue_group_desc
    from	    dbo.statrev_cinema_normal_transaction WITH (nolock),
                dbo.statrev_revenue_group WITH (nolock),
                dbo.statrev_revenue_master_group WITH (nolock),
                dbo.statrev_transaction_type WITH (nolock),
                dbo.film_campaign WITH (nolock),
                dbo.branch WITH (nolock),
                dbo.statrev_campaign_revision
    WHERE	    statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
    and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
    and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
    and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
    and         statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
    and         film_campaign.branch_code = branch.branch_code
    and         revenue_period >= @prev_start_period
    and         delta_date <= @report_date
    and         (branch.branch_code = @branch_code or @branch_code = 'all')
    and         (branch.country_code = @country_code or @country_code = '')
    and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
    and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
    and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
    and			((@company = 'A' or @company = 'a')
    or			(@company = 'V' and business_unit_id in (2,3,5))
    or			(@company = 'C' and business_unit_id in (9))
    or			(@company = 'O' and business_unit_id in (6,7,8)))
    group by    statrev_cinema_normal_transaction.revenue_period, 
                statrev_revenue_master_group.master_revenue_group,
                statrev_revenue_group.revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,
                branch_name, 
                sort_order,
                revenue_group_desc
    union
    select		statrev_cinema_normal_transaction.revenue_period, 
                statrev_revenue_group.revenue_group,
                statrev_revenue_master_group.master_revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,    
                sum(statrev_cinema_normal_transaction.cost),
                @delta_date,
                'C',
                'N',
                branch_name, 
                sort_order,
                revenue_group_desc
    from	    dbo.statrev_cinema_normal_transaction WITH (nolock),
                dbo.statrev_revenue_group WITH (nolock),
                dbo.statrev_revenue_master_group WITH (nolock),
                dbo.statrev_transaction_type WITH (nolock),
                dbo.film_campaign WITH (nolock),
                dbo.branch WITH (nolock),
                dbo.statrev_campaign_revision WITH (nolock)
    WHERE	    statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
    and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
    and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
    and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
    and         statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
    and         film_campaign.branch_code = branch.branch_code
    and         revenue_period >= @prev_start_period
    and         delta_date <= @delta_date
    and         (branch.branch_code = @branch_code or @branch_code = 'all')
    and         (branch.country_code = @country_code or @country_code = '')
    and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
    and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
    and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
        and			((@company = 'A' or @company = 'a')
    or			(@company = 'V' and business_unit_id in (2,3,5))
    or			(@company = 'C' and business_unit_id in (9))
    or			(@company = 'O' and business_unit_id in (6,7,8)))
group by    statrev_cinema_normal_transaction.revenue_period, 
                statrev_revenue_master_group.master_revenue_group,
                statrev_revenue_group.revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,
                branch_name, 
                sort_order,
                revenue_group_desc
    union
    select		statrev_cinema_normal_transaction.revenue_period, 
                statrev_revenue_group.revenue_group,
                statrev_revenue_master_group.master_revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,    
                sum(statrev_cinema_normal_transaction.cost),
                @prev_report_date,
                'C',
                'N',
                branch_name, 
                sort_order,
                revenue_group_desc
    from	    dbo.statrev_cinema_normal_transaction WITH (nolock),
                dbo.statrev_revenue_group WITH (nolock),
                dbo.statrev_revenue_master_group WITH (nolock),
                dbo.statrev_transaction_type WITH (nolock),
                dbo.film_campaign WITH (nolock),
                dbo.branch WITH (nolock),
                dbo.statrev_campaign_revision WITH (nolock)
    WHERE	    statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
    and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
    and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
    and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
    and         statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
    and         film_campaign.branch_code = branch.branch_code
    and         revenue_period >= @prev_start_period
    and         delta_date <= @prev_report_date
    and         (branch.branch_code = @branch_code or @branch_code = 'all')
    and         (branch.country_code = @country_code or @country_code = '')
    and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
    and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
    and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
        and			((@company = 'A' or @company = 'a')
    or			(@company = 'V' and business_unit_id in (2,3,5))
    or			(@company = 'C' and business_unit_id in (9))
    or			(@company = 'O' and business_unit_id in (6,7,8)))
group by    statrev_cinema_normal_transaction.revenue_period, 
                statrev_revenue_master_group.master_revenue_group,
                statrev_revenue_group.revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,
                branch_name, 
                sort_order,
                revenue_group_desc
    
    insert into #revenue_data
    select		null, 
                statrev_revenue_group.revenue_group,
                statrev_revenue_master_group.master_revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,    
                sum(statrev_cinema_deferred_transaction.cost),
                @report_date,
                'C',
                'D',
                branch_name, 
                sort_order,
                revenue_group_desc
    from	    dbo.statrev_cinema_deferred_transaction WITH (nolock),
                dbo.statrev_revenue_group WITH (nolock),
                dbo.statrev_revenue_master_group WITH (nolock),
                dbo.statrev_transaction_type WITH (nolock),
                dbo.film_campaign WITH (nolock),
                dbo.branch WITH (nolock),
                dbo.statrev_campaign_revision WITH (nolock)
    WHERE	    statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
    and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
    and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
    and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
    and         statrev_campaign_revision.revision_id = statrev_cinema_deferred_transaction.revision_id
    and         film_campaign.branch_code = branch.branch_code
    and         delta_date <= @report_date
    and         (branch.branch_code = @branch_code or @branch_code = 'all')
    and         (branch.country_code = @country_code or @country_code = '')
    and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
    and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
    and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
        and			((@company = 'A' or @company = 'A')
    or			(@company = 'V' and business_unit_id in (2,3,5))
    or			(@company = 'C' and business_unit_id in (9))
    or			(@company = 'O' and business_unit_id in (6,7,8)))
group by    statrev_revenue_master_group.master_revenue_group,
                statrev_revenue_group.revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,
                branch_name, 
                sort_order,
                revenue_group_desc
    union
    select		null, 
                statrev_revenue_group.revenue_group,
                statrev_revenue_master_group.master_revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,    
                sum(statrev_cinema_deferred_transaction.cost),
                @delta_date,
                'C',
                'D',
                branch_name, 
                sort_order,
                revenue_group_desc
    from	    dbo.statrev_cinema_deferred_transaction WITH (nolock),
                dbo.statrev_revenue_group WITH (nolock),
                dbo.statrev_revenue_master_group WITH (nolock),
                dbo.statrev_transaction_type WITH (nolock),
                dbo.film_campaign WITH (nolock),
                dbo.branch WITH (nolock),
                dbo.statrev_campaign_revision WITH (nolock)
    WHERE	    statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
    and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
    and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
    and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
    and         statrev_campaign_revision.revision_id = statrev_cinema_deferred_transaction.revision_id
    and         film_campaign.branch_code = branch.branch_code
    and         delta_date <= @delta_date
    and         (branch.branch_code = @branch_code or @branch_code = 'all')
    and         (branch.country_code = @country_code or @country_code = '')
    and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
    and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
    and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
        and			((@company = 'A' or @company = 'a')
    or			(@company = 'V' and business_unit_id in (2,3,5))
    or			(@company = 'C' and business_unit_id in (9))
    or			(@company = 'O' and business_unit_id in (6,7,8)))
group by    statrev_revenue_master_group.master_revenue_group,
                statrev_revenue_group.revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,
                branch_name, 
                sort_order,
                revenue_group_desc
    union
    select		null, 
                statrev_revenue_group.revenue_group,
                statrev_revenue_master_group.master_revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,    
                sum(statrev_cinema_deferred_transaction.cost),
                @prev_report_date,
                'C',
                'D',
                branch_name, 
                sort_order,
                revenue_group_desc
    from	    dbo.statrev_cinema_deferred_transaction WITH (nolock),
                dbo.statrev_revenue_group WITH (nolock),
                dbo.statrev_revenue_master_group WITH (nolock),
                dbo.statrev_transaction_type WITH (nolock),
                dbo.film_campaign WITH (nolock),
                dbo.branch WITH (nolock),
                dbo.statrev_campaign_revision WITH (nolock)
    WHERE	    statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
    and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
    and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
    and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
    and         statrev_campaign_revision.revision_id = statrev_cinema_deferred_transaction.revision_id
    and         film_campaign.branch_code = branch.branch_code
    and         delta_date <= @prev_report_date
    and         (branch.branch_code = @branch_code or @branch_code = 'all')
    and         (branch.country_code = @country_code or @country_code = '')
    and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
    and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
    and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
        and			((@company = 'A' or @company = 'a')
    or			(@company = 'V' and business_unit_id in (2,3,5))
    or			(@company = 'C' and business_unit_id in (9))
    or			(@company = 'O' and business_unit_id in (6,7,8)))
group by    statrev_revenue_master_group.master_revenue_group,
                statrev_revenue_group.revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,
                branch_name, 
                sort_order,
                revenue_group_desc
end

if @report_type = 'O' or @report_type = 'A'
begin
    insert into #revenue_data
    select		statrev_outpost_normal_transaction.revenue_period, 
                statrev_revenue_group.revenue_group,
                statrev_revenue_master_group.master_revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,    
                sum(statrev_outpost_normal_transaction.cost),
                @report_date,
                'O',
                'N',
                branch_name, 
                sort_order,
                revenue_group_desc
    from	    dbo.statrev_outpost_normal_transaction WITH (nolock),
                dbo.statrev_revenue_group WITH (nolock),
                dbo.statrev_revenue_master_group WITH (nolock),
                dbo.statrev_transaction_type WITH (nolock),
                dbo.film_campaign WITH (nolock),
                dbo.branch WITH (nolock),
                dbo.statrev_campaign_revision WITH (nolock)
    WHERE	    statrev_outpost_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
    and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
    and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
    and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
    and         statrev_campaign_revision.revision_id = statrev_outpost_normal_transaction.revision_id
    and         film_campaign.branch_code = branch.branch_code
    and         revenue_period >= @prev_start_period
    and         delta_date <= @report_date
    and         (branch.branch_code = @branch_code or @branch_code = 'all')
    and         (branch.country_code = @country_code or @country_code = '')
    and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
    and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
    and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
       and			((@company = 'A' or @company = 'a')
    or			(@company = 'V' and business_unit_id in (2,3,5))
    or			(@company = 'C' and business_unit_id in (9))
    or			(@company = 'O' and business_unit_id in (6,7,8)))
 group by    statrev_outpost_normal_transaction.revenue_period, 
                statrev_revenue_master_group.master_revenue_group,
                statrev_revenue_group.revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,
                branch_name, 
                sort_order,
                revenue_group_desc
    union
    select		statrev_outpost_normal_transaction.revenue_period, 
                statrev_revenue_group.revenue_group,
                statrev_revenue_master_group.master_revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,    
                sum(statrev_outpost_normal_transaction.cost),
                @delta_date,
                'O',
                'N',
                branch_name, 
                sort_order,
                revenue_group_desc
    from	    dbo.statrev_outpost_normal_transaction WITH (nolock),
                dbo.statrev_revenue_group WITH (nolock),
                dbo.statrev_revenue_master_group WITH (nolock),
                dbo.statrev_transaction_type WITH (nolock),
                dbo.film_campaign WITH (nolock),
                dbo.branch WITH (nolock),
                dbo.statrev_campaign_revision WITH (nolock)
    WHERE	    statrev_outpost_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
    and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
    and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
    and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
    and         statrev_campaign_revision.revision_id = statrev_outpost_normal_transaction.revision_id
    and         film_campaign.branch_code = branch.branch_code
    and         revenue_period >= @prev_start_period
    and         delta_date <= @delta_date
    and         (branch.branch_code = @branch_code or @branch_code = 'all')
    and         (branch.country_code = @country_code or @country_code = '')
    and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
    and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
    and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
        and			((@company = 'A' or @company = 'a')
    or			(@company = 'V' and business_unit_id in (2,3,5))
    or			(@company = 'C' and business_unit_id in (9))
    or			(@company = 'O' and business_unit_id in (6,7,8)))
group by    statrev_outpost_normal_transaction.revenue_period, 
                statrev_revenue_master_group.master_revenue_group,
                statrev_revenue_group.revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,
                branch_name, 
                sort_order,
                revenue_group_desc
    union
    select		statrev_outpost_normal_transaction.revenue_period, 
                statrev_revenue_group.revenue_group,
                statrev_revenue_master_group.master_revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,    
                sum(statrev_outpost_normal_transaction.cost),
                @prev_report_date,
                'O',
                'N',
                branch_name, 
                sort_order,
                revenue_group_desc
    from	    dbo.statrev_outpost_normal_transaction WITH (nolock),
                dbo.statrev_revenue_group WITH (nolock),
                dbo.statrev_revenue_master_group WITH (nolock),
                dbo.statrev_transaction_type WITH (nolock),
                dbo.film_campaign WITH (nolock),
                dbo.branch WITH (nolock),
                dbo.statrev_campaign_revision WITH (nolock)
    WHERE	    statrev_outpost_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
    and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
    and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
    and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
    and         statrev_campaign_revision.revision_id = statrev_outpost_normal_transaction.revision_id
    and         film_campaign.branch_code = branch.branch_code
    and         revenue_period >= @prev_start_period
    and         delta_date <= @prev_report_date
    and         (branch.branch_code = @branch_code or @branch_code = 'all')
    and         (branch.country_code = @country_code or @country_code = '')
    and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
    and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
    and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
        and			((@company = 'A' or @company = 'a')
    or			(@company = 'V' and business_unit_id in (2,3,5))
    or			(@company = 'C' and business_unit_id in (9))
    or			(@company = 'O' and business_unit_id in (6,7,8)))
group by    statrev_outpost_normal_transaction.revenue_period, 
                statrev_revenue_master_group.master_revenue_group,
                statrev_revenue_group.revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,
                branch_name, 
                sort_order,
                revenue_group_desc
    
    insert into #revenue_data
    select		null, 
                statrev_revenue_group.revenue_group,
                statrev_revenue_master_group.master_revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,    
                sum(statrev_outpost_deferred_transaction.cost),
                @report_date,
                'O',
                'D',
                branch_name, 
                sort_order,
                revenue_group_desc
    from	    dbo.statrev_outpost_deferred_transaction WITH (nolock),
                dbo.statrev_revenue_group WITH (nolock),
                dbo.statrev_revenue_master_group WITH (nolock),
                dbo.statrev_transaction_type WITH (nolock),
                dbo.film_campaign WITH (nolock),
                dbo.branch WITH (nolock),
                dbo.statrev_campaign_revision WITH (nolock)
    WHERE	    statrev_outpost_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
    and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
    and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
    and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
    and         statrev_campaign_revision.revision_id = statrev_outpost_deferred_transaction.revision_id
    and         film_campaign.branch_code = branch.branch_code
    and         delta_date <= @report_date
    and         (branch.branch_code = @branch_code or @branch_code = 'all')
    and         (branch.country_code = @country_code or @country_code = '')
    and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
    and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
    and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
        and			((@company = 'A' or @company = 'a')
    or			(@company = 'V' and business_unit_id in (2,3,5))
    or			(@company = 'C' and business_unit_id in (9))
    or			(@company = 'O' and business_unit_id in (6,7,8)))
group by    statrev_revenue_master_group.master_revenue_group,
                statrev_revenue_group.revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,
                branch_name, 
                sort_order,
                revenue_group_desc
    union
    select		null, 
                statrev_revenue_group.revenue_group,
                statrev_revenue_master_group.master_revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,    
                sum(statrev_outpost_deferred_transaction.cost),
                @delta_date,
                'O',
                'D',
                branch_name, 
                sort_order,
                revenue_group_desc
    from	    dbo.statrev_outpost_deferred_transaction WITH (nolock),
                dbo.statrev_revenue_group WITH (nolock),
                dbo.statrev_revenue_master_group WITH (nolock),
                dbo.statrev_transaction_type WITH (nolock),
                dbo.film_campaign WITH (nolock),
                dbo.branch WITH (nolock),
                dbo.statrev_campaign_revision WITH (nolock)
    WHERE	    statrev_outpost_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
    and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
    and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
    and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
    and         statrev_campaign_revision.revision_id = statrev_outpost_deferred_transaction.revision_id
    and         film_campaign.branch_code = branch.branch_code
    and         delta_date <= @delta_date
    and         (branch.branch_code = @branch_code or @branch_code = 'all')
    and         (branch.country_code = @country_code or @country_code = '')
    and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
    and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
    and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
        and			((@company = 'A' or @company = 'a')
    or			(@company = 'V' and business_unit_id in (2,3,5))
    or			(@company = 'C' and business_unit_id in (9))
    or			(@company = 'O' and business_unit_id in (6,7,8)))
group by    statrev_revenue_master_group.master_revenue_group,
                statrev_revenue_group.revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,
                branch_name, 
                sort_order,
                revenue_group_desc
    union
    select		null, 
                statrev_revenue_group.revenue_group,
                statrev_revenue_master_group.master_revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,    
                sum(statrev_outpost_deferred_transaction.cost),
                @prev_report_date,
                'O',
                'D',
                branch_name, 
                sort_order,
                revenue_group_desc
    from	    dbo.statrev_outpost_deferred_transaction WITH (nolock),
                dbo.statrev_revenue_group WITH (nolock),
                dbo.statrev_revenue_master_group WITH (nolock),
                dbo.statrev_transaction_type WITH (nolock),
                dbo.film_campaign WITH (nolock),
                dbo.branch WITH (nolock),
                dbo.statrev_campaign_revision WITH (nolock)
    WHERE	    statrev_outpost_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
    and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
    and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
    and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
    and         statrev_campaign_revision.revision_id = statrev_outpost_deferred_transaction.revision_id
    and         film_campaign.branch_code = branch.branch_code
    and         delta_date <= @prev_report_date
    and         (branch.branch_code = @branch_code or @branch_code = 'all')
    and         (branch.country_code = @country_code or @country_code = '')
    and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
    and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
    and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
        and			((@company = 'A' or @company = 'a')
    or			(@company = 'V' and business_unit_id in (2,3,5))
    or			(@company = 'C' and business_unit_id in (9))
    or			(@company = 'O' and business_unit_id in (6,7,8)))
group by    statrev_revenue_master_group.master_revenue_group,
                statrev_revenue_group.revenue_group,
                film_campaign.business_unit_id,
                branch.country_code,
                branch.branch_code,
                branch_name, 
                sort_order,
                revenue_group_desc
end

-- Insert Total Actual Revenue
INSERT into #OUTPUT(group_no, row_no, revenue_period,
      Revenue,
      statutory, deferred, future,
      row_start_date, row_end_date, 
      row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT	10, 10,revenue_period,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN REVENUE ELSE 0 END ), -- Revenue
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN REVENUE ELSE 0 END ), -- Statutory
	0, -- Deferred
	0, -- Future
	@row_start_date,@row_end_date,
    @report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	#revenue_data WITH (nolock)
WHERE	( report_date = @report_date )
and		( type1 = @report_type OR @report_type = 'A' )
and		( branch_code = @branch_code or @branch_code = 'all')
and		( country_code = @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and		revenue_period between @row_start_date and @row_end_date OR revenue_period = null
group by revenue_period

INSERT into #OUTPUT(group_no, row_no, revenue_period,
      Revenue,
      statutory, deferred, future,
      row_start_date, row_end_date, 
      row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT	10, 10,revenue_period,
	0, -- Revenue
	0, -- Statutory
	0, -- Deferred
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @period_end THEN REVENUE ELSE 0 END ), -- Future
	@row_start_date,@row_end_date,
    @report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	#revenue_data WITH (nolock)
WHERE	( report_date = @report_date )
and		( type1 = @report_type OR @report_type = 'A' )
and		( branch_code = @branch_code or @branch_code = 'all')
and		( country_code = @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
AND		  revenue_period > @period_end
group by revenue_period

INSERT into #OUTPUT(group_no, row_no, revenue_period,
      Revenue,
      statutory, deferred, future,
      row_start_date, row_end_date, 
      row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT	10, 10, revenue_period,
	0, -- Revenue
	0, -- Statutory
	REVENUE, -- Deferred
	0, -- Future
	@row_start_date,@row_end_date,
    @report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	#revenue_data WITH (nolock)
WHERE	  TYPE2 = 'D' 
and		( report_date = @report_date )
and		( type1 = @report_type OR @report_type = 'A' )
and		( branch_code = @branch_code or @branch_code = 'all')
and		( country_code = @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
--group by revenue_period

-- Insert Revenue as of delta date
INSERT into #OUTPUT(group_no, row_no, revenue_period,
      Revenue,
      statutory, deferred, future,
      row_start_date, row_end_date, 
      row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT	10, 30,
revenue_period,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @period_end THEN REVENUE ELSE 0 END ),
    @row_start_date,@row_end_date,
    @report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
	FROM	#revenue_data WITH (nolock)
WHERE	( report_date = @delta_date ) 
and		( type1 = @report_type OR @report_type = 'A' )
and		( branch_code = @branch_code or @branch_code = 'all')
and		( country_code = @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and		revenue_period between @row_start_date and @row_end_date
group by revenue_period

/*INSERT into #OUTPUT(group_no, row_no, revenue_period,
      Revenue,
      statutory, deferred, future,
      row_start_date, row_end_date, 
      row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT	10, 30,
revenue_period,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @period_end THEN REVENUE ELSE 0 END ),
    @row_start_date,@row_end_date,
    @report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
	FROM	#revenue_data WITH (nolock)
WHERE	( report_date = @delta_date ) 
and		( type1 = @report_type OR @report_type = 'A' )
and		( branch_code = @branch_code or @branch_code = 'all')
and		( country_code = @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and		revenue_period between @row_start_date and @row_end_date
group by revenue_period
*/
-- Insert Difference between Actual and As of Revenues
INSERT into #OUTPUT(group_no, row_no, revenue_period,
      Revenue,
     statutory, deferred, future,
      row_start_date, row_end_date, row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT      DISTINCT 10, 20, o2.revenue_period,
      o1.revenue - o2.revenue, 
      o1.statutory - o2.statutory, o1.deferred - o2.deferred, o1.future - o2.future,
      o1.row_start_date, o1.row_end_date,@report_date
      , @delta_date,
      @revenue_group,   @master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM  #OUTPUT o1, #OUTPUT o2  WITH (nolock)
WHERE (o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 10 AND o2.row_no = 30)
            AND o1.revenue_period = o2.revenue_period

-- Insert Budget/Forecast
INSERT into #OUTPUT(group_no, row_no, revenue_period,
      revenue,
      statutory, deferred, future,
      row_start_date, row_end_date, row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT      20, 40, revenue_period,
SUM(CASE WHEN revenue_period between @row_start_date and @row_end_date Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
            SUM(CASE WHEN revenue_period between @row_start_date and @row_end_date Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),
           0,
           0,
            @row_start_date,@row_end_date,
            @report_date
            , @ultimate_start_date,
            @revenue_group,   @master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM  statrev_budgets sb WITH (nolock),
            statrev_revenue_group srg WITH (nolock),
            statrev_revenue_master_group srmg WITH (nolock),
            branch b WITH (nolock) 
WHERE sb.branch_code = b.branch_code
AND         sb.revenue_group = srg.revenue_group
AND         srg.master_revenue_group = srmg.master_revenue_group
and         ( b.branch_code = @branch_code or @branch_code = 'all')
and         ( b.country_code = @country_code or @country_code = '')
and         ( sb.business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and         ( srg.revenue_group = @revenue_group or @revenue_group = 0)
AND         ( srmg.master_revenue_group >= ( CASE @report_type When 'O' Then 50 Else 1 End ))
AND         ( srmg.master_revenue_group < ( CASE @report_type When 'C' Then 50 Else 2000 End ))
--AND         ( srmg.master_revenue_group >= ( CASE @report_type When 'A' Then 1 Else 2000 End ))
and         ( srmg.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
AND         ( sb.revenue_period BETWEEN @row_start_date and @row_end_date )
and			((@company = 'A' or @company = 'a')
or			(@company = 'V' and business_unit_id in (2,3,5))
or			(@company = 'C' and business_unit_id in (9))
or			(@company = 'O' and business_unit_id in (6,7,8)))
group by revenue_period

-- Revenue and Budget difference
INSERT into #OUTPUT(group_no, row_no, revenue_period,
      revenue, 
      statutory, deferred, future,
      row_start_date, row_end_date, row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT      20, 50, o2.revenue_period,
      o1.revenue - o2.revenue,
      o1.statutory - o2.statutory, 
      0,
      o1.future - o2.future,
      o1.row_start_date, o1.row_end_date, @report_date
      , @ultimate_start_date,
      @revenue_group,   @master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM  #OUTPUT o1 WITH (nolock), #OUTPUT o2 WITH (nolock)
WHERE (o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 20 AND o2.row_no = 40)
and o1.revenue_period = o2.revenue_period

-- Revenue and Budget difference percentage
INSERT into #OUTPUT(group_no, row_no, revenue_period,
      revenue,
      statutory, deferred, future, statdefpcnt,
      row_start_date, row_end_date, row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT      20, 60, o2.revenue_period,
      CASE o1.revenue When 0 Then 0 Else ( o1.revenue - o2.revenue) / o1.revenue*100 END, 
      CASE o1.statutory When 0 Then 0 Else ( o1.statutory - o2.statutory) / o1.statutory*100 END, 
      0,
      CASE o1.future When 0 Then 0 Else ( o1.future - o2.future) / o1.future*100 END,
      CASE o1.statdef When 0 Then 0 Else ( o1.statdef - o2.statdef) / o1.statdef*100 END,
      o1.row_start_date, o1.row_end_date, @report_date
      , @ultimate_start_date,
      @revenue_group,   @master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM  #OUTPUT o1 WITH (nolock), #OUTPUT o2 WITH (nolock)
WHERE (o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 20 AND o2.row_no = 40)
and o1.revenue_period = o2.revenue_period

--Prior Year Revenue
INSERT into #OUTPUT(group_no, row_no, revenue_period,
      Revenue,
      statutory, deferred, future,
      row_start_date, row_end_date, 
      row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT	30, 70,
revenue_period,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date_prev and @row_end_date_prev THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date_prev and @row_end_date_prev THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @period_end THEN REVENUE ELSE 0 END ),
    @row_start_date,@row_end_date,
    @report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	#revenue_data WITH (nolock)
WHERE	( report_date = @prev_report_date) 
and		( type1 = @report_type OR @report_type = 'A' )
and		( branch_code = @branch_code or @branch_code = 'all')
and		( country_code = @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and		revenue_period between @row_start_date_prev and @row_end_date_prev
group by revenue_period

-- Prior Year and Revenue Difference
INSERT into #OUTPUT(group_no, row_no, revenue_period,
      revenue,
      statutory, deferred, future,
      row_start_date, row_end_date, row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT      30, 80, o2.revenue_period,
      o1.revenue - o2.revenue, 
      o1.statutory - o2.statutory, o1.deferred - o2.deferred, o1.future - o2.future,
      o2.row_start_date, o2.row_end_date, 
      @prev_report_date, @ultimate_start_date,
      @revenue_group,   @master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM  #OUTPUT o1 WITH (nolock), #OUTPUT o2 WITH (nolock)
WHERE (o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 30 AND o2.row_no = 70)
and DATEADD(week,-52,o1.revenue_period) = o2.revenue_period

-- Prior Year and Revenue Difference Percentage
INSERT into #OUTPUT(group_no, row_no, revenue_period,
      revenue,
      statutory, deferred, future, statdefpcnt,
      row_start_date, row_end_date, row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT      30, 90, o2.revenue_period,
      CASE o1.revenue When 0 Then 0 Else ( o1.revenue - o2.revenue) / o1.revenue*100 END, 
      CASE o1.statutory When 0 Then 0 Else ( o1.statutory - o2.statutory) / o1.statutory*100 END, 
      CASE o1.deferred When 0 Then 0 Else ( o1.deferred - o2.deferred) / o1.deferred*100 END,
      CASE o1.future When 0 Then 0 Else ( o1.future - o2.future) / o1.future*100 END,
      CASE o1.statdef When 0 Then 0 Else ( o1.statdef - o2.statdef) / o1.statdef*100 END,
      o2.row_start_date, o2.row_end_date, 
      @prev_report_date, @ultimate_start_date,
      @revenue_group,   @master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM  #OUTPUT o1 WITH (nolock), #OUTPUT o2 WITH (nolock)
WHERE (o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 30 AND o2.row_no = 70)
and DATEADD(week,-52,o1.revenue_period) = o2.revenue_period

-- Prior Year Final Revenue
INSERT into #OUTPUT(group_no, row_no, revenue_period,
      Revenue,
      statutory, deferred, future,
      row_start_date, row_end_date, 
      row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT	40, 100,
	revenue_period,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date_prev and @row_end_date_prev THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date_prev and @row_end_date_prev THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @period_end THEN REVENUE ELSE 0 END ),
    @row_start_date,@row_end_date,
    @report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	#revenue_data WITH (nolock)
WHERE	( report_date = @report_date ) 
and		( type1 = @report_type OR @report_type = 'A' )
and		( branch_code = @branch_code or @branch_code = 'all')
and		( country_code = @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and		revenue_period between @row_start_date_prev and @row_end_date_prev
group by revenue_period

-- Prior Year and Revenue Difference
INSERT into #OUTPUT(group_no, row_no, revenue_period,
      revenue,
      statutory, deferred, future,
      row_start_date, row_end_date, row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT      40, 110, o2.revenue_period,
      o1.revenue - o2.revenue, 
      o1.statutory - o2.statutory, o1.deferred - o2.deferred, o1.future - o2.future,
      o2.row_start_date, o2.row_end_date, 
      @prev_report_date, @ultimate_start_date,
      @revenue_group,   @master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM  #OUTPUT o1 WITH (nolock), #OUTPUT o2 WITH (nolock)
WHERE (o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 40 AND o2.row_no = 100)
and DATEADD(week,-52,o1.revenue_period) = o2.revenue_period

-- Prior Year and Revenue Difference Percentage
INSERT into #OUTPUT(group_no, row_no, revenue_period,
      revenue,
      statutory, deferred, future, statdefpcnt,
      row_start_date, row_end_date, row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT      40, 120, o2.revenue_period,
      CASE o1.revenue When 0 Then 0 Else ( o1.revenue - o2.revenue) / o1.revenue*100 END, 
      CASE o1.statutory When 0 Then 0 Else ( o1.statutory - o2.statutory) / o1.statutory*100 END, 
      CASE o1.deferred When 0 Then 0 Else ( o1.deferred - o2.deferred) / o1.deferred*100 END,
      CASE o1.future When 0 Then 0 Else ( o1.future - o2.future) / o1.future*100 END,
      CASE o1.statdef When 0 Then 0 Else ( o1.statdef - o2.statdef) / o1.statdef*100 END,
      o2.row_start_date, o2.row_end_date, 
      @prev_report_date, @ultimate_start_date,
      @revenue_group,   @master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM  #OUTPUT o1 WITH (nolock), #OUTPUT o2 WITH (nolock)
WHERE (o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 40 AND o2.row_no = 100)
and DATEADD(week,-52,o1.revenue_period) = o2.revenue_period

-- Revenue by Groups
INSERT into #OUTPUT(group_no, row_no, row_desc, revenue_period,
      revenue,
      statutory, deferred, future,
      row_start_date, row_end_date, row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT	50, revenue_group * 10, revenue_group_desc,
	revenue_period,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @period_end THEN REVENUE ELSE 0 END ),
    @row_start_date,@row_end_date,
    @report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	#revenue_data WITH (nolock)
WHERE	( report_date = @report_date ) 
and		( type1 = @report_type OR @report_type = 'A' )
and		( branch_code = @branch_code or @branch_code = 'all')
and		( country_code = @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and		revenue_period between @row_start_date and @row_end_date
GROUP BY revenue_group, master_revenue_group, revenue_group_desc, revenue_period

-- State Revenue
INSERT into #OUTPUT(group_no, row_no, row_desc, revenue_period,
      revenue,
      statutory, deferred, future,
      row_start_date, row_end_date, row_report_date, row_delta_date,
      row_rev_grp, row_mast_rev_grp, row_bus_unit_id, row_country_code, row_branch_code)
SELECT	60, branch_sort_order, branch_name,
	revenue_period,
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'D' THEN REVENUE ELSE 0 END ),
	SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @period_end THEN REVENUE ELSE 0 END ),
    @row_start_date,@row_end_date,
    @report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, @country_code, @branch_code
FROM	#revenue_data WITH (nolock)
WHERE	( report_date = @report_date ) 
and		( type1 = @report_type OR @report_type = 'A' )
and		( branch_code = @branch_code or @branch_code = 'all')
and		( country_code = @country_code or @country_code = '')
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and		revenue_period between @row_start_date and @row_end_date
GROUP BY country_code, branch_code, branch_sort_order, branch_name, revenue_period


-- Output Data
SELECT      h.group_action as 'group_action', 
					  o.group_no as 'group_no', 
					  ISNULL(o.group_desc, h.group_desc) AS group_desc,
					  o.row_no as 'row_no', 
					  CASE WHEN h.group_desc IN ('Prior year', 'Prior Year Final') THEN DATEADD(WEEK,+52,o.revenue_period) Else o.revenue_period END as revenue_period,
					  ISNULL(h.row_desc, o.row_desc) AS row_desc,
					  h.row_mode as 'row_mode', 
					  h.row_action as 'row_action', 
					  h.rowweight as 'rowweight', 
					  h.rowformat as 'rowformat', 
					  statutory as 'statutory', 
					  deferred as 'deferred',
					  CASE When o.group_no IN (20, 30, 40) and o.row_no IN (60, 90, 120) Then statdefpcnt Else statdef END AS statdeftotal, 
					  future as 'future',
					  row_start_date as 'row_start_date', 
					  row_end_date as 'row_end_date', 
					  row_report_date as 'row_report_date', 
					  row_delta_date as 'row_delta_date',
					  o.row_rev_grp as 'row_rev_grp',
					  o.row_mast_rev_grp as 'row_mast_rev_grp',
					  o.row_bus_unit_id as 'row_bus_unit_id',
					  o.row_country_code as 'row_country_code',
					  o.row_branch_code as 'row_branch_code'
FROM  #OUTPUT o WITH (nolock), #HEADERS h WITH (nolock)
WHERE o.group_no = h.group_no AND (o.row_no = h.row_no OR h.row_no = 0)
ORDER BY  o.group_no, 
					  o.row_no
return 0
GO
