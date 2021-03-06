/****** Object:  StoredProcedure [dbo].[p_availability_ff_generate_estimates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_availability_ff_generate_estimates]
GO
/****** Object:  StoredProcedure [dbo].[p_availability_ff_generate_estimates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create proc [dbo].[p_availability_ff_generate_estimates]		@movie_id					int,
																@arg_country_code			char(1)

WITH RECOMPILE
as

declare			@error									int,
				@error_msg								varchar(1000),
				@rowcount								int,
				@release_date							datetime,
				@matched_movie_id						int,
				@match_release_date						datetime,
				@four_week_met_att						numeric(20,8),
				@total_met_att							numeric(20,8),
				@four_week_reg_att						numeric(20,8),
				@total_reg_att							numeric(20,8),
				@four_week_met_remain					numeric(20,8),
				@total_met_att_remain					numeric(20,8),
				@four_week_reg_att_remain				numeric(20,8),
				@total_reg_att_remain					numeric(20,8),
				@four_week_met_actual					numeric(20,8),
				@total_met_att_actual					numeric(20,8),
				@four_week_reg_att_actual				numeric(20,8),
				@total_reg_att_actual					numeric(20,8),
				@remainder_met							numeric(20,8),
				@remainder_reg							numeric(20,8),
				@factor_week_one						numeric(20,8),
				@factor_week_two						numeric(20,8),
				@factor_week_three						numeric(20,8),
				@factor_week_four						numeric(20,8),
				@attendance_week_one					numeric(20,8),
				@attendance_week_two					numeric(20,8),
				@attendance_week_three					numeric(20,8),
				@attendance_week_four					numeric(20,8),
				@country_code							char(1),
				@weeks_diff								int,
				@staggered_release						int

set nocount on

/*
 * Check for moive country record - need a release date
 */ 

select			@country_code = @arg_country_code

select			@release_date = release_date
from			movie_country
where			movie_id = @movie_id
and				country_code = @country_code

select			@error = @@error,
				@rowcount = @@ROWCOUNT

if @error <> 0 or @rowcount <> 1 or @release_date is null
begin
	select	@error_msg = 'Error - you need to specify a release date for this movie before generating availability records.' + char(10) + char(13) + 'Please do so on the details tab of the movie window.'
	raiserror(@error_msg,  16 , 1)
	return -1
end

/*
 * Check for master record  record
 */ 
					
 select			@matched_movie_id = matched_movie_id,
				@four_week_met_att = four_week_attendance_metro,
				@total_met_att = total_attendance_metro,
				@four_week_reg_att = four_week_attendance_regional,
				@total_reg_att = total_attendance_regional,
				@factor_week_one = factor_week_one,
				@factor_week_two = factor_week_two,
				@factor_week_three = factor_week_three,
				@factor_week_four = 	factor_week_four
 from			availability_follow_film_master
 where			movie_id = @movie_id
 and			country_code = @country_code

 select			@error = @@error,
				@rowcount = @@ROWCOUNT

if @error <> 0 or @rowcount <> 1 
begin
	select	@error_msg = 'Error - you need to enter a master record for this movie before generating availability records.' + char(10) + char(13) + 'Please do so on the Follow Film Availability tab of the movie window.'
	raiserror(@error_msg,  16 , 1)
	return -1
end

/*
 * Check for moive country record - need a release date
 */ 

select			@match_release_date = release_date
from			movie_country
where			movie_id = @matched_movie_id
and				country_code = @country_code

select			@error = @@error,
				@rowcount = @@ROWCOUNT

if @error <> 0 or @rowcount <> 1 or @match_release_date is null
begin
	select	@error_msg = 'Error - failed to find release date for the matched movie.'
	raiserror(@error_msg,  16 , 1)
	return -1
end

select			@staggered_release = count(*) 
from			movie_country_alternate_release
where			movie_id = @movie_id
and				country_code = @country_code
and				alternate_release_mode_id = 1

/*
 * Set remainder & Weeks diff
 */

