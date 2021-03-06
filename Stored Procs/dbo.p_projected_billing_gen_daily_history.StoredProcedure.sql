/****** Object:  StoredProcedure [dbo].[p_projected_billing_gen_daily_history]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_projected_billing_gen_daily_history]
GO
/****** Object:  StoredProcedure [dbo].[p_projected_billing_gen_daily_history]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * p_projected_billing_gen_daily_history
 * --------------------------
 * This procedure calls p_projected_billing_gen_daily_history automatically every day
 *
 * Created/Modified
 * GC, 14/4/2002, Created.
 * GC, 6/5/2003, modified to data-warehouse type function
 */

CREATE PROC [dbo].[p_projected_billing_gen_daily_history]
--with recompile
as

/* Declare Variables */
declare     @error                 int,
            @billing_period     datetime,
            @report_date        datetime,
            @current_finyear    datetime,
            @period_no          tinyint,
            @next_year_period   datetime,
            @return_code        int


SET NOCOUNT ON 

select  @billing_period = min(benchmark_end_dec04)
from    accounting_period, benchmark_period_history
where   accounting_period.status = 'O'
and		accounting_period.finyear_end =  benchmark_period_history.finyear_end
and		accounting_period.period_no =  benchmark_period_history.period_no

select  @report_date = convert(datetime, convert(varchar(4),datepart(yy,getdate())) + '-' + convert(varchar(2),datepart(mm,getdate())) + '-' + convert(varchar(2),datepart(dd,getdate()))),
        @return_code = 0

select  @current_finyear = accounting_period.finyear_end,
        @period_no = accounting_period.period_no
from    accounting_period, benchmark_period_history
where   benchmark_period_history.benchmark_end_dec04 = @billing_period
and		benchmark_period_history.period_no = accounting_period.period_no
and		benchmark_period_history.finyear_end = accounting_period.finyear_end


select  @next_year_period = benchmark_end_dec04
from    benchmark_period_history
where   finyear_end = dateadd(yy,1,@current_finyear)
and     period_no = @period_no

/* generate current financial year */
exec @error =  p_projected_billing_gen_all_history @billing_period,
                                   @report_date
if @error <> 0 select @return_code = -100

/* generate next financial year */
exec @error =  p_projected_billing_gen_all_history @next_year_period,
                                   @report_date
if @error <> 0 select @return_code = -100

/* generate previous financial year if in July */
if @period_no = 7
begin
    select  @next_year_period = benchmark_end_dec04
    from    benchmark_period_history
    where   finyear_end = dateadd(yy,-1,@current_finyear)
    and     period_no = @period_no

    exec @error =  p_projected_billing_gen_all_history @next_year_period,
                                       @report_date
    if @error <> 0 select @return_code = -100
end


/******* TEMP - run this from here until Batch processor developed *******/
--exec @error = p_dw_refresh_proj_bill_wtd
--if @error <> 0 select @return_code = -100


SET NOCOUNT OFF 
return @return_code
GO
