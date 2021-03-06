/****** Object:  UserDefinedFunction [dbo].[f_cinelight_spot_segment_full_day]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_cinelight_spot_segment_full_day]
GO
/****** Object:  UserDefinedFunction [dbo].[f_cinelight_spot_segment_full_day]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[f_cinelight_spot_segment_full_day] (@spot_id int, @day_of_week	int)
RETURNS numeric(16,4)
AS
BEGIN
   DECLARE  @seconds	 		numeric(16,4),
			@percent_of_day		numeric(16,4)

	select 	@seconds = convert(numeric(16,4), isnull(sum(datediff(ss, start_date, end_date)),0.0))
	from	cinelight_spot_daily_segment
	where 	spot_id = @spot_id
	and 	datepart(dw,start_date) = @day_of_week

	if @seconds = 0
		return 0.0
	else
	begin
		select @percent_of_day = convert(numeric(16,4), @seconds) / convert(numeric(16,4),57599.0000)
		return @percent_of_day
	end


    error:
        return(0.0)

END



GO
