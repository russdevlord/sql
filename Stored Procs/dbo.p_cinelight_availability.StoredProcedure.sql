/****** Object:  StoredProcedure [dbo].[p_cinelight_availability]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelight_availability]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_availability]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinelight_availability]   	@start_date		datetime,
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
			@cinelight_id				int,
			@cinelight_desc				varchar(50),
			@film_complex_status		char(1),
			@movie_target				int,
			@screening_date				datetime,
			@avail_prints				int,
			@avail_duration				int,
			@booked_prints				int,
			@booked_duration			int,
			@screening_date_wk_1		datetime,
			@total_avail_prints_1		int,						
			@total_avail_duration_1		int,						
			@avail_duration_1			int,	
			@total_avail_dur_1			int,				
			@booked_prints_1			int,				
			@booked_duration_1			int,				
			@screening_date_wk_2		datetime,				
			@total_avail_prints_2	    int,						
			@total_avail_duration_2		int,						
			@avail_duration_2			int,	
			@total_avail_dur_2		    int,				
			@booked_prints_2			int,				
			@booked_duration_2			int,				
		    @screening_date_wk_3	    datetime,				
			@total_avail_prints_3	    int,						
			@total_avail_duration_3		int,						
			@avail_duration_3			int,	
			@booked_prints_3			int,				
			@booked_duration_3			int,				
			@total_avail_dur_3		    int,		
			@screening_date_wk_4		datetime,
			@total_avail_prints_4	    int,						
			@total_avail_duration_4		int,						
			@avail_duration_4			int,	
			@total_avail_dur_4		    int,				
			@booked_prints_4			int,
			@booked_duration_4			int,				
			@cinelight_type				int
	

/*
 * Create Work Table
 */

create table #work_table
(	
	film_market_no			int				null,
	complex_id				int				null,
	complex_name			varchar(50)		null,
	cinelight_id			int				null,
	cinelight_name			varchar(50)		null,
	cinelight_type		 	int				null,
	film_complex_status	    char(1)			null,
    screening_date_wk_1	    datetime		null,	
	total_avail_prints_1	int				null,
	total_avail_duration_1	int				null,
	booked_prints_1		    int				null,
	booked_duration_1		int				null,
    screening_date_wk_2	    datetime		null,
	total_avail_prints_2	int				null,
	total_avail_duration_2	int				null,
	booked_prints_2		    int				null,
	booked_duration_2		int				null,
	screening_date_wk_3	    datetime		null,
	total_avail_prints_3	int				null,
	total_avail_duration_3	int				null,
	booked_prints_3		    int				null,
	booked_duration_3	    int				null,
	screening_date_wk_4	    datetime		null,
	total_avail_prints_4	int				null,
	total_avail_duration_4	int				null,
	booked_prints_4		    int				null,
	booked_duration_4	    int				null
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
			c.film_complex_status,
			cl.cinelight_id,
			cl.cinelight_desc
from 		complex c,
			cinelight cl
where 		c.film_complex_status != 'C' 
and			c.film_market_no = (case when @film_market_no = 0 then c.film_market_no else @film_market_no end )
and			c.complex_id = cl.complex_id
order by 	c.film_market_no,
			c.complex_name,
			cl.cinelight_desc
for read only

open comp_csr
fetch comp_csr into @market_no, @complex_id, @complex_name, @film_complex_status, @cinelight_id, @cinelight_desc
while (@@fetch_status=0)
begin

	select @loop_count = 0

	declare 	fsd_csr cursor static for
	select 		cd.screening_date,
				1,
				cd.max_ads,
				cd.max_time
	from 		cinelight_date cd
	where 		cd.screening_date between @start_date and @end_date 
	and			cd.cinelight_id = @cinelight_id
	order by 	cd.screening_date
	for read only

	open fsd_csr
	fetch fsd_csr into @screening_date, @movie_target, @avail_prints, @avail_duration
	while(@@fetch_status=0 and @loop_count < 4) 
	begin

		select @loop_count = @loop_count + 1
	
		/*
		 * Select the booked prints and duration
		 */

		select		@booked_prints = count(cinelight_spot.spot_id),
					@booked_duration = sum(cinelight_package.duration)   
		from 		cinelight_spot,   
					cinelight_package,
					film_campaign fc
		where 		cinelight_spot.cinelight_id = @cinelight_id and
					cinelight_spot.screening_date = @screening_date and
					cinelight_spot.spot_status <> 'P' and
					cinelight_spot.spot_status <> 'C' and
					cinelight_spot.spot_status <> 'H' and
					cinelight_spot.spot_status <> 'D' and
					cinelight_spot.package_id = cinelight_package.package_id and
					fc.campaign_no = cinelight_spot.campaign_no and
					fc.campaign_no = cinelight_package.campaign_no
	
	  /*
       * Screening Date 1
       */

		if (@loop_count = 1)
			select  @screening_date_wk_1 = @screening_date,
					@total_avail_prints_1 = (isnull(@movie_target, 0 ) * isnull(@avail_prints, 0)),
					@booked_prints_1 = isnull(@booked_prints, 0 ),
					@booked_duration_2 = isnull(@booked_duration, 0 )

	  /*
		* Screening Date 2
		*/

		if (@loop_count = 2)
			select 	@screening_date_wk_2 = @screening_date,
					@total_avail_prints_2 = (isnull(@movie_target, 0 ) * isnull(@avail_prints, 0 )),
					@booked_prints_2 = isnull(@booked_prints, 0 ),
					@booked_duration_2 = isnull(@booked_duration, 0 )

		/*
       * Screening Date 3
       */

		if (@loop_count = 3)
			select 	@screening_date_wk_3 = @screening_date,
					@total_avail_prints_3 = (isnull(@movie_target, 0) * isnull(@avail_prints, 0)),
					@booked_prints_3 = isnull(@booked_prints, 0 ),
					@booked_duration_3 = isnull(@booked_duration, 0 )

		/*
       * Screening Date 4
       */

		if (@loop_count = 4)
			select 	@screening_date_wk_4 = @screening_date,
					@total_avail_prints_4 = (isnull(@movie_target, 0) * isnull(@avail_prints, 0)),
					@booked_prints_4 = isnull(@booked_prints, 0 ),
					@booked_duration_4 = isnull(@booked_duration, 0 )


		/*
       * Fetch Next
       */

	  fetch fsd_csr into @screening_date, @movie_target, @avail_prints, @avail_duration

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
							booked_duration_1,
							screening_date_wk_2, 
							total_avail_prints_2, 
							booked_prints_2, 
							booked_duration_2,
							screening_date_wk_3,
							total_avail_prints_3, 
							booked_prints_3, 
							booked_duration_3,
							screening_date_wk_4,
							total_avail_prints_4, 
							booked_prints_4,
							booked_duration_4 ) values (
							@market_no,
							@complex_id,
							@complex_name,
							@film_complex_status,
							@screening_date_wk_1,
							@total_avail_prints_1,
							@booked_prints_1,
							@booked_duration_1,
							@screening_date_wk_2, 
							@total_avail_prints_2, 
							@booked_prints_2, 
							@booked_duration_2,
							@screening_date_wk_3,
							@total_avail_prints_3, 
							@booked_prints_3,
							@booked_duration_3,
							@screening_date_wk_4,
							@total_avail_prints_4, 
							@booked_prints_4,
							@booked_duration_4 )

	/*
    * Fetch Next
    */

	fetch comp_csr into @market_no, @complex_id, @complex_name, @film_complex_status, @cinelight_id, @cinelight_desc

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
