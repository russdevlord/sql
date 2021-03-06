/****** Object:  StoredProcedure [dbo].[p_cinetam_adjust_estimates_weekend]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_adjust_estimates_weekend]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_adjust_estimates_weekend]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









create proc [dbo].[p_cinetam_adjust_estimates_weekend]		@screening_date			datetime

as

set nocount on

declare		@error											int,
			@complex_id										int, 
			@movie_id										int, 
			@cinetam_reporting_demographics_id				int, 
			@inclusion_id									int,
			@attendance										numeric(18,10),
			@full_weekend_attendance						numeric(18,10),
			@target_attendance								numeric(18,10),
			@next_week_attendance							numeric(18,10),
--			@last_week_attendance							numeric(18,10),
			@attendance_difference							numeric(18,10),
			@correct_allocation								numeric(18,10),
			@next_screening_date							datetime,
			@last_week										datetime,
			@first_actuals_week								datetime,
			@last_actuals_week								datetime,
			@row_check										int



begin transaction

/*
 * Delete Adjustment history
 */

delete			cinetam_inclusion_weekend_adjsum
where			screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error updating movie_history_weekend pt 1', 16, 1)
	rollback transaction
	return -1
end

delete			cinetam_follow_film_weekend_adjsum
where			screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error updating movie_history_weekend pt 1', 16, 1)
	rollback transaction
	return -1
end

/* 
 * Adjust based on the movies previous history
 */

select			wk.movie_id as movie_id, 
				wk.country, 
				sum(convert(numeric(20,8), wkend.attendance)) / sum(convert(numeric(20,8), wk.attendance)) as weekend_factor
into			#temp_table_movie
from			movie_history wk,
				movie_history_weekend wkend
where			wk.movie_id = wkend.movie_id
and				wk.complex_id = wkend.complex_id
and				wk.screening_date = wkend.screening_date
and				wk.occurence = wkend.occurence
and				wk.print_medium = wkend.print_medium
and				wk.three_d_type = wkend.three_d_type
and				wk.premium_cinema = wkend.premium_cinema
and				isnull(wk.attendance, 0) <> 0 
and				isnull(wkend.attendance, 0) <> 0 
and				wk.attendance_type = 'A'
and				wkend.attendance_type = 'A'
and				wk.screening_date < @screening_date
and				wk.screening_date >= (select max(release_date) from movie_country where movie_id = wk.movie_id and country_code = wk.country)
group by		wk.movie_id,
				wk.country

select @error = @@error
if @error <> 0
begin
	raiserror ('Error updating movie_history_weekend pt 1', 16, 1)
	rollback transaction
	return -1
end

update			movie_history_weekend
set				full_attendance = attendance / weekend_factor
from			#temp_table_movie
where			#temp_table_movie.movie_id = movie_history_weekend.movie_id
and				#temp_table_movie.country = movie_history_weekend.country
and				movie_history_weekend.screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error updating movie_history_weekend pt 2', 16, 1)
	rollback transaction
	return -1
end

update			cinetam_movie_history_weekend
set				full_attendance = attendance / weekend_factor
from			#temp_table_movie
where			#temp_table_movie.movie_id = cinetam_movie_history_weekend.movie_id
and				#temp_table_movie.country = cinetam_movie_history_weekend.country_code
and				cinetam_movie_history_weekend.screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error updating cinetam_movie_history_weekend pt 1', 16, 1)
	rollback transaction
	return -1
end

/*
 * Adjust based on preset target category percentages all movie 
 */

 update			movie_history_weekend
set				full_attendance = attendance / factor
from			target_categories, 
				attendance_weekend_adjustment_factors
where			movie_history_weekend.movie_id = target_categories.movie_id
and				attendance_weekend_adjustment_factors.movie_category_code = target_categories.movie_category_code
and				movie_history_weekend.screening_date = @screening_date
and				movie_history_weekend.full_attendance = 0

select @error = @@error
if @error <> 0
begin
	raiserror ('Error updating movie_history_weekend based on targets pt 1', 16, 1)
	rollback transaction
	return -1
end

update			movie_history_weekend
set				full_attendance = attendance
where			screening_date = @screening_date
and				full_attendance < attendance

select @error = @@error
if @error <> 0
begin
	raiserror ('Error updating movie_history_weekend based on targets pt 2', 16, 1)
	rollback transaction
	return -1
end

/*
 * Ensure no movie has full attendance less than weekend attendance
 */

update			cinetam_movie_history_weekend
set				full_attendance = attendance / factor
from			target_categories, 
				attendance_weekend_adjustment_factors
where			cinetam_movie_history_weekend.movie_id = target_categories.movie_id
and				attendance_weekend_adjustment_factors.movie_category_code = target_categories.movie_category_code
and				cinetam_movie_history_weekend.screening_date = @screening_date
and				cinetam_movie_history_weekend.full_attendance = 0


select @error = @@error
if @error <> 0
begin
	raiserror ('Error updating cinetmovie_history_weekend based on targets pt 1', 16, 1)
	rollback transaction
	return -1
end

update			cinetam_movie_history_weekend
set				full_attendance = attendance
where			screening_date = @screening_date
and				full_attendance < attendance

select @error = @@error
if @error <> 0
begin
	raiserror ('Error fixing weird ratios in movie_history_weekend', 16, 1)
	rollback transaction
	return -1
end

/*
 * Movie Estimates
 */

declare			movie_estimate_csr cursor for
select			cmce.complex_id, 
				cmce.movie_id,
				cmce.cinetam_reporting_demographics_id, 
				cmce.attendance
from			cinetam_movie_complex_estimates cmce,
				movie_history
