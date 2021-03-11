/****** Object:  UserDefinedFunction [dbo].[f_cineads_constraints]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_cineads_constraints]
GO
/****** Object:  UserDefinedFunction [dbo].[f_cineads_constraints]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE FUNCTION [dbo].[f_cineads_constraints](@complex_id int)
RETURNS @capacity TABLE
       (max_ads				int,
		max_time			int)        
AS
BEGIN
declare			@error				int
				
insert into		@capacity
select			max_ads,
				max_time
from			complex_screen_scheduling_xref
where			complex_id = @complex_id
RETURN
END











GO
