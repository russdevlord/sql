/****** Object:  UserDefinedFunction [dbo].[f_sun_date]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_sun_date]
GO
/****** Object:  UserDefinedFunction [dbo].[f_sun_date]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE FUNCTION [dbo].[f_sun_date] ( @accounting_period datetime)
RETURNS CHAR(7)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @sun_date CHAR(7)
	if @accounting_period < '1-jan-2017' or @accounting_period > '1-jan-2021' 
	begin
		SELECT	@sun_date = CONVERT(VARCHAR(4),DATEPART(year,calendar_end)) +  RIGHT('00' + CONVERT(VARCHAR(2),DATEPART(week,dateadd(wk, -1, benchmark_end))), 3)
		FROM	accounting_period
		WHERE	benchmark_end = @accounting_period
	end
	else 
	begin
		SELECT	@sun_date = CONVERT(VARCHAR(4),DATEPART(year,calendar_end)) +  RIGHT('00' + CONVERT(VARCHAR(2),DATEPART(week,benchmark_end)), 3)
		FROM	accounting_period
		WHERE	benchmark_end = @accounting_period
	end
			
		

	-- Return the result of the function
	RETURN @sun_date

END



GO