select			@remainder_met = @total_met_att - @four_week_met_att
select			@remainder_reg = @total_reg_att - @four_week_reg_att

select			@weeks_diff = datediff(wk, @match_release_date, @release_date)

/*
 * begin transaction
 */

begin transaction

 /*
  * Delete exisiting records
  */

delete			availability_follow_film_complex
where			movie_id = @movie_id
and				country_code = @country_code

select @error = @@error
if @error <> 0
begin
		raiserror(50050, 16, 1, 'Error: failed to delete existing data')
		rollback transaction
		return -1
end


 /*
  * insert 4 week information
  */

--insert demo metro
insert into		availability_follow_film_complex
select			@movie_id as movie_id,
				@country_code as country_code,
				dateadd(wk, datediff(wk, @match_release_date, weekly_complex_demo_attendance.screening_date), @release_date) as screening_date,
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id,
				case 
					when weekly_complex_demo_attendance.screening_date = @match_release_date then ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_met_att * @factor_week_one)
					when weekly_complex_demo_attendance.screening_date = dateadd(wk, 1, @match_release_date) then ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_met_att * @factor_week_two)
					when weekly_complex_demo_attendance.screening_date = dateadd(wk, 2, @match_release_date) then ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_met_att * @factor_week_three)
					when weekly_complex_demo_attendance.screening_date = dateadd(wk, 3, @match_release_date) then  ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_met_att * @factor_week_four)
				end as attendance
from			(select			screening_date, 
								cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as weekly_demo_attendance
				from			cinetam_movie_history ctam_hist,
								cinetam_reporting_demographics_xref
				where			ctam_hist.movie_id = @matched_movie_id
				and				cinetam_reporting_demographics_xref.cinetam_demographics_id = ctam_hist.cinetam_demographics_id
				and				ctam_hist.screening_date between @match_release_date and dateadd(wk, 3, @match_release_date)
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'N'))
				and				country_code = @country_code
				and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id <> 0
				and				screening_date is not null
				group by		screening_date, 
								cinetam_reporting_demographics_id) as weekly_demo_attendance,
				(select			screening_date, 
								complex_id,
								cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as weekly_complex_demo_attendance
				from			cinetam_movie_history ctam_hist,
								cinetam_reporting_demographics_xref
				where			ctam_hist.movie_id = @matched_movie_id
				and				cinetam_reporting_demographics_xref.cinetam_demographics_id = ctam_hist.cinetam_demographics_id				
				and				ctam_hist.screening_date between  @match_release_date and dateadd(wk, 3,  @match_release_date)
				and				country_code = @country_code
				and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id <> 0
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'N'))
				and				screening_date is not null
				group by		screening_date, 
								complex_id,
								cinetam_reporting_demographics_id) as weekly_complex_demo_attendance,
				(select			sum(convert(numeric(20,12), attendance)) as all_14plus_4weeks
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between  @match_release_date and dateadd(wk, 3,  @match_release_date)
				and				country = @country_code
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'N'))
				and				screening_date is not null) as all_14plus_4weeks,
				(select			cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as demo_4weeks
				from			cinetam_movie_history ctam_hist,
								cinetam_reporting_demographics_xref
				where			ctam_hist.movie_id = @matched_movie_id
				and				cinetam_reporting_demographics_xref.cinetam_demographics_id = ctam_hist.cinetam_demographics_id
				and				ctam_hist.screening_date between  @match_release_date and dateadd(wk, 3,  @match_release_date)
				and				country_code = @country_code
				and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id <> 0
				and				screening_date is not null
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'N'))
				group by		cinetam_reporting_demographics_id) as demo_4weeks
where			weekly_demo_attendance.cinetam_reporting_demographics_id = weekly_complex_demo_attendance.cinetam_reporting_demographics_id
and				weekly_demo_attendance.screening_date = weekly_complex_demo_attendance.screening_date
and				weekly_demo_attendance.cinetam_reporting_demographics_id = demo_4weeks.cinetam_reporting_demographics_id
group by		weekly_complex_demo_attendance.screening_date, 
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id
OPTION(RECOMPILE)

