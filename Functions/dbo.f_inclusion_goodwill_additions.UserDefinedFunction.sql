/****** Object:  UserDefinedFunction [dbo].[f_inclusion_goodwill_additions]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_inclusion_goodwill_additions]
GO
/****** Object:  UserDefinedFunction [dbo].[f_inclusion_goodwill_additions]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[f_inclusion_goodwill_additions] (@inclusion_id int)
RETURNS @goodwill TABLE
	(inclusion_id		int,
	no_weeks			int,
	added_attendance	int,
	actual_to_date		int,
	dimension_desc		varchar(20))
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
			select			@dimension_desc = 'Both 2D and 3D'
		end
		else if @2D_count = 0 and @3D_count > 0
		begin
			select			@dimension_desc = '3D only'
		end
		else if @2D_count > 0 and @3D_count = 0
		begin
			select			@dimension_desc = '2D only'
		end

		select			@added_attendance = sum(inclusion_follow_film_targets.target_attendance)
		from			inclusion_follow_film_targets
		where			inclusion_id = @inclusion_id
		and				original_target_attendance = 0 
		and				target_attendance <> 0 

	end
	else
	begin
		select			@min_screening_date = min(screening_date),
						@max_screening_date = max(screening_date),
						@cinetam_reporting_demographics_id = min(cinetam_reporting_demographics_id)
		from			inclusion_cinetam_targets
		where			inclusion_id = @inclusion_id
		and				original_target_attendance = 0 
		and				target_attendance <> 0 

		select			@dimension_desc = 'Not Valid'

		select			@added_attendance = sum(inclusion_cinetam_targets.target_attendance)
		from			inclusion_cinetam_targets
		where			inclusion_id = @inclusion_id
		and				original_target_attendance = 0 
		and				target_attendance <> 0 

	end

	select			@actual_to_date = sum(attendance)
	from			inclusion_campaign_spot_xref
	inner join		v_certificate_item_distinct on inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
	inner join		v_cinetam_movie_history_reporting_demos on v_certificate_item_distinct.certificate_group = v_cinetam_movie_history_reporting_demos.certificate_group_id
	where			inclusion_campaign_spot_xref.inclusion_id = @inclusion_id
	and				v_cinetam_movie_history_reporting_demos.screening_date <= dateadd(wk, -2, @min_screening_date)
	and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	select			@actual_to_date = isnull(@actual_to_date, 0) + sum(full_attendance)
	from			inclusion_campaign_spot_xref
	inner join		v_certificate_item_distinct on inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
	inner join		v_cinetam_movie_history_weekend_reporting_demos on v_certificate_item_distinct.certificate_group = v_cinetam_movie_history_weekend_reporting_demos.certificate_group_id
	where			inclusion_campaign_spot_xref.inclusion_id = @inclusion_id
	and				v_cinetam_movie_history_weekend_reporting_demos.screening_date = dateadd(wk, -1, @min_screening_date)
	and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	select			@no_weeks = datediff(wk, @min_screening_date, @max_screening_date) + 1
    
	insert into @goodwill values (@inclusion_id, @no_weeks, @added_attendance, @actual_to_date, @dimension_desc)

	return
END
GO