where			cmce.movie_id = movie_history.movie_id
and				cmce.complex_id = movie_history.complex_id
and				cmce.screening_date = movie_history.screening_date
and				cmce.screening_date = @screening_date
and				isnull(cmce.attendance,0) <> 0
and				cmce.screening_date >= (select			max(mc.release_date) 
										from			movie_country mc
										inner join		branch b on mc.country_code = b.country_code
										inner join		complex c on b.branch_code = c.branch_code
										where			movie_id = cmce.movie_id 
										and				complex_id = cmce.complex_id)
group by		cmce.complex_id, 
				cmce.movie_id,
				cmce.cinetam_reporting_demographics_id, 
				cmce.attendance
for				read only

open movie_estimate_csr 
fetch movie_estimate_csr into @complex_id, @movie_id, @cinetam_reporting_demographics_id, @attendance
while(@@FETCH_STATUS=0)
begin

	if @cinetam_reporting_demographics_id = 0
	begin
		select			@full_weekend_attendance = sum(full_attendance)
		from			movie_history_weekend
		where			complex_id = @complex_id
		and				movie_id = @movie_id
		and				screening_date = @screening_date

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend for movie estimates', 16, 1)
			rollback transaction
			return -1
		end
	end
	else
	begin
		select			@full_weekend_attendance = sum(full_attendance)
		from			cinetam_movie_history_weekend
		where			complex_id = @complex_id
		and				movie_id = @movie_id
		and				screening_date = @screening_date
		and				cinetam_demographics_id in (	select			cinetam_demographics_id 
														from			cinetam_reporting_demographics_xref 
														where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id) 

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend for movie estimates', 16, 1)
			rollback transaction
			return -1
		end
	end

	if @attendance > 0 and @full_weekend_attendance > 0
	begin
		update			cinetam_movie_complex_estimates
		set				attendance = convert(int, attendance *  (@full_weekend_attendance / @attendance))
		where			screening_date > @screening_date
		and				complex_id = @complex_id
		and				movie_id = @movie_id
		and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error updating cinetam_movie_complex_estimates', 16, 1)
			rollback transaction
			return -1
		end

	end

	fetch movie_estimate_csr into @complex_id, @movie_id, @cinetam_reporting_demographics_id, @attendance
end

/*
 * Correct any incorrect allocations
 */

declare			correct_cinetam_allocations_csr cursor for
select			inclusion_cinetam_settings.inclusion_id, 
				inclusion_cinetam_settings.complex_id,
				inclusion_cinetam_settings.cinetam_reporting_demographics_id,
				SUM(round(cmce.attendance_split,0)) as correct_allocation
from			v_certificate_item_distinct
inner join		inclusion_campaign_spot_xref on v_certificate_item_distinct.spot_reference = inclusion_campaign_spot_xref.spot_id
inner join		campaign_spot on inclusion_campaign_spot_xref.spot_id = campaign_spot.spot_id and v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
inner join		inclusion_cinetam_settings on inclusion_campaign_spot_xref.inclusion_id = inclusion_cinetam_settings.inclusion_id and campaign_spot.complex_id = inclusion_cinetam_settings.complex_id
inner join		inclusion inc on inclusion_cinetam_settings.inclusion_id = inc.inclusion_id
inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
inner join		(select			cmce.complex_id,
								cmce.screening_date,
								cmce.movie_id,
								cmce.cinetam_reporting_demographics_id,
								playlist.premium_cinema,
								playlist.certificate_group,
								case 
									when normal_playlists > 0 and premium_playlists = 0 and playlist.premium_cinema = 'Y' then -1
									when normal_playlists = 0 and premium_playlists > 0 and playlist.premium_cinema = 'N' then -1
									when normal_playlists > 0 and premium_playlists = 0 and playlist.premium_cinema = 'N' then convert(numeric(12,6), attendance) / convert(numeric(12,6), normal_playlists)
									when normal_playlists > 0 and premium_playlists > 0 and playlist.premium_cinema = 'Y' then convert(numeric(12,6), attendance * 0.15) / convert(numeric(12,6), premium_playlists)
									when normal_playlists > 0 and premium_playlists > 0 and playlist.premium_cinema = 'N' then convert(numeric(12,6), attendance * 0.85) / convert(numeric(12,6), normal_playlists)
									when normal_playlists = 0 and premium_playlists > 0 and playlist.premium_cinema = 'Y' then convert(numeric(12,6), attendance * 0.15) / convert(numeric(12,6), premium_playlists)
								end	as attendance_split
				from			cinetam_movie_complex_estimates cmce
				inner join		(select			complex_id, 
												screening_date,
												movie_id,
												case when premium_cinema = 'Y' then 'Y' else 'N' end as premium_cinema , 
												certificate_group
								from			movie_history) as playlist 
				on				cmce.complex_id = playlist.complex_id
				and				cmce.screening_date = playlist.screening_date
				and				cmce.movie_id = playlist.movie_id
				inner join		(select			complex_id,
												screening_date,
												movie_id,
												sum(premium_playlist) as premium_playlists,
												sum(normal_playlist) as normal_playlists
								from			(select			complex_id, 
																screening_date,
																movie_id,
																case when premium_cinema = 'Y' then 'Y' else 'N' end as premium_cinema , 
																certificate_group,
																case premium_cinema 
																	when 'Y' then 0
																	else 1 
																end as normal_playlist,
																case premium_cinema 
																	when 'Y' then 1 
																	else 0 
																end as premium_playlist
												from			movie_history) as movie_playlist
								group by		complex_id, 
												screening_date,
												movie_id) as playlists_temp
				on				cmce.complex_id = playlists_temp.complex_id
				and				cmce.screening_date = playlists_temp.screening_date
				and				cmce.movie_id = playlists_temp.movie_id) cmce 
