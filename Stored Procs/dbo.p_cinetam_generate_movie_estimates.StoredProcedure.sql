/****** Object:  StoredProcedure [dbo].[p_cinetam_generate_movie_estimates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_generate_movie_estimates]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_generate_movie_estimates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





create proc [dbo].[p_cinetam_generate_movie_estimates]		@movie_id				int,
															@country_code			char(1),
															@alternate_start_date	datetime

as 

declare			@error							int,
				@count_movie_match				int,
				@count_movie_group				int,
				@count_movie_category			int,
				@count_release_date				int,
				@count_alternate_date			int,
				@count_stagger_date				int,
				@record_exists					int,
				@screening_date					datetime,
				@complex_id						int,
				@required_weeks					int,
				@decline_rate					numeric(6,4),
				@release_date					datetime,
				@alternate_release_date			datetime,
				@film_market_no					int,
				@matched_release_date			datetime,
				@matched_movie_id				int,
				@matched_movie_group			int,
				@match_movie_category_code		char(2),
				@alternate_release_id			int,
				@alternate_release_mode_id		int,
				@preview_release_count			int,
				@preview_release_id				int,
				@main_release_date				datetime
				
set nocount on

select			@required_weeks = 4


select			@decline_rate  = convert(numeric(6,4), parameter_int) / 100.0000
from			dbo.system_parameters
where			parameter_name = 'ctam_est_dec_rate'

select			@count_movie_match = count(*)
from			cinetam_movie_matches
where			movie_id = @movie_id
and				country_code = @country_code

select			@count_movie_group = count(*)
from			cinetam_movie_match_group_xref 
where			movie_id = @movie_id
and				country_code = @country_code

select			@count_movie_category = count(*)
from			cinetam_movie_category_match
where			movie_id = @movie_id
and				country_code = @country_code


create table #temp_stagger_release
(
	alternate_release_id				int				not null,
	movie_id							int				not null,
	country_code						char(1)			not null,
	release_date						datetime		not null,
	alternate_release_mode_id			int				not null
)

create table #temp_stagger_details
(
	alternate_release_id				int				not null,
	film_market_no						int				not null,
	screening_date						datetime		not null,
	actual_start_date					datetime		not null,
	week_percentage						numeric(6,4)	not null
)

create table #temp_estimates
(
	movie_id							int				not null,
	cinetam_reporting_demographics_id	int				not null,
	screening_date						datetime		not null,
	complex_id							int				not null,
	attendance							int				not null,
	original_estimate					int				not null
)

create table #temp_estimates_preview_store
(
	movie_id							int				not null,
	cinetam_reporting_demographics_id	int				not null,
	screening_date						datetime		not null,
	complex_id							int				not null,
	attendance							int				not null,
	original_estimate					int				not null
)

if @count_movie_match + @count_movie_group + @count_movie_category > 1
begin
	raiserror ('You may only match to one matching method.  Please delete either the matched movie or the matched group or matched category so that only the desired one is left', 16, 1)
	return -1
end

if @count_movie_match + @count_movie_group + @count_movie_category = 0
begin
	raiserror ('What am I supposed to randomly create estimates based on the solar cycle of the werewolf lunar repercussive changes??  Please create a cinetam match for this movie so I am able to generate estimates.', 16, 1)
	return -1
end

select			@count_release_date = count(*),
				@release_date = release_date
from			movie_country 
where			movie_id = @movie_id
and				country_code = @country_code
group by		release_date

if @count_release_date != 1
begin
	raiserror ('You must select a release date for this country.', 16, 1)
	return -1
end

select			@count_stagger_date = count(alternate_release_id)
from			movie_country_alternate_release
where			movie_id = @movie_id
and				country_code = @country_code
and				alternate_release_mode_id = 1

if @count_stagger_date > 1 
begin
	raiserror ('You can only have 1 staggered release per country.', 16, 1)
	return -1
end

select			@preview_release_count = count(alternate_release_id)
from			movie_country_alternate_release
where			movie_id = @movie_id
and				country_code = @country_code
and				alternate_release_mode_id = 3

if @preview_release_count > 1 
begin
	raiserror ('You can only have 1 preview release per country.', 16, 1)
	return -1
end

if @preview_release_count = 1
begin
	select			@preview_release_id = alternate_release_id
	from			movie_country_alternate_release
	where			movie_id = @movie_id
	and				country_code = @country_code
	and				alternate_release_mode_id = 3

	if @preview_release_count > 1 
	begin
		raiserror ('Failed to get preview release id country.', 16, 1)
		return -1
	end
end

if @count_stagger_date = 0
begin
	insert into		#temp_stagger_release
	select			-100,
					movie_country.movie_id,
					movie_country.country_code, 
					release_date,
					1
	from			movie_country
	where			movie_id = @movie_id
	and				movie_country.country_code = @country_code

	insert into		#temp_stagger_details
	select			-100,
					film_market_no,
					release_date,
					movie_country.intial_release,
					1.0
	from			movie_country
	inner join		film_market on movie_country.country_code = film_market.country_code
	where			movie_country.movie_id = @movie_id
	and				movie_country.country_code = @country_code
	and				film_market.film_market_no <> 20
end

select			@count_alternate_date = count(alternate_release_id)
from			movie_country_alternate_release
where			movie_id = @movie_id
and				country_code = @country_code
and				alternate_release_mode_id >= 2

if @count_stagger_date > 0 or @count_alternate_date > 0
begin
	insert into		#temp_stagger_release
	select			alternate_release_id,
					movie_id,
					country_code,
					release_date,
					alternate_release_mode_id
	from			movie_country_alternate_release mcar
	where			movie_id = @movie_id
	and				country_code = @country_code

	insert into		#temp_stagger_details
	select			mcad.alternate_release_id,
					film_market_no,
					screening_date,
					actual_start_date,
					week_percentage
	from			movie_country_alternate_release mcar
	inner join		movie_country_alternate_details mcad on mcar.alternate_release_id = mcad.alternate_release_id
	where			movie_id = @movie_id
	and				country_code = @country_code
end

if @count_movie_match > 0 
begin
	select			@matched_release_date = release_date
	from			movie_country
	inner join		cinetam_movie_matches on movie_country.movie_id = cinetam_movie_matches.matched_movie_id and movie_country.country_code = cinetam_movie_matches.country_code
	where			cinetam_movie_matches.movie_id = @movie_id 
	and				cinetam_movie_matches.country_code = @country_code
end

if @count_movie_group > 0
begin
	select		@matched_movie_group = cinetam_movie_match_group_id
	from		cinetam_movie_match_group_xref 
	where		movie_id = @movie_id
	and			country_code = @country_code
end

if @count_movie_category > 0
begin
	select		@match_movie_category_code = movie_category_code
	from		cinetam_movie_category_match
	where		movie_id = @movie_id
	and			country_code = @country_code
end

begin transaction

delete			cmce
from			cinetam_movie_complex_estimates cmce
inner join		complex as c on c.complex_id = cmce.complex_id
inner join		state as s on s.state_code = c.state_code
where			movie_id = @movie_id
and				s.country_code = @country_code
and				screening_date >= @alternate_start_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting existing movies estimate records', 16, 1)
	rollback transaction
	return -1
end

delete			cinetam_movie_estimates
where			movie_id = @movie_id
and				country_code = @country_code

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting existing movies estimate records', 16, 1)
	rollback transaction
	return -1
end

declare			alternate_release_csr cursor for
select			distinct mcar.alternate_release_id,
				mcar.alternate_release_mode_id,
				mcar.release_date
from			#temp_stagger_release mcar
inner join		#temp_stagger_details mcad on mcar.alternate_release_id = mcad.alternate_release_id
where			screening_date >= @alternate_start_date
and				movie_id = @movie_id
and				country_code = @country_code
order by		alternate_release_mode_id desc
for				read only

open alternate_release_csr
fetch alternate_release_csr into @alternate_release_id, @alternate_release_mode_id, @alternate_release_date
while(@@FETCH_STATUS=0)
begin

	if @alternate_release_mode_id = 3 
	begin
		select			@required_weeks  = datediff(wk, @alternate_release_date, @release_date)
		if @required_weeks > 4
			select @required_weeks = 4
	end
	else
	begin
		select			@required_weeks  = 4
	end
		
	if @count_movie_match > 0 
	begin
		insert into		#temp_estimates
		select			cinetam_movie_matches.movie_id, 
						cinetam_reporting_demographics_id, 
						dateadd(wk, datediff(wk, @matched_release_date, v_ctam_mov_hist.screening_date), @release_date) as actual_week, 
						v_ctam_mov_hist.complex_id, 
						round((sum(attendance * (curr_cplx_date.cinatt_weighting / prev_cplx_date.cinatt_weighting)) * adjustment_factor), 0) as attendance,
						round((sum(attendance * (curr_cplx_date.cinatt_weighting / prev_cplx_date.cinatt_weighting)) * adjustment_factor), 0)
		from			v_cinetam_movie_history_reporting_demos v_ctam_mov_hist 
		inner join 		cinetam_movie_matches on v_ctam_mov_hist.movie_id = cinetam_movie_matches.matched_movie_id 
		and				v_ctam_mov_hist.country = cinetam_movie_matches.country_code
		inner join		complex_date curr_cplx_date on v_ctam_mov_hist.complex_id = curr_cplx_date.complex_id and dateadd(wk, datediff(wk, @matched_release_date, v_ctam_mov_hist.screening_date), @release_date) = curr_cplx_date.screening_date
		inner join		complex_date prev_cplx_date on v_ctam_mov_hist.complex_id = prev_cplx_date.complex_id and v_ctam_mov_hist.screening_date = prev_cplx_date.screening_date
		inner join		complex on v_ctam_mov_hist.complex_id = complex.complex_id and complex.film_complex_status <> 'C'
		where			cinetam_movie_matches.movie_id = @movie_id
		and				v_ctam_mov_hist.country = @country_code
		and				cinetam_movie_matches.country_code = @country_code
		and				v_ctam_mov_hist.country = cinetam_movie_matches.country_code
		and				(dateadd(wk, datediff(wk, @matched_release_date, v_ctam_mov_hist.screening_date), @release_date)) in (select screening_date from film_screening_dates)
		and				(dateadd(wk, datediff(wk, @matched_release_date, v_ctam_mov_hist.screening_date), @release_date)) between @release_date and dateadd(wk, @required_weeks - 1, @release_date)		
		and				prev_cplx_date.cinatt_weighting <> 0
		group by		cinetam_movie_matches.movie_id, 
						cinetam_reporting_demographics_id, 
						v_ctam_mov_hist.screening_date,
						v_ctam_mov_hist.complex_id,
						v_ctam_mov_hist.movie_id,
						v_ctam_mov_hist.country,
						cinetam_movie_matches.matched_movie_id ,
						adjustment_factor 
	end
	else if @count_movie_group > 0
	begin
		insert into		#temp_estimates
		select			v_xref.movie_id,
						temp_table.cinetam_reporting_demographics_id,
						dateadd(wk, actual_week, @release_date) as actual_date,
						temp_table.complex_id,
						avg(attendance * curr_cplx_date.cinatt_weighting) * v_xref.adjustment_factor as avg_attendance,
						avg(attendance * curr_cplx_date.cinatt_weighting) * v_xref.adjustment_factor 
		from			cinetam_movie_match_group_xref v_xref,
						(select			v_ctam_mov_hist.movie_id,
										cinetam_reporting_demographics_id, 
										datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_match_group_xref.movie_id and country_code = v_ctam_mov_hist.country), screening_date) as actual_week, 
										v_ctam_mov_hist.complex_id, 
										round(sum(attendance), 0) as attendance,
										cinetam_movie_match_group_id,
										v_ctam_mov_hist.country
						from			v_cinetam_movie_history_reporting_demos v_ctam_mov_hist 
						inner join		cinetam_movie_match_group_xref on v_ctam_mov_hist.movie_id = cinetam_movie_match_group_xref.movie_id 
						inner join		complex on v_ctam_mov_hist.complex_id = complex.complex_id and film_complex_status <> 'C'
						where			v_ctam_mov_hist.country = @country_code
						and				cinetam_movie_match_group_xref.country_code = @country_code
						and				v_ctam_mov_hist.country = cinetam_movie_match_group_xref.country_code
						and				cinetam_movie_match_group_xref.cinetam_movie_match_group_id = @matched_movie_group
						and				v_ctam_mov_hist.screening_date between '1-mar-2017' and '1-mar-2020'
						group by		v_ctam_mov_hist.movie_id, 
										cinetam_movie_match_group_xref.movie_id,
										v_ctam_mov_hist.country,
										cinetam_reporting_demographics_id, 
										v_ctam_mov_hist.screening_date,
										v_ctam_mov_hist.complex_id,
										cinetam_movie_match_group_id,
										v_ctam_mov_hist.country) as temp_table
		inner join		complex_date curr_cplx_date on temp_table.complex_id = curr_cplx_date.complex_id and dateadd(wk, actual_week, @release_date) = curr_cplx_date.screening_date
		where 			v_xref.cinetam_movie_match_group_id = temp_table.cinetam_movie_match_group_id
		and				v_xref.movie_id <> temp_table.movie_id 
		and				v_xref.movie_id = @movie_id
		and				v_xref.country_code = @country_code
		and 			actual_week between 0 and @required_weeks - 1
		group by		v_xref.movie_id, 
						temp_table.cinetam_reporting_demographics_id, 
						actual_week, 
						temp_table.country, 
						temp_table.complex_id,
						v_xref.adjustment_factor 
	end
	else if @count_movie_category > 0
	begin
		insert into		#temp_estimates
		select			@movie_id,
						temp_table.cinetam_reporting_demographics_id,
						dateadd(wk, actual_week, @release_date) as actual_date,
						temp_table.complex_id,
						avg(attendance * curr_cplx_date.cinatt_weighting) * cmcm.adjustment_factor as avg_attendance,
						avg(attendance * curr_cplx_date.cinatt_weighting) * cmcm.adjustment_factor
		from			cinetam_movie_category_match cmcm
		inner join		(select			v_ctam_mov_hist.movie_id,
										cinetam_reporting_demographics_id, 
										datediff(wk, (select release_date from movie_country where movie_id = v_ctam_mov_hist.movie_id and country_code = v_ctam_mov_hist.country), screening_date) as actual_week, 
										v_ctam_mov_hist.complex_id, 
										round(sum(attendance), 0) as attendance,
										movie_category_code,
										v_ctam_mov_hist.country
						from			v_cinetam_movie_history_reporting_demos v_ctam_mov_hist 
						inner join		target_categories tgtcat on v_ctam_mov_hist.movie_id = tgtcat.movie_id 
						inner join		complex on v_ctam_mov_hist.complex_id = complex.complex_id and film_complex_status <> 'C'
						where			v_ctam_mov_hist.country = @country_code
						and				tgtcat.movie_category_code = @match_movie_category_code
						and				v_ctam_mov_hist.screening_date between '1-mar-2017' and '1-mar-2020'
						group by		v_ctam_mov_hist.movie_id, 
										v_ctam_mov_hist.country,
										cinetam_reporting_demographics_id, 
										v_ctam_mov_hist.screening_date,
										v_ctam_mov_hist.complex_id,
										movie_category_code,
										v_ctam_mov_hist.country) as temp_table
		on				cmcm.movie_category_code = temp_table.movie_category_code
		and				cmcm.country_code = temp_table.country
		inner join		complex_date curr_cplx_date on temp_table.complex_id = curr_cplx_date.complex_id and dateadd(wk, actual_week, @release_date) = curr_cplx_date.screening_date
		where 			actual_week between 0 and @required_weeks - 1
		and				cmcm.movie_id = @movie_id
		and				cmcm.country_code = @country_code
		group by		temp_table.cinetam_reporting_demographics_id, 
						actual_week, 
						dateadd(wk, actual_week, @release_date),
						temp_table.country, 
						temp_table.complex_id,
						cmcm.adjustment_factor 
	end

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting phase 1 estimates', 16, 1)
		rollback transaction
		return -1
	end	

	--insert missing information using film market averages
	insert into		#temp_estimates
	select			missing_table.movie_id, 
					missing_table.cinetam_reporting_demographics_id, 
					missing_table.screening_date, 
					missing_table.complex_id,
					avg_table.avg_attendance * cplx_date.cinatt_weighting,
					avg_table.avg_original_estimate * cplx_date.cinatt_weighting
	from			(select			truth_table.movie_id, 
									truth_table.cinetam_reporting_demographics_id, 
									truth_table.screening_date, 
									truth_table.complex_id, 
									estimate_table.movie_id as missing_movie_id, 
									estimate_table.cinetam_reporting_demographics_id as missing_cinetam_reporting_demographics_id, 
									estimate_table.screening_date as missing_screening_date, 
									estimate_table.complex_id as missing_complex_id 
					from			(select			movie_id, 
													cinetam_reporting_demographics_id, 
													screening_date, 
													complex_id 
									from			movie_country mc
									inner join		film_screening_dates fsd on	fsd.screening_date between mc.release_date and dateadd(wk, @required_weeks - 1, mc.release_date)
									inner join		branch on mc.country_code = branch.country_code
									inner join		complex on branch.branch_code = complex.branch_code
									cross join		cinetam_reporting_demographics
									where			movie_id = @movie_id
									and				mc.country_code = @country_code
									and				film_complex_status <> 'C'
									and				complex.complex_id not in (1,2)) as truth_table
									left outer join (select			movie_id, 
																	cinetam_reporting_demographics_id, 
																	screening_date, 
																	complex_id 
													from			#temp_estimates 
													where			movie_id = @movie_id ) as estimate_table
									on				truth_table.movie_id = estimate_table.movie_id
									and				truth_table.cinetam_reporting_demographics_id = estimate_table.cinetam_reporting_demographics_id
									and				truth_table.screening_date = estimate_table.screening_date
									and				truth_table.complex_id = estimate_table.complex_id) as missing_table
	inner join		complex on missing_table.complex_id = complex.complex_id
	inner join		(select			movie_id, 
									film_market_no, 
									cinetam_reporting_demographics_id,
									screening_date,
									avg(attendance) as avg_attendance,
									avg(original_estimate) as avg_original_estimate
					from			#temp_estimates
					inner join		complex on #temp_estimates.complex_id = complex.complex_id
					where			movie_id = @movie_id
					group by		movie_id, 
									film_market_no, 
									cinetam_reporting_demographics_id,
									screening_date) as avg_table
	on				missing_table.movie_id  = avg_table.movie_id
	and				complex.film_market_no  = avg_table.film_market_no
	and				missing_table.screening_date  = avg_table.screening_date
	and				missing_table.cinetam_reporting_demographics_id  = avg_table.cinetam_reporting_demographics_id
	inner join		complex_date cplx_date on missing_table.complex_id = cplx_date.complex_id and missing_table.screening_date = cplx_date.screening_date
	where			missing_movie_id is null
	and				missing_complex_id is null
	and				missing_cinetam_reporting_demographics_id is null
	and				missing_screening_date is null

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting consolidated estimates - market', 16, 1)
		rollback transaction
		return -1
	end
	
	--insert missing information using country averages
	insert into		#temp_estimates
	select			missing_table.movie_id, 
					missing_table.cinetam_reporting_demographics_id, 
					missing_table.screening_date, 
					missing_table.complex_id,
					avg_table.avg_attendance * cplx_date.cinatt_weighting,
					avg_table.avg_original_estimate * cplx_date.cinatt_weighting
	from			(select			truth_table.movie_id, 
									truth_table.cinetam_reporting_demographics_id, 
									truth_table.screening_date, 
									truth_table.complex_id, 
									estimate_table.movie_id as missing_movie_id, 
									estimate_table.cinetam_reporting_demographics_id as missing_cinetam_reporting_demographics_id, 
									estimate_table.screening_date as missing_screening_date, 
									estimate_table.complex_id as missing_complex_id 
					from			(select			movie_id, 
													cinetam_reporting_demographics_id, 
													screening_date, 
													complex_id 
									from			movie_country mc
									inner join		film_screening_dates fsd on fsd.screening_date between mc.release_date and dateadd(wk, @required_weeks - 1, mc.release_date)
									inner join		branch on mc.country_code = branch.country_code
									inner join		complex on branch.branch_code = complex.branch_code
									cross join		cinetam_reporting_demographics
									where			movie_id = @movie_id
									and				mc.country_code = @country_code
									and				film_complex_status <> 'C'
									and				complex.complex_id not in (1,2)) as truth_table
									left outer join (select			movie_id, 
																	cinetam_reporting_demographics_id, 
																	screening_date, 
																	complex_id 
													from			#temp_estimates 
													where			movie_id = @movie_id ) as estimate_table
									on				truth_table.movie_id = estimate_table.movie_id
									and				truth_table.cinetam_reporting_demographics_id = estimate_table.cinetam_reporting_demographics_id
									and				truth_table.screening_date = estimate_table.screening_date
									and				truth_table.complex_id = estimate_table.complex_id) as missing_table
	inner join		(select			movie_id, 
									cinetam_reporting_demographics_id,
									screening_date,
									avg(attendance) as avg_attendance,
									avg(original_estimate) as avg_original_estimate
					from			#temp_estimates
					inner join		complex on #temp_estimates.complex_id = complex.complex_id
					inner join		branch on complex.branch_code = branch.branch_code
					where			movie_id = @movie_id
					and				country_code = @country_code
					group by		movie_id, 
									cinetam_reporting_demographics_id,
									screening_date) as avg_table
	on				missing_table.movie_id  = avg_table.movie_id
	and				missing_table.screening_date  = avg_table.screening_date
	and				missing_table.cinetam_reporting_demographics_id  = avg_table.cinetam_reporting_demographics_id
	inner join		complex_date cplx_date on missing_table.complex_id = cplx_date.complex_id and missing_table.screening_date = cplx_date.screening_date
	where			missing_movie_id is null
	and				missing_complex_id is null
	and				missing_cinetam_reporting_demographics_id is null
	and				missing_screening_date is null

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting consolidated estimates - country', 16, 1)
		rollback transaction
		return -1
	end

	delete			#temp_estimates
	from			complex,
					branch	
	where			#temp_estimates.complex_id = complex.complex_id
	and				complex.branch_code = branch.branch_code
	and				#temp_estimates.movie_id = @movie_id
	and				(film_complex_status = 'C'
	or				#temp_estimates.complex_id in (1,2))
	and				country_code = @country_code

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error deleting closed complexes', 16, 1)
		rollback transaction
		return -1
	end

	/*delete			#temp_estimates
	from			complex,
					branch	
	where			#temp_estimates.complex_id = complex.complex_id
	and				complex.branch_code = branch.branch_code
	and				#temp_estimates.movie_id = @movie_id
	and				screening_date > DATEADD(wk, @required_weeks - 1, @release_date)
	and				country_code = @country_code

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error deleting all weeks after week 8', 16, 1)
		rollback transaction
		return -1
	end*/
	
	insert into		#temp_estimates
	select			movie_id,
					cinetam_reporting_demographics_id,
					screening_dates.screening_date,
					#temp_estimates.complex_id,
					round(attendance * power(0.900000000, DATEDIFF(WK, #temp_estimates.screening_date, screening_dates.screening_date)),0),
					round(original_estimate * power(0.900000000, DATEDIFF(WK, #temp_estimates.screening_date, screening_dates.screening_date)),0)
	from			#temp_estimates,
					complex,
					branch,
					(select			screening_date
					from			film_screening_dates
					where			screening_date between DATEADD(wk, @required_weeks, @release_date) and DATEADD(wk, 9, @release_date)) as screening_dates
	where			#temp_estimates.complex_id = complex.complex_id
	and				complex.branch_code = branch.branch_code
	and				#temp_estimates.movie_id = @movie_id
	and				#temp_estimates.screening_date = DATEADD(wk, @required_weeks - 1, @release_date)
	and				country_code = @country_code

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting all weeks after week 8', 16, 1)
		rollback transaction
		return -1
	end

--	select * from #temp_estimates order by cinetam_reporting_demographics_id, complex_id, screening_date
	
	if @alternate_release_mode_id = 3 
	begin
		delete			#temp_estimates
		from			complex,
						branch	
		where			#temp_estimates.complex_id = complex.complex_id
		and				complex.branch_code = branch.branch_code
		and				#temp_estimates.movie_id = @movie_id
		and				screening_date > DATEADD(wk, datediff(wk, @alternate_release_date, @release_date) - 1, @release_date)
		and				country_code = @country_code

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error deleting all weeks after week 8', 16, 1)
			rollback transaction
			return -1
		end
	end

	if @alternate_release_id <> -100
	begin

		--select * from #temp_estimates

		update		#temp_estimates
		set			#temp_estimates.screening_date = dateadd(wk, datediff(wk, @release_date, mcar.release_date), #temp_estimates.screening_date)
		from		#temp_estimates
		inner join	complex c on #temp_estimates.complex_id = c.complex_id
		inner join	#temp_stagger_details mcad on c.film_market_no = mcad.film_market_no
		inner join  #temp_stagger_release mcar on mcad.alternate_release_id = mcar.alternate_release_id
		where		mcar.alternate_release_id = @alternate_release_id

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error inserting all weeks after week 8', 16, 1)
			rollback transaction
			return -1
		end

		--select * from #temp_estimates
		
		update		#temp_estimates
		set			#temp_estimates.screening_date = dateadd(wk, datediff(wk, mcar.release_date, mcad.screening_date), #temp_estimates.screening_date)
		from		#temp_estimates
		inner join	complex c on #temp_estimates.complex_id = c.complex_id
		inner join	#temp_stagger_details mcad on c.film_market_no = mcad.film_market_no
		inner join  #temp_stagger_release mcar on mcad.alternate_release_id = mcar.alternate_release_id
		where		mcar.alternate_release_id = @alternate_release_id

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error inserting all weeks after week 8', 16, 1)
			rollback transaction
			return -1
		end
		
		--select * from #temp_estimates

		insert into	#temp_estimates
		select		#temp_estimates.movie_id,
					cinetam_reporting_demographics_id,
					dateadd(wk, -1, #temp_estimates.screening_date),
					#temp_estimates.complex_id,
					#temp_estimates.attendance,
					#temp_estimates.original_estimate
		from		#temp_estimates
		inner join	complex c on #temp_estimates.complex_id = c.complex_id
		inner join	#temp_stagger_details mcad on c.film_market_no = mcad.film_market_no
		inner join  #temp_stagger_release mcar on mcad.alternate_release_id = mcar.alternate_release_id
		where		mcar.alternate_release_id = @alternate_release_id
		and			mcad.screening_date <> mcad.actual_start_date
		and			mcad.screening_date = #temp_estimates.screening_date
		and			mcar.alternate_release_mode_id = 1

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error inserting all weeks after week 8', 16, 1)
			rollback transaction
			return -1
		end
		
		update		#temp_estimates
		set			#temp_estimates.screening_date = dateadd(wk, 1, #temp_estimates.screening_date)
		from		#temp_estimates
		inner join	complex c on #temp_estimates.complex_id = c.complex_id
		inner join	#temp_stagger_details mcad on c.film_market_no = mcad.film_market_no
		inner join  #temp_stagger_release mcar on mcad.alternate_release_id = mcar.alternate_release_id
		where		mcar.alternate_release_id = @alternate_release_id
		and			mcad.screening_date <> mcad.actual_start_date
		and			mcar.alternate_release_mode_id = 1

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error inserting all weeks after week 8', 16, 1)
			rollback transaction
			return -1
		end
		
		update		#temp_estimates
		set			#temp_estimates.attendance = round(#temp_estimates.attendance * week_percentage,0),
					#temp_estimates.original_estimate = round(#temp_estimates.original_estimate * week_percentage,0)
		from		#temp_estimates
		inner join	complex c on #temp_estimates.complex_id = c.complex_id
		inner join	#temp_stagger_details mcad on c.film_market_no = mcad.film_market_no
		inner join  #temp_stagger_release mcar on mcad.alternate_release_id = mcar.alternate_release_id
		where		mcar.alternate_release_id = @alternate_release_id
		and			mcad.screening_date <> mcad.actual_start_date
		and			mcad.screening_date = #temp_estimates.screening_date
		and			mcar.alternate_release_mode_id = 1

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error inserting all weeks after week 8', 16, 1)
			rollback transaction
			return -1
		end
		
		update		#temp_estimates
		set			#temp_estimates.attendance = round(#temp_estimates.attendance * (1 - week_percentage),0),
					#temp_estimates.original_estimate = round(#temp_estimates.original_estimate * (1 - week_percentage),0)
		from		#temp_estimates
		inner join	complex c on #temp_estimates.complex_id = c.complex_id
		inner join	#temp_stagger_details mcad on c.film_market_no = mcad.film_market_no
		inner join  #temp_stagger_release mcar on mcad.alternate_release_id = mcar.alternate_release_id
		where		mcar.alternate_release_id = @alternate_release_id
		and			mcad.screening_date <> mcad.actual_start_date
		and			dateadd(wk, 1, mcad.screening_date) = #temp_estimates.screening_date
		and			mcar.alternate_release_mode_id = 1

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error inserting all weeks after week 8', 16, 1)
			rollback transaction
			return -1
		end
		
		update			#temp_estimates
		set				#temp_estimates.attendance = round(#temp_estimates.attendance * (week_percentage),0),
						#temp_estimates.original_estimate = round(#temp_estimates.original_estimate * (week_percentage),0)
		from			#temp_estimates
		inner join		complex c on #temp_estimates.complex_id = c.complex_id
		inner join		#temp_stagger_details mcad on c.film_market_no = mcad.film_market_no
		inner join		#temp_stagger_release mcar on mcad.alternate_release_id = mcar.alternate_release_id
		where			mcar.alternate_release_id = @alternate_release_id
		and				mcar.alternate_release_mode_id >= 2

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error inserting all weeks after week 8', 16, 1)
			rollback transaction
			return -1
		end
	end

	if @alternate_release_mode_id = 1
	begin
		select			@main_release_date = min(screening_date)
		from			#temp_estimates

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error for main release getting min screening date', 16, 1)
			rollback transaction
			return -1
		end

		if @preview_release_count = 1
		begin	
			update			#temp_estimates
			set				#temp_estimates.attendance = #temp_estimates.attendance - preview_temp_table.preview_attendance,
							#temp_estimates.original_estimate = #temp_estimates.original_estimate - preview_temp_table.preview_original_estimate
			from			#temp_estimates
			inner join		(select				movie_id, 
												complex_id, 
												cinetam_reporting_demographics_id,
												sum(attendance) as preview_attendance,
												sum(original_estimate) as preview_original_estimate
							from				#temp_estimates_preview_store
							group by			movie_id, 
												complex_id, 
												cinetam_reporting_demographics_id) as preview_temp_table 
			on				#temp_estimates.screening_date = @main_release_date
			and				#temp_estimates.movie_id = preview_temp_table.movie_id
			and				#temp_estimates.complex_id = preview_temp_table.complex_id
			and				#temp_estimates.cinetam_reporting_demographics_id = preview_temp_table.cinetam_reporting_demographics_id


			select @error = @@error
			if @error <> 0
			begin
				raiserror ('Error adjusting main release by effect of ', 16, 1)
				rollback transaction
				return -1
			end
		end 
	end


	insert into		cinetam_movie_complex_estimates
	select			*
	from			#temp_estimates
	order by		movie_id, complex_id, screening_date, cinetam_reporting_demographics_id	

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting records from temp table to actual table', 16, 1)
		rollback transaction
		return -1
	end

	if @alternate_release_mode_id = 3
	begin
		insert into		#temp_estimates_preview_store
		select			*
		from			#temp_estimates
		order by		movie_id, complex_id, screening_date, cinetam_reporting_demographics_id	

		select @error = @@error
		if @error <> 0
		begin
			raiserror ('Error storing preview results to reduce first week', 16, 1)
			rollback transaction
			return -1
		end
	end
	
	delete			#temp_estimates

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting records from temp table to actual table', 16, 1)
		rollback transaction
		return -1
	end
	
	fetch alternate_release_csr into @alternate_release_id, @alternate_release_mode_id, @alternate_release_date
end

drop table #temp_estimates
drop table #temp_stagger_details
drop table #temp_stagger_release

commit transaction
return 0
GO
