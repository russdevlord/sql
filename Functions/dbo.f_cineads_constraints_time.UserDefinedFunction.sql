/****** Object:  UserDefinedFunction [dbo].[f_cineads_constraints_time]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_cineads_constraints_time]
GO
/****** Object:  UserDefinedFunction [dbo].[f_cineads_constraints_time]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- Batch submitted through debugger: SQLQuery36.sql|17|0|C:\Users\mrussell\AppData\Local\Temp\~vs1ACE.sql







CREATE FUNCTION [dbo].[f_cineads_constraints_time](@complex_id int)
RETURNS int    
AS
BEGIN
declare			@error				int,
				@time				int
				

select @time = max_time
from dbo.f_cineads_constraints(@complex_id)

return @time

RETURN 0
END









GO
