USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[f_prev_benchmark]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


/**/



CREATE FUNCTION [dbo].[f_prev_benchmark] (@benchmark_end datetime)
RETURNS datetime
AS
BEGIN
   DECLARE  @previous_date				datetime
        
	select  @previous_date = max(benchmark_end)
	from    film_screening_date_xref_alternate 
	where   benchmark_end < @benchmark_end
	and		datepart(mm, benchmark_end) in (	select	datepart(mm, benchmark_end)  
							from	film_screening_date_xref_alternate 
							where	benchmark_end = @benchmark_end)
        
   return(@previous_date)   
   
   error:
        return(@benchmark_end)
   
END






GO
