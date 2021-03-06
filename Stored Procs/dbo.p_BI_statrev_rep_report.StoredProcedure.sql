/****** Object:  StoredProcedure [dbo].[p_BI_statrev_rep_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_BI_statrev_rep_report]
GO
/****** Object:  StoredProcedure [dbo].[p_BI_statrev_rep_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     proc [dbo].[p_BI_statrev_rep_report]    @report_date			datetime,
	                                    @delta_date			    datetime,
	                                    @PERIOD_START			datetime,
	                                    @PERIOD_END			    datetime,
                                     	@mode				    integer, -- 3 - Budget, 4 - Forecast
										@business_unit_id		int,
	                                    @revenue_group			int,
	                                    @master_revenue_group	int,
										@rep_code				varchar(20)
AS

DECLARE @prev_report_date		datetime,
        @prev_end_period        datetime,
        @prev_start_period      datetime,
        @ultimate_start_date	datetime,
        @period01		        datetime,
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
        @row_end_date_prev		datetime,
		@team_rep_mode			char(1),
		@mode_id				int,
		@rep_pos				int,
		@team_pos				int

select @report_date = dateadd(ss, -1, dateadd(dd, 1, @report_date))

select @rep_pos = charindex('REPR', @rep_code, 1)
select @team_pos = charindex('TEAM', @rep_code, 1)

select 	@mode_id = convert(integer,substring(@rep_code, 5, 16))

if @rep_pos > 0
begin
	select 	@team_rep_mode = 'R'
end
else if @team_pos > 0
begin
	select 	@team_rep_mode = 'T'
end
else
begin
	return -1        
end


-- Set dates unless specified
SELECT	@ultimate_start_date = '1-JAN-1900'
SELECT	@prev_report_date = dateadd(yy, -1, @report_date)

select @PERIOD_START = min(benchmark_end) from accounting_period where benchmark_end >= @PERIOD_START
select @PERIOD_END = max(benchmark_end) from accounting_period where benchmark_end <= @PERIOD_END

select @prev_start_period = benchmark_end from accounting_period where benchmark_end < @PERIOD_START and period_no in (select period_no from accounting_period where benchmark_end = @PERIOD_START)
select @prev_end_period = benchmark_end from accounting_period where benchmark_end < @PERIOD_END and period_no in (select period_no from accounting_period where benchmark_end = @PERIOD_END)
	        
CREATE TABLE #PERIODS 
(
    period_num			    int			    IDENTITY,
    period_no			    int			    NOT NULL,
    period_group		    INT			    NOT NULL,
    group_desc			    varchar(30)	    null,
    benchmark_start		    datetime	    null,
    benchmark_end		    datetime	    null
)

CREATE TABLE #OUTPUT (
	group_no		        int 		    not null,
	group_desc		        varchar(30)	    null,
	row_no	 		        int		        not null,
	row_desc		        varchar(30)	    null,
	revenue1		        money		    null DEFAULT 0.0,
	revenue2		        money		    null DEFAULT 0.0,
	revenue3		        money		    null DEFAULT 0.0,
	revenue4		        money		    null DEFAULT 0.0,
	revenue5		        money		    null DEFAULT 0.0,
	revenue6		        money		    null DEFAULT 0.0,
	revenue7		        money		    null DEFAULT 0.0,
	revenue8		        money		    null DEFAULT 0.0,
	revenue9		        money		    null DEFAULT 0.0,
	revenue10		        money		    null DEFAULT 0.0,
	revenue11		        money		    null DEFAULT 0.0,
	revenue12		        money		    null DEFAULT 0.0,
	statutory		        money		    null DEFAULT 0.0,
	deferred		        money		    null DEFAULT 0.0,
 	statdef	AS statutory + deferred,
 	statdefpcnt		        money		    null DEFAULT 0.0,
	future			        money		    null DEFAULT 0.0,
	row_rev_grp		        int 		    null,
	row_mast_rev_grp	    int		        null,
	row_bus_unit_id		    int 		    null,
	row_country_code	    varchar(1)	    null,
	row_branch_code		    varchar(1)	    null,
	period01_start		    datetime	    null,
	period02_start		    datetime 	    null,
	period03_start		    datetime	    null,
	period04_start		    datetime	    null,
	period05_start		    datetime	    null,
	period06_start		    datetime	    null,
	period07_start		    datetime	    null,
	period08_start		    datetime	    null,
	period09_start		    datetime	    null,
	period10_start		    datetime	    null,
	period11_start		    datetime	    null,
	period12_start		    datetime 	    null,
	period01_end		    datetime 	    null,
	period02_end		    datetime 	    null,
	period03_end		    datetime 	    null,
	period04_end		    datetime 	    null,
	period05_end		    datetime 	    null,
	period06_end		    datetime 	    null,
	period07_end		    datetime 	    null,
	period08_end		    datetime 	    null,
	period09_end		    datetime 	    null,
	period10_end		    datetime 	    null,
	period11_end		    datetime 	    null,
	period12_end		    datetime 	    null,
	row_start_date		    datetime 	    null,
	row_end_date		    datetime	    null,
	row_report_date		    datetime	    null,
	row_delta_date		    datetime	    null
	)
CREATE INDEX group_no_row_no ON #OUTPUT (group_no, row_no)

create table #revenue_data
(
    revenue_period          datetime        null,
    revenue_group           int             null,
    master_revenue_group    int             null,
    business_unit_id        int             null,
    country_code            char(1)         null,
    branch_code             char(2)         null,
    revenue                 money           null,
    report_date             datetime        null,
    type1                   char(1)         null,
    type2                   char(1)         null,
    branch_name             varchar(30)     null,
    branch_sort_order       int             null,
    revenue_group_desc      varchar(30)     null    
)
CREATE INDEX revenue_data ON #revenue_data (report_date,branch_code,country_code,business_unit_id,revenue_group,master_revenue_group)


CREATE TABLE #HEADERS
(
	group_action		    varchar(10)	    not null,
	group_no		        int 		    not null,
	group_desc		        varchar(30)	    null,
	row_no	 		        int		        not null,
	row_desc		        varchar(30)	    null,
	row_mode		        int		        null,
	row_action		        varchar(20)	    null,
	rowweight		        int		        null,
	rowformat		        int		        null
	)

-- Important to have the earlist first and the latest last
INSERT	#PERIODS(period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT	period_no, 1, 'Current', benchmark_start, benchmark_end
FROM	accounting_period
WHERE	benchmark_end BETWEEN @PERIOD_START AND @PERIOD_END
ORDER BY 4,5

---- Important to have it ON to allow explicit identity to be inserted #PERIODS table
SET IDENTITY_INSERT #PERIODS ON

-- Insert prior year start/end dates (periods are different to current year)
INSERT	#PERIODS(period_num, period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT	#PERIODS.period_num, ap.period_no, 2, 'Prior', ap.benchmark_start, ap.benchmark_end
FROM	#PERIODS, accounting_period ap
WHERE	#PERIODS.period_no = ap.period_no 
AND		DATEPART(YEAR, #PERIODS.benchmark_start) - 1 = DATEPART(YEAR, ap.benchmark_start)


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
        
/*
 * Insert Data
 */

