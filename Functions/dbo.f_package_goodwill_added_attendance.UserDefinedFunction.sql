/****** Object:  UserDefinedFunction [dbo].[f_package_goodwill_added_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_package_goodwill_added_attendance]
GO
/****** Object:  UserDefinedFunction [dbo].[f_package_goodwill_added_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[f_package_goodwill_added_attendance] (@package_id int)
RETURNS int
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

	select			@added_attendance = isnull(sum(attendance),0)
	from			campaign_spot
	inner join		v_certificate_item_distinct on campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
	inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
	where			package_id = @package_id
	and				spot_type = 'W'

	return(@added_attendance)
END
GO
