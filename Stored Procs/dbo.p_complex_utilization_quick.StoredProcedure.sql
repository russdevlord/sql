/****** Object:  StoredProcedure [dbo].[p_complex_utilization_quick]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_complex_utilization_quick]
GO
/****** Object:  StoredProcedure [dbo].[p_complex_utilization_quick]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_complex_utilization_quick]     @arg_country_code       char(3),
                                            @arg_film_market_no     int,
                                            @arg_complex_id	        int,
                                            @arg_start_date		    datetime,
                                            @arg_end_date		    datetime
as

set nocount on

/*
 * Declare Variables
 */

declare @max_time			int,
        @max_ads			int,
        @book_time			int,
        @book_ads			int,
        @errorode				int,
        @complex_id         int,
        @complex_csr_open   int,
        @screening_month    datetime

/*
 * Create Table to Hold Utilization Information
 */

create table #utilization
(
	complex_id		            int     null,
	max_ads	                    int     null,
    max_time	                int     null,
	booked_ads	                int     null,
    booked_time	                int     null
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
        /*
         * Calculate max ads and max time per month
         */
           select  @max_ads = IsNull(sum(cd.mg_max_ads * cd.movie_target), 0),
                   @max_time = IsNull(sum(cd.mg_max_time * cd.movie_target), 0)
              from complex_date cd,
                   complex c
             where cd.complex_id = c.complex_id and
                   (cd.complex_id = @complex_id) and
            	   cd.screening_date between @arg_start_date and @arg_end_date

           select  @max_ads = @max_ads + IsNull(sum(cd.max_ads * cd.movie_target), 0),
                   @max_time =@max_time + IsNull(sum(cd.max_time * cd.movie_target), 0)
              from complex_date cd,
                   complex c
             where cd.complex_id = c.complex_id and
                   (cd.complex_id = @complex_id) and
            	   cd.screening_date between @arg_start_date and @arg_end_date

        /*
         * Calculate Bookings per month
         */
            select @book_time = Isnull(sum(pack.duration),0),
            	   @book_ads = Isnull(sum(pack.prints),0)
              from campaign_spot spot,
            	   campaign_package pack,
                   film_campaign fc
             where spot.complex_id = @complex_id and
            	   spot.screening_date between @arg_start_date and @arg_end_date and
            	   spot.spot_status <> 'D' and
            	   spot.spot_status <> 'P' and
            	   spot.package_id = pack.package_id and
                   spot.campaign_no = fc.campaign_no and
                   pack.campaign_no = fc.campaign_no 

                   insert into #utilization values
                        ( @complex_id,
	                      @max_ads, 
	                      @max_time, 
                          @book_ads,
                          @book_time)


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

select      b.country_code,
            fm.film_market_no,
            utl.complex_id,
            utl.max_ads,
            utl.max_time,
            utl.booked_ads,
            utl.booked_time,
            @arg_start_date as arg_start_date,
            @arg_end_date
from        #utilization utl,
            complex cplx,
            film_market fm,
            branch b
where       utl.complex_id = cplx.complex_id 
and         b.state_code = cplx.state_code 
and         cplx.film_market_no = fm.film_market_no

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
