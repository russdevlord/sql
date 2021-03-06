/****** Object:  UserDefinedFunction [dbo].[f_get_screening_date]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_get_screening_date]
GO
/****** Object:  UserDefinedFunction [dbo].[f_get_screening_date]    Script Date: 12/03/2021 10:03:48 AM ******/
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