insert into #revenue_data
select		statrev_cinema_normal_transaction.revenue_period, 
            statrev_revenue_group.revenue_group,
            statrev_revenue_master_group.master_revenue_group,
            film_campaign.business_unit_id,
            branch.country_code,
            branch.branch_code,    
            sum(statrev_cinema_normal_transaction.cost * statrev_revision_team_xref.revenue_percent),
            @report_date,
            'C',
            'N',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_cinema_normal_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_team_xref
WHERE	    statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         revenue_period >= @prev_start_period
and         delta_date <= @report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_team_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_team_xref.team_id = @mode_id
and			@team_rep_mode = 'T'
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
            sum(statrev_cinema_normal_transaction.cost * statrev_revision_team_xref.revenue_percent),
            @delta_date,
            'C',
            'N',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_cinema_normal_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_team_xref
WHERE	    statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         revenue_period >= @prev_start_period
and         delta_date <= @delta_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_team_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_team_xref.team_id = @mode_id
and			@team_rep_mode = 'T'
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
            sum(statrev_cinema_normal_transaction.cost * statrev_revision_team_xref.revenue_percent),
            @prev_report_date,
            'C',
            'N',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_cinema_normal_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_team_xref
WHERE	    statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         revenue_period >= @prev_start_period
and         delta_date <= @prev_report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_team_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_team_xref.team_id = @mode_id
and			@team_rep_mode = 'T'
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
            sum(statrev_cinema_deferred_transaction.cost * statrev_revision_team_xref.revenue_percent),
            @report_date,
            'C',
            'D',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_cinema_deferred_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_team_xref
