/****** Object:  StoredProcedure [dbo].[p_follow_film_create_target]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_follow_film_create_target]
GO
/****** Object:  StoredProcedure [dbo].[p_follow_film_create_target]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_follow_film_create_target]		@inclusion_id			int,
													@complex_id				int,
													@screening_date			datetime,
													@movie_id				int

as

declare				@error			int

begin transaction

insert into		inclusion_follow_film_targets
select			inclusion.inclusion_id,
				inclusion_cinetam_settings.cinetam_reporting_demographics_id,
				inclusion_cinetam_settings.complex_id,
				movie_screening_instructions.movie_id,
				inclusion_spot.screening_date,
				convert(int, (convert(numeric(20,4), cinetam_movie_complex_estimates.attendance * (select count(*) from movie_history where screening_date = @screening_date and complex_id = @complex_id and premium_cinema <> 'Y' and advertising_open = 'Y' and  movie_id = cinetam_movie_complex_estimates.movie_id)) * sale_percentage)),
				0,
				'N',
				convert(int, (convert(numeric(20,4), cinetam_movie_complex_estimates.attendance * (select count(*) from movie_history where screening_date = @screening_date and complex_id = @complex_id and premium_cinema <> 'Y' and advertising_open = 'Y' and  movie_id = cinetam_movie_complex_estimates.movie_id)) * sale_percentage))
from			inclusion,
				inclusion_spot,
				inclusion_cinetam_settings,
				inclusion_cinetam_package,
				movie_screening_instructions,
				cinetam_movie_complex_estimates,
				inclusion_cinetam_master_target
where			inclusion.inclusion_id = inclusion_spot.inclusion_id
and				inclusion.inclusion_id = inclusion_cinetam_settings.inclusion_id
and				inclusion.inclusion_id = inclusion_cinetam_package.inclusion_id			
and				inclusion.inclusion_id = inclusion_cinetam_master_target.inclusion_id
and				inclusion_cinetam_package.package_id = 	movie_screening_instructions.package_id
and				inclusion_cinetam_settings.complex_id = cinetam_movie_complex_estimates.complex_id
and				movie_screening_instructions.movie_id = cinetam_movie_complex_estimates.movie_id
and				inclusion_cinetam_settings.cinetam_reporting_demographics_id = cinetam_movie_complex_estimates.cinetam_reporting_demographics_id
and				inclusion_spot.screening_date = cinetam_movie_complex_estimates.screening_date
and				inclusion.inclusion_type = 29
and				inclusion_spot.screening_date = @screening_date
and				inclusion_cinetam_settings.complex_id = @complex_id
and				inclusion.inclusion_id = @inclusion_id
and				movie_screening_instructions.movie_id = @movie_id
and				movie_screening_instructions.instruction_type = 1

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error: Could not create follow film targets'				, 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
