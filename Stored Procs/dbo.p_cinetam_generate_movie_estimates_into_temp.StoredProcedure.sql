/****** Object:  StoredProcedure [dbo].[p_cinetam_generate_movie_estimates_into_temp]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_generate_movie_estimates_into_temp]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_generate_movie_estimates_into_temp]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinetam_generate_movie_estimates_into_temp]		@movie_id				int,
																		@country_code			char(1)

as 

declare			@error							int,
				@count_movie_match				int,
				@count_movie_group				int,
				@count_release_date				int,
				@record_exists					int,
				@screening_date					datetime,
				@complex_id						int,
				@required_weeks					int,
				@release_date					datetime,
				@film_market_no					int,
				@matched_release_date			datetime,
				@max_screening_date				datetime
				

select		@required_weeks  = 8

/*
select		@required_weeks  = parameter_int 
from		dbo.system_parameters
where		parameter_name = 'ctam_est_reqd_week'
*/

select		@count_movie_match = count(*)
from		cinetam_movie_matches
where		movie_id = @movie_id
and			country_code = @country_code

select		@count_movie_group = count(*)
from		cinetam_movie_match_group_xref 
where		movie_id = @movie_id
and			country_code = @country_code

select		@max_screening_date = max(screening_date)
from		cinetam_movie_complex_estimates
inner join	complex on cinetam_movie_complex_estimates.complex_id = complex.complex_id
inner join	branch on complex.branch_code = branch.branch_code
where		movie_id = @movie_id
and			country_code = @country_code



if @count_movie_match > 0 and @count_movie_group > 0
begin
	raiserror ('You may only match to a individual movie or a movie goup not both.  Please delete either the matched movie or the matched group', 16, 1)
	return -1
end

select				@count_release_date = count(*),
					@release_date = release_date
from				movie_country 
where				movie_id = @movie_id
and					country_code = @country_code
group by			release_date


if @count_release_date < 1 or @count_release_date is null
begin
	raiserror ('You must select a release date for this country.', 16, 1)
	return -1
end


delete			cmce
from			temp_cmce cmce
inner join		complex as c on c.complex_id = cmce.complex_id
inner join		state as s on s.state_code = c.state_code
where			movie_id = @movie_id
and				s.country_code = @country_code

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting existing movies estimate records', 16, 1)
	return -1
end


insert into		temp_cmce
select			cinetam_movie_matches.movie_id, 
				cinetam_reporting_demographics_id, 
				dateadd(wk, datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_matches.matched_movie_id and country_code = v_ctam_mov_hist.country)
				, screening_Date) , (select release_date from movie_country where country_code = v_ctam_mov_hist.country and movie_id = cinetam_movie_matches.movie_id)) as actual_week, 
				complex_id, 
				round((sum(attendance) * adjustment_factor), 0) as attendance,
				round((sum(attendance) * adjustment_factor), 0)
from			v_cinetam_movie_history_reporting_demos v_ctam_mov_hist, 
				cinetam_movie_matches  
where			v_ctam_mov_hist.movie_id = cinetam_movie_matches.matched_movie_id 
and				cinetam_movie_matches.movie_id =@movie_id
and				v_ctam_mov_hist.country = @country_code  and cinetam_movie_matches.country_code = @country_code
and				cinetam_reporting_demographics_id <> 0
and				(dateadd(wk, datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_matches.matched_movie_id and country_code = v_ctam_mov_hist.country), screening_Date) , (select release_date from movie_country where country_code = v_ctam_mov_hist.country and movie_id = cinetam_movie_matches.movie_id))) in (select screening_Date from film_screening_dates)
and				(dateadd(wk, datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_matches.matched_movie_id and country_code = v_ctam_mov_hist.country), screening_Date) , (select release_date from movie_country where country_code = v_ctam_mov_hist.country and movie_id = cinetam_movie_matches.movie_id))) between @release_date and dateadd(wk, @required_weeks - 1, @release_date)						
group by		cinetam_movie_matches.movie_id, 
				cinetam_reporting_demographics_id, 
				screening_date,
				complex_id,
				v_ctam_mov_hist.movie_id,
				v_ctam_mov_hist.country,
				cinetam_movie_matches.matched_movie_id ,
				adjustment_factor 
union
select			v_xref.movie_id,
				temp_table.cinetam_reporting_demographics_id,
				dateadd(wk, actual_week, (select release_date from movie_country where movie_id = v_xref.movie_id and country_code = temp_table.country)) as actual_date,
				temp_table.complex_id,
				avg(attendance) as avg_attendance,
				avg(attendance) 
