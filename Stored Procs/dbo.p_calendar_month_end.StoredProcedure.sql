USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_calendar_month_end]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_calendar_month_end]	@source_date      datetime,
									  		@end_date        	datetime  OUTPUT
as

/*
 * Declare Variables
 */

declare  @month					integer,
			@year						integer,
         @first_day				datetime,
         @last_day				datetime

/*
 * Get Date Parts
 */

select @month = datepart(month,@source_date)
select @year = datepart(year,@source_date)

select @month = @month + 1
if(@month > 12)
	select @month = 1,
          @year = @year + 1

select @first_day = convert(datetime, convert(char(4),@year) + '/' + convert(char(2),@month) + '/01')
select @last_day = dateadd(dd,-1,@first_day)

select @end_date = @last_day

/*
 * Return Success
 */

return 0
GO
