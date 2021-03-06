/****** Object:  StoredProcedure [dbo].[p_availability_attendance_cost_ff_estimate]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_availability_attendance_cost_ff_estimate]
GO
/****** Object:  StoredProcedure [dbo].[p_availability_attendance_cost_ff_estimate]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[p_availability_attendance_cost_ff_estimate]  @country_code             char(1),      
                         @screening_dates            varchar(max),      
                         @film_markets             varchar(max),      
                         @cinetam_reporting_demographics_id    varchar(max),      
                         @product_category_sub_concat_id      varchar(max),      
                         @cinetam_reachfreq_duration_id      int,      
                         @movie_ids               varchar(max),      
                         @exhibitor_ids             varchar(max),      
                         @manual_adjustment_factor        numeric(6,4)      
                                                        
as      
      
declare   @error             int,                           
     @screening_date         datetime,                              
     @attendance_estimate      integer,                                                                       
     @generation_date        datetime,      
     @duration           int,      
     @national_count         int,      
     @metro_count          int,      
     @regional_count         int,      
	  @four_weeek_metro_full_attendance_pool numeric(20,8),      
	 @four_week_metro_cost money,      
	 @four_weeek_regional_full_attendance_pool numeric(20,8),      
	 @four_weeek_regional_cost money,        
	 @five_plus_week_metro_full_attendance_pool numeric(20,8),      
	 @five_plus_week_regional_full_attendance_pool numeric(20,8),      
	 @five_plus_week_metro_cost money,   
	 @five_plus_week_regional_cost money,     
	 @calculated_four_weeek_metro_cost money,      
	 @calculated_four_weeek_regional_cost money,      
	 @calculated_five_plus_week_metro_cost money,      
	 @calculated_five_plus_week_regional_cost money, 
	 @four_weeek_available_metro_all_people_attendance  numeric(20,8),
	 @four_weeek_available_regional_all_people_attendance  numeric(20,8),
	 @five_plus_week_available_metro_all_people_attendance  numeric(20,8),
	 @five_plus_week_available_regional_all_people_attendance  numeric(20,8),
	 @total_available_all_people_attendance numeric(20,8),
     @total_cost money		
      
      
set nocount on      
      
/*      
 * Set generation date      
 */      
      
select @generation_date = getdate()      
      
/*      
 * Temp Tables      
 */      
      
create table #screening_dates      
(      
 screening_date         datetime   not null      
)      
      
create table #film_markets      
(      
 film_market_no         int     not null      
)      
      
create table #movies      
(      
 movie_id            int     not null      
)      
      
create table #matched_movies      
(      
 movie_id            int     not null,      
 matched_movie_id        int     not null,      
 release_date_offset       int     not null      
)      
      
create table #exhibitors      
(      
 exhibitor_id           int     not null      
)      
      
create table #cinetam_reporting_demographics      
(      
 cinetam_reporting_demographics_id int     not null      
)      
      
create table #product_category_sub_concat      
(      
 product_category_sub_concat_id  int     not null      
)      
      
create table #product_category_sub_concat_linked      
(      
 product_category_sub_concat_id  int     not null      
)      
      
create table #cinetam_reachfreq_duration      
(      
 cinetam_reachfreq_duration_id   int     not null      
)      
      
create table #availability_attendance_ff      
(      
 screening_date         datetime   not null,      
 generation_date         datetime   not null,      
 country_code          char(1)    not null,      
 film_market_no         int     not null,      
 complex_id           int     not null,      
 cinetam_reporting_demographics_id int     not null,      
 cinetam_reachfreq_duration_id   int     not null,      
 exhibitor_id           int     not null,      
 product_category_sub_concat_id  int     not null,      
 movie_id            int     not null,      
 demo_attendance         numeric(20,8) not null,           
 four_weeek_metro_all_people_attendance   numeric(20,8) not null,      
 four_weeek_regional_all_people_attendance  numeric(20,8) not null,      
 five_plus_week_metro_all_people_attendance   numeric(20,8) not null,      
 five_plus_week_regional_all_people_attendance   numeric(20,8) not null,      
 product_booked_percentage    numeric(20,8) not null,      
 current_booked_percentage    numeric(20,8) not null,      
 projected_booked_percentage   numeric(20,8) not null,          
)      
    
