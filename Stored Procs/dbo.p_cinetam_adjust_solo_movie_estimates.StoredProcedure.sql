/****** Object:  StoredProcedure [dbo].[p_cinetam_adjust_solo_movie_estimates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_adjust_solo_movie_estimates]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_adjust_solo_movie_estimates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc	[dbo].[p_cinetam_adjust_solo_movie_estimates]	@movie_id				int,
															@screening_date			datetime,
															@country_code			char(1)

as

declare		@error			int

/*
 * Adjust Weekly Estimates
 */
 
create table #est_vs_act
(
	cinetam_reporting_demographics_id				int,
	movie_id										int,
	country_code									char(1),
	screening_date									datetime,
	actual_attendance								numeric(36,26),
	estimated_attendance							numeric(36,26)
)

insert into	#est_vs_act
select		actual.cinetam_reporting_demographics_id,
			actual.movie_id,
			@country_code,
			@screening_date ,
			actual.actual_attendance,
			estimate.estimated_attendance
from		(select			cinetam_reporting_demographics_id, 
							movie_id, 
							sum(attendance) as actual_attendance 
			from			v_cinetam_movie_history_reporting_demos 
			where			screening_date = @screening_date 
			and				country = @country_code 
			and				movie_id = @movie_id
			group by		cinetam_reporting_demographics_id, 
							movie_id) actual,
			(select			cinetam_reporting_demographics_id, 
							movie_id, 
							sum(attendance) as estimated_attendance 
			from			cinetam_movie_complex_estimates ,
							complex
			where			screening_date = @screening_date 
			and				movie_id = @movie_id
			and				complex.branch_code in (select branch_code from branch where country_code = @country_code )
			and				complex.complex_id = cinetam_movie_complex_estimates.complex_id
			group by		cinetam_reporting_demographics_id, 
							movie_id) estimate
where		estimate.movie_id = actual.movie_id
and			estimate.cinetam_reporting_demographics_id = actual.cinetam_reporting_demographics_id

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not adjust movie estimates. Close denied 0.', 16, 1)
	rollback transaction
	return -1
end

delete #est_vs_act where estimated_attendance = 0

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not adjust movie estimates . Close denied 1.', 16, 1)
	rollback transaction
	return -1
end

--select * from #est_vs_act


begin transaction

update		cinetam_movie_estimates
set			attendance = convert(int, attendance * (actual_attendance / estimated_attendance))
from		#est_vs_act
where		cinetam_movie_estimates.screening_date >= dateadd(wk, 1, #est_vs_act.screening_date)
and			cinetam_movie_estimates.country_code = #est_vs_act.country_code
and			cinetam_movie_estimates.movie_id = #est_vs_act.movie_id
and			cinetam_movie_estimates.cinetam_reporting_demographics_id = #est_vs_act.cinetam_reporting_demographics_id
and			cinetam_movie_estimates.movie_id in (select			movie_id 
												from			movie_country 
												where			movie_id = @movie_id
												and				country_code = cinetam_movie_estimates.country_code 
												and				release_date <= @screening_date)

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not adjust movie estimates . Close denied 2.', 16, 1)
	rollback transaction
	return -1
end


update		cinetam_movie_complex_estimates
set			attendance = convert(int, attendance * (actual_attendance / estimated_attendance))
from		#est_vs_act,
			complex,
			state
where		cinetam_movie_complex_estimates.complex_id = complex.complex_id
and			complex.state_code = state.state_code
and			state.country_code = #est_vs_act.country_code
and			cinetam_movie_complex_estimates.screening_date >= dateadd(wk, 1, #est_vs_act.screening_date)
and			cinetam_movie_complex_estimates.movie_id = #est_vs_act.movie_id
and			cinetam_movie_complex_estimates.cinetam_reporting_demographics_id = #est_vs_act.cinetam_reporting_demographics_id
and			cinetam_movie_complex_estimates.movie_id in (select			movie_id 
														from			movie_country 
														where			movie_id = @movie_id
														and				country_code = state.country_code 
														and				release_date <= @screening_date)

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not adjust movie complex level estimates . Close denied 3.', 16, 1)
	rollback transaction
	return -1
end

drop table #est_vs_act  

commit transaction 
return 0
GO
