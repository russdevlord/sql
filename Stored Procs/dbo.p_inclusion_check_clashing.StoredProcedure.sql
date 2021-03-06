/****** Object:  StoredProcedure [dbo].[p_inclusion_check_clashing]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_inclusion_check_clashing]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_check_clashing]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_inclusion_check_clashing] @campaign_no     int,
	                                   @complex_id      int,
	                                   @inclusion_id    int
as
set nocount on 
declare @error						int,
        @spot_csr_open			    tinyint,
        @screening_date			    datetime,
        @pcat						int,
		@spot_count				    int,
	    @clashing_count		        smallint,
		@campaign_clash_count	    smallint,
	    @clash_limit				smallint,
		@row_type					char(10),
        @client_clash_count         smallint,
        @product_clash_count        smallint,
        @client_clash               char(1),
        @product_clash              char(1),
        @inclusion_id_clash         char(1),
        @client_id                  int,
		@product_category_id		int,
		@media_product_id			int,
		@inclusion_format			char(1)

/*
 * Create a table for returning the screening dates and complex ids
 */

create table #clash
(
	screening_date		datetime,
	complex_id			int,
    inclusion_id		int,
	row_type			char(10),
    spot_count			int
)

/*
 * Initialise Variables
 */
select @spot_csr_open = 0

/*
 * Get inclusion_id Code to Count inclusion_ids less than this one
 */

select @inclusion_id = inclusion_id,
	   @product_category_id = product_category_id,
	   @media_product_id = media_product_id,
	   @inclusion_format = inclusion_format
  from inclusion,
	   inclusion_type
 where inclusion_id = @inclusion_id
   and inclusion.inclusion_type = inclusion_type.inclusion_type
 
/*
 * Select inclusion_id Clash as well to obtain the correct amount of clashing campaigns.
 */
 
select @inclusion_id_clash = allow_pack_clashing,
       @client_id = client_id
  from film_campaign 
 where campaign_no = @campaign_no

/*
 * Loop through Spots
 */

 declare spot_csr cursor static for
  select count(spot.spot_id),
         spot.complex_id,
         spot.screening_date,
         inc.product_category_id,
		 'Screening',
         inc.client_clash,
         inc.allow_product_clashing
    from inclusion_spot spot,
         inclusion inc
   where spot.campaign_no = @campaign_no and
		 spot.inclusion_id = @inclusion_id and
         spot.inclusion_id = inc.inclusion_id and
         spot.complex_id = @complex_id and
		 inc.inclusion_format <> 'R'
group by spot.complex_id,
         spot.screening_date,
         inc.product_category_id,
         inc.client_clash,
         inc.allow_product_clashing
union all
  select count(spot.spot_id),
         spot.complex_id,
         spot.billing_date,
         inc.product_category_id,
		 'Billing',
         inc.client_clash,
         inc.allow_product_clashing
    from inclusion_spot spot,
         inclusion inc
   where spot.campaign_no = @campaign_no and
		 spot.inclusion_id = @inclusion_id and
         spot.inclusion_id = inc.inclusion_id and
         spot.complex_id = @complex_id and
		 inc.inclusion_format <> 'R'
group by spot.complex_id,
         spot.billing_date,
         inc.product_category_id,
         inc.client_clash,
         inc.allow_product_clashing
union all
  select count(spot.spot_id),
         spot.outpost_venue_id,
         spot.op_screening_date,
         inc.product_category_id,
		 'Screening',
         inc.client_clash,
         inc.allow_product_clashing
    from inclusion_spot spot,
         inclusion inc
   where spot.campaign_no = @campaign_no and
		 spot.inclusion_id = @inclusion_id and
         spot.inclusion_id = inc.inclusion_id and
         spot.outpost_venue_id = @complex_id and
		 inc.inclusion_format = 'R'
group by spot.outpost_venue_id,
         spot.op_screening_date,
         inc.product_category_id,
         inc.client_clash,
         inc.allow_product_clashing
union all
  select count(spot.spot_id),
         spot.outpost_venue_id,
         spot.op_billing_date,
         inc.product_category_id,
		 'Billing',
         inc.client_clash,
         inc.allow_product_clashing
    from inclusion_spot spot,
         inclusion inc
   where spot.campaign_no = @campaign_no and
		 spot.inclusion_id = @inclusion_id and
         spot.inclusion_id = inc.inclusion_id and
         spot.outpost_venue_id = @complex_id and
		 inc.inclusion_format = 'R'