WHERE	    statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_deferred_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         delta_date <= @report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_team_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_team_xref.team_id = @mode_id
and			@team_rep_mode = 'T'
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
            sum(statrev_cinema_deferred_transaction.cost * statrev_revision_team_xref.revenue_percent),
            @delta_date,
            'C',
            'D',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_cinema_deferred_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_team_xref
WHERE	    statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_deferred_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         delta_date <= @delta_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_team_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_team_xref.team_id = @mode_id
and			@team_rep_mode = 'T'
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
            sum(statrev_cinema_deferred_transaction.cost * statrev_revision_team_xref.revenue_percent),
            @prev_report_date,
            'C',
            'D',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_cinema_deferred_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_team_xref
WHERE	    statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_deferred_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         delta_date <= @prev_report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_team_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_team_xref.team_id = @mode_id
and			@team_rep_mode = 'T'
group by    statrev_revenue_master_group.master_revenue_group,
            statrev_revenue_group.revenue_group,
            film_campaign.business_unit_id,
            branch.country_code,
            branch.branch_code,
            branch_name, 
            sort_order,
            revenue_group_desc


insert into #revenue_data
select		statrev_outpost_normal_transaction.revenue_period, 
            statrev_revenue_group.revenue_group,
            statrev_revenue_master_group.master_revenue_group,
            film_campaign.business_unit_id,
            branch.country_code,
            branch.branch_code,    
            sum(statrev_outpost_normal_transaction.cost * statrev_revision_team_xref.revenue_percent),
            @report_date,
            'O',
            'N',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_outpost_normal_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_team_xref
WHERE	    statrev_outpost_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_outpost_normal_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         revenue_period >= @prev_start_period
and         delta_date <= @report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_team_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_team_xref.team_id = @mode_id
and			@team_rep_mode = 'T'
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
            sum(statrev_outpost_normal_transaction.cost * statrev_revision_team_xref.revenue_percent),
            @delta_date,
            'O',
            'N',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_outpost_normal_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_team_xref
WHERE	    statrev_outpost_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_outpost_normal_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         revenue_period >= @prev_start_period
and         delta_date <= @delta_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_team_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_team_xref.team_id = @mode_id
and			@team_rep_mode = 'T'
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
            sum(statrev_outpost_normal_transaction.cost * statrev_revision_team_xref.revenue_percent),
            @prev_report_date,
            'O',
            'N',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_outpost_normal_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_team_xref
WHERE	    statrev_outpost_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_outpost_normal_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         revenue_period >= @prev_start_period
and         delta_date <= @prev_report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_team_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_team_xref.team_id = @mode_id
and			@team_rep_mode = 'T'
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
            sum(statrev_outpost_deferred_transaction.cost * statrev_revision_team_xref.revenue_percent),
            @report_date,
            'O',
            'D',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_outpost_deferred_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_team_xref
WHERE	    statrev_outpost_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_outpost_deferred_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         delta_date <= @report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_team_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_team_xref.team_id = @mode_id
and			@team_rep_mode = 'T'
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
            sum(statrev_outpost_deferred_transaction.cost * statrev_revision_team_xref.revenue_percent),
            @delta_date,
            'O',
            'D',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_outpost_deferred_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_team_xref
WHERE	    statrev_outpost_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_outpost_deferred_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         delta_date <= @delta_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_team_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_team_xref.team_id = @mode_id
and			@team_rep_mode = 'T'
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
            sum(statrev_outpost_deferred_transaction.cost * statrev_revision_team_xref.revenue_percent),
            @prev_report_date,
            'O',
            'D',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_outpost_deferred_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_team_xref
