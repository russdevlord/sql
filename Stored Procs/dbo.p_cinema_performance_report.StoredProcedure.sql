/****** Object:  StoredProcedure [dbo].[p_cinema_performance_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinema_performance_report]
GO
/****** Object:  StoredProcedure [dbo].[p_cinema_performance_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinema_performance_report]       @country			char(1),
															 @start_date		datetime,
		                                        @end_date			datetime,
		                                        @count				integer,
		                                        @sort_type   		char(1)
as

/*
 * Declare Variables
 */

declare	@ranking			integer,
			@value			money,
			@volume			integer,
			@counter			integer,
			@total_value	money,
			@total_volume	integer,
			@check_count	integer,
			@other_desc		varchar(50),
			@break			tinyint,
			@result_value	money,
			@result_volume	integer,
			@complex_id		integer,
			@complex_name	varchar(100),
			@film_market_no integer

/*
 * Create Work Table
 */

create table #work_table
(
   complex_id			integer				null,
	complex_name		varchar(100)		null,
	film_market_no		integer				null,
	value					money					null,
	volume				integer				null
)

/*
 * Create Results Table
 */

create table #results
(  
	ranking				integer				null,
	complex_id		   integer				null,
	complex_name		varchar(100)		null,
	film_market_no		integer				null,
	value					money					null,
	volume				integer				null
)

select @total_value = 0,
       @total_volume	= 0

/*
 * Cursor get all Cinemas
*/

 declare perf_csr cursor static for
  select spot.complex_id,
         max(c.complex_name),
	      max(c.film_market_no),
		   sum(spot.charge_rate),
         count(spot.charge_rate)
    from campaign_spot spot,
	 	   complex c,
			film_campaign fc,
         branch b
   where spot.billing_date >= @start_date and
         spot.billing_date <= @end_date and
  	      spot.complex_id = c.complex_id and
			spot.spot_status <> 'P' and
			spot.campaign_no = fc.campaign_no and
         fc.branch_code = b.branch_code and
         b.country_code = @country  
group by spot.complex_id
  		for read only

/*
 * Loop Campaigns
 */

open perf_csr
fetch perf_csr into @complex_id, @complex_name, @film_market_no, @value, @volume
while (@@fetch_status=0)
begin

	/*
    * Add to Totals
    */

	select @total_value = @total_value + @value
   select @total_volume	= @total_volume + @volume

	/*
 	 * Get Other Cinema Information
 	 */	

	select @other_desc = 'Other Cinemas'
		
	/*
    * Write to work_table
 	 */

	select @check_count = count(complex_id)
     from #work_table
    where complex_id = @complex_id

	if(@check_count = 1)
	begin
	
		update #work_table
         set value = value + @value,
             volume = volume + @volume
       where complex_id = @complex_id

	end
	else
	begin

			insert into #work_table (
                complex_id,
					 complex_name,
					 film_market_no,
					 value,
					 volume) values (
 					 @complex_id,
					 @complex_name,
					 @film_market_no,
					 @value,
					 @volume )	
       
	end

	/*
    * Fetch Next
    */

	 fetch perf_csr into @complex_id, @complex_name, @film_market_no, @value, @volume

end

close perf_csr

/*
 * Loop For Results
 */

select @counter = 0,
		 @break = 0,
	    @result_value = 0,
		 @result_volume = 0

if (@sort_type = 'V')
begin

	/*
    * Retrieve data from #work_table order by Value
    */

	declare work_csr cursor static for
	 select complex_id,
			  complex_name,
			  film_market_no,
			  value,
			  volume
	   from #work_table
  order by value desc
	     for read only
end
else
begin

	/*
    * Retrieve data from #work_table order by Volume
    */

	declare work_csr cursor static for
	 select complex_id,
			  complex_name,
			  film_market_no,
			  value,
			  volume
	   from #work_table
  order by volume desc
	     for read only
end


		 
open work_csr

while(@break = 0) and (@counter < @count)
begin

	fetch work_csr into @complex_id, @complex_name, @film_market_no, @value, @volume
	if(@@fetch_status = 0)
	begin

		/*
       * Calculate Result Totals
       */
  
		select @result_value = @result_value + @value,
				 @result_volume = @result_volume + @volume,
    	 	    @counter = @counter + 1		
		
		insert into #results ( ranking,
									  complex_id,
			  						  complex_name,
			  						  film_market_no,
			  						  value,
			  						  volume ) values (
									  @counter,
									  @complex_id,
									  @complex_name,
									  @film_market_no,
									  @value,
									  @volume )						
			
	end
	else
		select @break = 1
	
end

/*
 * Close Cursor
 */

close work_csr
deallocate work_csr
		
/*
 * Combine Remaining Entries
 */

select @total_value = @total_value - @result_value,
       @total_volume = @total_volume - @result_volume

insert into #results values(null, null, @other_desc, null, @total_value, @total_volume)

select ranking,
		 complex_id,
		 complex_name,
		 film_market_no,
		 value,
		 volume 
  from #results

/*
 * Return Success
 */

return 0
GO
