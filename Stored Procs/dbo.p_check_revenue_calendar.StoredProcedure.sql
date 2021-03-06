/****** Object:  StoredProcedure [dbo].[p_check_revenue_calendar]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_check_revenue_calendar]
GO
/****** Object:  StoredProcedure [dbo].[p_check_revenue_calendar]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_check_revenue_calendar]  

as

declare     @error                      int,
            @period                     int,
            @year                       int,
            @benchmark_end              datetime,
            @calendar                   char(3),
            @reporting_year             int,
			@leading_period				char(2),
			@sql						nvarchar(1000),
			@parms						nvarchar(1000),
			@screening_date             datetime            
        
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

create table  #results
(
	screening_date		datetime		null,
	benchmark_end		datetime		null,
    calendar			char(3)			null,
    reporting_year		int				null
)


declare 	rev_week_csr cursor static forward_only for
select  	screening_date,
			benchmark_end,
	        calendar,
	        reporting_year
from   		revenue_calendar_week
order by 	screening_date,
			benchmark_end,
	        calendar,
	        reporting_year
for     	read only

open rev_week_csr
fetch rev_week_csr into @screening_date, @benchmark_end, @calendar, @reporting_year
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
			select @sql = 	'insert into #results
				            select 	screening_date,
									benchmark_end,
									calendar,
									reporting_year	
							from	revenue_calendar_week' + 
							' where    screening_date = ' + quotename(convert(varchar(15), @screening_date,106), '''') + 
							' and      reporting_year = ' + convert(varchar(15), @reporting_year,105) + 
							' and calendar = ' + quotename(@calendar, '''') +
							' and 	period_' + @leading_period + ' = 0'

			exec(@sql)
		end
		else if @reporting_year < @year
		begin
			insert into #results
            select 	screening_date,
					benchmark_end,
					calendar,
					reporting_year	
			from	revenue_calendar_week
            where    screening_date = @screening_date             
            and      reporting_year = @reporting_year
			and		 calendar = @calendar
			and		 period_future = 0
		end
		
    end

    if @calendar = 'CY3' or @calendar = 'AY3'
    begin
        if @reporting_year = @year
		begin
			if @period > 6
			begin
				insert into #results
	            select 	screening_date,
						benchmark_end,
						calendar,
						reporting_year	
				from	revenue_calendar_week
	            where    screening_date = @screening_date             
	            and      reporting_year = @reporting_year
				and		 calendar = @calendar
				and		 period_future = 0
			end
			else
			begin
			select @sql = 	'insert into #results
				            select 	screening_date,
									benchmark_end,
									calendar,
									reporting_year	
							from	revenue_calendar_week' + 
							' where    screening_date = ' + quotename(convert(varchar(15), @screening_date,106), '''') + 
							' and      reporting_year = ' + convert(varchar(15), @reporting_year,105) + 
							' and calendar = ' + quotename(@calendar, '''') +
							' and 	(period_' + @leading_period + ' = 0' +
							' or period_07 = 0)'

				exec(@sql)
			end
		end
		else if @reporting_year < @year
		begin
			insert into #results
            select 	screening_date,
					benchmark_end,
					calendar,
					reporting_year	
			from	revenue_calendar_week
            where    screening_date = @screening_date             
            and      reporting_year = @reporting_year
			and		 calendar = @calendar
			and		 period_future = 0
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
				select @sql = 	'insert into #results
					            select 	screening_date,
										benchmark_end,
										calendar,
										reporting_year	
								from	revenue_calendar_week' + 
								' where    screening_date = ' + quotename(convert(varchar(15), @screening_date,106), '''') + 
								' and      reporting_year = ' + convert(varchar(15), @reporting_year,105) + 
								' and calendar = ' + quotename(@calendar, '''') +
								' and 	(period_' + @leading_period + ' = 0' +
								' or period_07 = 0)'
				exec(@sql)
			end
		end
		else if @reporting_year < @year
		begin
			insert into #results
            select 	screening_date,
					benchmark_end,
					calendar,
					reporting_year	
			from	revenue_calendar_week
            where    screening_date = @screening_date             
            and      reporting_year = @reporting_year
			and		 calendar = @calendar
			and		 period_future = 0
		end
    end

    fetch rev_week_csr into @screening_date, @benchmark_end, @calendar, @reporting_year
end

select * from #results

return 0
GO