on				movie_history.complex_id = cmce.complex_id 
and				movie_history.screening_date = cmce.screening_date 
and				movie_history.movie_id = cmce.movie_id 
and				inclusion_cinetam_settings.cinetam_reporting_demographics_id = cmce.cinetam_reporting_demographics_id
and				case when movie_history.premium_cinema = 'Y' then 'Y' else 'N' end = cmce.premium_cinema
and				movie_history.certificate_group = cmce.certificate_group
where			campaign_spot.screening_date = @screening_date
and				movie_history.screening_date = @screening_date
and				inclusion_type in (24, 32)
group by		inclusion_cinetam_settings.inclusion_id, 
				inclusion_cinetam_settings.complex_id,
				inclusion_cinetam_settings.cinetam_reporting_demographics_id

open correct_cinetam_allocations_csr
fetch correct_cinetam_allocations_csr into @inclusion_id, @complex_id, @cinetam_reporting_demographics_id, @correct_allocation
while(@@FETCH_STATUS=0)
begin

	select			@row_check = 0

	select			@row_check = count(*)
	from			inclusion_cinetam_targets
	where			inclusion_id = @inclusion_id
	and				complex_id = @complex_id
	and				screening_date = @screening_date
	and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error getting weekend numbers for MAP and TAP', 16, 1)
		rollback transaction
		return -1
	end

	if @row_check = 0
	begin
		insert into		inclusion_cinetam_targets
		values			(@inclusion_id,
						@cinetam_reporting_demographics_id,
						@complex_id,
						@screening_date,
						0,
						@correct_allocation,
						'Y',
						0)		

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for MAP and TAP', 16, 1)
			rollback transaction
			return -1
		end
	end
	else if @row_check > 0
	begin
		update			inclusion_cinetam_targets
		set				achieved_attendance = @correct_allocation
		where			inclusion_id = @inclusion_id
		and				complex_id = @complex_id
		and				screening_date = @screening_date
		and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
		
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for MAP and TAP', 16, 1)
			rollback transaction
			return -1
		end

	end

	fetch correct_cinetam_allocations_csr into @inclusion_id, @complex_id, @cinetam_reporting_demographics_id, @correct_allocation
end

declare			correct_follow_film_allocations_csr cursor for
select			inclusion_cinetam_settings.inclusion_id, 
				inclusion_cinetam_settings.complex_id,
				movie_history.movie_id,
				inclusion_cinetam_settings.cinetam_reporting_demographics_id,
				SUM(round(cmce.attendance_split,0)) as correct_allocation
from			v_certificate_item_distinct
inner join		inclusion_campaign_spot_xref on v_certificate_item_distinct.spot_reference = inclusion_campaign_spot_xref.spot_id
inner join		campaign_spot on inclusion_campaign_spot_xref.spot_id = campaign_spot.spot_id and v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
inner join		inclusion_cinetam_settings on inclusion_campaign_spot_xref.inclusion_id = inclusion_cinetam_settings.inclusion_id and campaign_spot.complex_id = inclusion_cinetam_settings.complex_id
inner join		inclusion inc on inclusion_cinetam_settings.inclusion_id = inc.inclusion_id
inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
inner join		(select			cmce.complex_id,
								cmce.screening_date,
								cmce.movie_id,
								cmce.cinetam_reporting_demographics_id,
								playlist.premium_cinema,
								playlist.certificate_group,
								case 
									when normal_playlists > 0 and premium_playlists = 0 and playlist.premium_cinema = 'Y' then -1
									when normal_playlists = 0 and premium_playlists > 0 and playlist.premium_cinema = 'N' then -1
									when normal_playlists > 0 and premium_playlists = 0 and playlist.premium_cinema = 'N' then convert(numeric(12,6), attendance) / convert(numeric(12,6), normal_playlists)
									when normal_playlists > 0 and premium_playlists > 0 and playlist.premium_cinema = 'Y' then convert(numeric(12,6), attendance * 0.15) / convert(numeric(12,6), premium_playlists)
									when normal_playlists > 0 and premium_playlists > 0 and playlist.premium_cinema = 'N' then convert(numeric(12,6), attendance * 0.85) / convert(numeric(12,6), normal_playlists)
									when normal_playlists = 0 and premium_playlists > 0 and playlist.premium_cinema = 'Y' then convert(numeric(12,6), attendance * 0.15) / convert(numeric(12,6), premium_playlists)
								end	as attendance_split
				from			cinetam_movie_complex_estimates cmce
				inner join		(select			complex_id, 
												screening_date,
												movie_id,
												case when premium_cinema = 'Y' then 'Y' else 'N' end as premium_cinema , 
												certificate_group
								from			movie_history) as playlist 
				on				cmce.complex_id = playlist.complex_id
				and				cmce.screening_date = playlist.screening_date
				and				cmce.movie_id = playlist.movie_id
				inner join		(select			complex_id,
												screening_date,
												movie_id,
												sum(premium_playlist) as premium_playlists,
												sum(normal_playlist) as normal_playlists
								from			(select			complex_id, 
																screening_date,
																movie_id,
																case when premium_cinema = 'Y' then 'Y' else 'N' end as premium_cinema , 
																certificate_group,
																case premium_cinema 
																	when 'Y' then 0
																	else 1 
																end as normal_playlist,
																case premium_cinema 
																	when 'Y' then 1 
																	else 0 
																end as premium_playlist
												from			movie_history) as movie_playlist
								group by		complex_id, 
												screening_date,
												movie_id) as playlists_temp
				on				cmce.complex_id = playlists_temp.complex_id
				and				cmce.screening_date = playlists_temp.screening_date
				and				cmce.movie_id = playlists_temp.movie_id) cmce 
