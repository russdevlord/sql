/****** Object:  UserDefinedFunction [dbo].[udf_recursive]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[udf_recursive]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_recursive]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_recursive] ( @i INT ) 
RETURNS VARCHAR(8000) AS BEGIN 
        
DECLARE @r VARCHAR(8000), @l VARCHAR(8000) 
SELECT @i = @i - 1,  @r = film_market_code + ', ' 
FROM dbo.film_market p1
WHERE --p1.film_market_no = @market_no AND	
	@i = ( SELECT COUNT(*) FROM dbo.film_market p2 
               WHERE p2.film_market_no = p1.film_market_no
                 AND p2.film_market_code <= p1.film_market_code ) ; 

IF @i > 0 BEGIN 
      --EXEC @l = dbo.udf_recursive @market_no, @i;
     EXEC @l = dbo.udf_recursive @i;
     SET @r =  @l + @r;

END 
RETURN @r;
END 
GO