select @error = @@error
if @error <> 0
begin
		raiserror(50050, 16, 1, 'Error: failed to insert data for first four weeks metro')
		rollback transaction
		return -1
end

--insert demo regional
insert into		availability_follow_film_complex
select			@movie_id as movie_id,
				@country_code as country_code,
				dateadd(wk, datediff(wk, @match_release_date, weekly_complex_demo_attendance.screening_date), @release_date) as screening_date,
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id,
				case 
					when weekly_complex_demo_attendance.screening_date = @match_release_date then ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_reg_att * @factor_week_one)
					when weekly_complex_demo_attendance.screening_date = dateadd(wk, 1, @match_release_date) then ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_reg_att * @factor_week_two)
					when weekly_complex_demo_attendance.screening_date = dateadd(wk, 2, @match_release_date) then ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_reg_att * @factor_week_three)
					when weekly_complex_demo_attendance.screening_date = dateadd(wk, 3, @match_release_date) then  ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_reg_att * @factor_week_four)
				end as attendance
from			(select			screening_date, 
								cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as weekly_demo_attendance
				from			cinetam_movie_history ctam_hist,
								cinetam_reporting_demographics_xref
				where			ctam_hist.movie_id = @matched_movie_id
				and				cinetam_reporting_demographics_xref.cinetam_demographics_id = ctam_hist.cinetam_demographics_id
				and				ctam_hist.screening_date between @match_release_date and dateadd(wk, 3, @match_release_date)
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'Y'))
				and				country_code = @country_code
				and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id <> 0
				and				screening_date is not null
				group by		screening_date, 
								cinetam_reporting_demographics_id) as weekly_demo_attendance,
				(select			screening_date, 
								complex_id,
								cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as weekly_complex_demo_attendance
				from			cinetam_movie_history ctam_hist,
								cinetam_reporting_demographics_xref
				where			ctam_hist.movie_id = @matched_movie_id
				and				cinetam_reporting_demographics_xref.cinetam_demographics_id = ctam_hist.cinetam_demographics_id				
				and				ctam_hist.screening_date between  @match_release_date and dateadd(wk, 3,  @match_release_date)
				and				country_code = @country_code
				and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id <> 0
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'Y'))
				and				screening_date is not null
				group by		screening_date, 
								complex_id,
								cinetam_reporting_demographics_id) as weekly_complex_demo_attendance,
				(select			sum(convert(numeric(20,12), attendance)) as all_14plus_4weeks
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between  @match_release_date and dateadd(wk, 3,  @match_release_date)
				and				country = @country_code
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'Y'))
				and				screening_date is not null) as all_14plus_4weeks,
				(select			cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as demo_4weeks
				from			cinetam_movie_history ctam_hist,
								cinetam_reporting_demographics_xref
				where			ctam_hist.movie_id = @matched_movie_id
				and				cinetam_reporting_demographics_xref.cinetam_demographics_id = ctam_hist.cinetam_demographics_id
				and				ctam_hist.screening_date between  @match_release_date and dateadd(wk, 3,  @match_release_date)
				and				country_code = @country_code
				and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id <> 0
				and				screening_date is not null
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'Y'))
				group by		cinetam_reporting_demographics_id) as demo_4weeks
where			weekly_demo_attendance.cinetam_reporting_demographics_id = weekly_complex_demo_attendance.cinetam_reporting_demographics_id
and				weekly_demo_attendance.screening_date = weekly_complex_demo_attendance.screening_date
and				weekly_demo_attendance.cinetam_reporting_demographics_id = demo_4weeks.cinetam_reporting_demographics_id
group by		weekly_complex_demo_attendance.screening_date, 
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id
OPTION(RECOMPILE)

select @error = @@error
if @error <> 0
begin
		raiserror(50050, 16, 1, 'Error: failed to insert data for first four weeks regional')
		rollback transaction
		return -1
end

