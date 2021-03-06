/****** Object:  UserDefinedFunction [dbo].[f_prev_attendance_screening_date]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_prev_attendance_screening_date]
GO
/****** Object:  UserDefinedFunction [dbo].[f_prev_attendance_screening_date]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO




CREATE FUNCTION [dbo].[f_prev_attendance_screening_date] (@screening_date datetime)
RETURNS datetime
AS
BEGIN
   DECLARE  @period_no          int,
            @previous_date				datetime
            
        select	@period_no = period_no
        from		film_screening_dates
        where   screening_date = @screening_date

			/*select  @previous_date = max(screening_date)
			from    v_movie_history_dates 
			where   screening_date < @screening_date
			and     attendance_period_no = @period_no        
			and		attendance > 0*/
			
			select  @previous_date = max(screening_date)
			from    film_screening_dates 
			where   screening_date < @screening_date
			and     attendance_period_no = @period_no        
        
        /*select	@period_no = attendance_period_no,
						@attendance = 0
        from		film_screening_dates
        where   screening_date = @screening_date*/
        
--		while (@attendance = 0)
--		begin
			/*select  @previous_date = max(screening_date)
			from    film_screening_dates 
			where   screening_date < @screening_date
			and     attendance_period_no = @period_no*/
			
--			select @screening_date = @previous_date

--			select @attendance = count(*)
--			from cinetam_movie_history
--			where screening_date = @screening_date
--		end
	
   return(@previous_date)   
   
   error:
        return(@screening_date)
   
END





GO
