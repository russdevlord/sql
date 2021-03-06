/****** Object:  StoredProcedure [dbo].[p_projected_billing_gen_daily_hoyts]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_projected_billing_gen_daily_hoyts]
GO
/****** Object:  StoredProcedure [dbo].[p_projected_billing_gen_daily_hoyts]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * p_projected_billing_gen_daily_hoyts
 * --------------------------
 * This procedure calls p_projected_billing_gen_daily_hoyts automatically every day
 *
 * Created/Modified
 * GC, 14/4/2002, Created.
 * GC, 6/5/2003, modified to data-warehouse type function
 */

CREATE PROC [dbo].[p_projected_billing_gen_daily_hoyts]
with recompile
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

select  @billing_period = min(aph.benchmark_end)
from    accounting_period ap, accounting_period_hoyts aph
where   ap.status = 'O'
and		ap.finyear_end =  aph.finyear_end
and		ap.period_no =  aph.period_no

-- select  @billing_period = min(benchmark_end)
-- from    accounting_period
-- where   status = 'O'

select  @report_date = convert(datetime, convert(varchar(4),datepart(yy,getdate())) + '-' + convert(varchar(2),datepart(mm,getdate())) + '-' + convert(varchar(2),datepart(dd,getdate()))),
        @return_code = 0

select  @current_finyear = finyear_end,
        @period_no = period_no
from    accounting_period_hoyts
where   benchmark_end = @billing_period

select  @next_year_period = benchmark_end
from    accounting_period_hoyts
where   finyear_end = dateadd(yy,1,@current_finyear)
and     period_no = @period_no

/* generate current financial year */
exec @error =  p_projected_billing_gen_all_hoyts @billing_period,
                                   @report_date
if @error <> 0 select @return_code = -100

/* generate next financial year */
exec @error =  p_projected_billing_gen_all_hoyts @next_year_period,
                                   @report_date
if @error <> 0 select @return_code = -100

/* generate previous financial year if in July */
if @period_no = 7
begin
    select  @next_year_period = benchmark_end
    from    accounting_period_hoyts
    where   finyear_end = dateadd(yy,-1,@current_finyear)
    and     period_no = @period_no

    exec @error =  p_projected_billing_gen_all_hoyts @next_year_period,
                                       @report_date
    if @error <> 0 select @return_code = -100
end


/******* TEMP - run this from here until Batch processor developed *******/
--exec @error = p_dw_refresh_proj_bill_wtd
--if @error <> 0 select @return_code = -100

/****Projected billings reforcast, writes result into projected_billings_calendar***/
/****should be de run until accounting periods will be in tune with calendar monthes***/
--exec sp_proj_bill_by_cal_mnth_step1
/* do not care about the return code */
--exec sp_proj_bill_by_cal_mnth_step2

SET NOCOUNT OFF 
return @return_code
GO
