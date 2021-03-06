/****** Object:  StoredProcedure [dbo].[p_check_campaign_safety]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_check_campaign_safety]
GO
/****** Object:  StoredProcedure [dbo].[p_check_campaign_safety]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_check_campaign_safety] @campaign_no integer
as

declare @error						integer,
        @spot_csr_open				tinyint,
        @complex_date				integer,
        @screening_date				datetime,
		@safety_limit				smallint,
		@safety_check				integer,
		@spot_count					integer,
		@campaign_count				integer,
		@package_code				char(4),
		@row_type					char(10),
		@package_id					integer,
		@complex_id					integer
	

/*
 * Create a table for returning the screening dates and complex ids
 */

create table #exceed
(
	screening_date		datetime,
	complex_id			int
)

/*
 * Initialise Variables
 */

select @spot_csr_open = 0
/*
 * Declare Cursors
 */ 

declare 	spot_csr cursor static for
select 		cd.screening_date,
			cd.complex_id,
			round((case when cp.media_product_id = 1 then (cd.campaign_safety_limit * pd.film_ad_percent) else (cd.campaign_safety_limit * pd.dmg_ad_percent) end) + (case when cd.campaign_safety_limit = 1 then 0.5 else -0.5 end),0),
			count(spot.spot_id),
			spot.package_id
from 		campaign_spot spot,
			complex_date cd,
			product_date pd,
			campaign_package cp
where 		spot.campaign_no = @campaign_no and
			spot.screening_date = cd.screening_date and
			spot.complex_id = cd.complex_id and
			cp.package_id = spot.package_id and 
			cp.product_category = pd.product_category_id and
			pd.screening_date = cd.screening_date and
			pd.screening_date = spot.screening_date
group by 	cd.complex_id,
			cd.screening_date,
			cd.campaign_safety_limit,
			spot.package_id,
			cp.media_product_id,
			pd.film_ad_percent,
			pd.dmg_ad_percent
order by 	cd.complex_id,
			cd.screening_date
for 		read only


/*
 * Loop through Spots
 */

open spot_csr
fetch spot_csr into 	@screening_date, 
					  	@complex_id, 
					  	@safety_limit,
                    	@spot_count,
						@package_id

while(@@fetch_status=0)
begin


	/*
	 * Get Package Code to Count Packages less than this one
	 */
	
	select @package_code = package_code
	  from campaign_package
	 where package_id = @package_id

	/*
	 * Check if this spot is Effected
	 */

	select @campaign_count = isnull(count(spot.spot_id), 0)
	  from campaign_spot spot,
			 campaign_package pack
	 where spot.complex_id = @complex_id and
          spot.screening_date = @screening_date and
			 spot.campaign_no = @campaign_no and
			 pack.package_code < @package_code and
			 spot.package_id = pack.package_id

	/*
	 * Check if this spot is Effected
	 */

	select @safety_check = @safety_limit - @campaign_count
	if(@safety_check < 0)
		select @safety_check = 0

	select @safety_check = @safety_check - @spot_count

	if(@safety_check < 0)
	begin

		if(@row_type = 'Screening')
			select @safety_check = @safety_check * -1
		else
			select @safety_check = 0

		insert into #exceed values (@screening_date, @complex_id)

	end

	/*
    * Fetch Next Spot
    */

	fetch spot_csr into @screening_date, 
							  @complex_id, 
							  @safety_limit,
							  @spot_count,
							  @package_id
end

close spot_csr
deallocate spot_csr

/*
 * Return Clash List
 */

  select screening_date,
         complex_id 
    from #exceed
order by screening_date asc,
			complex_id asc

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
