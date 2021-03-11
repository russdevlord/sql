USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_get_workingday]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_get_workingday]	  @start_date           datetime,
				  @end_date             datetime OUTPUT,
				  @workingdays	        int
as
set nocount on 
                             

declare @weeks					int,
		@start_week				int,
		@end_week				int,
		@start_dow				int,
		@end_dow				int,
        @temp_workingdays       int

                                  

select @end_date = dateadd(wk, @workingdays / 5, @start_date)
select @temp_workingdays = 0

while @temp_workingdays != @workingdays
begin
    execute p_workingdays @start_date, @end_date, @temp_workingdays OUTPUT
    
    if @workingdays < @temp_workingdays
    begin
        select @end_date = dateadd(dd, @workingdays - @temp_workingdays, @end_date)
    end
    else if @workingdays > @temp_workingdays
    begin
        select @end_date = dateadd(dd, (@temp_workingdays - @workingdays) * -1, @end_date)
    end
  
    
end

                          

return 0
GO