WHERE	    statrev_outpost_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_outpost_deferred_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         delta_date <= @prev_report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_team_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_team_xref.team_id = @mode_id
and			@team_rep_mode = 'T'
group by    statrev_revenue_master_group.master_revenue_group,
            statrev_revenue_group.revenue_group,
            film_campaign.business_unit_id,
            branch.country_code,
            branch.branch_code,
            branch_name, 
            sort_order,
            revenue_group_desc

insert into #revenue_data
select		statrev_cinema_normal_transaction.revenue_period, 
            statrev_revenue_group.revenue_group,
            statrev_revenue_master_group.master_revenue_group,
            film_campaign.business_unit_id,
            branch.country_code,
            branch.branch_code,    
            sum(statrev_cinema_normal_transaction.cost * statrev_revision_rep_xref.revenue_percent),
            @report_date,
            'C',
            'N',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_cinema_normal_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_rep_xref
WHERE	    statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         revenue_period >= @prev_start_period
and         delta_date <= @report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_rep_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_rep_xref.rep_id = @mode_id
and			@team_rep_mode = 'R'
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
            sum(statrev_cinema_normal_transaction.cost * statrev_revision_rep_xref.revenue_percent),
            @delta_date,
            'C',
            'N',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_cinema_normal_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_rep_xref
WHERE	    statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         revenue_period >= @prev_start_period
and         delta_date <= @delta_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_rep_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_rep_xref.rep_id = @mode_id
and			@team_rep_mode = 'R'
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
            sum(statrev_cinema_normal_transaction.cost * statrev_revision_rep_xref.revenue_percent),
            @prev_report_date,
            'C',
            'N',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_cinema_normal_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_rep_xref
WHERE	    statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         revenue_period >= @prev_start_period
and         delta_date <= @prev_report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_rep_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_rep_xref.rep_id = @mode_id
and			@team_rep_mode = 'R'
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
            sum(statrev_cinema_deferred_transaction.cost * statrev_revision_rep_xref.revenue_percent),
            @report_date,
            'C',
            'D',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_cinema_deferred_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_rep_xref
WHERE	    statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_deferred_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         delta_date <= @report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_rep_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_rep_xref.rep_id = @mode_id
and			@team_rep_mode = 'R'
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
            sum(statrev_cinema_deferred_transaction.cost * statrev_revision_rep_xref.revenue_percent),
            @delta_date,
            'C',
            'D',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_cinema_deferred_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_rep_xref
WHERE	    statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_deferred_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         delta_date <= @delta_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_rep_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_rep_xref.rep_id = @mode_id
and			@team_rep_mode = 'R'
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
            sum(statrev_cinema_deferred_transaction.cost * statrev_revision_rep_xref.revenue_percent),
            @prev_report_date,
            'C',
            'D',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_cinema_deferred_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_rep_xref
WHERE	    statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_deferred_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         delta_date <= @prev_report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_rep_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_rep_xref.rep_id = @mode_id
and			@team_rep_mode = 'R'
group by    statrev_revenue_master_group.master_revenue_group,
            statrev_revenue_group.revenue_group,
            film_campaign.business_unit_id,
            branch.country_code,
            branch.branch_code,
            branch_name, 
            sort_order,
            revenue_group_desc


insert into #revenue_data
select		statrev_outpost_normal_transaction.revenue_period, 
            statrev_revenue_group.revenue_group,
            statrev_revenue_master_group.master_revenue_group,
            film_campaign.business_unit_id,
            branch.country_code,
            branch.branch_code,    
            sum(statrev_outpost_normal_transaction.cost * statrev_revision_rep_xref.revenue_percent),
            @report_date,
            'O',
            'N',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_outpost_normal_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_rep_xref
WHERE	    statrev_outpost_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_outpost_normal_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         revenue_period >= @prev_start_period
and         delta_date <= @report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_rep_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_rep_xref.rep_id = @mode_id
and			@team_rep_mode = 'R'
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
            sum(statrev_outpost_normal_transaction.cost * statrev_revision_rep_xref.revenue_percent),
            @delta_date,
            'O',
            'N',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_outpost_normal_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_rep_xref
