/****** Object:  StoredProcedure [dbo].[p_film_premium_availability]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_premium_availability]
GO
/****** Object:  StoredProcedure [dbo].[p_film_premium_availability]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_film_premium_availability]     @start_date		datetime,
                               	            @film_market_no	int                                      
as

/*
 * Declare Variables
 */

declare	@loop_count					    int,
			@count						int,
			@end_date					datetime,
			@market_no					int,
			@complex_id					int,
			@complex_name				varchar(50),
			@film_complex_status		char(1),
			@movie_target				int,
			@screening_date			    datetime,
			@avail_prints				int,
			@booked_prints				int,
			@screening_date_wk_1		datetime,
			@total_avail_prints_1	    int,						
			@booked_prints_1			int,				
			@screening_date_wk_2		datetime,				
			@total_avail_prints_2   	int,						
			@booked_prints_2			int,				
		    @screening_date_wk_3		datetime,				
			@total_avail_prints_3	    int,						
			@booked_prints_3			int,				
			@total_avail_dur_3		    int,				
			@screening_date_wk_4		datetime,
			@total_avail_prints_4	    int,						
			@booked_prints_4			int,
			@premium_variance			numeric(6,4),
			@non_prem_spon_count		int,
			@reading_count				int
	
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
 * Cursor - Market Complexes
 */

if @film_market_no = 0 
begin
 declare comp_csr cursor static for 
  select c.film_market_no,
         c.complex_id, 
		 c.complex_name,
		 c.film_complex_status
    from complex c
   where c.film_complex_status != 'C'
order by c.film_market_no,
		 c.complex_name
     for read only
end
else
begin
 declare comp_csr cursor static for 
  select c.film_market_no,
         c.complex_id, 
		 c.complex_name,
		 c.film_complex_status
	from complex c
   where c.film_complex_status != 'C' and
         c.film_market_no = @film_market_no
order by c.film_market_no,
		 c.complex_name
     for read only
end

/*
 * Loop Complex
 */

open comp_csr
fetch comp_csr into @market_no, @complex_id, @complex_name, @film_complex_status
while (@@fetch_status=0)
begin

	select @loop_count = 0

	select 	@reading_count = count(complex_id)
	from	complex
	where 	complex_id = @complex_id
	and		exhibitor_id = 187 
		
	/*
	 * Cursor - Next 4 Complex Dates
	 */

	 declare cd_csr cursor static for
	  select cd.screening_date,
			 cd.movie_target
	    from complex_date cd
	   where cd.screening_date >= @start_date and
			 cd.screening_date <= @end_date and
			 cd.complex_id = @complex_id
	order by cd.screening_date,
			 cd.movie_target
		   for read only

	open cd_csr
	fetch cd_csr into @screening_date, @movie_target
	while(@@fetch_status=0 and @loop_count < 4) 
	begin

		select @loop_count = @loop_count + 1


		select 	@non_prem_spon_count = count(spot_id)
		from	campaign_spot,
				campaign_package
		where	campaign_spot.package_id = campaign_package.package_id
		and		campaign_spot.complex_id = @complex_id
		and		campaign_spot.screening_date = @screening_date
		and		campaign_spot.spot_status <> 'P'
		and		campaign_package.all_movies = 'Y'
		and		campaign_package.premium_screen_type = 'N'
	
		if @non_prem_spon_count > 0 
			select @premium_variance = 0.0
		else if @reading_count > 1 
			select @premium_variance = 0.250
		else
			select @premium_variance = 0.5
	
		select 	@movie_target = round(@movie_target * @premium_variance,0)

		/*
		 * Select the booked prints and duration
		 */

	  select @booked_prints = count(campaign_package.package_id)   
		from campaign_spot,   
			 campaign_package
 	   where campaign_spot.complex_id = @complex_id and
			 campaign_spot.screening_date = @screening_date and
		 	 campaign_spot.spot_status <> 'P' and
			 campaign_spot.spot_status <> 'C' and
			 campaign_spot.spot_status <> 'H' and
			 campaign_spot.spot_status <> 'D' and
			 campaign_spot.package_id = campaign_package.package_id and
             (campaign_package.screening_trailers = 'B' or
             campaign_package.screening_trailers = 'F')
	
	  /*
       * Screening Date 1
       */

		if (@loop_count = 1)
			select @screening_date_wk_1 = @screening_date,
				   @total_avail_prints_1 = isnull(@movie_target, 0),
				   @booked_prints_1 = isnull(@booked_prints, 0 )

		/*
       * Screening Date 2
       */

		if (@loop_count = 2)
			select @screening_date_wk_2 = @screening_date,
				   @total_avail_prints_2 = isnull(@movie_target, 0),
				   @booked_prints_2 = isnull(@booked_prints, 0 )

		/*
       * Screening Date 3
       */

		if (@loop_count = 3)
			select @screening_date_wk_3 = @screening_date,
				   @total_avail_prints_3 = isnull(@movie_target, 0),
				   @booked_prints_3 = isnull(@booked_prints, 0 )

		/*
       * Screening Date 4
       */

		if (@loop_count = 4)
			select @screening_date_wk_4 = @screening_date,
				   @total_avail_prints_4 = isnull(@movie_target, 0),
				   @booked_prints_4 = isnull(@booked_prints, 0 )


		/*
       * Fetch Next
       */

	  fetch cd_csr into @screening_date, @movie_target

	end

	close cd_csr
	deallocate cd_csr
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
							@booked_prints_4)

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
