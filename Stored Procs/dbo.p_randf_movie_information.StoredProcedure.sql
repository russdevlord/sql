/****** Object:  StoredProcedure [dbo].[p_randf_movie_information]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_randf_movie_information]
GO
/****** Object:  StoredProcedure [dbo].[p_randf_movie_information]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[p_randf_movie_information]		@resultid		int
AS

--Follow Movie-NewZeland Mix methodology for all except FF

declare			@higher_unique_people			numeric(30,20), 
				@higher_unique_transactions		numeric(30,20),
				@lower_unique_people			numeric(30,20),
				@lower_unique_transactions		numeric(30,20),
				@frequency_week_one				numeric(30,20),
				@reach_threshold				numeric(30,20),
				@start_date						datetime,
				@country_code					char(1),
				@cinetam_rf_mode_id				int

set nocount on

select			@start_date = min(screening_date) 
from			cinetam_reachfreq_results_fsd_xref
where			result_id = @resultid

select			@country_code = rset.country_code,
				@cinetam_rf_mode_id = r.cinetam_reachfreq_mode_id 
from			cinetam_reachfreq_results r 
inner join		cinetam_reachfreq_resultset rset on r.resultset_id = rset.resultset_id 
where			result_id = @resultid

if @cinetam_rf_mode_id = 1
begin
	--print 'Not required for Follow film'
	--Higer unique/week 52
	select			@higher_unique_people = count(distinct membership_id),
					@higher_unique_transactions = isnull(sum(isnull(unique_transactions,0)),0)
	from			v_movio_data_demo_fsd as vfsd 
	inner join		cinetam_reporting_demographics_xref as reportingdemo on reportingdemo.cinetam_demographics_id = vfsd.cinetam_demographics_id
	inner join		data_translate_movie as dtm on dtm.movie_code = vfsd.movie_code					
	inner join		complex c on vfsd.complex_id = c.complex_id
	inner join		cinetam_reachfreq_results_mkt_xref mkt on c.film_market_no = mkt.film_market_no
	inner join		cinetam_reachfreq_results r on r.result_id = mkt.result_id
	inner join		cinetam_reachfreq_movie_xref as mx on r.result_id = mx.result_id
	inner join		cinetam_movie_matches as cmm on cmm.movie_id = mx.movie_id and cmm.country_code = @country_code
	inner join		cinetam_reachfreq_results_fsd_xref as fsd on r.result_id = fsd.result_id																											
	where			vfsd.screening_date between dbo.f_randf_prev_follow_film_screening_date(@start_date, mx.movie_id, @country_code) 
	and				dbo.f_randf_prev_follow_film_screening_date(fsd.screening_date, mx.movie_id, @country_code)
	and				reportingdemo.cinetam_reporting_demographics_id = r.cinetam_reporting_demographics_id
	and				dtm.movie_id = cmm.matched_movie_id
	and				dtm.data_provider_id in (1,4)
	and				vfsd.country_code = @country_code 
	and				r.result_id = @resultid		
			
	if @higher_unique_people = 0 --need to check for @higher_unique_transactions=0????
	begin
		select			@higher_unique_people = count(distinct membership_id),
						@higher_unique_transactions = isnull(sum(isnull(unique_transactions,0)),0)
		from			v_movio_data_demo_fsd as vfsd 
		inner join		cinetam_reporting_demographics_xref as reportingdemo on reportingdemo.cinetam_demographics_id = vfsd.cinetam_demographics_id
		inner join		data_translate_movie as dtm on dtm.movie_code = vfsd.movie_code					
		inner join		dbo.cinetam_reachfreq_results r on r.cinetam_reporting_demographics_id=reportingdemo.cinetam_reporting_demographics_id
		inner join		cinetam_reachfreq_movie_xref as mx on r.result_id = mx.result_id
		inner join		cinetam_movie_matches as cmm on cmm.movie_id = mx.movie_id and cmm.country_code=@country_code
		inner join		cinetam_reachfreq_results_fsd_xref as fsd on r.result_id = fsd.result_id 
		where			vfsd.screening_date between dbo.f_randf_prev_follow_film_screening_date(@start_date, mx.movie_id, @country_code) 
		and				dbo.f_randf_prev_follow_film_screening_date(fsd.screening_date, mx.movie_id, @country_code)			
		and				reportingdemo.cinetam_reporting_demographics_id = r.cinetam_reporting_demographics_id
		and				dtm.movie_id = cmm.matched_movie_id
		and				dtm.data_provider_id in (1,4)
		and				vfsd.country_code = @country_code
		and				r.result_id = @resultid
	end	
					
	--Lower unique/week 1 - First screening date
	select			@lower_unique_people = count(distinct membership_id),
					@lower_unique_transactions = isnull(sum(isnull(unique_transactions,0)),0)
	from			v_movio_data_demo_fsd as vfsd 
	inner join		cinetam_reporting_demographics_xref as reportingdemo on reportingdemo.cinetam_demographics_id = vfsd.cinetam_demographics_id
	inner join		data_translate_movie as dtm on dtm.movie_code = vfsd.movie_code					
	inner join		complex c on vfsd.complex_id = c.complex_id
	inner join		cinetam_reachfreq_results_mkt_xref mkt on c.film_market_no = mkt.film_market_no
	inner join		cinetam_reachfreq_results r on r.result_id = mkt.result_id
	inner join		cinetam_reachfreq_movie_xref as mx on r.result_id = mx.result_id
	inner join		cinetam_movie_matches as cmm on cmm.movie_id = mx.movie_id and cmm.country_code = @country_code
	where			vfsd.screening_date = dbo.f_randf_prev_follow_film_screening_date(@start_date, mx.movie_id, @country_code) 		
	and				reportingdemo.cinetam_reporting_demographics_id = r.cinetam_reporting_demographics_id
	and				dtm.movie_id = cmm.matched_movie_id
	and				dtm.data_provider_id in (1,4)
	and				vfsd.country_code = @country_code
	and				r.result_id = @resultid	
					
	if @lower_unique_people = 0
	begin
		select			@lower_unique_people = count(distinct membership_id),
						@lower_unique_transactions = isnull(sum(isnull(unique_transactions,0)),0)
		from			v_movio_data_demo_fsd as vfsd 
		inner join		cinetam_reporting_demographics_xref as reportingdemo on reportingdemo.cinetam_demographics_id = vfsd.cinetam_demographics_id
		inner join		data_translate_movie as dtm on dtm.movie_code = vfsd.movie_code					
		inner join		cinetam_reachfreq_results r on r.cinetam_reporting_demographics_id = reportingdemo.cinetam_reporting_demographics_id
		inner join		cinetam_reachfreq_movie_xref as mx on r.result_id = mx.result_id
		inner join		cinetam_movie_matches as cmm on cmm.movie_id = mx.movie_id and cmm.country_code = @country_code
		where			vfsd.screening_date = dbo.f_randf_prev_follow_film_screening_date(@start_date, mx.movie_id, @country_code) 		
		and				reportingdemo.cinetam_reporting_demographics_id = r.cinetam_reporting_demographics_id
		and				dtm.movie_id = cmm.matched_movie_id
		and				dtm.data_provider_id in (1,4)
		and				vfsd.country_code =  @country_code
		and				r.result_id = @resultid	
	end														
end
else
begin
	--Higer unique/week 52
	select			@higher_unique_people = count(distinct membership_id),
					@higher_unique_transactions = isnull(sum(isnull(unique_transactions,0)),0)
	from			cinetam_reachfreq_results r
	inner join		cinetam_reachfreq_resultset rs on r.resultset_id = rs.resultset_id	
	inner join		cinetam_reachfreq_results_mkt_xref mkt on r.result_id = mkt.result_id
	inner join		movio_data_randf_summary mdrandfs on mdrandfs.film_market_no = mkt.film_market_no
	and				mdrandfs.country_code = rs.country_code  
	and				mdrandfs.cinetam_reporting_demographics_id = r.cinetam_reporting_demographics_id
	inner join		film_screening_date_attendance_prev fsdap on mdrandfs.screening_date = fsdap.prev_screening_date
	and				fsdap.screening_date between dateadd(wk, -52, @start_date) and dateadd(wk, -1, @start_date)
	where			r.result_id = @resultid

	if @higher_unique_people = 0
	begin
		select			@higher_unique_people = count(distinct membership_id),
						@higher_unique_transactions = isnull(sum(isnull(unique_transactions,0)),0)
		from			cinetam_reachfreq_results r
		inner join		cinetam_reachfreq_resultset rs on r.resultset_id = rs.resultset_id	
		inner join		cinetam_reachfreq_results_mkt_xref mkt on r.result_id = mkt.result_id
		inner join		movio_data_randf_summary mdrandfs on mdrandfs.country_code = rs.country_code  
		and				mdrandfs.cinetam_reporting_demographics_id = r.cinetam_reporting_demographics_id
		inner join		film_screening_date_attendance_prev fsdap on mdrandfs.screening_date = fsdap.prev_screening_date
		and				fsdap.screening_date between dateadd(wk, -52, @start_date) and dateadd(wk, -1, @start_date)
		where			r.result_id = @resultid
	end

	--Lower unique/week 1 - First screening date
	select			@lower_unique_people = count(distinct membership_id),
					@lower_unique_transactions = isnull(sum(isnull(unique_transactions,0)),0)
	from			cinetam_reachfreq_results r
	inner join		cinetam_reachfreq_resultset rs on r.resultset_id = rs.resultset_id	
	inner join		cinetam_reachfreq_results_mkt_xref mkt on r.result_id = mkt.result_id
	inner join		movio_data_randf_summary mdrandfs on mdrandfs.film_market_no = mkt.film_market_no
	and				mdrandfs.country_code = rs.country_code  
	and				mdrandfs.cinetam_reporting_demographics_id = r.cinetam_reporting_demographics_id
	inner join		film_screening_date_attendance_prev fsdap on mdrandfs.screening_date = fsdap.prev_screening_date
	and				fsdap.screening_date = dateadd(wk, -52, @start_date) 
	where			r.result_id = @resultid

	if @lower_unique_people = 0
	begin
		select			@lower_unique_people = count(distinct membership_id),
						@lower_unique_transactions = isnull(sum(isnull(unique_transactions,0)),0)
		from			cinetam_reachfreq_results r
		inner join		cinetam_reachfreq_resultset rs on r.resultset_id = rs.resultset_id	
		inner join		cinetam_reachfreq_results_mkt_xref mkt on r.result_id = mkt.result_id
		inner join		movio_data_randf_summary mdrandfs on mdrandfs.country_code = rs.country_code  
		and				mdrandfs.cinetam_reporting_demographics_id = r.cinetam_reporting_demographics_id
		inner join		film_screening_date_attendance_prev fsdap on mdrandfs.screening_date = fsdap.prev_screening_date
		and				fsdap.screening_date = dateadd(wk, -52, @start_date) 
		where			r.result_id = @resultid
	end
end

--print @higher_unique_people
--print @higher_unique_transactions

--print @lower_unique_people
--print @lower_unique_transactions

--calculate week one frequency
select	@frequency_week_one = @lower_unique_transactions /  @lower_unique_people
--print @frequency_week_one

--calculate weighted average of threshold		
select			@reach_threshold = isnull(sum(isnull(cp.reach_threshold,0) * isnull(cp.population,0)) / sum(isnull(cp.population,0)),0) 
from			cinetam_reachfreq_population as cp 
inner join		cinetam_reachfreq_results_mkt_xref as mkt on mkt.film_market_no=cp.film_market_no
inner join		cinetam_reachfreq_results as r on r.result_id=mkt.result_id
where			screening_date = @start_date 
and				cp.country_code = @country_code
and				r.cinetam_reporting_demographics_id = cp.cinetam_reporting_demographics_id
and				r.result_id = @resultid 

select			@higher_unique_people	 as 'WeekFiftyTwoUniquePeople',
				@higher_unique_transactions	 as 'WeekFiftyTwoUniqueTransactions',
				@frequency_week_one as 'WeekOneFrequency',
				@reach_threshold as 'ReachThreshold'


return 0
GO