WHERE	    statrev_outpost_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_outpost_normal_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         revenue_period >= @prev_start_period
and         delta_date <= @delta_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_rep_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_rep_xref.rep_id = @mode_id
and			@team_rep_mode = 'R'
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
            sum(statrev_outpost_normal_transaction.cost * statrev_revision_rep_xref.revenue_percent),
            @prev_report_date,
            'O',
            'N',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_outpost_normal_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_rep_xref
WHERE	    statrev_outpost_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_outpost_normal_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         revenue_period >= @prev_start_period
and         delta_date <= @prev_report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_rep_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_rep_xref.rep_id = @mode_id
and			@team_rep_mode = 'R'
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
            sum(statrev_outpost_deferred_transaction.cost * statrev_revision_rep_xref.revenue_percent),
            @report_date,
            'O',
            'D',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_outpost_deferred_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_rep_xref
WHERE	    statrev_outpost_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_outpost_deferred_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         delta_date <= @report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_rep_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_rep_xref.rep_id = @mode_id
and			@team_rep_mode = 'R'
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
            sum(statrev_outpost_deferred_transaction.cost * statrev_revision_rep_xref.revenue_percent),
            @delta_date,
            'O',
            'D',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_outpost_deferred_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_rep_xref
WHERE	    statrev_outpost_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_outpost_deferred_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         delta_date <= @delta_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_rep_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_rep_xref.rep_id = @mode_id
and			@team_rep_mode = 'R'
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
            sum(statrev_outpost_deferred_transaction.cost * statrev_revision_rep_xref.revenue_percent),
            @prev_report_date,
            'O',
            'D',
            branch_name, 
            sort_order,
            revenue_group_desc
from	    dbo.statrev_outpost_deferred_transaction,
            dbo.statrev_revenue_group,
            dbo.statrev_revenue_master_group,
            dbo.statrev_transaction_type,
            dbo.film_campaign,
            dbo.branch,
            dbo.statrev_campaign_revision,
			dbo.statrev_revision_rep_xref
WHERE	    statrev_outpost_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_outpost_deferred_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and         delta_date <= @prev_report_date
and         (film_campaign.business_unit_id = @business_unit_id or @business_unit_id = 0) 
and         (statrev_revenue_group.revenue_group = @revenue_group or @revenue_group = 0)
and         (statrev_revenue_master_group.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and			statrev_revision_rep_xref.revision_id = statrev_campaign_revision.revision_id
and			statrev_revision_rep_xref.rep_id = @mode_id
and			@team_rep_mode = 'R'
group by    statrev_revenue_master_group.master_revenue_group,
            statrev_revenue_group.revenue_group,
            film_campaign.business_unit_id,
            branch.country_code,
            branch.branch_code,
            branch_name, 
            sort_order,
            revenue_group_desc

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
if @team_rep_mode = 'T'
	INSERT INTO #HEADERS VALUES ( 'Revenue', 70, 'Account Managers', 0, NULL, 1, 'Current',  400, 1)


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
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period01 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period02 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period03 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period04 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period05 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period06 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period07 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period08 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period09 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period10 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period11 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period12 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'D' THEN REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @period_end THEN REVENUE ELSE 0 END ),0),
    @period01,@period01,
    @period02,@period02,
    @period03,@period03,
    @period04,@period04,
    @period05,@period05,
    @period06,@period06,
    @period07,@period07,
    @period08,@period08,
    @period09,@period09,
    @period10,@period10,
    @period11,@period11,
    @period12,@period12,
    @row_start_date,@row_end_date,
    @report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, '', ''
FROM	#revenue_data
WHERE	( report_date = @report_date )
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)

-- Insert Revenue as of delta date
INSERT into #OUTPUT(group_no, row_no, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, 
	row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	10, 30,
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period01 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period02 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period03 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period04 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period05 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period06 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period07 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period08 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period09 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period10 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period11 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period12 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'D' THEN REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @period_end THEN REVENUE ELSE 0 END ),0),
    @period01,@period01,
    @period02,@period02,
    @period03,@period03,
    @period04,@period04,
    @period05,@period05,
    @period06,@period06,
    @period07,@period07,
    @period08,@period08,
    @period09,@period09,
    @period10,@period10,
    @period11,@period11,
    @period12,@period12,
    @row_start_date,@row_end_date,
	@delta_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, '', ''