--insert all people metro
insert into		availability_follow_film_complex
select			@movie_id as movie_id,
				@country_code as country_code,
				dateadd(wk, datediff(wk, @match_release_date, weekly_complex_demo_attendance.screening_date), @release_date) as screening_date,
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id,
				case 
					when weekly_complex_demo_attendance.screening_date = @match_release_date then ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_met_att * @factor_week_one)
					when weekly_complex_demo_attendance.screening_date = dateadd(wk, 1, @match_release_date) then ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_met_att * @factor_week_two)
					when weekly_complex_demo_attendance.screening_date = dateadd(wk, 2, @match_release_date) then ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_met_att * @factor_week_three)
					when weekly_complex_demo_attendance.screening_date = dateadd(wk, 3, @match_release_date) then  ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_met_att * @factor_week_four)
				end as attendance
from			(select			screening_date, 
								0 as cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as weekly_demo_attendance
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between @match_release_date and dateadd(wk, 3, @match_release_date)
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'N'))
				and				country = @country_code
				and				screening_date is not null
				group by		screening_date) as weekly_demo_attendance,
				(select			screening_date, 
								complex_id,
								0 as cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as weekly_complex_demo_attendance
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between  @match_release_date and dateadd(wk, 3,  @match_release_date)
				and				country = @country_code
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'N'))
				and				screening_date is not null
				group by		screening_date, 
								complex_id) as weekly_complex_demo_attendance,
				(select			sum(convert(numeric(20,12), attendance)) as all_14plus_4weeks
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between  @match_release_date and dateadd(wk, 3,  @match_release_date)
				and				country = @country_code
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'N'))
				and				screening_date is not null) as all_14plus_4weeks,
				(select			0 as cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as demo_4weeks
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between  @match_release_date and dateadd(wk, 3,  @match_release_date)
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'N'))
				and				country = @country_code
				and				screening_date is not null) as demo_4weeks
where			weekly_demo_attendance.cinetam_reporting_demographics_id = weekly_complex_demo_attendance.cinetam_reporting_demographics_id
and				weekly_demo_attendance.screening_date = weekly_complex_demo_attendance.screening_date
and				weekly_demo_attendance.cinetam_reporting_demographics_id = demo_4weeks.cinetam_reporting_demographics_id
group by		weekly_complex_demo_attendance.screening_date, 
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id
OPTION(RECOMPILE)

select @error = @@error
if @error <> 0
begin
		raiserror(50050, 16, 1, 'Error: failed to insert data for first four weeks metro all people')
		rollback transaction
		return -1
end

--insert all people regional
insert into		availability_follow_film_complex
select			@movie_id as movie_id,
				@country_code as country_code,
				dateadd(wk, datediff(wk, @match_release_date, weekly_complex_demo_attendance.screening_date), @release_date) as screening_date,
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id,
				case 
					when weekly_complex_demo_attendance.screening_date = @match_release_date then ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_reg_att * @factor_week_one)
					when weekly_complex_demo_attendance.screening_date = dateadd(wk, 1, @match_release_date) then ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_reg_att * @factor_week_two)
					when weekly_complex_demo_attendance.screening_date = dateadd(wk, 2, @match_release_date) then ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_reg_att * @factor_week_three)
					when weekly_complex_demo_attendance.screening_date = dateadd(wk, 3, @match_release_date) then  ((sum(weekly_complex_demo_attendance) / sum(weekly_demo_attendance)) * (sum(demo_4weeks) / max(all_14plus_4weeks))) * (@four_week_reg_att * @factor_week_four)
				end as attendance
from			(select			screening_date, 
								0 as cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as weekly_demo_attendance
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between @match_release_date and dateadd(wk, 3, @match_release_date)
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'Y'))
				and				country = @country_code
				and				screening_date is not null
				group by		screening_date) as weekly_demo_attendance,
				(select			screening_date, 
								complex_id,
								0 as cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as weekly_complex_demo_attendance
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between  @match_release_date and dateadd(wk, 3,  @match_release_date)
				and				country = @country_code
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'Y'))
				and				screening_date is not null
				group by		screening_date, 
								complex_id) as weekly_complex_demo_attendance,
				(select			sum(convert(numeric(20,12), attendance)) as all_14plus_4weeks
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between  @match_release_date and dateadd(wk, 3,  @match_release_date)
				and				country = @country_code
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'Y'))
				and				screening_date is not null) as all_14plus_4weeks,
				(select			0 as cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as demo_4weeks
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between  @match_release_date and dateadd(wk, 3,  @match_release_date)
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'Y'))
				and				country = @country_code
				and				screening_date is not null) as demo_4weeks
