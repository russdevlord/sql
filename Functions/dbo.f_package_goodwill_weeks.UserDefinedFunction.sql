/****** Object:  UserDefinedFunction [dbo].[f_package_goodwill_weeks]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_package_goodwill_weeks]
GO
/****** Object:  UserDefinedFunction [dbo].[f_package_goodwill_weeks]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[f_package_goodwill_weeks] (@package_id int)
RETURNS int
AS
BEGIN
DECLARE  @min_screening_date							datetime,
			@max_screening_date							datetime,
			@inclusion_type								int,
			@no_weeks									int,
			@added_attendance							int,
			@actual_to_date								int,
			@2D_count									int,
			@3D_count									int,
			@dimension_desc								varchar(20),
			@cinetam_reporting_demographics_id			int

	select			@min_screening_date = min(screening_date),
					@max_screening_date = max(screening_date)
	from			campaign_spot
	where			package_id = @package_id
	and				spot_type = 'W'

	select			@no_weeks = datediff(wk, @min_screening_date, @max_screening_date) + 1
    
	return(@no_weeks) 
   

END
GO
