/****** Object:  StoredProcedure [dbo].[p_availability_randf_attendance_estimate_digilite]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_availability_randf_attendance_estimate_digilite]
GO
/****** Object:  StoredProcedure [dbo].[p_availability_randf_attendance_estimate_digilite]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[p_availability_randf_attendance_estimate_digilite]	@result_id			int
as

declare			@screening_date						datetime,    
				@adjustment_factor					numeric(6,4),                
				@cinetam_reporting_demo_id			int,  
				@metro_avg							int,  
				@regional_avg						int,  
				@metro_screens						int,  
				@regional_screens					int,        
				@attendance_estimate				int,  
				@metro_pool							int,  
				@regional_pool						int,  
				@metro_panels						int,  
				@regional_panels					int,  
				@all_people_attendance				int,  
				@all_people_metro_avg				int,  
				@all_people_regional_avg			int,  
				@all_people_metro_pool				int,  
				@all_people_regional_pool			int,  
				@mm_adjustment						numeric(6,4),  
				@country_code						char(1)               

select			@country_code = rset.country_code,
				@cinetam_reporting_demo_id = r.cinetam_reporting_demographics_id,  			
				@adjustment_factor = r.manual_adjustment_factor
from			cinetam_reachfreq_results r 
inner join		cinetam_reachfreq_resultset rset on r.resultset_id=rset.resultset_id 
where			result_id = @result_id
		   
create table #filmMarketNo 
(
	film_market_no			int			not null
)	

insert into		#filmMarketNo
select			film_market_no 
from			cinetam_reachfreq_results_mkt_xref as mkt
inner join		cinetam_reachfreq_results r on r.result_id=mkt.result_id	
where			r.result_id=@result_id								

create table #randf_attendance_digilite
(
	screening_date			datetime			not null,
	demo_attendance			numeric(20,8)		not null,
	all_people_attendance	numeric(20,8)		not null,
	demo_cpm				money				not null,
	full_attendance			numeric(20,8)		not null
)

--every location with a digilite in metro get number digitlite screens   	      
select			@metro_panels = count(cinelight_id)  
from			cinelight as cl 
inner join		complex c on cl.complex_id = c.complex_id    				        
where			cl.cinelight_status = 'O' 
and				c.film_market_no in (select film_market_no from #filmMarketNo)
and				c.complex_region_class = 'M'  							  

select			@regional_panels = count(cinelight_id)  
from			cinelight as cl join complex c on cl.complex_id=c.complex_id    						  
where			cl.cinelight_status = 'O' 
and				c.film_market_no in (select film_market_no from #filmMarketNo)
and				c.complex_region_class != 'M'  					

	
declare			screening_date_csr cursor static for  
select			screening_date,
				isnull(metro_screens,0) as metro_screens,
				isnull(regional_screens,0) as regional_screens,
				(select			max(mm_adjustment)
				from			cinetam_reachfreq_population  
				where			film_market_no in (select film_market_no from #filmMarketNo)  
				and				cinetam_reporting_demographics_id = @cinetam_reporting_demo_id  
				and				screening_date = dbo.f_prev_attendance_screening_date(cinetam_reachfreq_results_fsd_xref.screening_date)  
				and				country_code = @country_code  ) as mm_adjustment
from			cinetam_reachfreq_results_fsd_xref
where			result_id = @result_id
group by		screening_date, 
				metro_screens, 
				regional_screens
having			(isnull(metro_screens,0) + isnull(regional_screens,0)) > 0
order by		screening_date  
  
open screening_date_csr  
fetch screening_date_csr into @screening_date, @metro_screens, @regional_screens, @mm_adjustment
while(@@fetch_status = 0)  
begin  
	--every location with a digilite in metro get total attendance  			  
	select			@metro_pool = sum(history.attendance * (curr_cin_att.cinatt_weighting / prev_cin_att.cinatt_weighting)) * @adjustment_factor  
	from			cinetam_movie_history_rf_cplx as history 
	inner join		complex as c  on history.complex_id = c.complex_id			 
	inner join		complex_date curr_cin_att on c.complex_id = curr_cin_att.complex_id and @screening_date = curr_cin_att.screening_date
	inner join		complex_date prev_cin_att on c.complex_id = prev_cin_att.complex_id and history.screening_date = prev_cin_att.screening_date
	inner join		film_screening_date_attendance_prev as fsdap on history.screening_date = fsdap.prev_screening_date
	and				fsdap.screening_date = @screening_date
	where			history.cinetam_reporting_demographics_id = @cinetam_reporting_demo_id
	and				c.film_market_no in (select film_market_no from #filmMarketNo)
	and				complex_region_class = 'M'  
	and				c.complex_id in (select complex_id from cinelight where cinelight_status = 'O')   
	and				history.country_code = @country_code  
	and				prev_cin_att.cinatt_weighting <> 0

	select			@regional_pool = sum(history.attendance * (curr_cin_att.cinatt_weighting / prev_cin_att.cinatt_weighting)) * @adjustment_factor  
	from			cinetam_movie_history_rf_cplx as history 
	inner join		complex as c  on history.complex_id = c.complex_id					  
	inner join		complex_date curr_cin_att on c.complex_id = curr_cin_att.complex_id and @screening_date = curr_cin_att.screening_date
	inner join		complex_date prev_cin_att on c.complex_id = prev_cin_att.complex_id and history.screening_date = prev_cin_att.screening_date
	inner join		film_screening_date_attendance_prev as fsdap on history.screening_date = fsdap.prev_screening_date
	and				fsdap.screening_date = @screening_date
	where			history.cinetam_reporting_demographics_id = @cinetam_reporting_demo_id
	and				c.film_market_no in (select film_market_no from #filmMarketNo)
	and				complex_region_class != 'M'  
	and				c.complex_id in (select complex_id from cinelight where cinelight_status = 'O')   
	and				history.country_code = @country_code 	
	and				prev_cin_att.cinatt_weighting <> 0
    
	select			@all_people_metro_pool = sum(m.attendance * (curr_cin_att.cinatt_weighting / prev_cin_att.cinatt_weighting)) * @adjustment_factor  
	from			cinetam_movie_history_rf_cplx m 
	inner join		complex c on m.complex_id = c.complex_id
	inner join		complex_date curr_cin_att on c.complex_id = curr_cin_att.complex_id and @screening_date = curr_cin_att.screening_date
	inner join		complex_date prev_cin_att on c.complex_id = prev_cin_att.complex_id and m.screening_date = prev_cin_att.screening_date
	inner join		film_screening_date_attendance_prev as fsdap on m.screening_date = fsdap.prev_screening_date
	and				fsdap.screening_date = @screening_date
	where			c.film_market_no in (select film_market_no from #filmMarketNo)
	and				complex_region_class = 'M'  
	and				c.complex_id in (select complex_id from cinelight where cinelight_status = 'O')   
	and				m.country_code = @country_code 	
	and				prev_cin_att.cinatt_weighting <> 0
	and				m.cinetam_reporting_demographics_id = 0
 	
	select			@all_people_regional_pool  = sum(m.attendance * (curr_cin_att.cinatt_weighting / prev_cin_att.cinatt_weighting)) * @adjustment_factor  
	from			cinetam_movie_history_rf_cplx m 
	inner join		complex c on m.complex_id = c.complex_id
	inner join		complex_date curr_cin_att on c.complex_id = curr_cin_att.complex_id and @screening_date = curr_cin_att.screening_date
	inner join		complex_date prev_cin_att on c.complex_id = prev_cin_att.complex_id and m.screening_date = prev_cin_att.screening_date
	inner join		film_screening_date_attendance_prev as fsdap on m.screening_date = fsdap.prev_screening_date
	and				fsdap.screening_date = @screening_date
	where			c.film_market_no in (select film_market_no from #filmMarketNo)
	and				complex_region_class != 'M'  
	and				c.complex_id in (select complex_id from cinelight where cinelight_status = 'O')   
	and				m.country_code = @country_code 	
	and				prev_cin_att.cinatt_weighting <> 0 
  	and				m.cinetam_reporting_demographics_id = 0

	select			@metro_pool = @metro_pool * (1 + @mm_adjustment)  		
	select			@regional_pool = @regional_pool * (1 + @mm_adjustment)  
	select			@all_people_metro_pool = @all_people_metro_pool * (1 + @mm_adjustment)  
	select			@all_people_regional_pool = @all_people_regional_pool * (1 + @mm_adjustment)  
    
	select			@metro_avg = @metro_pool / @metro_panels  
	select			@regional_avg =  @regional_pool / @regional_panels  				
	select			@all_people_metro_avg = @all_people_metro_pool / @metro_panels  
	select			@all_people_regional_avg = @all_people_regional_pool / @regional_panels  
 
	insert into #randf_attendance_digilite 
	values
	(
		@screening_date,
		(isnull(@metro_avg,0) * isnull(@metro_screens,0)) + (isnull(@regional_avg,0) * isnull(@regional_screens,0)),
		(isnull(@all_people_metro_avg,0) * isnull(@metro_screens,0)) + (isnull(@all_people_regional_avg,0) * isnull(@regional_screens,0)),
		0,
		0
	)
      
	fetch screening_date_csr into @screening_date, @metro_screens, @regional_screens, @mm_adjustment
end  
  
drop table #filmMarketNo

select * from #randf_attendance_digilite
   
return 0
GO