from			cinetam_movie_match_group_xref v_xref,
				(select			v_ctam_mov_hist.movie_id,
								cinetam_reporting_demographics_id, 
								datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_match_group_xref.movie_id and country_code = v_ctam_mov_hist.country), screening_Date) as actual_week, 
								complex_id, 
								round((sum(attendance) * adjustment_factor), 0) as attendance,
								cinetam_movie_match_group_id,
								v_ctam_mov_hist.country
				from			v_cinetam_movie_history_reporting_demos v_ctam_mov_hist, 
								cinetam_movie_match_group_xref
				where			v_ctam_mov_hist.movie_id = cinetam_movie_match_group_xref.movie_id 
				and				v_ctam_mov_hist.country = @country_code
				and				cinetam_reporting_demographics_id <> 0
				group by		v_ctam_mov_hist.movie_id, 
								cinetam_movie_match_group_xref.movie_id,
								v_ctam_mov_hist.country,
								cinetam_reporting_demographics_id, 
								screening_date,
								complex_id,
								adjustment_factor,
								cinetam_movie_match_group_id,
								v_ctam_mov_hist.country) as temp_table
where 				v_xref.cinetam_movie_match_group_id = temp_table.cinetam_movie_match_group_id
and					v_xref.movie_id <> temp_table.movie_id 
and					v_xref.movie_id = @movie_id
and 				actual_week between 0 and 9
group by			v_xref.movie_id, temp_table.cinetam_reporting_demographics_id, actual_week, temp_table.country, temp_table.complex_id

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting phase 1 estimates', 16, 1)
	return -1
end

insert into		temp_cmce
select			cinetam_movie_matches.movie_id, 
				0, 
				dateadd(wk, datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_matches.matched_movie_id and country_code = v_ctam_mov_hist.country)
				, screening_Date) , (select release_date from movie_country where country_code = v_ctam_mov_hist.country and movie_id = cinetam_movie_matches.movie_id)) as actual_week, 
				complex_id, 
				round((sum(attendance) * adjustment_factor), 0) as attendance,
				round((sum(attendance) * adjustment_factor), 0)
from			movie_history v_ctam_mov_hist, 
				cinetam_movie_matches  
where			v_ctam_mov_hist.movie_id = cinetam_movie_matches.matched_movie_id 
and				cinetam_movie_matches.movie_id =@movie_id
and				attendance > 0
and				v_ctam_mov_hist.country = @country_code  
and				cinetam_movie_matches.country_code = @country_code
and				(dateadd(wk, datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_matches.matched_movie_id and country_code = v_ctam_mov_hist.country), screening_Date) , (select release_date from movie_country where country_code = v_ctam_mov_hist.country and movie_id = cinetam_movie_matches.movie_id))) in (select screening_Date from film_screening_dates)
and				(dateadd(wk, datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_matches.matched_movie_id and country_code = v_ctam_mov_hist.country), screening_Date) , (select release_date from movie_country where country_code = v_ctam_mov_hist.country and movie_id = cinetam_movie_matches.movie_id))) between @release_date and dateadd(wk, @required_weeks - 1, @release_date)						
group by		cinetam_movie_matches.movie_id, 
				screening_date,
				complex_id,
				v_ctam_mov_hist.movie_id,
				v_ctam_mov_hist.country,
				cinetam_movie_matches.matched_movie_id ,
				adjustment_factor 
union
select			v_xref.movie_id,
				temp_table.cinetam_reporting_demographics_id,
				dateadd(wk, actual_week, (select release_date from movie_country where movie_id = v_xref.movie_id and country_code = temp_table.country)) as actual_date,
				temp_table.complex_id,
				avg(attendance) as avg_attendance,
				avg(attendance) 
from			cinetam_movie_match_group_xref v_xref,
				(select			v_ctam_mov_hist.movie_id,
								0 as cinetam_reporting_demographics_id, 
								datediff(wk, (select release_date from movie_country where movie_id = cinetam_movie_match_group_xref.movie_id and country_code = v_ctam_mov_hist.country), screening_Date) as actual_week, 
								complex_id, 
								round((sum(attendance) * adjustment_factor), 0) as attendance,
								cinetam_movie_match_group_id,
								v_ctam_mov_hist.country
				from			movie_history v_ctam_mov_hist, 
								cinetam_movie_match_group_xref
				where			v_ctam_mov_hist.movie_id = cinetam_movie_match_group_xref.movie_id 
				and				v_ctam_mov_hist.country = @country_code
				and				attendance > 0
				group by		v_ctam_mov_hist.movie_id, 
								cinetam_movie_match_group_xref.movie_id,
								v_ctam_mov_hist.country,
								screening_date,
								complex_id,
								adjustment_factor,
								cinetam_movie_match_group_id,
								v_ctam_mov_hist.country) as temp_table
where 			v_xref.cinetam_movie_match_group_id = temp_table.cinetam_movie_match_group_id
and				v_xref.movie_id <> temp_table.movie_id 
and				v_xref.movie_id = @movie_id
and				v_xref.country_code = @country_code
and 			actual_week between 0 and 9
group by		v_xref.movie_id, 
				temp_table.cinetam_reporting_demographics_id, 
				actual_week, 
				temp_table.country, 
				temp_table.complex_id

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting phase 1-a estimates', 16, 1)
	return -1
end

