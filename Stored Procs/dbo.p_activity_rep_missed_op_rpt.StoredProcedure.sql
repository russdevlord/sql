/****** Object:  StoredProcedure [dbo].[p_activity_rep_missed_op_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_activity_rep_missed_op_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_activity_rep_missed_op_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_activity_rep_missed_op_rpt]  @activity_type  char(1),
                                        @branch_code    char(2),
                                        @start_date        datetime,
                                        @end_date       datetime,
                                        @rep_id         integer
as

declare @error          		integer,
        @target_calls_wk        integer,
        @target_appts_wk        integer,
        @target_pres_wk         integer,
        @target_sales_wk        integer,
        @target_avo             money,
        @finyear                datetime

/* must presume that end date is within required finyear for the purpose of getting targets */
select  @finyear = finyear_end
from    sales_period
where   sales_period_start <= @end_date
and     sales_period_end >= @end_date


select  @target_calls_wk = value
from    activity_benchmarks
where   benchmark_type = 1
and     branch_code = @branch_code
and     finyear_end = @finyear

select  @target_appts_wk = value
from    activity_benchmarks
where   benchmark_type = 2
and     branch_code = @branch_code
and     finyear_end = @finyear

select  @target_pres_wk = value
from    activity_benchmarks
where   benchmark_type = 3
and     branch_code = @branch_code
and     finyear_end = @finyear

select  @target_sales_wk = value
from    activity_benchmarks
where   benchmark_type = 4
and     branch_code = @branch_code
and     finyear_end = @finyear

select  @target_avo = value
from    activity_benchmarks
where   benchmark_type = 5
and     branch_code = @branch_code
and     finyear_end = @finyear

select  ars.week_ending              'week_ending',
        sum(ars.calls_phone)          'calls_phone'   ,
        sum(ars.calls_face)            'calls_face'  ,
        sum(ars.appts_phone)           'appts_phone'  ,
        sum(ars.appts_face)            'appts_face'  ,
        sum(ars.presentations_kept_phone) 'presentations_kept_phone'     ,
        sum(ars.presentations_kept_face)  'presentations_kept_face'    ,
        sum(ars.presentations_cancelled) 'presentations_cancelled',
        sum(ars.sales_qty)               'sales_qty',
        sum(ars.sales_value)             'sales_value',
        sum(ars.future_appts_phone)      'future_appts_phone',
        sum(ars.future_appts_face)       'future_appts_face',
        sum(ars.poster_deliveries)       'poster_deliveries',
        sum(ars.artwork_approvals)       'artwork_approvals',
        sum(ars.servicing_calls_phone)   'servicing_calls_phone',
        sum(ars.servicing_calls_face)    'servicing_calls_face',
        @target_calls_wk                 'target_calls_wk',
        @target_appts_wk                 'target_appts_wk',
        @target_pres_wk                  'target_pres_wk',
        @target_sales_wk                 'target_sales_wk',
        @target_avo                      'target_avo',
        datediff(wk,@start_date,@end_date)          'num_weeks'
from    activity_rep_daily_summary ars
where   ars.rep_id = @rep_id
and     ars.activity_date >= @start_date
and     ars.activity_date <= @end_date
group by ars.week_ending

return 0
GO