where			weekly_demo_attendance.cinetam_reporting_demographics_id = weekly_complex_demo_attendance.cinetam_reporting_demographics_id
and				weekly_demo_attendance.screening_date = weekly_complex_demo_attendance.screening_date
and				weekly_demo_attendance.cinetam_reporting_demographics_id = demo_4weeks.cinetam_reporting_demographics_id
group by		weekly_complex_demo_attendance.screening_date, 
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id
OPTION(RECOMPILE)

select @error = @@error
if @error <> 0
begin
		raiserror(50050, 16, 1, 'Error: failed to insert data for first four weeks regional all people')
		rollback transaction
		return -1
end

/*
 * Insert 5+ weeks
 */

--insert demos metro
insert into		availability_follow_film_complex
select			@movie_id as movie_id,
				@country_code as country_code,
				dateadd(wk, datediff(wk, @match_release_date, weekly_complex_demo_attendance.screening_date), @release_date) as screening_date,
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id,
				(sum(weekly_complex_demo_attendance) / sum(demo_all_weeks)) * (sum(demo_all_weeks) / max(all_14plus_4weeks)) * @remainder_met
from			(select			screening_date, 
								complex_id,
								cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as weekly_complex_demo_attendance
				from			cinetam_movie_history ctam_hist,
								cinetam_reporting_demographics_xref
				where			ctam_hist.movie_id = @matched_movie_id
				and				cinetam_reporting_demographics_xref.cinetam_demographics_id = ctam_hist.cinetam_demographics_id				
				and				ctam_hist.screening_date between dateadd(wk, 4,  @match_release_date) and dateadd(wk, 7,  @match_release_date)
				and				country_code = @country_code
				and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id <> 0
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'N'))
				and				screening_date is not null
				group by		screening_date, 
								complex_id,
								cinetam_reporting_demographics_id) as weekly_complex_demo_attendance,
				(select			sum(convert(numeric(20,12), attendance)) as all_14plus_4weeks
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between dateadd(wk, 4,  @match_release_date) and dateadd(wk, 7,  @match_release_date)
				and				country = @country_code
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'N'))
				and				screening_date is not null) as all_14plus_4weeks,
				(select			cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as demo_all_weeks
				from			cinetam_movie_history ctam_hist,
								cinetam_reporting_demographics_xref
				where			ctam_hist.movie_id = @matched_movie_id
				and				cinetam_reporting_demographics_xref.cinetam_demographics_id = ctam_hist.cinetam_demographics_id
				and				ctam_hist.screening_date between dateadd(wk, 4,  @match_release_date) and dateadd(wk, 7,  @match_release_date)
				and				country_code = @country_code
				and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id <> 0
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'N'))
				and				screening_date is not null
				group by		cinetam_reporting_demographics_id) as demo_all_weeks
where			demo_all_weeks.cinetam_reporting_demographics_id = weekly_complex_demo_attendance.cinetam_reporting_demographics_id
group by		weekly_complex_demo_attendance.screening_date, 
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id
OPTION(RECOMPILE)

select @error = @@error
if @error <> 0
begin
		raiserror(50050, 16, 1, 'Error: failed to insert data for remainder weeks')
		rollback transaction
		return -1
end


--Insert All People metro
insert into		availability_follow_film_complex
select			@movie_id as movie_id,
				@country_code as country_code,
				dateadd(wk, datediff(wk, @match_release_date, weekly_complex_demo_attendance.screening_date), @release_date) as screening_date,
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id,
				(sum(weekly_complex_demo_attendance) / sum(demo_all_weeks)) * (sum(demo_all_weeks) / max(all_14plus_4weeks)) * @remainder_met