insert into		temp_cmce
select			missing_table.movie_id, 
				missing_table.cinetam_reporting_demographics_id, 
				missing_table.screening_date, 
				missing_table.complex_id,
				avg_table.avg_attendance,
				avg_table.avg_original_estimate
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
								from			movie_country
								inner join		film_screening_dates on film_screening_dates.screening_date between movie_country.release_date and dateadd(wk, @required_weeks - 1, movie_country.release_date)
								inner join		branch on movie_country.country_code = branch.country_code
								inner join		complex on branch.branch_code = complex.branch_code
								cross join		cinetam_reporting_demographics
								where			movie_id = @movie_id
								and				movie_country.country_code = @country_code
								and				film_complex_status <> 'C') as truth_table
								left outer join (select			movie_id, 
																cinetam_reporting_demographics_id, 
																screening_date, 
																complex_id 
												from			temp_cmce 
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
				from			temp_cmce
				inner join		complex on temp_cmce.complex_id = complex.complex_id
				where			movie_id = @movie_id
				group by		movie_id, 
								film_market_no, 
								cinetam_reporting_demographics_id,
								screening_date) as avg_table
on				missing_table.movie_id  = avg_table.movie_id
and				complex.film_market_no  = avg_table.film_market_no
and				missing_table.screening_date  = avg_table.screening_date
and				missing_table.cinetam_reporting_demographics_id  = avg_table.cinetam_reporting_demographics_id
where			missing_movie_id is null
and				missing_complex_id is null
and				missing_cinetam_reporting_demographics_id is null
and				missing_screening_date is null

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting consolidated estimates - market', 16, 1)
	return -1
end

insert into		temp_cmce
select			missing_table.movie_id, 
				missing_table.cinetam_reporting_demographics_id, 
				missing_table.screening_date, 
				missing_table.complex_id,
				avg_table.avg_attendance,
				avg_table.avg_original_estimate
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
								from			movie_country
								inner join		film_screening_dates on film_screening_dates.screening_date between movie_country.release_date and dateadd(wk, @required_weeks - 1, movie_country.release_date)
								inner join		branch on movie_country.country_code = branch.country_code
								inner join		complex on branch.branch_code = complex.branch_code
								cross join		cinetam_reporting_demographics
								where			movie_id = @movie_id
								and				movie_country.country_code = @country_code
								and				film_complex_status <> 'C') as truth_table
								left outer join (select			movie_id, 
																cinetam_reporting_demographics_id, 
																screening_date, 
																complex_id 
												from			temp_cmce 
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
				from			temp_cmce
				inner join		complex on temp_cmce.complex_id = complex.complex_id
				inner join		branch on complex.branch_code = branch.branch_code
				where			movie_id = @movie_id
				and				country_code = @country_code
				group by		movie_id, 
								cinetam_reporting_demographics_id,
								screening_date) as avg_table
on				missing_table.movie_id  = avg_table.movie_id
and				missing_table.screening_date  = avg_table.screening_date
and				missing_table.cinetam_reporting_demographics_id  = avg_table.cinetam_reporting_demographics_id
where			missing_movie_id is null
and				missing_complex_id is null
and				missing_cinetam_reporting_demographics_id is null
and				missing_screening_date is null

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting consolidated estimates - country', 16, 1)
	return -1
end

delete			temp_cmce
from			complex,
				branch	
where			temp_cmce.complex_id = complex.complex_id
and				complex.branch_code = branch.branch_code
and				temp_cmce.movie_id = @movie_id
and				film_complex_status = 'C'
and				country_code = @country_code

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting closed complexes', 16, 1)
	return -1
end

delete			temp_cmce
from			complex,
				branch	
where			temp_cmce.complex_id = complex.complex_id
and				complex.branch_code = branch.branch_code
and				temp_cmce.movie_id = @movie_id
and				screening_date > DATEADD(wk, 7, @release_date)
and				country_code = @country_code

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting all weeks after week 8', 16, 1)
	return -1
end

insert into		temp_cmce
select			movie_id,
				cinetam_reporting_demographics_id,
				screening_dates.screening_date,
				temp_cmce.complex_id,
				round(attendance * power(0.900000000, DATEDIFF(WK, temp_cmce.screening_date, screening_dates.screening_date) - 1),0),
				round(original_estimate * power(0.900000000, DATEDIFF(WK, temp_cmce.screening_date, screening_dates.screening_date) - 1),0)
from			temp_cmce,
				complex,
				branch,
				(select			screening_date
				from			film_screening_dates
				where			screening_date between DATEADD(wk, 8, @release_date) and @max_screening_date) as screening_dates
where			temp_cmce.complex_id = complex.complex_id
and				complex.branch_code = branch.branch_code
and				temp_cmce.movie_id = @movie_id
and				temp_cmce.screening_date = DATEADD(wk, 7, @release_date)
and				country_code = @country_code

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting all weeks after week 8', 16, 1)
	return -1
end

return 0
GO
