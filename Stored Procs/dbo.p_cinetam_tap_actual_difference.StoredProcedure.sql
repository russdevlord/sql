/****** Object:  StoredProcedure [dbo].[p_cinetam_tap_actual_difference]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_tap_actual_difference]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_tap_actual_difference]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinetam_tap_actual_difference]		@complex_id				int,
																							@screening_date		datetime,
																							@inclusion_id				int

as

declare		@error															int,
				@est_to_date												numeric(20,12),
				@act_to_date												numeric(20,12),
				@difference													numeric(20,12),
				@complex_share											numeric(20,12),
				@market_share											numeric(20,12),
				@two_week_prior										datetime,
				@one_week_prior										datetime,
				@campaign_no												int,
				@cinetam_reporting_demographics_id		int

select		@two_week_prior = dateadd(wk, -2, @screening_date),
				@one_week_prior = dateadd(wk, -1, @screening_date)

select	@error = @@error
if @error <> 0
begin
	raiserror ('Error: Could go back two weeks', 16, 1)
	return -1
end

select	@campaign_no = campaign_no
from		inclusion 
where	inclusion_id = @inclusion_id

select	@error = @@error
if @error <> 0
begin
	raiserror ('Error: Could not find campaign_no', 16, 1)
	return -1
end

select	@cinetam_reporting_demographics_id = cinetam_reporting_demographics_id
from		inclusion_cinetam_settings
where	inclusion_id = @inclusion_id

select	@error = @@error
if @error <> 0
begin
	raiserror ('Error: Could not find reporting_demo', 16, 1)
	return -1
end

select		@est_to_date = sum(target_attendance)
from			inclusion_cinetam_targets
where		inclusion_id = @inclusion_id
and			screening_date <= @one_week_prior

select	@error = @@error
if @error <> 0
begin
	raiserror ('Error: Could not find estimate', 16, 1)
	return -1
end

select 			@act_to_date = sum(cinetam_movie_history.attendance)
from				film_campaign,
					movie_history,
					v_certificate_item_distinct,
					campaign_spot,
					cinetam_movie_history,
					inclusion_campaign_spot_xref
where			film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history.certificate_group
and				movie_history.attendance is not null
and				movie_history.attendance > 0 
and				campaign_spot.screening_date <= @two_week_prior
and				movie_history.screening_date <= @two_week_prior
and				movie_history.complex_id = cinetam_movie_history.complex_id
and				movie_history.movie_id = cinetam_movie_history.movie_id
and				movie_history.screening_date = cinetam_movie_history.screening_date
and				movie_history.occurence = cinetam_movie_history.occurence
and				movie_history.print_medium = cinetam_movie_history.print_medium
and				movie_history.three_d_type = cinetam_movie_history.three_d_type
and				inclusion_campaign_spot_xref.spot_id = campaign_spot.spot_id
and				inclusion_campaign_spot_xref.inclusion_id = @inclusion_id
and				cinetam_movie_history.cinetam_demographics_id in (select cinetam_demographics_id from cinetam_reporting_demographics_xref where cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id)

select	@error = @@error
if @error <> 0
begin
	raiserror ('Error: Could not find actual', 16, 1)
	return -1
end

select 			@act_to_date = isnull(@act_to_date,0) + sum(cinetam_movie_complex_estimates.attendance)
from				film_campaign,
					movie_history,
					v_certificate_item_distinct,
					campaign_spot,
					inclusion_campaign_spot_xref,
					cinetam_movie_complex_estimates
where			film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and				v_certificate_item_distinct.certificate_group = movie_history.certificate_group
and				campaign_spot.screening_date = @one_week_prior
and				movie_history.screening_date = @one_week_prior
and				movie_history.complex_id = cinetam_movie_complex_estimates.complex_id
and				movie_history.movie_id = cinetam_movie_complex_estimates.movie_id
and				movie_history.screening_date = cinetam_movie_complex_estimates.screening_date
and				inclusion_campaign_spot_xref.spot_id = campaign_spot.spot_id
and				inclusion_campaign_spot_xref.inclusion_id = @inclusion_id
and				cinetam_movie_complex_estimates.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

select	@difference =  @act_to_date - @est_to_date

select	@error = @@error
if @error <> 0
begin
	raiserror ('Error: Could not find determine difference', 16, 1)
	return -1
end

select	@complex_share = sum(cinetam_complex_date_settings.percent_market)
from		cinetam_complex_date_settings
where	complex_id = @complex_id
and		screening_date = @screening_date
and		cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id					

select	@error = @@error
if @error <> 0
begin
	raiserror ('Error: Could not complex share', 16, 1)
	return -1
end
												
select		@market_share = sum(cinetam_complex_date_settings.percent_market)
from 		inclusion_spot,   
				film_campaign_complex,
				cinetam_complex_date_settings  
where		film_campaign_complex.complex_id = cinetam_complex_date_settings.complex_id
and			inclusion_spot.screening_date = cinetam_complex_date_settings.screening_date
and			inclusion_spot.screening_date = @screening_date
and			cinetam_complex_date_settings.screening_date = @screening_date
and			inclusion_spot.campaign_no = film_campaign_complex.campaign_no
and  			inclusion_spot.inclusion_id = @inclusion_id 
and	  		cinetam_complex_date_settings.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

select	@error = @@error
if @error <> 0
begin
	raiserror ('Error: Could not market share', 16, 1)
	return -1
end
		
select @difference = @difference * @complex_share / @market_share

select isnull(@difference,0) as extra_target

return 0
GO
