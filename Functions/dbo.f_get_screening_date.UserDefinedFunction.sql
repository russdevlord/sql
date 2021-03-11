USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[f_get_screening_date]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[f_get_screening_date]
(
	  @date datetime
)
RETURNS datetime
AS
BEGIN		

	DECLARE @ScreenigDate DATETIME
	SELECT @ScreenigDate = CASE WHEN DATENAME(WEEKDAY, @date) = 'THURSDAY' THEN
		 @date 
    ELSE
        DATEADD(d, -((DATEPART(WEEKDAY,@date) + 2 + @@DATEFIRST) % 7), @date)
    END 
	Return @ScreenigDate 
END
GO