on				movie_history.complex_id = cmce.complex_id 
and				movie_history.screening_date = cmce.screening_date 
and				movie_history.movie_id = cmce.movie_id 
and				inclusion_cinetam_settings.cinetam_reporting_demographics_id = cmce.cinetam_reporting_demographics_id
and				case when movie_history.premium_cinema = 'Y' then 'Y' else 'N' end = cmce.premium_cinema
and				movie_history.certificate_group = cmce.certificate_group
where			campaign_spot.screening_date = @screening_date
and				movie_history.screening_date = @screening_date
and				inclusion_type = 29
group by		inclusion_cinetam_settings.inclusion_id, 
				inclusion_cinetam_settings.complex_id,
				movie_history.movie_id,
				inclusion_cinetam_settings.cinetam_reporting_demographics_id


open correct_follow_film_allocations_csr
fetch correct_follow_film_allocations_csr into @inclusion_id, @complex_id, @movie_id, @cinetam_reporting_demographics_id, @correct_allocation
while(@@FETCH_STATUS=0)
begin

	select			@row_check = 0

	select			@row_check = count(*)
	from			inclusion_follow_film_targets
	where			inclusion_id = @inclusion_id
	and				complex_id = @complex_id
	and				screening_date = @screening_date
	and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				movie_id = @movie_id

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error getting weekend numbers for MAP and TAP', 16, 1)
		rollback transaction
		return -1
	end

	if @row_check = 0
	begin
		insert into		inclusion_follow_film_targets
		values			(@inclusion_id,
						@cinetam_reporting_demographics_id,
						@complex_id,
						@movie_id,
						@screening_date,
						0,
						@correct_allocation,
						'Y',
						0)		

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for MAP and TAP', 16, 1)
			rollback transaction
			return -1
		end
	end
	else if @row_check > 0
	begin
		update			inclusion_follow_film_targets
		set				achieved_attendance = @correct_allocation
		where			inclusion_id = @inclusion_id
		and				complex_id = @complex_id
		and				screening_date = @screening_date
		and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
		and				movie_id = @movie_id

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for MAP and TAP', 16, 1)
			rollback transaction
			return -1
		end

	end

	fetch correct_follow_film_allocations_csr into @inclusion_id, @complex_id, @movie_id, @cinetam_reporting_demographics_id, @correct_allocation
end

/*
 * Inclusion CineTAM Targets
 */

declare			tap_target_csr cursor for
select			inc_ctam_temp.inclusion_id,
				inc_ctam_temp.cinetam_reporting_demographics_id,
				sum(inc_ctam_temp.target_attendance) as this_week_target,
				next_week_date.next_screening_date as next_week,
				sum(next_week_temp.target_attendance) as next_week_attendance
from			(select			inclusion_cinetam_targets.inclusion_id,
								inclusion_cinetam_targets.cinetam_reporting_demographics_id,
								sum(target_attendance) as target_attendance
				from			inclusion_cinetam_targets
				inner join		inclusion on inclusion_cinetam_targets.inclusion_id = inclusion.inclusion_id
				where			inclusion_cinetam_targets.screening_date = @screening_date
				and				inclusion.inclusion_status <> 'P'
				group by		inclusion_cinetam_targets.inclusion_id,
								inclusion_cinetam_targets.cinetam_reporting_demographics_id) as inc_ctam_temp
inner join		(select			future_date.inclusion_id,
								future_date.cinetam_reporting_demographics_id,
								min(future_date.screening_date) as next_screening_date
				from			inclusion_cinetam_targets future_date
				where			screening_date > @screening_date
				group by		future_date.inclusion_id,
								future_date.cinetam_reporting_demographics_id) as next_week_date
on				inc_ctam_temp.inclusion_id = next_week_date.inclusion_id
and				inc_ctam_temp.cinetam_reporting_demographics_id = next_week_date.cinetam_reporting_demographics_id
inner join		(select			future.inclusion_id,
								future.cinetam_reporting_demographics_id,
								future.screening_date,
								sum(future.target_attendance) as target_attendance
				from			inclusion_cinetam_targets future
				group by		future.inclusion_id,
								future.cinetam_reporting_demographics_id,
								future.screening_date) as next_week_temp
on				inc_ctam_temp.inclusion_id = next_week_temp.inclusion_id
and				inc_ctam_temp.cinetam_reporting_demographics_id = next_week_temp.cinetam_reporting_demographics_id
and				next_week_date.next_screening_date = next_week_temp.screening_date
group by		inc_ctam_temp.inclusion_id,
				inc_ctam_temp.cinetam_reporting_demographics_id,
				next_week_date.next_screening_date
order by		inc_ctam_temp.inclusion_id,
				cinetam_reporting_demographics_id
for				read only

