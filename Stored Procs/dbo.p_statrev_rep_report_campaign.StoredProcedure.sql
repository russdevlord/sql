/****** Object:  StoredProcedure [dbo].[p_statrev_rep_report_campaign]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_rep_report_campaign]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_rep_report_campaign]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE     proc [dbo].[p_statrev_rep_report_campaign]   @report_date			datetime,
														@delta_date			    datetime,
														@PERIOD_START			datetime,
														@PERIOD_END			    datetime,
														@business_unit_id		int,
														@revenue_group			int,
														@master_revenue_group	int,
														@rep_code				varchar(20)


AS

set nocount on

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
	        
CREATE TABLE #report_periods 
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
	group_desc		        varchar(100)	    null,
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
	row_delta_date		    datetime	    null,
    campaign_no				int				null,
    product_desc			varchar(100)	null,
	client_name				varchar(100)	null,
	agency_name				varchar(100)	null,
	agency_group_name		varchar(100)	null,
	buying_group_desc		varchar(100)	null
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
    revenue_group_desc      varchar(30)     null,
    campaign_no				int				null,
    product_desc			varchar(100)	null,
	client_name				varchar(100)	null,
	agency_name				varchar(100)	null,
	agency_group_name		varchar(100)	null,
	buying_group_desc		varchar(100)	null    
)

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
INSERT	#report_periods(period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT	period_no, 1, 'Current', benchmark_start, benchmark_end
FROM	accounting_period
WHERE	benchmark_end BETWEEN @PERIOD_START AND @PERIOD_END
ORDER BY benchmark_start, benchmark_end

---- Important to have it ON to allow explicit identity to be inserted #report_periods table
SET IDENTITY_INSERT #report_periods ON

select @period01            = benchmark_end from #report_periods where period_num = 1 and period_group = 1
select @period02            = benchmark_end from #report_periods where period_num = 2 and period_group = 1
select @period03            = benchmark_end from #report_periods where period_num = 3 and period_group = 1
select @period04            = benchmark_end from #report_periods where period_num = 4 and period_group = 1
select @period05            = benchmark_end from #report_periods where period_num = 5 and period_group = 1
select @period06            = benchmark_end from #report_periods where period_num = 6 and period_group = 1
select @period07            = benchmark_end from #report_periods where period_num = 7 and period_group = 1
select @period08            = benchmark_end from #report_periods where period_num = 8 and period_group = 1
select @period09            = benchmark_end from #report_periods where period_num = 9 and period_group = 1
select @period10            = benchmark_end from #report_periods where period_num = 10 and period_group = 1
select @period11            = benchmark_end from #report_periods where period_num = 11 and period_group = 1
select @period12            = benchmark_end from #report_periods where period_num = 12 and period_group = 1
select @row_start_date	    = min(benchmark_end) from #report_periods where period_group = 1
select @row_end_date		= max(benchmark_end) from #report_periods where period_group = 1
select @row_start_date_prev = min(benchmark_end) from #report_periods where period_group = 2
select @row_end_date_prev   = max(benchmark_end) from #report_periods where period_group = 2

/*
select * from #report_periods      
select @PERIOD_START
select @team_rep_mode
select @mode_id
*/

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
            revenue_group_desc,
            film_campaign.campaign_no,
            film_campaign.product_desc,
			client_name,
			agency_name,
			agency_group_name,
			buying_group_desc
from	    statrev_cinema_normal_transaction,
            statrev_revenue_group,
            statrev_revenue_master_group,
            statrev_transaction_type,
            film_campaign,
            branch,
            statrev_campaign_revision,
			statrev_revision_team_xref,
			agency,
			client,
			agency_groups,
			agency_buying_groups
WHERE	    statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and			film_campaign.client_id = client.client_id
and			film_campaign.reporting_agency = agency.agency_id
and			agency.agency_group_id = agency_groups.agency_group_id
and			agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and         revenue_period >= @period_start
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
            revenue_group_desc,
            film_campaign.campaign_no,
            film_campaign.product_desc,
			client_name,
			agency_name,
			agency_group_name,
			buying_group_desc

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
            revenue_group_desc,
            film_campaign.campaign_no,
            film_campaign.product_desc,
			client_name,
			agency_name,
			agency_group_name,
			buying_group_desc
from	    statrev_cinema_deferred_transaction,
            statrev_revenue_group,
            statrev_revenue_master_group,
            statrev_transaction_type,
            film_campaign,
            branch,
            statrev_campaign_revision,
			statrev_revision_team_xref,
			agency,
			client,
			agency_groups,
			agency_buying_groups
