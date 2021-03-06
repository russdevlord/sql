/****** Object:  StoredProcedure [dbo].[p_insert_revenue_calendar_mth]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_insert_revenue_calendar_mth]
GO
/****** Object:  StoredProcedure [dbo].[p_insert_revenue_calendar_mth]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_insert_revenue_calendar_mth]       @benchmark_end             datetime

as

declare     @error                      int,
            @period                     int,
            @year                       int,
            @calendar                   char(3),
            @reporting_year             int,
			@leading_period				char(2),
			@sql						nvarchar(1000),
			@parms						nvarchar(1000)
            
        
/* 
 * These are the types of calendar we have to create            
 *            
 * CY 	    Calendar
 * AY 	    Financial
 * AY3	    Financial Jul-Dec
 * AY4	    Financial Jan-Jun
 * CY3	    Calendar Jan-Jun
 * CY4	    Calendar Jul-Dec
 *
 */

set nocount on

begin transaction
 
delete revenue_calendar_month where benchmark_end = @benchmark_end 

select @error = @@error
if @error <> 0
begin
    raiserror ('Error deleting old revenue calendar month records', 16, 1)
    rollback transaction
    return -1
end

insert into revenue_calendar_month
    (benchmark_end,
    calendar,
    reporting_year,
    reporting_column,
    month_name,
    period_01,
    period_02,
    period_03,
    period_04,
    period_05,
    period_06,
    period_07,
    period_08,
    period_09,
    period_10,
    period_11,
    period_12)
select  benchmark_end,
        calendar,
        year(dateadd(yy, +1, benchmark_end)),
        month(benchmark_end),
        convert(char(2), datepart(dd, benchmark_end)) + '-' + convert(char(3), datename(mm, benchmark_end)) + '-' + convert(char(4), datepart(yy, benchmark_end)),
        0,
        0,
        0,
        0,
        0,
        0,                    
        0,
        0,
        0,
        0,
        0,
        0
from    accounting_period,
        revenue_calendar_year
where   accounting_period.benchmark_end = @benchmark_end
and     calendar not in ('CY1','CY2','AY1','AY2','CY','CY3','CY4')
and		month(benchmark_end) > 6
union
select  benchmark_end,
        calendar,
        year(benchmark_end),
        month(benchmark_end),
        convert(char(2), datepart(dd, benchmark_end)) + '-' + convert(char(3), datename(mm, benchmark_end)) + '-' + convert(char(4), datepart(yy, benchmark_end)),
        0,
        0,
        0,
        0,
        0,
        0,                    
        0,
        0,
        0,
        0,
        0,
        0
from    accounting_period,
        revenue_calendar_year
where   accounting_period.benchmark_end = @benchmark_end
and     calendar not in ('CY1','CY2','AY1','AY2','AY','AY3','AY4')
union
select  benchmark_end,
        calendar,
        year(benchmark_end),
        month(benchmark_end),
        convert(char(2), datepart(dd, benchmark_end)) + '-' + convert(char(3), datename(mm, benchmark_end)) + '-' + convert(char(4), datepart(yy, benchmark_end)),
        0,
        0,
        0,
        0,
        0,
        0,                    
        0,
        0,
        0,
        0,
        0,
        0
from    accounting_period,
        revenue_calendar_year
where   accounting_period.benchmark_end = @benchmark_end
and     calendar not in ('CY1','CY2','AY1','AY2','CY','CY3','CY4')
and		month(benchmark_end) < 7

declare rev_week_csr cursor static forward_only for
select  benchmark_end,
        calendar,
        reporting_year
from    revenue_calendar_month
where   benchmark_end = @benchmark_end
order by benchmark_end,
        calendar,
        reporting_year
for     read only

open rev_week_csr
fetch rev_week_csr into @benchmark_end, @calendar, @reporting_year
while(@@fetch_status=0)
begin

    if left(@calendar, 2) = 'AY'
    begin
        select  @period = month(dateadd(mm, 6, @benchmark_end))
        select  @year   = year(dateadd(mm, 6, @benchmark_end))
	end
    else
	begin
        select  @period = month(@benchmark_end)
        select  @year   = year(@benchmark_end)   
    end
  
	if @period > 9 
	begin
		select @leading_period = convert(char(2), @period)
	end
	else
	begin
		select @leading_period = '0' + convert(char(2), @period)
	end

    if @calendar = 'CY' or @calendar = 'AY'
    begin
        if @reporting_year = @year
		begin
			select @sql = 	'update   revenue_calendar_month set period_' + 
							 + @leading_period +
							' = 1 where    benchmark_end = ' + quotename(convert(varchar(15), @benchmark_end,106), '''') + 
							' and      reporting_year = ' + convert(varchar(15), @reporting_year,105) + 
							' and calendar = ' + quotename(@calendar, '''')
			exec(@sql)
		end
    end

    if @calendar = 'CY3' or @calendar = 'AY3'
    begin
        if @reporting_year = @year
		begin
			if @period < 7
			begin
				select @sql = 	'update   revenue_calendar_month set period_' + 
								 + @leading_period +
								' = 1, period_07 = 1 where    benchmark_end = ' + quotename(convert(varchar(15), @benchmark_end,106), '''') + 
								' and      reporting_year = ' + convert(varchar(15), @reporting_year,105) + 
								' and calendar = ' + quotename(@calendar, '''')
				exec(@sql)
			end
		end
    end

    if @calendar = 'CY4' or @calendar = 'AY4'
    begin
        if @reporting_year = @year
		begin
			if @period > 6
			begin
				select @period = @period - 6
				select @leading_period = '0' + convert(char(2), @period)
				select @sql = 	'update   revenue_calendar_month set period_' + 
								 + @leading_period +
								' = 1 , period_07 = 1 where    benchmark_end = ' + quotename(convert(varchar(15), @benchmark_end,106), '''') + 
								' and      reporting_year = ' + convert(varchar(15), @reporting_year,105) + 
								' and calendar = ' + quotename(@calendar, '''')
				exec(@sql)
			end
		end
    end



    fetch rev_week_csr into @benchmark_end, @calendar, @reporting_year
end

commit transaction
return 0
GO
