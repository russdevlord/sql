/****** Object:  UserDefinedFunction [dbo].[f_inclusion_goodwill_min_date]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_inclusion_goodwill_min_date]
GO
/****** Object:  UserDefinedFunction [dbo].[f_inclusion_goodwill_min_date]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[f_inclusion_goodwill_min_date] (@inclusion_id int)
RETURNS datetime
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

	select			@inclusion_type = inclusion_type
	from			inclusion 
	where			inclusion_id = @inclusion_id

	if @inclusion_type = 29
	begin
		select			@min_screening_date = min(screening_date),
						@max_screening_date = max(screening_date)
		from			inclusion_follow_film_targets
		where			inclusion_id = @inclusion_id
		and				original_target_attendance = 0 
		and				target_attendance <> 0 
	end
	else
	begin
		select			@min_screening_date = min(screening_date),
						@max_screening_date = max(screening_date)
		from			inclusion_cinetam_targets
		where			inclusion_id = @inclusion_id
		and				original_target_attendance = 0 
		and				target_attendance <> 0 
	end

	return(@min_screening_date)
END
GO