--create table #film_markets_metro_complexes    
--(      
-- complex_id           int     not null      
--)      
    
--create table #film_markets_regional_complexes    
--(      
-- complex_id           int     not null      
--)        
    
create table #movie_screening_dates_weeks
(      
  movie_id            int     not null,      
  screening_date      datetime   not null,
  week_number	      int not null      
) 

create table #randf_estimates_ff
(	
	demo_attendance									numeric(20,8)	not null,
	all_people_attendance							numeric(20,8)	not null,
	cost											money null	
)

/*      
 * Parse Variables into the temp tables      
 */      
      
insert into #screening_dates      
select * from dbo.f_multivalue_parameter(@screening_dates,',')      
      
insert into #film_markets      
select * from dbo.f_multivalue_parameter(@film_markets,',')      
      
insert into #movies      
select * from dbo.f_multivalue_parameter(@movie_ids,',')      
      
insert into #exhibitors      
select * from dbo.f_multivalue_parameter(@exhibitor_ids,',')      
      
insert into #cinetam_reporting_demographics      
select * from dbo.f_multivalue_parameter(@cinetam_reporting_demographics_id,',')      
      
insert into #product_category_sub_concat      
select * from dbo.f_multivalue_parameter(@product_category_sub_concat_id,',')      
      
insert into #cinetam_reachfreq_duration      
select * from dbo.f_multivalue_parameter(@cinetam_reachfreq_duration_id,',')      
      
insert into  #matched_movies      
select    availability_follow_film_master.movie_id, availability_follow_film_master.matched_movie_id, datediff(wk,match_movie.release_date, original_movie.release_date)      
from     availability_follow_film_master      
inner join   movie_country original_movie on availability_follow_film_master.movie_id =original_movie.movie_id and availability_follow_film_master.country_code =original_movie.country_code       
inner join   movie_country match_movie on  availability_follow_film_master.matched_movie_id =match_movie.movie_id and availability_follow_film_master.country_code =match_movie.country_code       
inner join   #movies on availability_follow_film_master.movie_id = #movies.movie_id      
where    availability_follow_film_master.country_code = @country_code      
      
insert into  #product_category_sub_concat_linked      
select    product_category_sub_concat_id       
from     #product_category_sub_concat      
      
