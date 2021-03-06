/****** Object:  StoredProcedure [dbo].[p_op_insert_revenue_calendar]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_insert_revenue_calendar]
GO
/****** Object:  StoredProcedure [dbo].[p_op_insert_revenue_calendar]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_op_insert_revenue_calendar]       @screening_date             datetime

as

declare     @error                      int,
            @period                     int,
            @year                       int,
            @benchmark_end              datetime,
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
 * CY3	    Calendar Jan-Jun
 * AY4	    Financial Jan-Jun
 * CY4	    Calendar Jul-Dec
 *
 */

set nocount on

begin transaction
 
delete outpost_revenue_calendar_week where screening_date = @screening_date 

select @error = @@error
if @error <> 0
begin
    raiserror ('Error deleting old revenue calendar week records', 16, 1)
    rollback transaction
    return -1
end
 
insert into outpost_revenue_calendar_week
    (screening_date,
    benchmark_end,
    calendar,
    reporting_year,
    reporting_month,
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
    period_12,
    period_future)
select  screening_date,
        benchmark_end,
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
        0,
        0
from    outpost_screening_date_xref,
        revenue_calendar_year
where   outpost_screening_date_xref.screening_date = @screening_date
and     calendar not in ('CY1','CY2','AY1','AY2')
union
select  screening_date,
        benchmark_end,
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
        0,
        0
from    outpost_screening_date_xref,
        revenue_calendar_year
where   outpost_screening_date_xref.screening_date = @screening_date
and     calendar not in ('CY1','CY2','AY1','AY2')
union
select  screening_date,
        benchmark_end,
        calendar,
        year(dateadd(yy, -1, benchmark_end)),
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
        0,
        0
from    outpost_screening_date_xref,
        revenue_calendar_year
where   outpost_screening_date_xref.screening_date = @screening_date
and     calendar not in ('CY1','CY2','AY1','AY2')
union
select  screening_date,
        benchmark_end,
        calendar,
        year(dateadd(yy, -2, benchmark_end)),
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
        0,
        0
from    outpost_screening_date_xref,
        revenue_calendar_year
where   outpost_screening_date_xref.screening_date = @screening_date
and     calendar not in ('CY1','CY2','AY1','AY2')


declare rev_week_csr cursor static forward_only for
select  benchmark_end,
        calendar,
        reporting_year
from    outpost_revenue_calendar_week
where   screening_date = @screening_date
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
			select @sql = 	'update   outpost_revenue_calendar_week set period_' + 
							 + @leading_period +
							' = 1 where    screening_date = ' + quotename(convert(varchar(15), @screening_date,106), '''') + 
							' and      reporting_year = ' + convert(varchar(15), @reporting_year,105) + 
							' and calendar = ' + quotename(@calendar, '''')
			exec(@sql)
		end
		else if @reporting_year < @year
		begin
            update   outpost_revenue_calendar_week
            set      period_future = 1
            where    screening_date = @screening_date             
            and      reporting_year = @reporting_year
			and		 calendar = @calendar
		end
		
    end

    if @calendar = 'CY3' or @calendar = 'AY3'
    begin
        if @reporting_year = @year
		begin
			if @period > 6
			begin
	            update   outpost_revenue_calendar_week
	            set      period_future = 1
	            where    screening_date = @screening_date             
	            and      reporting_year = @reporting_year
				and		 calendar = @calendar
			end
			else
			begin
				select @sql = 	'update   outpost_revenue_calendar_week set period_' + 
								 + @leading_period +
								' = 1, period_07 = 1 where    screening_date = ' + quotename(convert(varchar(15), @screening_date,106), '''') + 
								' and      reporting_year = ' + convert(varchar(15), @reporting_year,105) + 
								' and calendar = ' + quotename(@calendar, '''')
				exec(@sql)
			end
		end
		else if @reporting_year < @year
		begin
            update   outpost_revenue_calendar_week
            set      period_future = 1
            where    screening_date = @screening_date             
            and      reporting_year = @reporting_year
			and		 calendar = @calendar
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
				select @sql = 	'update   outpost_revenue_calendar_week set period_' + 
								 + @leading_period +
								' = 1 , period_07 = 1 where    screening_date = ' + quotename(convert(varchar(15), @screening_date,106), '''') + 
								' and      reporting_year = ' + convert(varchar(15), @reporting_year,105) + 
								' and calendar = ' + quotename(@calendar, '''')
				exec(@sql)
			end
		end
		else if @reporting_year < @year
		begin
            update   outpost_revenue_calendar_week
            set      period_future = 1
            where    screening_date = @screening_date             
            and      reporting_year = @reporting_year
			and		 calendar = @calendar
		end
    end

/*    if @calendar = 'AY'
    begin
        if @reporting_year = @year
		begin
			select @sql = 	'update   outpost_revenue_calendar_week set period_' + 
							 + @leading_period +
							' = 1 where    screening_date = ' + quotename(convert(varchar(15), @screening_date,106), '''') + 
							' and      reporting_year = ' + convert(varchar(15), @reporting_year,105) + 
							' and calendar = ' + quotename(@calendar, '''')
			exec(@sql)
		end
		else
		begin
            update   outpost_revenue_calendar_week
            set      period_future = 1
            where    screening_date = @screening_date             
            and      reporting_year = @reporting_year
			and		 calendar = @calendar
		end
    end

    if @calendar = 'AY3'
    begin
        if @reporting_year = @year
		begin
			select @sql = 	'update   outpost_revenue_calendar_week set period_' + 
							 + @leading_period +
							' = 1 where    screening_date = ' + quotename(convert(varchar(15), @screening_date,106), '''') + 
							' and      reporting_year = ' + convert(varchar(15), @reporting_year,105) + 
							' and calendar = ' + quotename(@calendar, '''')
			exec(@sql)
		end
		else
		begin
            update   outpost_revenue_calendar_week
            set      period_future = 1
            where    screening_date = @screening_date             
            and      reporting_year = @reporting_year
			and		 calendar = @calendar
		end
    end

    if @calendar = 'AY4'
    begin
        if @reporting_year = @year
		begin
			select @sql = 	'update   outpost_revenue_calendar_week set period_' + 
							 + @leading_period +
							' = 1 where    screening_date = ' + quotename(convert(varchar(15), @screening_date,106), '''') + 
							' and      reporting_year = ' + convert(varchar(15), @reporting_year,105) + 
							' and calendar = ' + quotename(@calendar, '''')
			exec(@sql)
		end
		else
		begin
            update   outpost_revenue_calendar_week
            set      period_future = 1
            where    screening_date = @screening_date             
            and      reporting_year = @reporting_year
			and		 calendar = @calendar
		end
    end
*/

    fetch rev_week_csr into @benchmark_end, @calendar, @reporting_year
end

commit transaction
return 0
GO
