/****** Object:  StoredProcedure [dbo].[p_inclusion_fix_achievement]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_inclusion_fix_achievement]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_fix_achievement]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc	[dbo].[p_inclusion_fix_achievement]		@inclusion_id		int

as

declare		@error										int,
			@movie_id									int,
			@achievement								int,
			@cinetam_reporting_demographics_id			int,
			@screening_date								datetime,
			@complex_id									int,
			@inclusion_type								int

set nocount on

select			@inclusion_type = inclusion_type
from			inclusion 
where			inclusion_id = @inclusion_id

if @inclusion_type = 29
begin
	declare			target_csr cursor for
	select			complex_id, 
					screening_date,
					movie_id, 
					cinetam_reporting_demographics_id
	from			inclusion_follow_film_targets
	where			inclusion_id = @inclusion_id
	and				processed = 'Y'
	order by		complex_id, 
					screening_date,
					movie_id, 
					cinetam_reporting_demographics_id
	for				read only

	open target_csr
	fetch target_csr into @complex_id, @screening_date, @movie_id, @cinetam_reporting_demographics_id
	while(@@FETCH_STATUS = 0) 
	begin
		select			@achievement = 0

		select			@achievement = SUM(cinetam_movie_complex_estimates.attendance)
		from			inclusion_campaign_spot_xref
		inner join		v_certificate_item_distinct on inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
		inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
		inner join		cinetam_movie_complex_estimates on movie_history.movie_id = cinetam_movie_complex_estimates.movie_id
		and				movie_history.complex_id = cinetam_movie_complex_estimates.complex_id
		and				movie_history.screening_date = cinetam_movie_complex_estimates.screening_date
		where			inclusion_campaign_spot_xref.inclusion_id = @inclusion_id
		and				movie_history.movie_id = @movie_id
		and				movie_history.complex_id = @complex_id
		and				movie_history.screening_date = @screening_date
		and				cinetam_movie_complex_estimates.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

		update			inclusion_follow_film_targets
		set				achieved_attendance = isnull(@achievement,0)
		where			movie_id = @movie_id
		and				complex_id = @complex_id
		and				screening_date = @screening_date
		and				inclusion_id = @inclusion_id

		fetch target_csr into @complex_id, @screening_date, @movie_id, @cinetam_reporting_demographics_id
	end
end
else
begin
	declare			target_csr cursor for
	select			complex_id, 
					screening_date, 
					cinetam_reporting_demographics_id
	from			inclusion_follow_film_targets
	where			inclusion_id = @inclusion_id
	and				processed = 'Y'
	order by		complex_id, 
					screening_date, 
					cinetam_reporting_demographics_id
	for				read only

	open target_csr
	fetch target_csr into @complex_id, @screening_date, @cinetam_reporting_demographics_id
	while(@@FETCH_STATUS = 0) 
	begin

		select			@achievement = 0

		select			@achievement = SUM(cinetam_movie_complex_estimates.attendance)
		from			inclusion_campaign_spot_xref
		inner join		v_certificate_item_distinct on inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
		inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
		inner join		cinetam_movie_complex_estimates on movie_history.movie_id = cinetam_movie_complex_estimates.movie_id
		and				movie_history.complex_id = cinetam_movie_complex_estimates.complex_id
		and				movie_history.screening_date = cinetam_movie_complex_estimates.screening_date
		where			inclusion_campaign_spot_xref.inclusion_id = @inclusion_id
		and				movie_history.complex_id = @complex_id
		and				movie_history.screening_date = @screening_date
		and				cinetam_movie_complex_estimates.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

		update			inclusion_follow_film_targets
		set				achieved_attendance = isnull(@achievement,0)
		where			complex_id = @complex_id
		and				screening_date = @screening_date
		and				inclusion_id = @inclusion_id

		fetch target_csr into @complex_id, @screening_date, @cinetam_reporting_demographics_id
	end
end

return 0
GO
