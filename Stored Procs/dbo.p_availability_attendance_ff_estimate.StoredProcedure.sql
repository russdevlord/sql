/****** Object:  StoredProcedure [dbo].[p_availability_attendance_ff_estimate]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_availability_attendance_ff_estimate]
GO
/****** Object:  StoredProcedure [dbo].[p_availability_attendance_ff_estimate]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--sp_helptext p_availability_attendance_ff_estimate


  
  
CREATE proc [dbo].[p_availability_attendance_ff_estimate]  @country_code             char(1),  
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
     @population           int,  
     @attendance          int,  
     @all_people_attendance      int,  
     @reach             numeric(30,6),  
     @frequency           numeric(30,6),  
     @cpm             money,  
     @cost             money,  
     @market            varchar(30),  
     @screening_date         datetime,  
     @start_date          datetime,  
     @end_date           datetime,  
     @adjustment_factor       numeric(6,4),  
     @movie_adjustment_factor     numeric(6,4),  
     @metro_avg           int,  
     @regional_avg          int,  
     @metro_screens         int,  
     @regional_screens        int,  
     @attendance_estimate      integer,  
     @attendance_pool        integer,  
     @metro_pool          integer,  
     @regional_pool          integer,  
     @metro_panels         integer,  
     @regional_panels         integer,  
     @attendance_population      integer,  
     @actual_population        integer,        
     @movio_unique_transactions    integer,  
     @all_people_metro_avg      integer,  
     @all_people_regional_avg     integer,  
     @all_people_metro_pool      integer,  
     @all_people_regional_pool     integer,  
     @rows             integer,  
     @generation_date        datetime,  
     @duration           int,  
     @national_count         int,  
     @metro_count          int,  
     @regional_count         int  
  
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
	complex_name										varchar(50)		not null,
 cinetam_reporting_demographics_id int     not null,  
 cinetam_reachfreq_duration_id   int     not null,  
 exhibitor_id           int     not null,  
 product_category_sub_concat_id  int     not null,  
 movie_id            int     not null,  
 demo_attendance         numeric(20,8) not null,  
 all_14plus_attendance       numeric(20,8) not null,  
 product_booked_percentage    numeric(20,8) not null,  
 current_booked_percentage    numeric(20,8) not null,  
 projected_booked_percentage   numeric(20,8) not null  
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
  
  
/*  
 * Generate FF Availability  
 */  
  
insert into  #availability_attendance_ff  
select    avail.screening_date,  
      @generation_date,  
      avail.country_code,  
      complex.film_market_no,  
      complex.complex_id,  
	  complex.complex_name, 
      avail.cinetam_reporting_demographics_id,  
      cinetam_reachfreq_duration_id,  
      complex.exhibitor_id,  
      product_category_sub_concat_id,  
      avail.movie_id,  
      sum(isnull(attendance,0)) as demo_attendance,  
      (select    sum(isnull(attendance,0))  as all_people_attendance  
      from     availability_follow_film_complex avail_all  
      where    avail_all.country_code = @country_code  
      and     avail_all.cinetam_reporting_demographics_id = 0  
      and     avail_all.screening_date = avail.screening_date  
      and     avail_all.complex_id = complex.complex_id  
      and     avail_all.movie_id = avail.movie_id) as all_people_attendance,  
      0,  
      0,  
      0  
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
      complex.film_market_no,  
      complex.complex_id,  
	  complex.complex_name,
      avail.cinetam_reporting_demographics_id,  
      cinetam_reachfreq_duration_id,  
      complex.exhibitor_id,  
      product_category_sub_concat_id,  
      avail.movie_id,  
      avail.country_code  
   
select @error = @@error  
if @error <> 0   
begin  
 raiserror('Error: failed to delete complex level targets', 16, 1)  
 return -1  
end  
  
/*  
 * Check Current Level of Bookings  
 * - a) those complexes excluded by current level of bookings  
 * - b) Those complexes excluded by product category  
 */  
  
  
--a  
update  #availability_attendance_ff  
set   product_booked_percentage = temp_table.attendance_target  
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
and    #availability_attendance_ff.movie_id = temp_table.movie_id  
*/
  
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
  
/*  
 * Return Data or insert into table  
 */  
  
select * from #availability_attendance_ff  
where demo_attendance <> 0  
  
/*  
 * Return  
 */  
  
return 0
GO
