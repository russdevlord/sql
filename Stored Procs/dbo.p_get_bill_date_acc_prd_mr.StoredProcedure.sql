/****** Object:  StoredProcedure [dbo].[p_get_bill_date_acc_prd_mr]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_get_bill_date_acc_prd_mr]
GO
/****** Object:  StoredProcedure [dbo].[p_get_bill_date_acc_prd_mr]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create  PROC [dbo].[p_get_bill_date_acc_prd_mr]    @billing_date	datetime,
                                       @acc_prd1        datetime OUTPUT,
                                       @days1           int OUTPUT,
                                       @acc_prd2        datetime  OUTPUT,
                                       @days2           int OUTPUT
as

--set nocount on 

declare @benchmark_prd_end datetime,
        @benchmark_prd_start datetime,
        @acc_prd1_start  datetime,
        @acc_prd2_start  datetime,
        @billing_week_end   datetime

select @billing_week_end = dateadd(day, 6, @billing_date)     

--slide screening dates go far beyond existing acc periods ...?! 
if not exists(select 1 
          from accounting_period_calendar
          where @billing_week_end <= benchmark_end)   
          begin
            select @days1 = 0
            select @days2 = 0
            return 0
          end

select @acc_prd1 = benchmark_end,
       @acc_prd1_start = benchmark_start,
       @benchmark_prd_start = (case when period_no = 1 then convert(varchar, datepart(year, finyear_end) ) + '-1-1' 
                                    when period_no = 7 then convert(varchar, datepart(year, finyear_end) - 1) + '-7-1' 
                                    else benchmark_start end),
       @benchmark_prd_end = (case when period_no = 12 then convert(varchar, datepart(year, finyear_end) - 1) + '-12-31' 
                                  when period_no = 6  then convert(varchar, datepart(year, finyear_end) ) + '-6-30' 
                                  else benchmark_end end) 
from accounting_period_calendar
where  @billing_date between 
        (case when period_no = 1 then convert(varchar, datepart(year, finyear_end) ) + '-1-1' 
              when period_no = 7 then convert(varchar, datepart(year, finyear_end) - 1) + '-7-1' 
              else benchmark_start end)
  and  (case when period_no = 12 then convert(varchar, datepart(year, finyear_end) - 1) + '-12-31' 
             when period_no = 6  then convert(varchar, datepart(year, finyear_end) ) + '-6-30' 
             else benchmark_end end) 

/* screening week falls in one acc period */
if @billing_week_end >= @benchmark_prd_start and @billing_week_end <= @benchmark_prd_end and
   @billing_date >= @benchmark_prd_start and @billing_date <= @benchmark_prd_end 
   begin
    select @days1 = 7
    select @days2 = 0
    return 0
   end

/* screening week spreads over two acc periods */   
if @billing_date < @benchmark_prd_start
   begin
        select @days2 = datediff(day, @billing_date, @benchmark_prd_start) + 1
        select @days1 = 7 - @days2
        select @acc_prd2 = max(benchmark_end)
            from accounting_period_calendar
            where benchmark_end < @acc_prd1
        return 0
   end
else
    begin
        select @days1 = datediff(day, @billing_date, @benchmark_prd_end) + 1
        select @days2 = 7 - @days1
        select @acc_prd2 = min(benchmark_end)
            from accounting_period_calendar
            where benchmark_end > @acc_prd1
        return 0
    end
    
   
return 0
GO