group by spot.outpost_venue_id,
         spot.op_billing_date,
         inc.product_category_id,
         inc.client_clash,
         inc.allow_product_clashing
     for read only

open spot_csr
select @spot_csr_open = 1
fetch spot_csr into @spot_count, 
					@complex_id, 
					@screening_date, 
					@pcat,
					@row_type,
                    @client_clash,
                    @product_clash

while(@@fetch_status = 0)
begin

    /*
     * Initialise Variables
     */
     
     select @client_clash_count = 0,
            @product_clash_count = 0,
            @campaign_clash_count = 0

	/*
	 * Get Clash Limit for Complex and Screening Date
	 */


	if @inclusion_format <> 'R'
	begin
	  select @clash_limit = round((case when @media_product_id = 6 then 1 else 0 end) ,0)
        from complex_date cd,
			 product_date pd
       where cd.complex_id = @complex_id and
             cd.screening_date = @screening_date and
			 cd.screening_date = pd.screening_date and
			 pd.product_category_id = @product_category_id
	end
	else
	begin
	  select @clash_limit = round((case when @media_product_id = 6 then 1 else 0 end) ,0)
        from outpost_venue_date cd,
			 product_date pd
       where cd.outpost_venue_id = @complex_id and
             cd.screening_date = @screening_date and
			 cd.screening_date = pd.screening_date and
			 pd.product_category_id = @product_category_id
	end
    
	/*
	 * Get Count of Booked Spots with the Same Product Category
	 */

	if @inclusion_format <> 'R'
	begin
	  select @clashing_count = IsNull(count(inc.inclusion_id),0)
		from inclusion_spot spot,
			 inclusion inc,
             film_campaign fc
  	   where spot.complex_id = @complex_id and
			 spot.screening_date = @screening_date and
			 spot.spot_status <> 'P' and
			 spot.campaign_no <> @campaign_no and
			 spot.inclusion_id = inc.inclusion_id and
			 inc.product_category_id = @pcat and
             fc.campaign_no = spot.campaign_no and
             fc.campaign_no = inc.campaign_no 
	end
	else
	begin
	  select @clashing_count = IsNull(count(inc.inclusion_id),0)
		from inclusion_spot spot,
			 inclusion inc,
             film_campaign fc
  	   where spot.outpost_venue_id = @complex_id and
			 spot.op_screening_date = @screening_date and
			 spot.spot_status <> 'P' and
			 spot.campaign_no <> @campaign_no and
			 spot.inclusion_id = inc.inclusion_id and
			 inc.product_category_id = @pcat and
             fc.campaign_no = spot.campaign_no and
             fc.campaign_no = inc.campaign_no 
	end

    /*
     * Check the clashing count same criteria as above but where the client clash is on if it is on for this campaign
     */      
     
     if @client_clash = 'Y' and @product_clash = 'N'
     begin
		if @inclusion_format <> 'R'
		begin
	        select @client_clash_count = IsNull(count(inc.inclusion_id),0)
			  from inclusion_spot spot,
				   inclusion inc,
	               film_campaign fc
	  	     where spot.complex_id = @complex_id and
				   spot.screening_date = @screening_date and
				   spot.spot_status <> 'P' and
				   spot.campaign_no <> @campaign_no and
				   spot.inclusion_id = inc.inclusion_id and
				   inc.product_category_id = @pcat and
	               fc.campaign_no = spot.campaign_no and
	               fc.campaign_no = inc.campaign_no and
	               fc.client_id = @client_id and
	               inc.client_clash = 'Y' and
	               inc.allow_product_clashing = 'N'
		end
		else
		begin
	        select @client_clash_count = IsNull(count(inc.inclusion_id),0)
			  from inclusion_spot spot,
				   inclusion inc,
	               film_campaign fc
	  	     where spot.outpost_venue_id = @complex_id and
				   spot.op_screening_date = @screening_date and
				   spot.spot_status <> 'P' and
				   spot.campaign_no <> @campaign_no and
				   spot.inclusion_id = inc.inclusion_id and
				   inc.product_category_id = @pcat and
	               fc.campaign_no = spot.campaign_no and
	               fc.campaign_no = inc.campaign_no and
	               fc.client_id = @client_id and
	               inc.client_clash = 'Y' and
	               inc.allow_product_clashing = 'N'
		end
     end
     
     if @product_clash = 'Y'
     begin
		if @inclusion_format <> 'R'
		begin
	        select @product_clash_count  = IsNull(count(inc.inclusion_id),0)
			  from inclusion_spot spot,
				   inclusion inc,
	               film_campaign fc
	  	     where spot.complex_id = @complex_id and
				   spot.screening_date = @screening_date and
				   spot.spot_status <> 'P' and
				   spot.campaign_no <> @campaign_no and
				   spot.inclusion_id = inc.inclusion_id and
				   inc.product_category_id = @pcat and
	               fc.campaign_no = spot.campaign_no and
	               fc.campaign_no = inc.campaign_no and
	               inc.allow_product_clashing = 'Y'
		end
		else
		begin
	        select @product_clash_count  = IsNull(count(inc.inclusion_id),0)
			  from inclusion_spot spot,
				   inclusion inc,
	               film_campaign fc
	  	     where spot.outpost_venue_id = @complex_id and
				   spot.op_screening_date = @screening_date and
				   spot.spot_status <> 'P' and
				   spot.campaign_no <> @campaign_no and
				   spot.inclusion_id = inc.inclusion_id and
				   inc.product_category_id = @pcat and
	               fc.campaign_no = spot.campaign_no and
	               fc.campaign_no = inc.campaign_no and
	               inc.allow_product_clashing = 'Y'
		end
     end
             
	/*
	 * Get Count of Booked Spots with the Same Product Category from the Same Campaign
	 * With a inclusion_id Code less than the inclusion_id being checked.
	 */
     
     if @inclusion_id_clash = 'N'
     begin
		if @inclusion_format <> 'R'
		begin
			select 	@campaign_clash_count = isnull(count(inc.inclusion_id),0)
			from 	inclusion_spot spot,
					inclusion inc
			where 	spot.complex_id = @complex_id and
					spot.screening_date = @screening_date and
					spot.campaign_no = @campaign_no and
					spot.inclusion_id = inc.inclusion_id and
					inc.inclusion_id < @inclusion_id and				
					inc.product_category_id = @pcat
		end
		else
		begin
			select 	@campaign_clash_count = isnull(count(inc.inclusion_id),0)
			from 	inclusion_spot spot,
					inclusion inc
			where 	spot.outpost_venue_id = @complex_id and
					spot.op_screening_date = @screening_date and
					spot.campaign_no = @campaign_no and
					spot.inclusion_id = inc.inclusion_id and
					inc.inclusion_id < @inclusion_id and				
					inc.product_category_id = @pcat
		end
     end   	
    
 	 select @clash_limit = @clash_limit - (@clashing_count + @campaign_clash_count) + (@client_clash_count + @product_clash_count)

	 if(@clash_limit < 0)
		select @clash_limit = 0

	 select @clash_limit = @clash_limit - @spot_count

	/*
	 * Check if this spot is Affected
	 */

	 if(@clash_limit < 0)
	 begin

		if(@row_type = 'Screening')
			select @clash_limit = @clash_limit * -1
		else
			select @clash_limit = 0

		insert into #clash values (@screening_date, @complex_id, @inclusion_id, @row_type, @clash_limit)

	 end

	/*
     * Fetch Next Spot
     */

	fetch spot_csr into @spot_count, 
					    @complex_id, 
					    @screening_date, 
					    @pcat,
					    @row_type,
                        @client_clash,
                        @product_clash

end

close spot_csr
deallocate spot_csr
select @spot_csr_open = 0

/*
 * Return Clash List
 */

  select screening_date,
         complex_id,
         inclusion_id,
		 row_type,
         spot_count
    from #clash
order by screening_date asc,
		 complex_id asc,
         inclusion_id asc

/*
 * Return Success
 */

return 0

/*
 * Error Handler
 */

error:

	if (@spot_csr_open = 1)
   begin
		close spot_csr
		deallocate spot_csr
	end
	return -1
GO