FROM	#revenue_data
WHERE	( report_date = @delta_date ) 
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
	
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
	@revenue_group,	@master_revenue_group, @business_unit_id, '', ''
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 10 AND o2.row_no = 30)


-- Insert Budget/Forecast
if @team_rep_mode = 'R'
begin
	INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
		statutory, deferred, future,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		row_start_date, row_end_date, row_report_date, row_delta_date,
		row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
	SELECT	20, 40,
		isnull(SUM(CASE WHEN revenue_period = @period01 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period02 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period03 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period04 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period05 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period06 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period07 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period08 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period09 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period10 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period11 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period12 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period between @row_start_date and @row_end_date Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
	 	0,
	 	0,
	    @period01,@period01,
	    @period02,@period02,
	    @period03,@period03,
	    @period04,@period04,
	    @period05,@period05,
	    @period06,@period06,
	    @period07,@period07,
	    @period08,@period08,
	    @period09,@period09,
	    @period10,@period10,
	    @period11,@period11,
	    @period12,@period12,
	    @row_start_date,@row_end_date,
		@report_date, @ultimate_start_date,
		@revenue_group,	@master_revenue_group, @business_unit_id, '', ''
	FROM	statrev_budgets_rep sb,
			statrev_revenue_group srg,
			statrev_revenue_master_group srmg
	WHERE	sb.revenue_group = srg.revenue_group
	AND		srg.master_revenue_group = srmg.master_revenue_group
	AND		sb.revenue_period between @row_start_date and @row_end_date
	and		sb.rep_id = @mode_id
	and		@team_rep_mode = 'R'
	and     ( sb.business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
	and     ( srg.revenue_group = @revenue_group or @revenue_group = 0)
	and     ( srmg.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
end	

if @team_rep_mode = 'T'
begin
-- Insert Budget/Forecast
	INSERT into #OUTPUT(group_no, row_no, 
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
		statutory, deferred, future,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		row_start_date, row_end_date, row_report_date, row_delta_date,
		row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
	SELECT	20, 40,
		isnull(SUM(CASE WHEN revenue_period = @period01 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period02 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period03 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period04 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period05 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period06 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period07 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period08 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period09 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period10 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period11 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period = @period12 Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
		isnull(SUM(CASE WHEN revenue_period between @row_start_date and @row_end_date Then (CASE @mode When 3 Then Budget Else Forecast END) ELSE 0 END ),0),
	 	0,
	 	0,
	    @period01,@period01,
	    @period02,@period02,
	    @period03,@period03,
	    @period04,@period04,
	    @period05,@period05,
	    @period06,@period06,
	    @period07,@period07,
	    @period08,@period08,
	    @period09,@period09,
	    @period10,@period10,
	    @period11,@period11,
	    @period12,@period12,
	    @row_start_date,@row_end_date,
		@report_date, @ultimate_start_date,
		@revenue_group,	@master_revenue_group, @business_unit_id, '', ''
	FROM	statrev_budgets_rep sb,
			statrev_revenue_group srg,
			statrev_revenue_master_group srmg
	WHERE	sb.revenue_group = srg.revenue_group
	AND		srg.master_revenue_group = srmg.master_revenue_group
	AND		sb.revenue_period between @row_start_date and @row_end_date
	and		sb.team_id = @mode_id
	and		@team_rep_mode = 'T'
	and     ( sb.business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
	and     ( srg.revenue_group = @revenue_group or @revenue_group = 0)
	and     ( srmg.master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
end

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
	@revenue_group,	@master_revenue_group, @business_unit_id, '', ''
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
	@revenue_group,	@master_revenue_group, @business_unit_id, '', ''
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 20 AND o2.row_no = 40)

--Prior Year Revenue
INSERT into #OUTPUT(group_no, row_no, 
 	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	30, 70,
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period01_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period02_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period03_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period04_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period05_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period06_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period07_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period08_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period09_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period10_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period11_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period12_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date_prev and @row_end_date_prev THEN REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'D' THEN REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @row_end_date_prev THEN REVENUE ELSE 0 END ),0),
    @period01_prev,@period01_prev,
    @period02_prev,@period02_prev,
    @period03_prev,@period03_prev,
    @period04_prev,@period04_prev,
    @period05_prev,@period05_prev,
    @period06_prev,@period06_prev,
    @period07_prev,@period07_prev,
    @period08_prev,@period08_prev,
    @period09_prev,@period09_prev,
    @period10_prev,@period10_prev,
    @period11_prev,@period11_prev,
    @period12_prev,@period12_prev,
    @row_start_date_prev,@row_end_date_prev,
	@prev_report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, '', ''
FROM	#revenue_data
WHERE	( report_date = @prev_report_date ) 
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)


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
	@revenue_group,	@master_revenue_group, @business_unit_id, '', ''
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 30 AND o2.row_no = 70)


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
	@revenue_group,	@master_revenue_group, @business_unit_id, '', ''
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 30 AND o2.row_no = 70)


-- Prior Year Final Revenue
INSERT into #OUTPUT(group_no, row_no, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	40, 100,
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period01_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period02_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period03_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period04_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period05_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period06_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period07_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period08_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period09_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period10_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period11_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period12_prev Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date_prev and @row_end_date_prev THEN REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'D' THEN REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @row_end_date_prev THEN REVENUE ELSE 0 END ),0),
    @period01_prev,@period01_prev,
    @period02_prev,@period02_prev,
    @period03_prev,@period03_prev,
    @period04_prev,@period04_prev,
    @period05_prev,@period05_prev,
    @period06_prev,@period06_prev,
    @period07_prev,@period07_prev,
    @period08_prev,@period08_prev,
    @period09_prev,@period09_prev,
    @period10_prev,@period10_prev,
    @period11_prev,@period11_prev,
    @period12_prev,@period12_prev,
    @row_start_date_prev,@row_end_date_prev,
	@report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, '', ''
