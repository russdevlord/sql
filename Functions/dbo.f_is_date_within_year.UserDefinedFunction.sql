/****** Object:  UserDefinedFunction [dbo].[f_is_date_within_year]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_is_date_within_year]
GO
/****** Object:  UserDefinedFunction [dbo].[f_is_date_within_year]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[f_is_date_within_year] (@date as datetime, @year_end as datetime)
RETURNS tinyint
AS
BEGIN
   DECLARE  @year_start		datetime

	if isnull(@year_end, '1-jan-1900') = '1-jan-1900'
		return 0

	/* 
	 * Calendar Year
	 */				            
	if datepart(month, @year_end) = 12   
		begin
			select	@year_start = calendar_start
			from	calendar_year
			where 	calendar_end = @year_end
			if @@error <> 0
				goto error

		end

	/* 
	 * Financial Year
	 */				            
	if datepart(month, @year_end) = 6   
		begin
			select	@year_start = finyear_start
			from	financial_year
			where 	finyear_end = @year_end
			if @@error <> 0
				goto error

		end

	if isnull(@year_start, '1-jan-1900') = '1-jan-1900'
		return 0

	if @date >= @year_start and @date <= @year_end
		return 1

	return 0
   
   error:
        return 0
   
END


GO
