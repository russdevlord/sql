/****** Object:  UserDefinedFunction [dbo].[f_outpost_spot_segment_full_week]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_outpost_spot_segment_full_week]
GO
/****** Object:  UserDefinedFunction [dbo].[f_outpost_spot_segment_full_week]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[f_outpost_spot_segment_full_week] (@spot_id int)
RETURNS numeric(16,4)
AS
BEGIN
   DECLARE	@seconds	 				numeric(16,4),
							@percent_of_week		numeric(16,4)		
            
	select 		@seconds = convert(numeric(16,4), isnull(sum(datediff(ss, start_date, end_date)),0.0))
	from			outpost_spot_daily_segment 
	where 		spot_id = @spot_id  
	
	if @seconds = 0
		return 0.0
	else
	begin
		select	@percent_of_week = convert(numeric(16,4), @seconds) / convert(numeric(16,4),403193.0000)
		return		@percent_of_week
	end	
         
   
    error:
        return(0.0)
   
END


GO
