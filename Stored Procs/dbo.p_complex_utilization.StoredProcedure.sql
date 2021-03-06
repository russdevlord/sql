/****** Object:  StoredProcedure [dbo].[p_complex_utilization]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_complex_utilization]
GO
/****** Object:  StoredProcedure [dbo].[p_complex_utilization]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_complex_utilization]  @arg_country_code     char(3),
                                   @arg_film_market_no   int,
                                   @arg_complex_id	     int,
        						   @arg_start_date		 datetime,
        						   @arg_end_date		 datetime
as

set nocount on

/*
 * Declare Variables
 */

declare @max_time			int,
        @max_ads			int,
        @prior_period_max_time			int,
        @prior_period_max_ads			int,
        @book_time			int,
        @book_ads			int,
        @prior_period_book_time			int,
        @prior_period_book_ads			int,
        @errorode				int,
        @complex_id         int,
        @complex_csr_open   int,
        @screening_month    datetime

/*
* Instantiate initial values 
*/

if isNull(@arg_end_date, '1900-01-01') = '1900-01-01'
    select @arg_end_date = @arg_start_date    

select @arg_end_date = dateadd(month, 1, @arg_end_date)

/*
 * Create Table to Hold Utilization Information
 */

create table #utilization
(
	complex_id		       int        null,
	screening_month        datetime		null,
	max_ads	               int        null,
    max_time	           int        null,
	prior_period_max_ads   int        null,
    prior_period_max_time  int        null,
	booked_ads	           int		  null,
    booked_time	           int        null,
	proir_period_booked_ads	   int    null,
    prior_period_booked_time   int    null
)

/*
 * Declare Cursors
 */
  declare complex_csr cursor static for
   select c.complex_id         
      from complex c,
           branch b
     where c.state_code  = b.state_code and
           c.film_complex_status <> 'C' and
           (c.complex_id = @arg_complex_id or @arg_complex_id = 0) and
           (b.country_code = @arg_country_code or @arg_country_code = '') and
           (c.film_market_no = @arg_film_market_no or @arg_film_market_no = 0) 
       for read only

/*
 * Loop Through Complexes
 */

open complex_csr
select @complex_csr_open = 1
fetch complex_csr into @complex_id
while(@@fetch_status=0)
begin
    select @screening_month = @arg_start_date

    while (@screening_month < @arg_end_date)
        begin


        /*
         * Calculate max ads and max time per month
         */
           select  @max_ads = IsNull(sum(cd.mg_max_ads * cd.movie_target), 0),
                   @max_time = IsNull(sum(cd.mg_max_time * cd.movie_target), 0)
              from complex_date cd,
                   complex c
             where cd.complex_id = c.complex_id and
                   (cd.complex_id = @complex_id) and
            	   datepart(month, cd.screening_date) = datepart(month,@screening_month) and
            	   datepart(year, cd.screening_date) = datepart(year,@screening_month) 

           select  @prior_period_max_ads = IsNull(sum(cd.mg_max_ads * cd.movie_target), 0),
                   @prior_period_max_time =  IsNull(sum(cd.mg_max_time * cd.movie_target), 0)
              from complex_date cd,
                   complex c
             where cd.complex_id = c.complex_id and
                   (cd.complex_id = @complex_id) and
            	   datepart(month, cd.screening_date) = datepart(month,@screening_month) and
            	   datepart(year, cd.screening_date) = datepart(year,@screening_month) - 1

        /*
         * Calculate Bookings per month
         */
            select @book_time = Isnull(sum(pack.duration),0),
            	   @book_ads = Isnull(sum(pack.prints),0)
              from campaign_spot spot,
            	   campaign_package pack,
                   film_campaign fc
             where spot.complex_id = @complex_id and
            	   datepart(month, spot.screening_date) = datepart(month,@screening_month) and
            	   datepart(year, spot.screening_date) = datepart(year,@screening_month) and
            	   spot.spot_status <> 'D' and
            	   spot.spot_status <> 'P' and
            	   spot.package_id = pack.package_id and
                   spot.campaign_no = fc.campaign_no and
                   pack.campaign_no = fc.campaign_no 

            select @prior_period_book_time = Isnull(sum(pack.duration),0),
            	   @prior_period_book_ads = Isnull(sum(pack.prints),0)
              from campaign_spot spot,
            	   campaign_package pack,
                   film_campaign fc
             where spot.complex_id = @complex_id and
            	   datepart(month, spot.screening_date) = datepart(month,@screening_month) and
            	   datepart(year, spot.screening_date) = datepart(year,@screening_month)- 1 and
            	   spot.spot_status <> 'D' and
            	   spot.spot_status <> 'P' and
            	   spot.package_id = pack.package_id and
                   spot.campaign_no = fc.campaign_no and
                   pack.campaign_no = fc.campaign_no 

                   insert into #utilization values
                        ( @complex_id,
                          @screening_month,
	                      @max_ads, 
	                      @max_time, 
	                      @prior_period_max_ads,
	                      @prior_period_max_time,
                          @book_ads,
                          @book_time,  
                          @prior_period_book_ads,
                          @prior_period_book_time)

                select @screening_month = dateadd(month, 1, @screening_month)
        end

	/*
	 * Fetch Next
	 */

    fetch complex_csr into @complex_id

end

close complex_csr
select @complex_csr_open = 0
deallocate complex_csr

/*
 * Return Overbooked Data
 */

  select b.country_code,
         fm.film_market_no,
         utl.complex_id,
         utl.screening_month,
	     utl.max_ads,
         utl.max_time,
	     utl.prior_period_max_ads,
         utl.prior_period_max_time,
	     utl.booked_ads,
         utl.booked_time,
	     utl.proir_period_booked_ads,
         utl.prior_period_booked_time
    from #utilization utl,
         complex cplx,
		 film_market fm,
         branch b
   where utl.complex_id = cplx.complex_id and
          b.state_code = cplx.state_code and
         cplx.film_market_no = fm.film_market_no

/*
 * Return Success
 */

return 0

/*
 * Error Handler
 */

error:

	if (@complex_csr_open = 1)
    begin
		close complex_csr
		deallocate complex_csr
	end
	return -1
GO
