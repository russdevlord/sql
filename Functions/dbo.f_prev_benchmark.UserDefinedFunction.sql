/****** Object:  UserDefinedFunction [dbo].[f_prev_benchmark]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_prev_benchmark]
GO
/****** Object:  UserDefinedFunction [dbo].[f_prev_benchmark]    Script Date: 12/03/2021 10:03:48 AM ******/
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
