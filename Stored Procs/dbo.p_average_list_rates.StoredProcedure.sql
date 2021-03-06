/****** Object:  StoredProcedure [dbo].[p_average_list_rates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_average_list_rates]
GO
/****** Object:  StoredProcedure [dbo].[p_average_list_rates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_average_list_rates]	@mode					tinyint,
                                 @country				char(1),
											@start_date			datetime,
        									@end_date			datetime,
                                 @min_duration		smallint,
											@max_duration		smallint

as

/*
 * Decalare Variables
 */

declare 	@error					integer,
			@first_name				varchar(30),
			@last_name				varchar(30),
         @campaign_no			integer,
         @store_campaign_no	integer,
			@campaign_status		char(1),
			@product_desc			varchar(100),
			@pack_code				char(1),
			@pack_duration			smallint,
			@pack_prints			smallint,
			@pack_average_rate	money,
         @pack_spend				money,
			@pack_spot_count		integer,
         @package_id				integer,
			@country_name			varchar(30)
		

/*
 * Declare Cursors
 */





/*
 * Create Temporary Table
 */

create table #results
(
	campaign_no			integer				null,
	product_desc		varchar(100)		null,
	campaign_status	char(1)				null,
	first_name			varchar(30)			null,
	last_name			varchar(30)			null,
	pack_code			char(1)				null,
	pack_duration		smallint				null,
	pack_prints			smallint				null,
	average_rate		money					null,
	spot_count			integer				null,
   total_spend			money					null,
	country_name		varchar(30)			null
)

/*
 * Initialise Variables
 */

select @store_campaign_no = 0

select @country_name = c.country_name
  from country c
 where c.country_code = @country

/*
 * Loop Packages for Mode 1
 */

if(@mode = 1)
begin
	 declare mode1_csr cursor static for
	  select fc.campaign_no,
			   pack.package_id
	    from film_campaign fc, 
			   campaign_package pack,
			   branch br
	   where fc.start_date >= @start_date and
		      fc.start_date <= @end_date and
			   fc.campaign_no = pack.campaign_no and
	         fc.branch_code = br.branch_code and
			   pack.duration >= @min_duration and
		      pack.duration <= @max_duration and
			   br.country_code = @country and
	           fc.campaign_status in ('F','L','X')
	group by fc.campaign_no,
	         pack.package_id
	order by fc.campaign_no ASC,
	         pack.package_id ASC
	     for read only

	open mode1_csr
	fetch mode1_csr into @campaign_no, @package_id 
	while(@@fetch_status=0)
	begin

		/*
		 * Get Campaign Info
		 */
		
		if(@store_campaign_no <> @campaign_no)
		begin
			select @first_name = rep.first_name,
					 @last_name = rep.last_name,
					 @campaign_status = fc.campaign_status,
					 @product_desc = fc.product_desc
			  from film_campaign fc, 
					 sales_rep rep
			 where fc.campaign_no = @campaign_no and
					 fc.rep_id = rep.rep_id
		end
		
		select @pack_code = pack.package_code,
				 @pack_duration = pack.duration,
				 @pack_prints = pack.prints,	
				 @pack_average_rate = pack.average_rate,
				 @pack_spot_count = pack.spot_count
		  from campaign_package pack
		 where pack.package_id = @package_id

      select @pack_spend = @pack_average_rate * @pack_spot_count 

		if(@pack_spot_count = 0)
		begin
	
			select @pack_average_rate = avg(spot.charge_rate),
					 @pack_spot_count = count(spot.charge_rate),
                @pack_spend = sum(spot.charge_rate)
			  from campaign_spot spot
			 where spot.package_id = @package_id and
                    spot.campaign_no = @campaign_no and
				  ( spot.spot_type = 'S' or
					 spot.spot_type = 'Y' or
                                spot.spot_type = 'C' )
	
			select @pack_average_rate = isnull(@pack_average_rate,0),
					 @pack_spot_count = isnull(@pack_spot_count,0),		
					 @pack_spend = isnull(@pack_spend,0)

		end

		/*
       * Write to Table
       */

		if(@pack_spot_count > 0)
			insert into #results (
                campaign_no,
                product_desc,
                campaign_status,
                first_name,
                last_name,
                pack_code,
                pack_duration,
                pack_prints,
                average_rate,
                spot_count,
                total_spend,
					 country_name ) values (
                @campaign_no, 
                @product_desc,
                @campaign_status,
                @first_name,
                @last_name,
                @pack_code,
                @pack_duration,
                @pack_prints,
                @pack_average_rate,
                @pack_spot_count, 
                @pack_spend,
					 @country_name )

		/*
		 * Fetch Next
		 */

		fetch mode1_csr into @campaign_no, @package_id 

	end
	deallocate mode1_csr

