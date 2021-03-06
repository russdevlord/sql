/****** Object:  UserDefinedFunction [dbo].[f_inclusion_goodwill_dimension]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_inclusion_goodwill_dimension]
GO
/****** Object:  UserDefinedFunction [dbo].[f_inclusion_goodwill_dimension]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[f_inclusion_goodwill_dimension] (@inclusion_id int)
RETURNS varchar(50)
AS
BEGIN
DECLARE		@min_screening_date							datetime,
			@max_screening_date							datetime,
			@inclusion_type								int,
			@no_weeks									int,
			@added_attendance							int,
			@actual_to_date								int,
			@2D_count									int,
			@3D_count									int,
			@dimension_desc								varchar(50),
			@cinetam_reporting_demographics_id			int

	select			@inclusion_type = inclusion_type
	from			inclusion 
	where			inclusion_id = @inclusion_id

	if @inclusion_type = 29
	begin
		select			@min_screening_date = min(screening_date),
						@max_screening_date = max(screening_date),
						@cinetam_reporting_demographics_id = min(cinetam_reporting_demographics_id)
		from			inclusion_follow_film_targets
		where			inclusion_id = @inclusion_id
		and				original_target_attendance = 0 
		and				target_attendance <> 0 

		select			@2D_count = count(*)
		from			inclusion_follow_film_targets
		inner join		movie on inclusion_follow_film_targets.movie_id = movie.movie_id
		where			inclusion_id = @inclusion_id
		and				screening_date >= @min_screening_date
		and				charindex('3D', long_name) = 0

		select			@3D_count = count(*)
		from			inclusion_follow_film_targets
		inner join		movie on inclusion_follow_film_targets.movie_id = movie.movie_id
		where			inclusion_id = @inclusion_id
		and				screening_date >= @min_screening_date
		and				charindex('3D', long_name) <> 0

		if @2D_count > 0 and @3D_count > 0
		begin
			select			@dimension_desc = 'Goodwill is both 2D and 3D'
		end
		else if @2D_count = 0 and @3D_count > 0
		begin
			select			@dimension_desc = 'Goodwill is 3D only'
		end
		else if @2D_count > 0 and @3D_count = 0
		begin
			select			@dimension_desc = 'Goodwill is 2D only'
		end
	end
	else
	begin
		select			@dimension_desc = 'Not Valid'
	end

	return(@dimension_desc)
END
GO
