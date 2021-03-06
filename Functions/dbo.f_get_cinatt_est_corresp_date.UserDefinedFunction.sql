/****** Object:  UserDefinedFunction [dbo].[f_get_cinatt_est_corresp_date]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_get_cinatt_est_corresp_date]
GO
/****** Object:  UserDefinedFunction [dbo].[f_get_cinatt_est_corresp_date]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[f_get_cinatt_est_corresp_date](@screening_date as datetime)
RETURNS datetime
AS
BEGIN
    DECLARE @correspond_screening_date datetime
    
    select  @correspond_screening_date = max(screening_date) 
    from    film_screening_dates
    where   abs(datediff( day, dateadd(year, -1, @screening_date), screening_date)) <= 3
    
    if not exists (select 1 from cinema_attendance where screening_date = @screening_date)
        select  @correspond_screening_date = max(screening_date) 
        from    film_screening_dates
        where   abs(datediff( day, dateadd(year, -2, @screening_date), screening_date)) <= 3
    

RETURN @correspond_screening_date    
END

GO
