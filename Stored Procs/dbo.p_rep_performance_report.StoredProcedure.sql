/****** Object:  StoredProcedure [dbo].[p_rep_performance_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rep_performance_report]
GO
/****** Object:  StoredProcedure [dbo].[p_rep_performance_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_rep_performance_report]     @country			char(1),
										  @start_date		datetime,
                                    	  @end_date			datetime,
                                    	  @count				integer,
                                         @sort_type   	char(1)
as
set nocount on 
/*
 * Declare Variables
 */

declare	@ranking			integer,
			@id_value		integer,
			@description	varchar(50),
			@branch			varchar(50),
			@value			money,
			@volume			integer,
			@counter			integer,
			@total_value	money,
			@total_volume	integer,
			@check_count	integer,
			@other_desc		varchar(50),
			@break			tinyint,
			@result_value	money,
			@result_volume	integer



/*
 * Create Work Table
 */

create table #work_table
(
   id_value				integer				null,
	description		   varchar(100)		null,
	branch				varchar(50)			null,
	value					money					null,
	volume				integer				null
)

/*
 * Create Results Table
 */

create table #results
(  
	ranking				integer				null,
	id_value			   integer				null,
	description		   varchar(100)		null,
	branch				varchar(50)			null,
	value					money					null,
	volume				integer				null
)

select @total_value = 0,
       @total_volume	= 0

/*
* Cursor get all Reps
*/
declare		perf_csr cursor static for
	select	fc.rep_id,
			sum(spot.charge_rate),
			count(spot.charge_rate)
	from	campaign_spot spot,
			film_campaign fc,
			branch b       
	where	spot.billing_date >= @start_date and
			spot.billing_date <= @end_date and
			spot.campaign_no = fc.campaign_no and
			spot.spot_status <> 'P' and
			fc.branch_code = b.branch_code and
			b.country_code = @country			
group by	fc.rep_id
for read only
/*
 * Loop Campaigns
 */
open perf_csr
fetch perf_csr into @id_value, @value, @volume
while (@@Fetch_status=0)
begin

	/*
    * Add to Totals
    */

	select @total_value = @total_value + @value
   select @total_volume	= @total_volume + @volume

	/*
 	 * Get Rep Information
 	 */	

	select @description = sr.last_name + ', ' + sr.first_name,
		    @branch = b.branch_name,
			 @other_desc = 'Other Reps'
     from film_campaign fc,
   		 sales_rep sr,
			 branch b
    where fc.rep_id = @id_value and
	   	 fc.rep_id = sr.rep_id and
			 fc.branch_code = b.branch_code

	/*
    * Write to work_table
 	 */

	select @check_count = count(id_value)
     from #work_table
    where id_value = @id_value

	if(@check_count = 1)
	begin
	
		update #work_table
         set value = value + @value,
             volume = volume + @volume
       where id_value = @id_value

	end
	else
	begin

			insert into #work_table (
                id_value,
					 description,
					 branch,
					 value,
					 volume ) values (
 					 @id_value,
					 @description,
					 @branch,
					 @value,
					 @volume )	
       
	end

	/*
    * Fetch Next
    */

	 fetch perf_csr into @id_value, @value, @volume

end

close perf_csr
deallocate perf_csr

/*
 * Loop For Results
 */

select	@counter = 0,
		@break = 0,
		@result_value = 0,
		@result_volume = 0

if (@sort_type = 'V')
begin

	/*
    * Retrieve data from #work_table order by Value
    */

	declare work_csr cursor static for
	 select id_value,
			  description,
			  branch,
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
	 select id_value,
			  description,
			  branch,
			  value,
			  volume 
	   from #work_table
  order by volume desc
	     for read only
end

open work_csr

while(@break = 0) and (@counter < @count)
begin

	fetch work_csr into @id_value, @description, @branch, @value, @volume
	if(@@fetch_status = 0)
	begin

		/*
       * Calculate Result Totals
       */
  
		select @result_value = @result_value + @value,
				 @result_volume = @result_volume + @volume,
    	 	    @counter = @counter + 1		
		
		insert into #results ( ranking,
									  id_value,
									  description,
									  branch,
									  value,
									  volume ) values (
									  @counter,
									  @id_value,
									  @description,
								     @branch,
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
		 id_value,
		 description,
		 branch,
		 value,
		 volume 
  from #results

/*
 * Return Success
 */

return 0
GO
