/****** Object:  StoredProcedure [dbo].[p_randf_actual_loyalty_data]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_randf_actual_loyalty_data]
GO
/****** Object:  StoredProcedure [dbo].[p_randf_actual_loyalty_data]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[p_randf_actual_loyalty_data] @resultId		int
AS

declare			@actual_population				integer,						
				@loyalty_unique_transactions	integer		,
				@country_code					char(1) ,
				@cinetam_reporting_demo_id		int,
				@cinetam_rf_mode_id				int,
				@start_date						datetime

set nocount on

select @start_date = min(screening_date) from cinetam_reachfreq_results_fsd_xref
where result_id=@resultId


select @country_code= rset.country_code,
		@cinetam_reporting_demo_id=r.cinetam_reporting_demographics_id,
  		@cinetam_rf_mode_id=r.cinetam_reachfreq_mode_id
from cinetam_reachfreq_results r join cinetam_reachfreq_resultset rset 
on r.resultset_id=rset.resultset_id 
where result_id=@resultId

create table #resultScreeningDates(screening_date datetime not null)		

--get actual_population
select @actual_population = isnull(sum(isnull(crp.population,0)),0)  from cinetam_reachfreq_population crp 
join cinetam_reachfreq_results_mkt_xref mkt on crp.film_market_no=mkt.film_market_no
join dbo.cinetam_reachfreq_results r on r.result_id=mkt.result_id		
where 
crp.screening_date=dbo.f_prev_attendance_screening_date(@start_date)
and	crp.cinetam_reporting_demographics_id = r.cinetam_reporting_demographics_id
and	country_code = @country_code
and r.result_id=@resultId

--get loyalty unique transactions based on mode id of result
if @cinetam_rf_mode_id = 1
	begin		
		select 	@loyalty_unique_transactions = isnull(sum(isnull(unique_transactions,0)),0)
		from		v_movio_data_demo_fsd as vfsd 
					join cinetam_reporting_demographics_xref as reportingdemo
					on reportingdemo.cinetam_demographics_id = vfsd.cinetam_demographics_id
					join data_translate_movie as dtm 
					on dtm.movie_code= vfsd.movie_code					
					join complex c on vfsd.complex_id = c.complex_id
					join cinetam_reachfreq_results_mkt_xref mkt on c.film_market_no=mkt.film_market_no
					join cinetam_reachfreq_results r on r.result_id=mkt.result_id
					join cinetam_reachfreq_movie_xref as mx on r.result_id=mx.result_id
					join cinetam_movie_matches as cmm on cmm.movie_id=mx.movie_id and cmm.country_code=@country_code
					join cinetam_reachfreq_results_fsd_xref as fsd
					on r.result_id=fsd.result_id					
		where		
		vfsd.screening_date = dbo.f_randf_prev_follow_film_screening_date(fsd.screening_date, mx.movie_id, @country_code)
		and reportingdemo.cinetam_reporting_demographics_id = @cinetam_reporting_demo_id
		and	dtm.movie_id = cmm.matched_movie_id
		and	dtm.data_provider_id in (1,4)
		and	vfsd.country_code = @country_code 
		and r.result_id=@resultId

		if @loyalty_unique_transactions = 0
		begin
		select 		@loyalty_unique_transactions = isnull(sum(isnull(unique_transactions,0)),0)
					from		v_movio_data_demo_fsd as vfsd 
					join cinetam_reporting_demographics_xref as reportingdemo
					on reportingdemo.cinetam_demographics_id = vfsd.cinetam_demographics_id
					join data_translate_movie as dtm 
					on dtm.movie_code= vfsd.movie_code					
					join dbo.cinetam_reachfreq_results r 
					on r.cinetam_reporting_demographics_id=reportingdemo.cinetam_reporting_demographics_id
					join cinetam_reachfreq_movie_xref as mx on r.result_id=mx.result_id
					join cinetam_movie_matches as cmm on cmm.movie_id=mx.movie_id and cmm.country_code=@country_code
					join cinetam_reachfreq_results_fsd_xref as fsd
					on r.result_id=fsd.result_id 

			where		
			vfsd.screening_date = dbo.f_randf_prev_follow_film_screening_date(fsd.screening_date, mx.movie_id, @country_code)			
			and	dtm.movie_id = cmm.matched_movie_id
			and	dtm.data_provider_id in (1,4)
			and	vfsd.country_code = @country_code
			and r.result_id=@resultId
		end
	end

else if @cinetam_rf_mode_id = 3
	begin
	insert into #resultScreeningDates select screening_date from v_reachfreq_results_screeningdates where result_id = @resultId 
			
	select 	@loyalty_unique_transactions = isnull(sum(isnull(unique_transactions,0)),0)
			from v_movio_data_demo_fsd as vfsd 
			join #resultScreeningDates vdates on vfsd.screening_date = vdates.screening_date 
			join cinetam_reporting_demographics_xref as reportingdemo 
			on reportingdemo.cinetam_demographics_id=vfsd.cinetam_demographics_id
			join v_reachfreq_results_with_related_enitties vres on vfsd.complex_id = vres.complex_id
			and reportingdemo.cinetam_reporting_demographics_id = vres.cinetam_reporting_demographics_id
			join
				(select	film_name,vfsd.screening_date,isnull(sum(isnull(unique_transactions,0)),0) as unique_transactions_not_top_2,
				rank() over (partition by vfsd.screening_date order by  sum(unique_transactions) desc) as movie_rank
				from v_movio_data_demo_fsd as vfsd 
				join #resultScreeningDates vdates on vfsd.screening_date = vdates.screening_date 
				join cinetam_reporting_demographics_xref as reportingdemo 
				on reportingdemo.cinetam_demographics_id = vfsd.cinetam_demographics_id
				join v_reachfreq_results_with_related_enitties vres on vfsd.complex_id = vres.complex_id
				and reportingdemo.cinetam_reporting_demographics_id = vres.cinetam_reporting_demographics_id						
				where 						
				reportingdemo.cinetam_reporting_demographics_id = @cinetam_reporting_demo_id
				and vres.result_id = @resultId
				group by film_name,vfsd.screening_date) as temp_table 
				on temp_table.screening_date = vfsd.screening_date and temp_table.film_name = vfsd.film_name  
			where						
			reportingdemo.cinetam_reporting_demographics_id = @cinetam_reporting_demo_id
			and temp_table.movie_rank not in (1,2)					
			and vres.result_id=@resultId			

			if @loyalty_unique_transactions = 0
			begin
				select	@loyalty_unique_transactions = isnull(sum(isnull(unique_transactions,0)),0) 
					from v_movio_data_demo_fsd as vfsd 
					inner join #resultScreeningDates vdates on vfsd.screening_date = vdates.screening_date 
					inner join cinetam_reporting_demographics_xref as reportingdemo 
					on reportingdemo.cinetam_demographics_id=vfsd.cinetam_demographics_id						
					join dbo.cinetam_reachfreq_results r 
					on r.cinetam_reporting_demographics_id=reportingdemo.cinetam_reporting_demographics_id						
					Join
						(	select	film_name,vfsd.screening_date,isnull(sum(isnull(unique_transactions,0)),0) as unique_transactions_not_top_2,
							rank() over (partition by vfsd.screening_date order by  sum(isnull(unique_transactions,0)) desc) as movie_rank
							from v_movio_data_demo_fsd as vfsd 
							inner join #resultScreeningDates vdates on vfsd.screening_date = vdates.screening_date 
							inner join cinetam_reporting_demographics_xref as reportingdemo 
							on reportingdemo.cinetam_demographics_id=vfsd.cinetam_demographics_id
							join dbo.cinetam_reachfreq_results r 
							on r.cinetam_reporting_demographics_id=reportingdemo.cinetam_reporting_demographics_id								
							where 
							vfsd.country_code = @country_code and r.result_id=@resultId
							group by film_name,vfsd.screening_date
						) as temp_table 	
					on temp_table.screening_date = vfsd.screening_date and temp_table.film_name = vfsd.film_name  
					where 
					temp_table.movie_rank not in (1,2)								
					and	  vfsd.country_code = country_code
					and  r.result_id=@resultId							
			end
	end
else
	begin			
		insert into #resultScreeningDates select screening_date from v_reachfreq_results_screeningdates where result_id = @resultId 

		select @loyalty_unique_transactions = isnull(sum(isnull(unique_transactions,0)),0)
		from   v_movio_data_demo_fsd as vfsd 
		inner join #resultScreeningDates vdates on vfsd.screening_date = vdates.screening_date 
		inner join  cinetam_reporting_demographics_xref reportingdemo on reportingdemo.cinetam_demographics_id=vfsd.cinetam_demographics_id
		inner join v_reachfreq_results_with_related_enitties vres on vfsd.complex_id = vres.complex_id
		and reportingdemo.cinetam_reporting_demographics_id = vres.cinetam_reporting_demographics_id
		and vres.result_id = @resultId

		if @loyalty_unique_transactions = 0
		begin			
			select 		@loyalty_unique_transactions = isnull(sum(isnull(unique_transactions,0)),0)
			from		v_movio_data_demo_fsd as vfsd 
						inner join #resultScreeningDates vdates on vfsd.screening_date = vdates.screening_date 
						inner join cinetam_reporting_demographics_xref as reportingdemo
						on vfsd.cinetam_demographics_id=reportingdemo.cinetam_demographics_id
						inner join dbo.cinetam_reachfreq_results r 
						on r.cinetam_reporting_demographics_id=reportingdemo.cinetam_reporting_demographics_id								
			where vfsd.country_code = country_code and r.result_id=@resultId									
		end		
	end

drop table #resultScreeningDates

select	@actual_population as 'actual_population',
		@loyalty_unique_transactions as 'loyalty_unique_transactions'		
	

return 0
GO
