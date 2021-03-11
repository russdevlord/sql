USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[f_package_goodwill_min_date]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE FUNCTION [dbo].[f_package_goodwill_min_date] (@package_id int)
RETURNS datetime
AS
BEGIN
DECLARE  @min_screening_date							datetime,
			@max_screening_date							datetime,
			@package_type								int,
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


	return(@min_screening_date)
END
GO