from			(select			screening_date, 
								complex_id,
								0 as cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as weekly_complex_demo_attendance
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between dateadd(wk, 4,  @match_release_date) and dateadd(wk, 7,  @match_release_date)
				and				country = @country_code
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'N'))
				and				screening_date is not null
				group by		screening_date, 
								complex_id) as weekly_complex_demo_attendance,
				(select			sum(convert(numeric(20,12), attendance)) as all_14plus_4weeks
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between dateadd(wk, 4,  @match_release_date) and dateadd(wk, 7,  @match_release_date)
				and				country = @country_code
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'N'))
				and				screening_date is not null) as all_14plus_4weeks,
				(select			0 as cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as demo_all_weeks
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between dateadd(wk, 4,  @match_release_date) and dateadd(wk, 7,  @match_release_date)
				and				country = @country_code
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'N'))
				and				screening_date is not null) as demo_all_weeks
where			demo_all_weeks.cinetam_reporting_demographics_id = weekly_complex_demo_attendance.cinetam_reporting_demographics_id
group by		weekly_complex_demo_attendance.screening_date, 
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id
OPTION(RECOMPILE)

select @error = @@error
if @error <> 0
begin
		raiserror(50050, 16, 1, 'Error: failed to insert data for remainder weeks')
		rollback transaction
		return -1
end

--insert demos regional
insert into		availability_follow_film_complex
select			@movie_id as movie_id,
				@country_code as country_code,
				dateadd(wk, datediff(wk, @match_release_date, weekly_complex_demo_attendance.screening_date), @release_date) as screening_date,
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id,
				(sum(weekly_complex_demo_attendance) / sum(demo_all_weeks)) * (sum(demo_all_weeks) / max(all_14plus_4weeks)) * @remainder_reg
from			(select			screening_date, 
								complex_id,
								cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as weekly_complex_demo_attendance
				from			cinetam_movie_history ctam_hist,
								cinetam_reporting_demographics_xref
				where			ctam_hist.movie_id = @matched_movie_id
				and				cinetam_reporting_demographics_xref.cinetam_demographics_id = ctam_hist.cinetam_demographics_id				
				and				ctam_hist.screening_date between dateadd(wk, 4,  @match_release_date) and dateadd(wk, 7,  @match_release_date)
				and				country_code = @country_code
				and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id <> 0
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'Y'))
				and				screening_date is not null
				group by		screening_date, 
								complex_id,
								cinetam_reporting_demographics_id) as weekly_complex_demo_attendance,
				(select			sum(convert(numeric(20,12), attendance)) as all_14plus_4weeks
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between dateadd(wk, 4,  @match_release_date) and dateadd(wk, 7,  @match_release_date)
				and				country = @country_code
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'Y'))
				and				screening_date is not null) as all_14plus_4weeks,
				(select			cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as demo_all_weeks
				from			cinetam_movie_history ctam_hist,
								cinetam_reporting_demographics_xref
				where			ctam_hist.movie_id = @matched_movie_id
				and				cinetam_reporting_demographics_xref.cinetam_demographics_id = ctam_hist.cinetam_demographics_id
				and				ctam_hist.screening_date between dateadd(wk, 4,  @match_release_date) and dateadd(wk, 7,  @match_release_date)
				and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id <> 0
				and				country_code = @country_code
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'Y'))
				and				screening_date is not null
				group by		cinetam_reporting_demographics_id) as demo_all_weeks
where			demo_all_weeks.cinetam_reporting_demographics_id = weekly_complex_demo_attendance.cinetam_reporting_demographics_id
group by		weekly_complex_demo_attendance.screening_date, 
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id
OPTION(RECOMPILE)

select @error = @@error
if @error <> 0
begin
		raiserror(50050, 16, 1, 'Error: failed to insert data for remainder weeks')
		rollback transaction
		return -1
end


