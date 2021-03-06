/****** Object:  StoredProcedure [dbo].[p_workingdays]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_workingdays]
GO
/****** Object:  StoredProcedure [dbo].[p_workingdays]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_workingdays]	  @start_date      datetime,
									  @end_date        datetime,
									  @workingdays	    integer	OUTPUT
as
set nocount on 
/*
 * Declare Variables
 */

declare  @weeks					integer,
			@start_week				integer,
			@end_week				integer,
			@start_dow				integer,
			@end_dow					integer

/*
 * Calculate Working Days
 */

select @workingdays = null

if @end_date >= @start_date
begin
	select @start_week = datepart(wk,@start_date)
	select @end_week = @start_week + datediff(wk,@start_date,@end_date)
	select @start_dow = datepart(dw,@start_date)
	select @end_dow = datepart(dw,@end_date)
	
	--Add 5 days for each total week spanned.
	select @weeks = ((@end_week - 1) - (@start_week + 1) + 1)
	
	if @weeks > 0
		select @workingdays = @weeks * 5
	else
		select @workingdays = 0
	
	-- Set Start to Monday, if Sunday
	if @start_dow = 1
		select @start_dow = 2
	
	-- Set Start to Friday, if Saturday
	if @end_dow = 7
		select @end_dow = 6
	
	if @weeks >= 0
	begin
		--Add weekdays in the start week
		select @workingdays = @workingdays + ( 7 - @start_dow )
		
		--Add weekdays in the end week
		select @workingdays = @workingdays + ( @end_dow - 1 )
	end
	else
	begin
		select @workingdays = ( @end_dow - @start_dow ) + 1
	end
end

/*
 * Return Success
 */

return 0
GO