open tap_target_csr 
fetch tap_target_csr into @inclusion_id, @cinetam_reporting_demographics_id, @target_attendance, @next_screening_date, @next_week_attendance
while(@@FETCH_STATUS=0)
begin

	if @cinetam_reporting_demographics_id = 0
	begin
		select			@full_weekend_attendance = isnull(sum(full_attendance),0)
		from			movie_history_weekend
		where			screening_date = @screening_date
		and				certificate_group in (	select			certificate_group 
												from			inclusion_campaign_spot_xref, 
																v_certificate_item_distinct, 
																inclusion_spot
												where			inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
												and				inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id
												and				inclusion_spot.inclusion_id = @inclusion_id
												and				inclusion_spot.screening_date = @screening_date)

	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for MAP and TAP', 16, 1)
			rollback transaction
			return -1
		end
	end 
	else
	begin
		select			@full_weekend_attendance = isnull(sum(full_attendance),0)
		from			cinetam_movie_history_weekend
		where			screening_date = @screening_date
		and				cinetam_demographics_id in (	select			cinetam_demographics_id 
														from			cinetam_reporting_demographics_xref 
														where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id) 
		and				certificate_group_id in (		select			certificate_group 
														from			inclusion_campaign_spot_xref, 
																		v_certificate_item_distinct, 
																		inclusion_spot
														where			inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
														and				inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id
														and				inclusion_spot.inclusion_id = @inclusion_id
														and				inclusion_spot.screening_date = @screening_date)

	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for MAP and TAP', 16, 1)
			rollback transaction
			return -1
		end
	end

	select			@attendance_difference = isnull(@target_attendance,0) - isnull(@full_weekend_attendance, 0)

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error getting TAP next week total attendance', 16, 1)
		rollback transaction
		return -1
	end
						
	insert into		cinetam_inclusion_weekend_adjsum
					(
						inclusion_id,
						screening_date,
						weekly_target,
						weekly_extrapolated_weekend,
						last_week_trueup_actuals,
						last_week_trueup_targets
					)		
	select			@inclusion_id,
					@screening_date,
					isnull(@target_attendance, 0),
					isnull(@full_weekend_attendance, 0),
					0,
					0

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error updating inclusion_cinetam_targets 4', 16, 1)
		rollback transaction
		return -1
	end
	
	if isnull(@attendance_difference, 0) <> 0 and isnull(@next_week_attendance, 0) <> 0
	begin
		update			inclusion_cinetam_targets
		set				target_attendance = target_attendance + convert(int, ((convert(numeric(18,10), target_attendance) / @next_week_attendance) * @attendance_difference))
		where			inclusion_id = @inclusion_id
		and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
		and				screening_date = @next_screening_date

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error updating inclusion_cinetam_targets 5', 16, 1)
			rollback transaction
			return -1
		end
	end

	fetch tap_target_csr into @inclusion_id, @cinetam_reporting_demographics_id, @target_attendance, @next_screening_date, @next_week_attendance
end

 /*
  * Follow Film Targets
  */

declare			ff_target_csr cursor for
select			inc_ffilm_temp.inclusion_id,
				inc_ffilm_temp.movie_id,
				inc_ffilm_temp.cinetam_reporting_demographics_id,
				sum(inc_ffilm_temp.target_attendance) as this_week_target,
				next_week_temp.screening_date,
				sum(next_week_temp.target_attendance)
from			(select			inclusion_follow_film_targets.inclusion_id,
								inclusion_follow_film_targets.movie_id,
								inclusion_follow_film_targets.cinetam_reporting_demographics_id,
								sum(target_attendance) as target_attendance
				from			inclusion_follow_film_targets
				inner join		inclusion on inclusion_follow_film_targets.inclusion_id = inclusion.inclusion_id
				where			inclusion_follow_film_targets.screening_date = @screening_date
				and				inclusion.inclusion_status <> 'P'
				group by		inclusion_follow_film_targets.inclusion_id,
								inclusion_follow_film_targets.movie_id,
								inclusion_follow_film_targets.cinetam_reporting_demographics_id) as inc_ffilm_temp
inner join		(select			future_date.inclusion_id,
								future_date.movie_id,
								future_date.cinetam_reporting_demographics_id,
								min(future_date.screening_date) as next_screening_date
				from			inclusion_follow_film_targets future_date
				where			screening_date > @screening_date
				group by		future_date.inclusion_id,
								future_date.movie_id,
								future_date.cinetam_reporting_demographics_id) as next_week_date
on				inc_ffilm_temp.inclusion_id = next_week_date.inclusion_id
and				inc_ffilm_temp.movie_id = next_week_date.movie_id
and				inc_ffilm_temp.cinetam_reporting_demographics_id = next_week_date.cinetam_reporting_demographics_id
inner join		(select			future.inclusion_id,
								future.movie_id,
								future.cinetam_reporting_demographics_id,
								future.screening_date,
								sum(future.target_attendance) as target_attendance
				from			inclusion_follow_film_targets future
				group by		future.inclusion_id,
								future.movie_id,
								future.cinetam_reporting_demographics_id,
								future.screening_date) as next_week_temp
on				inc_ffilm_temp.inclusion_id = next_week_temp.inclusion_id
and				inc_ffilm_temp.movie_id = next_week_temp.movie_id
and				inc_ffilm_temp.cinetam_reporting_demographics_id = next_week_temp.cinetam_reporting_demographics_id
and				next_week_date.next_screening_date = next_week_temp.screening_date
group by		inc_ffilm_temp.inclusion_id,
				inc_ffilm_temp.movie_id,
				inc_ffilm_temp.cinetam_reporting_demographics_id,
				next_week_temp.screening_date
order by		inc_ffilm_temp.inclusion_id,
				inc_ffilm_temp.movie_id,
				inc_ffilm_temp.cinetam_reporting_demographics_id
for				read only