FROM	#revenue_data
WHERE	( report_date = @report_date ) 
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)


-- Prior Year Final and Revenue Difference
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
	@report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, '', ''
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 40 AND o2.row_no = 100)

-- Prior Year Final and Revenue Difference percentage
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
	@report_date, @ultimate_start_date,
	@revenue_group,	@master_revenue_group, @business_unit_id, '', ''
FROM	#OUTPUT o1, #OUTPUT o2
WHERE	(o1.group_no = 10 AND o1.row_no = 10) AND (o2.group_no = 40 AND o2.row_no = 100)


-- Revenue by Groups
INSERT into #OUTPUT(group_no, row_no, row_desc,
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	50, revenue_group * 10, revenue_group_desc,
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period01 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period02 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period03 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period04 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period05 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period06 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period07 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period08 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period09 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period10 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period11 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period12 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'D' THEN REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @period_end THEN REVENUE ELSE 0 END ),0),
    @period01,@period01,
    @period02,@period02,
    @period03,@period03,
    @period04,@period04,
    @period05,@period05,
    @period06,@period06,
    @period07,@period07,
    @period08,@period08,
    @period09,@period09,
    @period10,@period10,
    @period11,@period11,
    @period12,@period12,
    @row_start_date,@row_end_date,
	@report_date, @ultimate_start_date,
	revenue_group, master_revenue_group, @business_unit_id, '', ''
FROM	#revenue_data
WHERE	( report_date = @report_date ) 
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
GROUP BY revenue_group, master_revenue_group, revenue_group_desc

-- State Revenue
INSERT into #OUTPUT(group_no, row_no, row_desc,
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
SELECT	60, branch_sort_order, branch_name,
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period01 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period02 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period03 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period04 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period05 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period06 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period07 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period08 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period09 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period10 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period11 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period12 Then REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'D' THEN REVENUE ELSE 0 END ),0),
	isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @period_end THEN REVENUE ELSE 0 END ),0),
    @period01,@period01,
    @period02,@period02,
    @period03,@period03,
    @period04,@period04,
    @period05,@period05,
    @period06,@period06,
    @period07,@period07,
    @period08,@period08,
    @period09,@period09,
    @period10,@period10,
    @period11,@period11,
    @period12,@period12,
    @row_start_date,@row_end_date,
	@report_date, @ultimate_start_date,
	@revenue_group, @master_revenue_group, @business_unit_id, country_code, branch_code