end

/*
 * Loop Packages for Mode 2
 */

if(@mode = 2)
begin
	 declare mode2_csr cursor static for
	  select spot.campaign_no,
			   spot.package_id
	    from film_campaign fc,
	         campaign_spot spot,
			   campaign_package pack,
	         branch bra
	   where fc.campaign_no = spot.campaign_no and
	         spot.billing_date >= @start_date and
			   spot.billing_date <= @end_date and
	         fc.branch_code = bra.branch_code and
	         bra.country_code = @country and
			   pack.duration >= @min_duration and
		      pack.duration <= @max_duration and
				pack.package_id = spot.package_id and
	           fc.campaign_status in ('F','L','X')
	group by spot.campaign_no,
			   spot.package_id
	order by spot.campaign_no ASC,
	         spot.package_id ASC
	     for read only

	open mode2_csr
	fetch mode2_csr into @campaign_no, @package_id 
	while(@@fetch_status=0)
	begin

		/*
		 * Get Campaign Info
		 */
		
		if(@store_campaign_no <> @campaign_no)
		begin
			select @first_name = rep.first_name,
					 @last_name = rep.last_name,
					 @campaign_status = fc.campaign_status,
					 @product_desc = fc.product_desc
			  from film_campaign fc, 
					 sales_rep rep
			 where fc.campaign_no = @campaign_no and
					 fc.rep_id = rep.rep_id
		end
	
		select @pack_code = pack.package_code,
				 @pack_duration = pack.duration,
				 @pack_prints = pack.prints,	
				 @pack_average_rate = 0,
				 @pack_spot_count = 0,
             @pack_spend = 0
		  from campaign_package pack
		 where pack.package_id = @package_id

	
		select @pack_average_rate = avg(spot.charge_rate),
				 @pack_spot_count = count(spot.charge_rate),			    
             @pack_spend = sum(spot.charge_rate)
		  from campaign_spot spot
		 where spot.campaign_no = @campaign_no and
				 spot.billing_date >= @start_date and
				 spot.billing_date <= @end_date and
				 spot.package_id = @package_id and
			  ( spot.spot_type = 'S' or
				 spot.spot_type = 'Y'  or
           spot.spot_type = 'C' )
	
		select @pack_average_rate = isnull(@pack_average_rate,0),
				 @pack_spot_count = isnull(@pack_spot_count,0),		
				 @pack_spend = isnull(@pack_spend,0)	

		/*
       * Write to Table
       */

		if(@pack_spot_count > 0)
			insert into #results (
                campaign_no,
                product_desc,
                campaign_status,
                first_name,
                last_name,
                pack_code,
                pack_duration,
                pack_prints,
                average_rate,
                spot_count, 
                total_spend,
					 country_name ) values (
                @campaign_no, 
                @product_desc,
                @campaign_status,
                @first_name,
                @last_name,
                @pack_code,
                @pack_duration,
                @pack_prints,
                @pack_average_rate,
                @pack_spot_count,
                @pack_spend,
					 @country_name )

		/*
		 * Fetch Next
		 */

		fetch mode2_csr into @campaign_no, @package_id 

	end
	deallocate mode2_csr

end

/*
 * Return Results
 */
	 
select campaign_no,
       product_desc,
       campaign_status,
       first_name,
       last_name,
       pack_code,
       pack_duration,
       pack_prints,
       average_rate,
       spot_count,
       total_spend,
		 country_name
  from #results
					
/*
 * Return Success
 */

return 0
GO