open ff_target_csr 
fetch ff_target_csr into @inclusion_id, @movie_id, @cinetam_reporting_demographics_id, @target_attendance, @next_screening_date, @next_week_attendance
while(@@FETCH_STATUS=0)
begin

	if @cinetam_reporting_demographics_id = 0
	begin
		select			@full_weekend_attendance = isnull(sum(full_attendance),0)
		from			movie_history_weekend
		where			movie_id = @movie_id
		and				screening_date = @screening_date
		and				certificate_group in (		select			certificate_group 
													from			inclusion_campaign_spot_xref, 
																	v_certificate_item_distinct, 
																	inclusion_spot
													where			inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
													and				inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id
													and				inclusion_spot.inclusion_id = @inclusion_id
													and				inclusion_spot.screening_date = @screening_date)

	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for FF', 16, 1)
			rollback transaction
			return -1
		end
	end
	else
	begin
		select			@full_weekend_attendance = isnull(sum(full_attendance),0)
		from			cinetam_movie_history_weekend
		where			movie_id = @movie_id
		and				cinetam_demographics_id in (select			cinetam_demographics_id 
													from			cinetam_reporting_demographics_xref 
													where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id) 
		and				screening_date = @screening_date
		and				certificate_group_id in (	select			certificate_group 
													from			inclusion_campaign_spot_xref, 
																	v_certificate_item_distinct, 
																	inclusion_spot
													where			inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
													and				inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id
													and				inclusion_spot.inclusion_id = @inclusion_id
													and				inclusion_spot.screening_date = @screening_date)

	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for FF', 16, 1)
			rollback transaction
			return -1
		end
	end

	select			@attendance_difference = isnull(@target_attendance, 0) - isnull(@full_weekend_attendance, 0)

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error calculating FF attendance dfference', 16, 1)
		rollback transaction
		return -1
	end

	insert into		cinetam_follow_film_weekend_adjsum
					(
						inclusion_id,
						screening_date,
						movie_id, 
						weekly_target,
						weekly_extrapolated_weekend,
						last_week_trueup_actuals,
						last_week_trueup_targets
					)		
	select			@inclusion_id,
					@screening_date,
					@movie_id,
					isnull(@target_attendance, 0),
					isnull(@full_weekend_attendance, 0),
					0,
					0

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error updating inclusion_cinetam_targets 6', 16, 1)
		rollback transaction
		return -1
	end

	if isnull(@attendance_difference,0) <> 0 and @next_week_attendance <> 0
	begin

		update			inclusion_follow_film_targets
		set				target_attendance = target_attendance + convert(int, ((convert(numeric(18,10), target_attendance) / @next_week_attendance) * @attendance_difference))
		where			screening_date = @next_screening_date
		and				movie_id = @movie_id
		and				inclusion_id = @inclusion_id
		and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error updating inclusion_cinetam_targets 7', 16, 1)
			rollback transaction
			return -1
		end
	end

	fetch ff_target_csr into @inclusion_id, @movie_id, @cinetam_reporting_demographics_id, @target_attendance, @next_screening_date, @next_week_attendance
end

/*
 * Update campaigns in their last scheduled week
 */

declare			ctam_actual_csr cursor for
select			inc_ctam_temp.inclusion_id,
				inc_ctam_temp.cinetam_reporting_demographics_id,
				inc_ctam_temp.max_screening_date as last_week
from			(select			inclusion_cinetam_targets.inclusion_id,
								inclusion_cinetam_targets.cinetam_reporting_demographics_id,
								max(screening_date) as max_screening_date
				from			inclusion_cinetam_targets
				inner join		inclusion on inclusion_cinetam_targets.inclusion_id = inclusion.inclusion_id
				where			inclusion_cinetam_targets.screening_date >= dateadd(wk, 1, @screening_date)
				and				inclusion.inclusion_status <> 'P'
				group by		inclusion_cinetam_targets.inclusion_id,
								inclusion_cinetam_targets.cinetam_reporting_demographics_id
				having			max(screening_date) = dateadd(wk, 1, @screening_date)	) as inc_ctam_temp
group by		inc_ctam_temp.inclusion_id,
				inc_ctam_temp.cinetam_reporting_demographics_id,
				inc_ctam_temp.max_screening_date
order by		inc_ctam_temp.inclusion_id,
				inc_ctam_temp.cinetam_reporting_demographics_id
for				read only