FROM	#revenue_data
WHERE	( report_date = @report_date ) 
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
GROUP BY country_code, branch_code, branch_sort_order, branch_name
ORDER BY country_code, branch_code, branch_sort_order, branch_name

if @team_rep_mode= 'T'
begin
	-- Account Manager Revenue
	INSERT into #OUTPUT(group_no, row_no, row_desc,
		revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12, 
		statutory, deferred, future,
		period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
		period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
		row_start_date, row_end_date, row_report_date, row_delta_date,
		row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code)
	SELECT	70, branch_sort_order, branch_name,
		isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period01 Then REVENUE ELSE 0 END ),0),
		isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period02 Then REVENUE ELSE 0 END ),0),
		isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period03 Then REVENUE ELSE 0 END ),0),
		isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period04 Then REVENUE ELSE 0 END ),0),
		isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period05 Then REVENUE ELSE 0 END ),0),
		isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period06 Then REVENUE ELSE 0 END ),0),
		isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period07 Then REVENUE ELSE 0 END ),0),
		isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period08 Then REVENUE ELSE 0 END ),0),
		isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period09 Then REVENUE ELSE 0 END ),0),
		isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period10 Then REVENUE ELSE 0 END ),0),
		isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period11 Then REVENUE ELSE 0 END ),0),
		isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period = @period12 Then REVENUE ELSE 0 END ),0),
		isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period between @row_start_date and @row_end_date THEN REVENUE ELSE 0 END ),0),
		isnull(SUM(CASE WHEN TYPE2 = 'D' THEN REVENUE ELSE 0 END ),0),
		isnull(SUM(CASE WHEN TYPE2 = 'N' AND revenue_period > @period_end THEN REVENUE ELSE 0 END ),0),
	    @period01,@period01,
	    @period02,@period02,
	    @period03,@period03,
	    @period04,@period04,
	    @period05,@period05,
	    @period06,@period06,
	    @period07,@period07,
	    @period08,@period08,
	    @period09,@period09,
	    @period10,@period10,
	    @period11,@period11,
	    @period12,@period12,
	    @row_start_date,@row_end_date,
		@report_date, @ultimate_start_date,
		@revenue_group, @master_revenue_group, @business_unit_id, country_code, branch_code
	FROM	#revenue_data
	WHERE	( report_date = @report_date ) 
	and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
	and		( revenue_group = @revenue_group or @revenue_group = 0)
	and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
	GROUP BY country_code, branch_code, branch_sort_order, branch_name
	ORDER BY country_code, branch_code, branch_sort_order, branch_name
end


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
	period01_end, period02_end, period03_end, period04_end, period05_end, period06_end,
	period07_end, period08_end, period09_end, period10_end, period11_end, period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date,
	o.row_rev_grp,
	o.row_mast_rev_grp,
	o.row_bus_unit_id,
	o.row_country_code,
	o.row_branch_code,
	@mode_id As mode_ID
INTO #PreFormat
FROM	#OUTPUT o, #HEADERS h
WHERE	o.group_no = h.group_no AND (o.row_no = h.row_no OR h.row_no = 0)

-- Output Data
SELECT DISTINCT --Row_desc, period01_end AS Period, 
CASE WHEN group_no = 10 THEN Sum(revenue1) END Revenue, CASE WHEN group_no = 20 THEN Sum(revenue1) END Budget, CASE WHEN group_no = 40 THEN Sum(revenue1) END Prior_Year
FROM #PreFormat
Where row_desc = 'Actual'
AND group_no IN (10,20,40)
group by group_no
--GROUP BY row_desc, group_no, period01_end, revenue1
--UNION ALL
--SELECT DISTINCT CASE WHEN (row_desc = 'Actual') THEN row_desc End Row_desc, Max(period02_end) AS Period, CASE WHEN group_no = 10 THEN revenue2 END Revenue, CASE WHEN group_no = 20 THEN revenue2 END Budget, CASE WHEN group_no = 40 THEN Sum(revenue2) END Prior_Year
--FROM #PreFormat
--Where row_desc = 'Actual'
--AND group_no IN (10,20,40)
--GROUP BY row_desc, group_no, period02_end, revenue2
--DROP Proc p_BI_statrev_rep_report

--return 0
GO