--Insert All People regional
insert into		availability_follow_film_complex
select			@movie_id as movie_id,
				@country_code as country_code,
				dateadd(wk, datediff(wk, @match_release_date, weekly_complex_demo_attendance.screening_date), @release_date) as screening_date,
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id,
				(sum(weekly_complex_demo_attendance) / sum(demo_all_weeks)) * (sum(demo_all_weeks) / max(all_14plus_4weeks)) * @remainder_reg
from			(select			screening_date, 
								complex_id,
								0 as cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as weekly_complex_demo_attendance
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between dateadd(wk, 4,  @match_release_date) and dateadd(wk, 7,  @match_release_date)
				and				country = @country_code
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'Y'))
				and				screening_date is not null
				group by		screening_date, 
								complex_id) as weekly_complex_demo_attendance,
				(select			sum(convert(numeric(20,12), attendance)) as all_14plus_4weeks
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between dateadd(wk, 4,  @match_release_date) and dateadd(wk, 7,  @match_release_date)
				and				country = @country_code
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'Y'))
				and				screening_date is not null) as all_14plus_4weeks,
				(select			0 as cinetam_reporting_demographics_id,
								sum(convert(numeric(20,12), attendance)) as demo_all_weeks
				from			movie_history ctam_hist
				where			ctam_hist.movie_id = @matched_movie_id
				and				ctam_hist.screening_date between dateadd(wk, 4,  @match_release_date) and dateadd(wk, 7,  @match_release_date)
				and				country = @country_code
				and				complex_id in (select complex_id from complex where film_complex_status != 'C' and film_market_no in (select film_market_no from film_market where regional = 'Y'))
				and				screening_date is not null) as demo_all_weeks
where			demo_all_weeks.cinetam_reporting_demographics_id = weekly_complex_demo_attendance.cinetam_reporting_demographics_id
group by		weekly_complex_demo_attendance.screening_date, 
				weekly_complex_demo_attendance.complex_id,
				weekly_complex_demo_attendance.cinetam_reporting_demographics_id
OPTION(RECOMPILE)

select @error = @@error
if @error <> 0
begin
		raiserror(50050, 16, 1, 'Error: failed to insert data for remainder weeks')
		rollback transaction
		return -1
end

select			@four_week_met_actual = sum(attendance)
from			availability_follow_film_complex
inner join		complex on availability_follow_film_complex.complex_id = complex.complex_id
where			movie_id = @movie_id
and				country_code = @country_code
and				film_market_no in (select film_market_no from film_market where regional = 'N')
and				screening_date between @release_date and dateadd(wk, 3, @release_date)
and				cinetam_reporting_demographics_id = 0

select			@four_week_reg_att_actual = sum(attendance)
from			availability_follow_film_complex
inner join		complex on availability_follow_film_complex.complex_id = complex.complex_id
where			movie_id = @movie_id
and				country_code = @country_code
and				film_market_no in (select film_market_no from film_market where regional = 'Y')
and				screening_date between @release_date and dateadd(wk, 3, @release_date)
and				cinetam_reporting_demographics_id = 0

select			@total_met_att_actual = sum(attendance)
from			availability_follow_film_complex
inner join		complex on availability_follow_film_complex.complex_id = complex.complex_id
where			movie_id = @movie_id
and				country_code = @country_code
and				film_market_no in (select film_market_no from film_market where regional = 'N')
and				screening_date > dateadd(wk, 3, @release_date)
and				cinetam_reporting_demographics_id = 0

select			@total_reg_att_actual = sum(attendance)
from			availability_follow_film_complex
inner join		complex on availability_follow_film_complex.complex_id = complex.complex_id
where			movie_id = @movie_id
and				country_code = @country_code
and				film_market_no in (select film_market_no from film_market where regional = 'Y')
and				screening_date > dateadd(wk, 3, @release_date)
and				cinetam_reporting_demographics_id = 0

select			@four_week_met_remain = @four_week_met_att - @four_week_met_actual
select			@total_met_att_remain = @remainder_met - @total_met_att_actual
select			@four_week_reg_att_remain = @four_week_reg_att - @four_week_reg_att_actual
select			@total_reg_att_remain = @remainder_reg - @total_reg_att_actual