open ctam_actual_csr 
fetch ctam_actual_csr into @inclusion_id, @cinetam_reporting_demographics_id, @last_week
while(@@FETCH_STATUS=0)
begin


	if @cinetam_reporting_demographics_id = 0
	begin
		select			@last_actuals_week = max(screening_date),
						@first_actuals_week = min(screening_date),
						@attendance = isnull(sum(attendance),0)
		from			movie_history
		where			isnull(attendance, 0) != 0 
		and				certificate_group in (	select			certificate_group 
												from			inclusion_campaign_spot_xref, 
																v_certificate_item_distinct, 
																inclusion_spot
												where			inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
												and				inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id
												and				inclusion_spot.inclusion_id = @inclusion_id)

	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for MAPTAP', 16, 1)
			rollback transaction
			return -1
		end
	end
	else
	begin
		select			@last_actuals_week = max(screening_date),
						@first_actuals_week = min(screening_date),
						@attendance = isnull(sum(attendance),0)
		from			cinetam_movie_history
		where			isnull(attendance, 0) != 0 
		and				certificate_group_id in (select			certificate_group 
												from			inclusion_campaign_spot_xref, 
																v_certificate_item_distinct, 
																inclusion_spot
												where			inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
												and				inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id
												and				inclusion_spot.inclusion_id = @inclusion_id)		
		and				cinetam_demographics_id in (select			cinetam_demographics_id 
													from			cinetam_reporting_demographics_xref 
													where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id) 

	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for MAPTAP', 16, 1)
			rollback transaction
			return -1
		end
	end

	if @cinetam_reporting_demographics_id = 0
	begin
		select			@attendance = isnull(@attendance,0) + isnull(sum(full_attendance),0)
		from			movie_history_weekend
		where			isnull(attendance, 0) != 0 
		and				screening_date > @last_actuals_week
		and				certificate_group in (	select			certificate_group 
												from			inclusion_campaign_spot_xref, 
																v_certificate_item_distinct, 
																inclusion_spot
												where			inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
												and				inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id
												and				inclusion_spot.inclusion_id = @inclusion_id)

	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for MAPTAP', 16, 1)
			rollback transaction
			return -1
		end
	end
	else
	begin
		select			@attendance = isnull(@attendance,0) + isnull(sum(full_attendance),0)
		from			cinetam_movie_history_weekend
		where			isnull(attendance, 0) != 0 
		and				screening_date > @last_actuals_week
		and				certificate_group_id in (select			certificate_group 
												from			inclusion_campaign_spot_xref, 
																v_certificate_item_distinct, 
																inclusion_spot
												where			inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
												and				inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id
												and				inclusion_spot.inclusion_id = @inclusion_id)
		and				cinetam_demographics_id in (select			cinetam_demographics_id 
													from			cinetam_reporting_demographics_xref 
													where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id) 

	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for MAPTAP', 16, 1)
			rollback transaction
			return -1
		end
	end


	select			@target_attendance = sum(isnull(original_target_attendance, 0))
	from			inclusion_cinetam_targets
	where			inclusion_id = @inclusion_id
	and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error getting weekend numbers for MAPTAP', 16, 1)
		rollback transaction
		return -1
	end

	select			@attendance_difference = isnull(@target_attendance, 0) - isnull(@attendance, 0)

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error calculating MAPTAP attendance dfference', 16, 1)
		rollback transaction
		return -1
	end

	if @attendance_difference <= 0
		select			@attendance_difference = 910

	select			@attendance_difference = @attendance_difference * 1.1

	select			@row_check = count(*)
	from			cinetam_inclusion_weekend_adjsum
	where			inclusion_id = @inclusion_id
	and				screening_date = @screening_date

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error calculating MAPTAP attendance dfference', 16, 1)
		rollback transaction
		return -1
	end

	if isnull(@row_check, 0) = 0
	begin
		insert into		cinetam_inclusion_weekend_adjsum
						(
							inclusion_id,
							screening_date,
							weekly_target,
							weekly_extrapolated_weekend,
							last_week_trueup_actuals,
							last_week_trueup_targets
						)		
		select			@inclusion_id,
						@screening_date,
						0,
						0,
						isnull(@attendance, 0),
						isnull(@target_attendance, 0)

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error updating inclusion_cinetam_targets 8', 16, 1)
			rollback transaction
			return -1
		end
	end
	else
	begin
		update			cinetam_inclusion_weekend_adjsum
		set				last_week_trueup_actuals = isnull(@attendance,0),
						last_week_trueup_targets = isnull(@target_attendance,0)
		where			inclusion_id = @inclusion_id
		and				screening_date = @screening_date

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error updating inclusion_cinetam_targets 9', 16, 1)
			rollback transaction
			return -1
		end
	end

	if isnull(@attendance_difference,0) <> 0 and @target_attendance <> 0
	begin

		update			inclusion_cinetam_targets
		set				target_attendance = @attendance_difference * (temp_table.complex_total / @target_attendance)
		from			(select			complex_id,
										sum(original_target_attendance) as complex_total
						from			inclusion_cinetam_targets
						where			inclusion_cinetam_targets.inclusion_id = @inclusion_id
						and				inclusion_cinetam_targets.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
						group by		complex_id) as temp_table
		where			inclusion_cinetam_targets.screening_date = @last_week
		and				inclusion_cinetam_targets.inclusion_id = @inclusion_id
		and				inclusion_cinetam_targets.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
		and				temp_table.complex_id = inclusion_cinetam_targets.complex_id

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error updating inclusion_cinetam_targets 10', 16, 1)
			rollback transaction
			return -1
		end
	end

	fetch ctam_actual_csr into @inclusion_id, @cinetam_reporting_demographics_id, @last_week
end

declare			ffilm_actual_csr cursor for 
select			inc_ffilm_temp.inclusion_id,
				inc_ffilm_temp.cinetam_reporting_demographics_id,
				inc_ffilm_temp.movie_id,
				inc_ffilm_temp.max_screening_date as last_week
from			(select			inclusion_follow_film_targets.inclusion_id,
								inclusion_follow_film_targets.cinetam_reporting_demographics_id,
								inclusion_follow_film_targets.movie_id,
								max(screening_date) as max_screening_date
				from			inclusion_follow_film_targets
				inner join		inclusion on inclusion_follow_film_targets.inclusion_id = inclusion.inclusion_id
				where			inclusion_follow_film_targets.screening_date >= dateadd(wk, 1, @screening_date)
				and				inclusion.inclusion_status <> 'P'
				group by		inclusion_follow_film_targets.inclusion_id,
								inclusion_follow_film_targets.cinetam_reporting_demographics_id,
								inclusion_follow_film_targets.movie_id
				having			max(screening_date) = dateadd(wk, 1, @screening_date)	) as inc_ffilm_temp
group by		inc_ffilm_temp.inclusion_id,
				inc_ffilm_temp.cinetam_reporting_demographics_id,
				inc_ffilm_temp.movie_id,
				inc_ffilm_temp.max_screening_date
order by		inc_ffilm_temp.inclusion_id,
				cinetam_reporting_demographics_id
for				read only