WHERE	    statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_deferred_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and			film_campaign.client_id = client.client_id
and			film_campaign.reporting_agency = agency.agency_id
and			agency.agency_group_id = agency_groups.agency_group_id
and			agency_groups.buying_group_id = agency_buying_groups.buying_group_id
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
            revenue_group_desc,
            film_campaign.campaign_no,
            film_campaign.product_desc,
			client_name,
			agency_name,
			agency_group_name,
			buying_group_desc


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
            revenue_group_desc,
            film_campaign.campaign_no,
            film_campaign.product_desc,
			client_name,
			agency_name,
			agency_group_name,
			buying_group_desc
from	    statrev_cinema_normal_transaction,
            statrev_revenue_group,
            statrev_revenue_master_group,
            statrev_transaction_type,
            film_campaign,
            branch,
            statrev_campaign_revision,
			statrev_revision_rep_xref,
			agency,
			client,
			agency_groups,
			agency_buying_groups
WHERE	    statrev_cinema_normal_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and			film_campaign.client_id = client.client_id
and			film_campaign.reporting_agency = agency.agency_id
and			agency.agency_group_id = agency_groups.agency_group_id
and			agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and         revenue_period >= @period_start
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
            revenue_group_desc,
            film_campaign.campaign_no,
            film_campaign.product_desc,
			client_name,
			agency_name,
			agency_group_name,
			buying_group_desc

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
            revenue_group_desc,
            film_campaign.campaign_no,
            film_campaign.product_desc,
			client_name,
			agency_name,
			agency_group_name,
			buying_group_desc
from	    statrev_cinema_deferred_transaction,
            statrev_revenue_group,
            statrev_revenue_master_group,
            statrev_transaction_type,
            film_campaign,
            branch,
            statrev_campaign_revision,
			statrev_revision_rep_xref,
			agency,
			client,
			agency_groups,
			agency_buying_groups
WHERE	    statrev_cinema_deferred_transaction.transaction_type = statrev_transaction_type.statrev_transaction_type
and	        statrev_transaction_type.revenue_group = statrev_revenue_group.revenue_group
and	        statrev_revenue_group.master_revenue_group = statrev_revenue_master_group.master_revenue_group
and         statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and         statrev_campaign_revision.revision_id = statrev_cinema_deferred_transaction.revision_id
and         film_campaign.branch_code = branch.branch_code
and			film_campaign.client_id = client.client_id
and			film_campaign.reporting_agency = agency.agency_id
and			agency.agency_group_id = agency_groups.agency_group_id
and			agency_groups.buying_group_id = agency_buying_groups.buying_group_id
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
            revenue_group_desc,
            film_campaign.campaign_no,
            film_campaign.product_desc,
			client_name,
			agency_name,
			agency_group_name,
			buying_group_desc

-- Insert Groups/Line headers such group desc, font, format..etc
INSERT INTO #HEADERS VALUES ( 'Revenue', 10, 'Revenue', 10, 'Actual', 1, 'Current', 700, 1)

-- Insert Total Actual Revenue
INSERT into #OUTPUT(group_no, row_no, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, deferred, future,
	period01_start, period01_end, period02_start, period02_end, period03_start, period03_end, period04_start, period04_end, period05_start, period05_end, period06_start, period06_end,
	period07_start, period07_end, period08_start, period08_end, period09_start, period09_end, period10_start, period10_end, period11_start, period11_end, period12_start, period12_end,
	row_start_date, row_end_date, 
	row_report_date, row_delta_date,
	row_rev_grp, row_mast_rev_grp, row_bus_unit_id,	row_country_code, row_branch_code, campaign_no, product_desc, client_name, agency_name, agency_group_name, buying_group_desc)
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
	@revenue_group,	@master_revenue_group, @business_unit_id, '', '', campaign_no, product_desc, client_name, agency_name, agency_group_name, buying_group_desc
FROM	#revenue_data
WHERE	( report_date = @report_date )
and		( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and		( revenue_group = @revenue_group or @revenue_group = 0)
and		( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
group by campaign_no, product_desc, client_name, agency_name, agency_group_name, buying_group_desc

--select * from #revenue_data

-- Output Data
SELECT	campaign_no, product_desc, client_name, agency_name, agency_group_name, buying_group_desc, 
	revenue1, revenue2, revenue3, revenue4, revenue5, revenue6, revenue7, revenue8, revenue9, revenue10, revenue11, revenue12,
	statutory, 
	deferred,
	CASE When o.group_no IN (20, 30, 40) and o.row_no IN (60, 90, 120) Then statdefpcnt Else statdef END AS statdeftotal, 
	future,
	period01_end,  period02_end,  period03_end,  period04_end,  period05_end,  period06_end,
	period07_end,  period08_end,  period09_end,  period10_end,  period11_end,  period12_end,
	row_start_date, row_end_date, row_report_date, row_delta_date
FROM	#OUTPUT o, #HEADERS h
WHERE	(revenue1 + revenue2 + revenue3 + revenue4 + revenue5 + revenue6 + revenue7 + revenue8 + revenue9 +  revenue10 + revenue11 + revenue12 +statutory + deferred) <> 0
ORDER BY campaign_no
return 0
GO
