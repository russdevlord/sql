/****** Object:  StoredProcedure [dbo].[p_weekdays]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_weekdays]
GO
/****** Object:  StoredProcedure [dbo].[p_weekdays]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_weekdays]		  @start_date   datetime,
									  @end_date     datetime,
									  @weekdays	    integer	OUTPUT
as
set nocount on 
declare  @weeks					integer,
			@start_week				integer,
			@end_week				integer,
			@start_dow				integer,
			@end_dow					integer


select @start_week = datepart(wk,@start_date)
select @end_week = @start_week + datediff(wk,@start_date,@end_date)
select @start_dow =  datepart(dw,@start_date)
select @end_dow = datepart(dw,@end_date)

--Add 5 days for each total week spanned.
select @weeks = ((@end_week - 1) - (@start_week + 1) + 1)

if @weeks > 0
	select @weekdays = @weeks * 5
else
	select @weekdays = 0


--Add weekdays in the start week
select @weekdays = @weekdays + ( 7 - @start_dow )

--Add weekdays in the end week
select @weekdays = @weekdays + ( @end_dow - 1 )

select @weekdays

return 0
GO
