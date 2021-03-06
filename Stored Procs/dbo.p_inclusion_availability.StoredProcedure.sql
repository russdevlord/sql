/****** Object:  StoredProcedure [dbo].[p_inclusion_availability]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_inclusion_availability]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_availability]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_inclusion_availability]   	@start_date		datetime,
                               	  		@film_market_no	int
                                      
as

/*
 * Declare Variables
 */

declare	    @loop_count				    int,
			@count						int,
			@end_date					datetime,
			@market_no					int,
			@complex_id					int,
			@complex_name				varchar(50),
			@film_complex_status		char(1),
			@movie_target				int,
			@screening_date				datetime,
			@avail_prints				int,
			@booked_prints				int,
			@screening_date_wk_1		datetime,
			@total_avail_prints_1		int,						
			@total_avail_dur_1			int,				
			@booked_prints_1			int,				
			@screening_date_wk_2		datetime,				
			@total_avail_prints_2	    int,						
			@total_avail_dur_2		    int,				
			@booked_prints_2			int,				
		    @screening_date_wk_3	    datetime,				
			@total_avail_prints_3	    int,						
			@booked_prints_3			int,				
			@total_avail_dur_3		    int,				
			@screening_date_wk_4		datetime,
			@total_avail_prints_4	    int,						
			@total_avail_dur_4		    int,				
			@booked_prints_4			int			
	
/*
 * Create Work Table
 */

create table #work_table
(	
	film_market_no			int				null,
	complex_id				int				null,
	complex_name			varchar(50)		null,
	film_complex_status	    char(1)			null,
    screening_date_wk_1	    datetime		null,	
	total_avail_prints_1	int				null,
	booked_prints_1		    int				null,
    screening_date_wk_2	    datetime		null,
	total_avail_prints_2	int				null,
	booked_prints_2		    int				null,
	screening_date_wk_3	    datetime		null,
	total_avail_prints_3	int				null,
	booked_prints_3		    int				null,
	screening_date_wk_4	    datetime		null,
	total_avail_prints_4	int				null,
	booked_prints_4		    int				null
)

/*
 * Select End Date
 */

select @end_date = dateadd(wk, 4, @start_date)

/*
 * Loop Complex
 */

declare 	comp_csr cursor static for 
select 		c.film_market_no,
			c.complex_id, 
			c.complex_name,
			c.film_complex_status
from 		complex c
where 		c.film_complex_status != 'C' 
and			c.film_market_no = (case when @film_market_no = 0 then c.film_market_no else @film_market_no end )
order by 	c.film_market_no,
			c.complex_name
for read only

open comp_csr
fetch comp_csr into @market_no, @complex_id, @complex_name, @film_complex_status
while (@@fetch_status=0)
begin

	select @loop_count = 0

     declare fsd_csr cursor static for
      select fsd.screening_date,
		     1,
			 1
        from film_screening_dates fsd
       where fsd.screening_date >= @start_date and
		     fsd.screening_date <= @end_date 
    order by fsd.screening_date
	     for read only

	open fsd_csr
	fetch fsd_csr into @screening_date, @movie_target, @avail_prints
	while(@@fetch_status=0 and @loop_count < 4) 
	begin

		select @loop_count = @loop_count + 1
	
		/*
		 * Select the booked prints and duration
		 */

	  select @booked_prints = count(spot_id)   
		from inclusion_spot,   
			 inclusion,
             film_campaign fc
	   where inclusion_spot.complex_id = @complex_id and
			 inclusion_spot.screening_date = @screening_date and
			 inclusion_spot.spot_status <> 'P' and
			 inclusion_spot.spot_status <> 'C' and
			 inclusion_spot.spot_status <> 'H' and
			 inclusion_spot.spot_status <> 'D' and
			 inclusion_spot.inclusion_id = inclusion.inclusion_id and
             fc.campaign_no = inclusion_spot.campaign_no and
             fc.campaign_no = inclusion.campaign_no
	
	  /*
       * Screening Date 1
       */

		if (@loop_count = 1)
			select @screening_date_wk_1 = @screening_date,
					 @total_avail_prints_1 = (isnull(@movie_target, 0 ) * isnull(@avail_prints, 0)),
					 @booked_prints_1 = isnull(@booked_prints, 0 )

		/*
       * Screening Date 2
       */

		if (@loop_count = 2)
			select @screening_date_wk_2 = @screening_date,
					 @total_avail_prints_2 = (isnull(@movie_target, 0 ) * isnull(@avail_prints, 0 )),
					 @booked_prints_2 = isnull(@booked_prints, 0 )

		/*
       * Screening Date 3
       */

		if (@loop_count = 3)
			select @screening_date_wk_3 = @screening_date,
					 @total_avail_prints_3 = (isnull(@movie_target, 0) * isnull(@avail_prints, 0)),
					 @booked_prints_3 = isnull(@booked_prints, 0 )

		/*
       * Screening Date 4
       */

		if (@loop_count = 4)
			select @screening_date_wk_4 = @screening_date,
					 @total_avail_prints_4 = (isnull(@movie_target, 0) * isnull(@avail_prints, 0)),
					 @booked_prints_4 = isnull(@booked_prints, 0 )


		/*
       * Fetch Next
       */

	  fetch fsd_csr into @screening_date, @movie_target, @avail_prints

	end

	close fsd_csr
	deallocate fsd_csr
	
	/*
    * Insert
    */

	insert into #work_table (film_market_no,
                            complex_id,
							complex_name,
							film_complex_status,
							screening_date_wk_1,	
							total_avail_prints_1,
							booked_prints_1,
							screening_date_wk_2, 
							total_avail_prints_2, 
							booked_prints_2, 
							screening_date_wk_3,
							total_avail_prints_3, 
							booked_prints_3, 
							screening_date_wk_4,
							total_avail_prints_4, 
							booked_prints_4  ) values (
							@market_no,
							@complex_id,
							@complex_name,
							@film_complex_status,
							@screening_date_wk_1,
							@total_avail_prints_1,
							@booked_prints_1,
							@screening_date_wk_2, 
							@total_avail_prints_2, 
							@booked_prints_2, 
							@screening_date_wk_3,
							@total_avail_prints_3, 
							@booked_prints_3,
							@screening_date_wk_4,
							@total_avail_prints_4, 
							@booked_prints_4 )

	/*
    * Fetch Next
    */

	fetch comp_csr into @market_no, @complex_id, @complex_name, @film_complex_status

end	

close comp_csr
deallocate comp_csr

/*
 * Return Result Set
 */

select *
  from #work_table

/*
 * Return Success
 */

return 0
GO