if @four_week_met_remain > 0
begin
	update			top (convert(int, @four_week_met_remain)) availability_follow_film_complex
	set				attendance = attendance + 1
	from			complex 
	where			movie_id = @movie_id
	and				country_code = @country_code
	and				availability_follow_film_complex.complex_id = complex.complex_id
	and				film_market_no in (select film_market_no from film_market where regional = 'N')
	and				screening_date between @release_date and dateadd(wk, 3, @release_date)
	and				cinetam_reporting_demographics_id = 0

	select @error = @@error
	if @error <> 0
	begin
			raiserror(50050, 16, 1, 'Error: failed to insert data for remainder weeks')
			rollback transaction
			return -1
	end
end

if @four_week_reg_att_remain > 0
begin
	update			top (convert(int, @four_week_reg_att_remain)) availability_follow_film_complex
	set				attendance = attendance + 1
	from			complex 
	where			movie_id = @movie_id
	and				availability_follow_film_complex.complex_id = complex.complex_id
	and				country_code = @country_code
	and				film_market_no in (select film_market_no from film_market where regional = 'Y')
	and				screening_date between @release_date and dateadd(wk, 3, @release_date)
	and				cinetam_reporting_demographics_id = 0

	select @error = @@error
	if @error <> 0
	begin
			raiserror(50050, 16, 1, 'Error: failed to insert data for remainder weeks')
			rollback transaction
			return -1
	end
end

if @total_met_att_remain > 0
begin	
	update			top (convert(int, @total_met_att_remain)) availability_follow_film_complex
	set				attendance = attendance + 1
	from			complex 
	where			movie_id = @movie_id
	and				availability_follow_film_complex.complex_id = complex.complex_id
	and				country_code = @country_code
	and				film_market_no in (select film_market_no from film_market where regional = 'N')
	and				screening_date > dateadd(wk, 3, @release_date)
	and				cinetam_reporting_demographics_id = 0

	select @error = @@error
	if @error <> 0
	begin
			raiserror(50050, 16, 1, 'Error: failed to insert data for remainder weeks')
			rollback transaction
			return -1
	end
end

if @total_reg_att_remain > 0
begin
	update			top (convert(int, @total_reg_att_remain)) availability_follow_film_complex
	set				attendance = attendance + 1
	from			complex 
	where			movie_id = @movie_id
	and				availability_follow_film_complex.complex_id = complex.complex_id
	and				country_code = @country_code
	and				film_market_no in (select film_market_no from film_market where regional = 'Y')
	and				screening_date > dateadd(wk, 3, @release_date)
	and				cinetam_reporting_demographics_id = 0

	select @error = @@error
	if @error <> 0
	begin
			raiserror(50050, 16, 1, 'Error: failed to insert data for remainder weeks')
			rollback transaction
			return -1
	end
end

if @staggered_release > 0
begin
	update			availability_follow_film_complex
	set				availability_follow_film_complex.screening_date = dateadd(wk, datediff(wk, @release_date, movie_country_alternate_details.screening_date), availability_follow_film_complex.screening_date)
	from			availability_follow_film_complex
	inner join		complex on availability_follow_film_complex.complex_id = complex.complex_id
	inner join		branch on complex.branch_code = branch.branch_code
	and				branch.country_code = @country_code
	inner join		movie_country_alternate_release on availability_follow_film_complex.movie_id = movie_country_alternate_release.movie_id
	and				movie_country_alternate_release.country_code = @country_code
	and				movie_country_alternate_release.alternate_release_mode_id = 1
	inner join		movie_country_alternate_details on movie_country_alternate_release.alternate_release_id = movie_country_alternate_details.alternate_release_id
	and				complex.film_market_no = movie_country_alternate_details.film_market_no
	where			availability_follow_film_complex.movie_id = @movie_id
	
	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error staggering the estimates', 16, 1)
		rollback transaction
		return -1
	end
end

/*
 * Commit and Return 
 */

commit transaction
return 0
GO
