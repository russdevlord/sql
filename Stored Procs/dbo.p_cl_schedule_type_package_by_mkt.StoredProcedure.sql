/****** Object:  StoredProcedure [dbo].[p_cl_schedule_type_package_by_mkt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cl_schedule_type_package_by_mkt]
GO
/****** Object:  StoredProcedure [dbo].[p_cl_schedule_type_package_by_mkt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create  PROC [dbo].[p_cl_schedule_type_package_by_mkt] @campaign_no 	   integer	  
as

/*
 * Declare Variables
 */
 
declare  @errorode					integer,
         @error         		integer,
         @rowcount				integer,
		 @campaign_value 		money,
		 @campaign_cost 		money,
		 @makegood_cost 		money,
		 @standby_value			money,
		 @package_id 			integer,
		 @package_code 			varchar(2),
         @package_desc          varchar(100)

/*
 * Create Results Table
 */
 
create table #results 
(
	package_code		varchar(2)			null,
	package_desc		varchar(100)		null,
	display_group		smallint	        null,
	display_order		smallint	        null,
	label				varchar(50)		    null,
    value				money				null,
    charge				money				null,
    makegood			money				null,
	number				integer				null,
    film_market_no      int                 null,
    film_market_desc    varchar(40)         null
)

/*
 * Declare Cursors
 */
 
 declare package_csr cursor static for
  select package_id, 
	 	 package_code,
         package_desc
    from cinelight_package
   where campaign_no = @campaign_no
order by package_code
     for read only
     
/*
 * Loop Packages
 */
 	
open package_csr
fetch package_csr into @package_id, @package_code, @package_desc
while(@@fetch_status=0)
begin
	
    /*
     * Calculate 'Scheduled' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           1,
           1,
           'Scheduled',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate),
           film_market.film_market_no,
            film_market_desc
	  from cinelight_spot, cinelight, film_market, complex
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_type = 'S' 
    and     cinelight_spot.cinelight_id = cinelight.cinelight_id
and complex.complex_id =  cinelight.complex_id
    and     complex.film_market_no = film_market.film_market_no   
group by    film_market.film_market_no,
            film_market_desc

    /*
     * Calculate 'Manual' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           1,
           2,
           'Revenue',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate),
           film_market.film_market_no,
           film_market_desc
	  from cinelight_spot, cinelight, film_market, complex
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_type = 'R'
    and     cinelight_spot.cinelight_id = cinelight.cinelight_id
and complex.complex_id =  cinelight.complex_id
    and     complex.film_market_no = film_market.film_market_no        
group by    film_market.film_market_no,
            film_market_desc
	
    /*
     * Calculate 'Standby' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           1,
           3,
           'Stand By',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate),
           film_market.film_market_no,
           film_market_desc
	  from cinelight_spot, cinelight, film_market, complex
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_type = 'Y'
    and     cinelight_spot.cinelight_id = cinelight.cinelight_id
and complex.complex_id =  cinelight.complex_id
    and     complex.film_market_no = film_market.film_market_no        
group by    film_market.film_market_no,
            film_market_desc

    /*
     * Calculate 'Contra' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           2,
           4,
           'Contra',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate),
           film_market.film_market_no,
           film_market_desc
	  from cinelight_spot, cinelight, film_market, complex
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_type = 'C'
    and     cinelight_spot.cinelight_id = cinelight.cinelight_id
and complex.complex_id =  cinelight.complex_id
    and     complex.film_market_no = film_market.film_market_no        
group by    film_market.film_market_no,
            film_market_desc

    /*
     * Calculate 'Bonus' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           2,
           5,
           'Bonus',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate),
           film_market.film_market_no,
           film_market_desc
	  from cinelight_spot, cinelight, film_market, complex
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_type = 'B'
    and     cinelight_spot.cinelight_id = cinelight.cinelight_id
and complex.complex_id =  cinelight.complex_id
    and     complex.film_market_no = film_market.film_market_no        
group by    film_market.film_market_no,
            film_market_desc

    /*
     * Calculate 'No Charge' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           2,
           6,
           'No Charge',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate),
           film_market.film_market_no,
           film_market_desc
	  from cinelight_spot, cinelight, film_market, complex
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_type = 'N'
    and     cinelight_spot.cinelight_id = cinelight.cinelight_id
and complex.complex_id =  cinelight.complex_id
    and     complex.film_market_no = film_market.film_market_no        
group by    film_market.film_market_no,
            film_market_desc
            
    /*
     * Calculate 'No Charge' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           2,
           7,
           'Goodwill Bonus',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate),
           film_market.film_market_no,
           film_market_desc
	  from cinelight_spot, cinelight, film_market, complex
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_type = 'W'
    and     cinelight_spot.cinelight_id = cinelight.cinelight_id
and complex.complex_id =  cinelight.complex_id
    and     complex.film_market_no = film_market.film_market_no        
group by    film_market.film_market_no,
            film_market_desc
	            
	
    /*
     * Calculate 'Makegood' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           3,
           8,
           'Make Good',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate),
           film_market.film_market_no,
           film_market_desc
	  from cinelight_spot, cinelight, film_market, complex
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_type = 'D'
    and     cinelight_spot.cinelight_id = cinelight.cinelight_id
and complex.complex_id =  cinelight.complex_id
    and     complex.film_market_no = film_market.film_market_no        
group by    film_market.film_market_no,
            film_market_desc
	
    /*
     * Calculate 'Makeup' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           3,
           98,
           'Makeup',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate),
           film_market.film_market_no,
           film_market_desc
	  from cinelight_spot, cinelight, film_market, complex
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_type = 'M'
    and     cinelight_spot.cinelight_id = cinelight.cinelight_id
and complex.complex_id =  cinelight.complex_id
    and     complex.film_market_no = film_market.film_market_no        
group by    film_market.film_market_no,
            film_market_desc
	
    /*
     * Calculate 'Manual' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           3,
           10,
           'Manual',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate),
           film_market.film_market_no,
           film_market_desc
	  from cinelight_spot, cinelight, film_market, complex
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_type = 'V'
    and     cinelight_spot.cinelight_id = cinelight.cinelight_id
and complex.complex_id =  cinelight.complex_id
    and     complex.film_market_no = film_market.film_market_no        
group by    film_market.film_market_no,
            film_market_desc
	
    /*
     * Fetch Next
     */
     
    fetch package_csr into @package_id, @package_code, @package_desc

end

close package_csr
deallocate package_csr

/*
 * Return Result Set
 */
 
select package_code,
	   package_desc,
	   display_group,
	   display_order,
	   label,
       value,
       charge,
       makegood,
	   number,
       film_market_no,
       film_market_desc
  from #results

return 0
GO
