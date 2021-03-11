USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[f_next_attendance_screening_date]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO



CREATE FUNCTION [dbo].[f_next_attendance_screening_date] (@screening_date datetime)
RETURNS datetime
AS
BEGIN
   DECLARE  @period_no          int,
            @next_date      datetime
            
        select  @period_no = attendance_period_no
        from    film_screening_dates
        where   screening_date = @screening_date
            
        select  @next_date = min(screening_date)
        from    film_screening_dates 
        where   screening_date > @screening_date
        and     attendance_period_no = @period_no

		if @screening_Date =  '23-jun-2016'
			select @next_Date = '22-jun-2017'

   return(@next_date)   
   
   error:
        return(@screening_date)
   
END



GO