insert into  #product_category_sub_concat_linked      
select    product_category_sub_concat_id      
from     product_category_sub_concat      
where    product_category_id in (select product_category_id from product_category_sub_concat where product_category_sub_concat_id in (select product_category_sub_concat_id from #product_category_sub_concat))      
and     product_category_sub_concat_id not in (select product_category_sub_concat_id from #product_category_sub_concat_linked)      
and     product_subcategory_id is null      
    

;with cte as
(select distinct m.movie_id,ff.screening_date from availability_follow_film_complex ff   
inner join #movies m on ff.movie_id=m.movie_id)
insert into #movie_screening_dates_weeks
select  movie_id,screening_date,
row_number() over(partition by movie_id order by screening_date) week_number
from cte order by movie_id,screening_date,week_number 
    
select    @duration = max_duration      
from     cinetam_reachfreq_duration      
where    cinetam_reachfreq_duration_id = @cinetam_reachfreq_duration_id      
      
select    @national_count = count(*)      
from     #film_markets      
where    film_market_no = -100      
      
select    @metro_count = count(*)      
from     #film_markets      
where    film_market_no = -50      
      
select    @regional_count = count(*)      
from     #film_markets      
where    film_market_no = -25      
      
      
if @metro_count >= 1      
begin      
 delete   #film_markets      
 from    film_market      
 where   #film_markets.film_market_no = film_market.film_market_no      
 and    country_code = @country_code      
 and    regional = 'N'      
      
 insert into #film_markets      
 select   film_market_no      
 from    film_market      
 where   country_code = @country_code      
 and    regional = 'N'      
end      
      
if @regional_count >= 1      
begin      
 delete  #film_markets      
 from   film_market      
 where  #film_markets.film_market_no = film_market.film_market_no      
 and   country_code = @country_code      
 and   regional = 'Y'      
      
 insert into #film_markets      
 select   film_market_no      
 from    film_market      
 where   country_code = @country_code      
 and    regional = 'Y'      
end      
      
if @national_count >= 1      
begin      
 delete  #film_markets      
 from   film_market      
 where  #film_markets.film_market_no = film_market.film_market_no      
 and   country_code = @country_code      
      
 insert into #film_markets      
 select   film_market_no      
 from    film_market      
 where   country_code = @country_code      
end      
      
--insert into #film_markets_metro_complexes    
--select complex_id from complex c   
--inner join  #film_markets fm on c.film_market_no=fm.film_market_no    
--inner join  film_market as film_market on fm.film_market_no=film_market.film_market_no  
--inner join #exhibitors e on c.exhibitor_id = e.exhibitor_id        
--where  film_market.regional='N' and c.film_complex_status <> 'C'     
  
--insert into #film_markets_regional_complexes    
--select complex_id from complex c   
--inner join  #film_markets fm on c.film_market_no=fm.film_market_no    
--inner join film_market on fm.film_market_no=film_market.film_market_no    
--inner join #exhibitors e on c.exhibitor_id = e.exhibitor_id        
--where  film_market.regional='Y' and c.film_complex_status <> 'C'    

      
/*      
 * Generate FF Availability      
 */      
      
insert into  #availability_attendance_ff      
select    avail.screening_date,      
      @generation_date,      
      avail.country_code,      
      complex.film_market_no,      
      complex.complex_id,      
      avail.cinetam_reporting_demographics_id,      
      cinetam_reachfreq_duration_id,      
      complex.exhibitor_id,      
      product_category_sub_concat_id,      
      avail.movie_id,      
      sum(isnull(attendance,0)) as demo_attendance,            
	   (select   isnull(sum(isnull(attendance,0)),0)  
      from     availability_follow_film_complex avail_all    
	  inner join complex cplx_avail_all on avail_all.complex_id = cplx_avail_all.complex_id
	  inner join film_market on cplx_avail_all.film_market_no = film_market.film_market_no
      where    avail_all.country_code = @country_code    
      and     avail_all.cinetam_reporting_demographics_id = 0    
      and     avail_all.screening_date = avail.screening_date 	 
	  and	  regional = 'N'
	  and     avail.screening_date in (select screening_date from #movie_screening_dates_weeks where movie_id=avail.movie_id and week_number <=4)
      and     avail_all.complex_id = complex.complex_id    
      and     avail_all.movie_id = avail.movie_id) as four_weeek_metro_all_people_attendance,     
       
     (select     isnull(sum(isnull(attendance,0)),0)  
      from     availability_follow_film_complex avail_all      
      --inner join #film_markets_regional_complexes rc on avail_all.complex_id=rc.complex_id          
	  inner join complex cplx_avail_all on avail_all.complex_id = cplx_avail_all.complex_id
	  inner join film_market on cplx_avail_all.film_market_no = film_market.film_market_no
      where    avail_all.country_code = @country_code
	  and     avail_all.cinetam_reporting_demographics_id = 0
	  and     avail_all.screening_date = avail.screening_date 	
	  and	  regional = 'Y'
	  and     avail.screening_date in (select screening_date from #movie_screening_dates_weeks where movie_id=avail.movie_id and week_number <=4)      
      and     avail_all.complex_id = complex.complex_id    
      and     avail_all.movie_id = avail.movie_id) as four_weeek_regional_all_people_attendance,          
    
     (select     isnull(sum(isnull(attendance,0)),0) 
      from     availability_follow_film_complex avail_all      
      -- inner join #film_markets_metro_complexes mc on avail_all.complex_id = mc.complex_id          
	   inner join complex cplx_avail_all on avail_all.complex_id = cplx_avail_all.complex_id
	   inner join film_market on cplx_avail_all.film_market_no = film_market.film_market_no
       where    avail_all.country_code = @country_code     
	   and     avail_all.cinetam_reporting_demographics_id = 0
	   and     avail_all.screening_date = avail.screening_date
	   and	  regional = 'N' 
	   and     avail.screening_date in (select screening_date from #movie_screening_dates_weeks where movie_id=avail.movie_id and week_number >=5)      
	   and     avail_all.complex_id = complex.complex_id      
      and     avail_all.movie_id = avail.movie_id)  as five_plus_week_metro_all_people_attendance,
    
     (select     isnull(sum(isnull(attendance,0)),0)    
      from     availability_follow_film_complex avail_all      
      --inner join #film_markets_regional_complexes rc on avail_all.complex_id=rc.complex_id    
	  inner join complex cplx_avail_all on avail_all.complex_id = cplx_avail_all.complex_id
	  inner join film_market on cplx_avail_all.film_market_no = film_market.film_market_no
      where    avail_all.country_code = @country_code      
	  and     avail_all.cinetam_reporting_demographics_id = 0 
	  and     avail_all.screening_date = avail.screening_date
	  and	  regional = 'Y' 
	  and     avail.screening_date in (select screening_date from #movie_screening_dates_weeks where movie_id=avail.movie_id and week_number >=5)      
	  and     avail_all.complex_id = complex.complex_id            
      and     avail_all.movie_id = avail.movie_id) as five_plus_week_regional_all_people_attendance,                          
  
      0 as product_booked_percentage,      
      0 as current_booked_percentage,      
      0 as projected_booked_percentage            
from     availability_follow_film_complex avail      
inner join   complex on avail.complex_id = complex.complex_id      
inner join   #film_markets on complex.film_market_no = #film_markets.film_market_no      
inner join   #exhibitors on complex.exhibitor_id = #exhibitors.exhibitor_id      
inner join   #screening_dates on avail.screening_date = #screening_dates.screening_date      
inner join   #movies on avail.movie_id = #movies.movie_id      
inner join   #cinetam_reporting_demographics on avail.cinetam_reporting_demographics_id = #cinetam_reporting_demographics.cinetam_reporting_demographics_id      
cross join   #product_category_sub_concat      
cross join   #cinetam_reachfreq_duration      
where    avail.country_code = @country_code   
and complex.film_complex_status <> 'C'  
group by   avail.screening_date,   
   avail.complex_id,  
      complex.film_market_no,      
      complex.complex_id,      
      avail.cinetam_reporting_demographics_id,      
      cinetam_reachfreq_duration_id,      
      complex.exhibitor_id,      
      product_category_sub_concat_id,      
      avail.movie_id,      
      avail.country_code      
       
select @error = @@error      
if @error <> 0       
begin      
 raiserror('Error: failed to fetch records for estiamted and all people attendance', 16, 1)      
 return -1      
end      

/*      
 * Check Current Level of Bookings      
 * - a) those complexes excluded by current level of bookings      
 * - b) Those complexes excluded by product category      
 */      
--select * from #availability_attendance_ff      
    
--a      
update  #availability_attendance_ff  set   product_booked_percentage = temp_table.attendance_target      
from   (select   inclusion_spot.screening_date,       
         inclusion_cinetam_settings.complex_id,       
         movie_screening_instructions.movie_id,      
         sum(inclusion_cinetam_master_target.sale_percentage) as attendance_target      
    from    inclusion_cinetam_settings      
    inner join  inclusion_spot on inclusion_cinetam_settings.inclusion_id = inclusion_spot.inclusion_id      
	    inner join  inclusion_cinetam_master_target on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_master_target.inclusion_id      
    inner join  inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id      
    inner join  campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id      
    inner join  movie_screening_instructions on inclusion_cinetam_package.package_id = movie_screening_instructions.package_id      
    inner join  #screening_dates on inclusion_spot.screening_date = #screening_dates.screening_date      
    inner join  #movies on movie_screening_instructions.movie_id = #movies.movie_id      
    inner join  product_category_sub_concat on product_category_sub_concat.product_category_id = campaign_package.product_category and isnull(product_category_sub_concat.product_subcategory_id, 0) = isnull(campaign_package.product_subcategory, 0)      
    inner join  #product_category_sub_concat_linked on #product_category_sub_concat_linked.product_category_sub_concat_id = product_category_sub_concat.product_category_sub_concat_id      
    where   campaign_package.campaign_package_status <> 'P'  
	and					(allow_product_clashing = 'N'                
or						client_clash = 'N')   
group by  inclusion_spot.screening_date,       
         inclusion_cinetam_settings.complex_id,       
         movie_screening_instructions.movie_id) as temp_table      
where  #availability_attendance_ff.screening_date = temp_table.screening_date      
and   #availability_attendance_ff.complex_id = temp_table.complex_id      
and   #availability_attendance_ff.movie_id = temp_table.movie_id      
      
--b      
update  #availability_attendance_ff      
set   current_booked_percentage = temp_table.time_avail      
from   (select   inclusion_spot.screening_date,       
         inclusion_cinetam_settings.complex_id,       
         movie_screening_instructions.movie_id,       
         (sum(convert(numeric(20,8), campaign_package.duration) * inclusion_cinetam_master_target.sale_percentage) + @duration) /  (max_time + mg_max_time) as time_avail      
    from    inclusion_cinetam_settings      
    inner join  inclusion_spot on inclusion_cinetam_settings.inclusion_id = inclusion_spot.inclusion_id      
 	    inner join  inclusion_cinetam_master_target on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_master_target.inclusion_id   
		   inner join  inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id      
    inner join  campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id      
    inner join  movie_screening_instructions on inclusion_cinetam_package.package_id = movie_screening_instructions.package_id      
    inner join  #screening_dates on inclusion_spot.screening_date = #screening_dates.screening_date      
    inner join  #movies on movie_screening_instructions.movie_id = #movies.movie_id      
    inner join  complex_date on inclusion_spot.screening_date = complex_date.screening_date and  inclusion_cinetam_settings.complex_id = complex_date.complex_id      
    where   campaign_package.campaign_package_status <> 'P'      
    group by  inclusion_spot.screening_date,       
         inclusion_cinetam_settings.complex_id,       
         movie_screening_instructions.movie_id,       
         max_time + mg_max_time) as temp_table      
where  #availability_attendance_ff.screening_date = temp_table.screening_date      
and   #availability_attendance_ff.complex_id = temp_table.complex_id      
and   #availability_attendance_ff.movie_id = temp_table.movie_id      
      
      
update   #availability_attendance_ff      
set    current_booked_percentage = 1.0      
where   current_booked_percentage >= 1.0       
      
/*      
 * Estimate Future Level of Bookings       
 */      
      
/*update   #availability_attendance_ff      
set    projected_booked_percentage = (current_booked_percentage * temp_table.diff_time_avail) - current_booked_percentage      
from    (select   before_table_final.screening_date,      
     before_table_final.complex_id,      
     before_table_final.movie_id,      
     before_table_final.time_avail / this_time_before_table.time_avail as diff_time_avail      
from    ( select   dateadd(wk, release_date_offset, inclusion_spot.screening_date) as screening_date,       
           inclusion_cinetam_settings.complex_id,       
           #matched_movies.movie_id,       
           (sum(convert(numeric(20,8), campaign_package.duration) * inclusion_cinetam_master_target.sale_percentage) + @duration) /  (max_time + mg_max_time) as time_avail      
      from    inclusion_cinetam_settings      
      inner join  inclusion_spot on inclusion_cinetam_settings.inclusion_id = inclusion_spot.inclusion_id      
	  inner join  inclusion_cinetam_master_target on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_master_target.inclusion_id   
	  inner join  inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id      
      inner join  campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id      
      inner join  movie_screening_instructions on inclusion_cinetam_package.package_id = movie_screening_instructions.package_id      
      inner join  #matched_movies on movie_screening_instructions.movie_id = #matched_movies.matched_movie_id      
      inner join  #screening_dates on dateadd(wk, release_date_offset, inclusion_spot.screening_date) = #screening_dates.screening_date      
      inner join  complex_date on dateadd(wk, release_date_offset, inclusion_spot.screening_date) = complex_date.screening_date and  inclusion_cinetam_settings.complex_id = complex_date.complex_id      
      where   campaign_package.campaign_package_status <> 'P'      
      group by  dateadd(wk, release_date_offset, inclusion_spot.screening_date),       
           inclusion_cinetam_settings.complex_id,       
           #matched_movies.movie_id,       
           max_time + mg_max_time) as before_table_final      
inner join  ( select   dateadd(wk, release_date_offset, inclusion_spot.screening_date) as screening_date,       
           inclusion_cinetam_settings.complex_id,       
           #matched_movies.movie_id,       
           (sum(convert(numeric(20,8), campaign_package.duration) * inclusion_cinetam_master_target.sale_percentage) + @duration) /  (max_time + mg_max_time) as time_avail      
      from    inclusion_cinetam_settings      
      inner join  inclusion_spot on inclusion_cinetam_settings.inclusion_id = inclusion_spot.inclusion_id      
   	    inner join  inclusion_cinetam_master_target on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_master_target.inclusion_id   
      inner join  inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id      
      inner join  campaign_package on  inclusion_cinetam_package.package_id = campaign_package.package_id      
      inner join  movie_screening_instructions on inclusion_cinetam_package.package_id = movie_screening_instructions.package_id      
      inner join  #matched_movies on movie_screening_instructions.movie_id = #matched_movies.matched_movie_id      
      inner join  #screening_dates on dateadd(wk, release_date_offset, inclusion_spot.screening_date) = #screening_dates.screening_date      
      inner join  complex_date on dateadd(wk, release_date_offset, inclusion_spot.screening_date) = complex_date.screening_date and  inclusion_cinetam_settings.complex_id = complex_date.complex_id      
      where   campaign_package.campaign_package_status <> 'P'      
      and    inclusion_spot.campaign_no not in (select campaign_no from film_campaign_event where event_type = 'C' and event_date > dateadd(wk, release_date_offset * -1 , getdate()))       
      group by  dateadd(wk, release_date_offset, inclusion_spot.screening_date),       
           inclusion_cinetam_settings.complex_id,       
           #matched_movies.movie_id,       
           max_time + mg_max_time ) as this_time_before_table      
on     before_table_final.complex_id =  this_time_before_table.complex_id      
and    before_table_final.screening_date =  this_time_before_table.screening_date      
and    before_table_final.movie_id =  this_time_before_table.movie_id) as temp_table      
where   #availability_attendance_ff.screening_date = temp_table.screening_date      
and    #availability_attendance_ff.complex_id = temp_table.complex_id      
and    #availability_attendance_ff.movie_id = temp_table.movie_id      */
      

update   #availability_attendance_ff  
set    projected_booked_percentage = 1.0  
where   projected_booked_percentage >= 1.0  

update   #availability_attendance_ff  
set    current_booked_percentage = 1.0  
where   current_booked_percentage >= 1.0  

update   #availability_attendance_ff  
set    product_booked_percentage = 1.0  
where   product_booked_percentage >= 1.0  


update   #availability_attendance_ff  
set    projected_booked_percentage = 1.0  
where   current_booked_percentage + projected_booked_percentage >= 1.0  
  
update   #availability_attendance_ff  
set    projected_booked_percentage = 0.0  
where   current_booked_percentage + projected_booked_percentage < 1.0  
  
update   #availability_attendance_ff  
set    projected_booked_percentage = 0  
where   current_booked_percentage >= 1.0  
  
update   #availability_attendance_ff  
set    current_booked_percentage = 0.0  
where   current_booked_percentage  < 1.0  
  
update   #availability_attendance_ff  
set    current_booked_percentage = product_booked_percentage  
where   product_booked_percentage > current_booked_percentage  
  
update   #availability_attendance_ff  
set    current_booked_percentage = isnull(current_booked_percentage, 0.0),  
     product_booked_percentage = isnull(product_booked_percentage, 0.0),  
     projected_booked_percentage = isnull(projected_booked_percentage, 0.0),  
     demo_attendance = isnull(demo_attendance, 0.0) * @manual_adjustment_factor  
       
--select * from #availability_attendance_ff

/*      
 * Calculate Cost - Get 4 week and 5+ week full attendance pool, full cost and calculate final cost based on that      
 */      
     
-- 4 week and 5+ week metro and regional attendace and cost       
select @four_weeek_metro_full_attendance_pool = sum(isnull(four_week_attendance_metro,0)),      
    @four_weeek_regional_full_attendance_pool = sum(isnull(four_week_attendance_regional,0)),      
    @four_week_metro_cost = sum(isnull(four_week_metro_cost,0)),      
    @four_weeek_regional_cost= sum(isnull(four_week_region_cost,0)),      
    @five_plus_week_metro_full_attendance_pool = sum(isnull(total_attendance_metro,0) - isnull(four_week_attendance_metro,0)),          
    @five_plus_week_regional_full_attendance_pool = sum(isnull(total_attendance_regional,0) - isnull(four_week_attendance_regional,0)),      
    @five_plus_week_metro_cost = sum(isnull(total_metro_cost,0) - isnull(four_week_metro_cost,0)),          
    @five_plus_week_regional_cost= sum(isnull(total_region_cost,0) - isnull(four_week_region_cost,0))      
    from availability_follow_film_master as avail_master       
    inner join #movies on avail_master.movie_id = #movies.movie_id      
    where avail_master.country_code = @country_code          

select 
@attendance_estimate=isnull(sum(case when current_booked_percentage = 1 then 0 when projected_booked_percentage = 1 then 0 else (1 - product_booked_percentage) * demo_attendance end),0),	

@four_weeek_available_metro_all_people_attendance = 
		isnull(sum(case when current_booked_percentage = 1 then 0 when projected_booked_percentage = 1 then 0 else (1 - product_booked_percentage) * four_weeek_metro_all_people_attendance end),0),

@four_weeek_available_regional_all_people_attendance=
		isnull(sum(case when current_booked_percentage = 1 then 0 when projected_booked_percentage = 1 then 0 else (1 - product_booked_percentage) * four_weeek_regional_all_people_attendance end),0),

@five_plus_week_available_metro_all_people_attendance=
		isnull(sum(case when current_booked_percentage = 1 then 0 when projected_booked_percentage = 1 then 0 else (1 - product_booked_percentage) * five_plus_week_metro_all_people_attendance end),0),

@five_plus_week_available_regional_all_people_attendance=
		isnull(sum(case when current_booked_percentage = 1 then 0 when projected_booked_percentage = 1 then 0 else (1 - product_booked_percentage) * five_plus_week_regional_all_people_attendance end),0)
from #availability_attendance_ff  

set @four_weeek_available_metro_all_people_attendance = @four_weeek_available_metro_all_people_attendance * @manual_adjustment_factor
set @four_weeek_available_regional_all_people_attendance = @four_weeek_available_regional_all_people_attendance * @manual_adjustment_factor
set @five_plus_week_available_metro_all_people_attendance = @five_plus_week_available_metro_all_people_attendance * @manual_adjustment_factor
set @five_plus_week_available_regional_all_people_attendance = @five_plus_week_available_regional_all_people_attendance * @manual_adjustment_factor
      
--Calculate final cost       
set @calculated_four_weeek_metro_cost = ((@four_weeek_available_metro_all_people_attendance)/nullif(@four_weeek_metro_full_attendance_pool,0)) * @four_week_metro_cost   
                     
set @calculated_four_weeek_regional_cost=((@four_weeek_available_regional_all_people_attendance)/nullif(@four_weeek_regional_full_attendance_pool,0)) * @four_weeek_regional_cost             

set @calculated_five_plus_week_metro_cost=((@five_plus_week_available_metro_all_people_attendance)/nullif(@five_plus_week_metro_full_attendance_pool,0)) * @five_plus_week_metro_cost             

set @calculated_five_plus_week_regional_cost=((@five_plus_week_available_regional_all_people_attendance)/nullif(@five_plus_week_regional_full_attendance_pool,0)) * @five_plus_week_regional_cost       

/*      
 * Return Data or insert into table      
 */      

set @total_available_all_people_attendance = (isnull(@four_weeek_available_metro_all_people_attendance,0)
         + isnull(@four_weeek_available_regional_all_people_attendance,0)   
         + isnull(@five_plus_week_available_metro_all_people_attendance,0)   
         + isnull(@five_plus_week_available_regional_all_people_attendance,0))        
  
set @total_cost =(isnull(@calculated_four_weeek_metro_cost,0)   
    + isnull(@calculated_four_weeek_regional_cost,0)   
    + isnull(@calculated_five_plus_week_metro_cost,0)   
    + isnull(@calculated_five_plus_week_regional_cost,0))   

insert into #randf_estimates_ff
select @attendance_estimate, @total_available_all_people_attendance as all_people_attendance,@total_cost as cost   
        
select * from #randf_estimates_ff      
     
return 0
GO