open ffilm_actual_csr 
fetch ffilm_actual_csr into @inclusion_id, @cinetam_reporting_demographics_id, @movie_id, @last_week
while(@@FETCH_STATUS=0)
begin

	if @cinetam_reporting_demographics_id = 0
	begin
		select			@last_actuals_week = max(screening_date),
						@first_actuals_week = min(screening_date),
						@attendance = isnull(sum(attendance),0)
		from			movie_history
		where			isnull(attendance, 0) != 0 
		and				movie_id = @movie_id
		and				certificate_group in (	select			certificate_group 
												from			inclusion_campaign_spot_xref, 
																v_certificate_item_distinct, 
																inclusion_spot
												where			inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
												and				inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id
												and				inclusion_spot.inclusion_id = @inclusion_id)

	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for FF', 16, 1)
			rollback transaction
			return -1
		end
	end
	else
	begin
		select			@last_actuals_week = max(screening_date),
						@first_actuals_week = min(screening_date),
						@attendance = isnull(sum(attendance),0)
		from			cinetam_movie_history
		where			isnull(attendance, 0) != 0 
		and				movie_id = @movie_id
		and				certificate_group_id in (select			certificate_group 
												from			inclusion_campaign_spot_xref, 
																v_certificate_item_distinct, 
																inclusion_spot
												where			inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
												and				inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id
												and				inclusion_spot.inclusion_id = @inclusion_id)		
		and				cinetam_demographics_id in (select			cinetam_demographics_id 
													from			cinetam_reporting_demographics_xref 
													where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id) 

	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for FF', 16, 1)
			rollback transaction
			return -1
		end
	end

	if @cinetam_reporting_demographics_id = 0
	begin
		select			@attendance = isnull(@attendance,0) + isnull(sum(full_attendance),0)
		from			movie_history_weekend
		where			isnull(attendance, 0) != 0 
		and				movie_id = @movie_id
		and				screening_date > @last_actuals_week
		and				certificate_group in (	select			certificate_group 
												from			inclusion_campaign_spot_xref, 
																v_certificate_item_distinct, 
																inclusion_spot
												where			inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
												and				inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id
												and				inclusion_spot.inclusion_id = @inclusion_id)

	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for FF', 16, 1)
			rollback transaction
			return -1
		end
	end
	else
	begin
		select			@attendance = isnull(@attendance,0) + isnull(sum(full_attendance),0)
		from			cinetam_movie_history_weekend
		where			isnull(attendance, 0) != 0 
		and				movie_id = @movie_id
		and				screening_date > @last_actuals_week
		and				certificate_group_id in (select			certificate_group 
												from			inclusion_campaign_spot_xref, 
																v_certificate_item_distinct, 
																inclusion_spot
												where			inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
												and				inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id
												and				inclusion_spot.inclusion_id = @inclusion_id)
		and				cinetam_demographics_id in (select			cinetam_demographics_id 
													from			cinetam_reporting_demographics_xref 
													where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id) 

	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error getting weekend numbers for FF', 16, 1)
			rollback transaction
			return -1
		end
	end


	select			@target_attendance = sum(isnull(original_target_attendance, 0))
	from			inclusion_follow_film_targets
	where			inclusion_id = @inclusion_id
	and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				movie_id = @movie_id

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error getting weekend numbers for FF', 16, 1)
		rollback transaction
		return -1
	end

	select			@attendance_difference = isnull(@target_attendance, 0) - isnull(@attendance, 0)

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error calculating FF attendance dfference', 16, 1)
		rollback transaction
		return -1
	end

	if @attendance_difference <= 0
		select			@attendance_difference = 910


	select			@attendance_difference = @attendance_difference * 1.1

	select			@row_check = count(*)
	from			cinetam_follow_film_weekend_adjsum
	where			inclusion_id = @inclusion_id
	and				screening_date = @screening_date
	and				movie_id = @movie_id

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error calculating FF attendance dfference', 16, 1)
		rollback transaction
		return -1
	end

	if isnull(@row_check, 0) = 0
	begin
		insert into		cinetam_follow_film_weekend_adjsum
						(
							inclusion_id,
							screening_date,
							movie_id,
							weekly_target,
							weekly_extrapolated_weekend,
							last_week_trueup_actuals,
							last_week_trueup_targets
						)		
		select			@inclusion_id,
						@screening_date,
						@movie_id,
						0,
						0,
						isnull(@attendance, 0),
						isnull(@target_attendance, 0)

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error updating inclusion_cinetam_targets 1', 16, 1)
			rollback transaction
			return -1
		end
	end
	else
	begin
		update			cinetam_follow_film_weekend_adjsum
		set				last_week_trueup_actuals = isnull(@attendance,0),
						last_week_trueup_targets = isnull(@target_attendance,0)
		where			inclusion_id = @inclusion_id
		and				screening_date = @screening_date
		and				movie_id = @movie_id

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error updating inclusion_cinetam_targets 2', 16, 1)
			rollback transaction
			return -1
		end
	end

	if isnull(@attendance_difference,0) <> 0 and @target_attendance <> 0
	begin

		update			inclusion_follow_film_targets
		set				target_attendance = @attendance_difference * (temp_table.complex_total / @target_attendance)
		from			(select			complex_id,
										sum(original_target_attendance) as complex_total
						from			inclusion_follow_film_targets
						where			inclusion_follow_film_targets.inclusion_id = @inclusion_id
						and				inclusion_follow_film_targets.movie_id = @movie_id
						and				inclusion_follow_film_targets.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
						group by		complex_id) as temp_table
		where			inclusion_follow_film_targets.screening_date = @last_week
		and				inclusion_follow_film_targets.inclusion_id = @inclusion_id
		and				inclusion_follow_film_targets.movie_id = @movie_id
		and				inclusion_follow_film_targets.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
		and				inclusion_follow_film_targets.complex_id = temp_table.complex_id

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error updating inclusion_cinetam_targets 3', 16, 1)
			rollback transaction
			return -1
		end
	end

	fetch ffilm_actual_csr into @inclusion_id, @cinetam_reporting_demographics_id, @movie_id, @last_week
end

/*
 * Store summary information
 */

delete			inclusion_cinetam_attendance_weekend
where			screening_date = @screening_date
	
select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Delete inclusion_cinetam_attendance_weekend. Close denied.', 16, 1)
	rollback transaction
	return -1
end

insert into		inclusion_cinetam_attendance_weekend
select			inclusion_id,
				campaign_no,
				screening_date,
				cinetam_reporting_demographics_id,
				movie_id,
				isnull(attendance,0),
				isnull(full_attendance,0) 
from			v_inclusion_cinetam_attendance_weekend
where			screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Update film_screening_dates. Close denied.', 16, 1)
	rollback transaction
	return -1
end

						 
/*
 * Update Attendance Status
 */

update			film_screening_dates
set				weekend_attendance_status = 'X'
where 			screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Load Attendance Screening Date information. Close denied.', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
