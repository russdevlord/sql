/****** Object:  StoredProcedure [dbo].[p_sched_check_clashing]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sched_check_clashing]
GO
/****** Object:  StoredProcedure [dbo].[p_sched_check_clashing]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sched_check_clashing]		@campaign_no		int,
												@complex_id			int,
												@package_id			int
as
set nocount on 

declare		@error						int,
			@spot_csr_open				tinyint,
			@screening_date				datetime,
			@pcat						int,
			@pcat_sub					int,
			@spot_count					int,
			@clashing_count				smallint,
			@campaign_clash_count		smallint,
			@clash_limit				smallint,
			@row_type					char(10),
			@package_code		    	char(4),
			@client_clash_count			smallint,
			@product_clash_count		smallint,
			@client_clash				char(1),
			@client_clash_sub			char(1),
			@product_clash				char(1),
			@package_clash				char(1),
			@client_id					int,
			@product_category_id		int,
			@sub_product_category		int,
			@media_product_id			int,
			@campaign_type				int,
			@screen_no					int

/*
 * Create a table for returning the screening dates and complex ids
 */

create table #clash
(
	screening_date		datetime,
	complex_id			int,
    package_id			int,
	row_type			char(10),
    spot_count			int,
    screen_no			int
)

/*
 * Initialise Variables
 */
 
select	@spot_csr_open = 0

/*
 * Get Package Code to Count Packages less than this one
 */

select		@package_code = package_code,
			@product_category_id = product_category,
			@sub_product_category = isnull( product_subcategory,0),
			@media_product_id = media_product_id
from		campaign_package
where		package_id = @package_id
 
/*
 * Select Package Clash as well to obtain the correct amount of clashing campaigns.
 */
 
select		@package_clash = allow_pack_clashing,
			@client_id = client_id,
			@campaign_type = campaign_type		
from		film_campaign 
where		campaign_no = @campaign_no

/*
 * Loop through Spots
 */

if @campaign_type < 5
begin
	declare		spot_csr cursor static for
	select		count(spot.spot_id),
				spot.complex_id,
				spot.screening_date,
				pack.product_category,
				pack.product_subcategory,
				'Screening',
				pack.client_clash,
				pack.allow_product_clashing,
				pack.allow_subcategory_clashing,
				-1
	from		campaign_spot spot,
				campaign_package pack
	where		spot.campaign_no = @campaign_no 
	and			spot.package_id = @package_id 
	and			spot.package_id = pack.package_id 
	and			spot.complex_id = @complex_id
	group by	spot.complex_id,
				spot.screening_date,
				pack.product_category,
				pack.product_subcategory,
				pack.client_clash,
				pack.allow_product_clashing,
				pack.allow_subcategory_clashing
	union all
	select		count(spot.spot_id),
				spot.complex_id,
				spot.billing_date,
				pack.product_category,
				pack.product_subcategory,
				'Billing',
				pack.client_clash,
				pack.allow_product_clashing,
				pack.allow_subcategory_clashing,
				-1
	from		campaign_spot spot,
				campaign_package pack
	where		spot.campaign_no = @campaign_no 
	and			spot.package_id = @package_id 
	and			spot.package_id = pack.package_id 
	and			spot.complex_id = @complex_id
	group by	spot.complex_id,
				spot.billing_date,
				pack.product_category,
				pack.product_subcategory,
				pack.client_clash,
				pack.allow_product_clashing,
				pack.allow_subcategory_clashing
	for			read only
end	
else
begin
	declare		spot_csr cursor static for
	select		count(spot.spot_id),
				spot.complex_id,
				spot.screening_date,
				pack.product_category,
				pack.product_subcategory,
				'Screening',
				pack.client_clash,
				pack.allow_product_clashing,
				pack.allow_subcategory_clashing,
				cin.cinema_no
	from		campaign_spot spot,
				campaign_package pack,
				cinema cin
	where		spot.campaign_no = @campaign_no 
	and			spot.package_id = @package_id 
	and			spot.package_id = pack.package_id 
	and			spot.complex_id = @complex_id
	and			spot.complex_id = cin.complex_id
	and			cin.active_flag = 'Y'
	and			spot.film_plan_id = cin.cinema_no
	group by	spot.complex_id,
				spot.screening_date,
				pack.product_category,
				pack.product_subcategory,
				pack.client_clash,
				pack.allow_product_clashing,
				pack.allow_subcategory_clashing,
				cin.cinema_no
	union all
	select		count(spot.spot_id),
				spot.complex_id,
				spot.billing_date,
				pack.product_category,
				pack.product_subcategory,
				'Billing',
				pack.client_clash,
				pack.allow_product_clashing,
				pack.allow_subcategory_clashing,
				cin.cinema_no
	from		campaign_spot spot,
				campaign_package pack,
				cinema cin
	where		spot.campaign_no = @campaign_no 
	and			spot.package_id = @package_id 
	and			spot.package_id = pack.package_id 
	and			spot.complex_id = @complex_id
	and			spot.complex_id = cin.complex_id
	and			cin.active_flag = 'Y'
	and			spot.film_plan_id = cin.cinema_no
	group by	spot.complex_id,
				spot.billing_date,
				pack.product_category,
				pack.product_subcategory,
				pack.client_clash,
				pack.allow_product_clashing,
				pack.allow_subcategory_clashing,
				cin.cinema_no
	for			read only
end

open spot_csr
select @spot_csr_open = 1
fetch spot_csr into	@spot_count, @complex_id, @screening_date, @pcat, @pcat_sub, @row_type, @client_clash, @product_clash, @client_clash_sub, @screen_no
while(@@fetch_status = 0)
begin
 /* (pack.product_subcategory = @product_subcategory OR 
              @product_subcategory = 0 
              OR isnull(pack.product_subcategory,0) = 0)
*/
    /*
     * Initialise Variables
     */
     
     select	@client_clash_count = 0,
			@product_clash_count = 0,
			@campaign_clash_count = 0

	/*
	 * Get Clash Limit for Complex and Screening Date
	 */


	if @screen_no = -1
	begin
		select	@clash_limit = round((case when @media_product_id = 1 then (cd.clash_safety_limit * pd.film_ad_percent) 
									else (cd.clash_safety_limit * pd.dmg_ad_percent) end) + (case when cd.clash_safety_limit = 1 then 0.5 else -0.5 end),0)
		from	complex_date cd,
				product_date pd
		where	cd.complex_id = @complex_id 
		and		cd.screening_date = @screening_date 
		and		cd.screening_date = pd.screening_date 
		and		pd.product_category_id = @product_category_id
	end
	else
	begin
		select	@clash_limit = 1
	end

    
	/*
	 * Get Count of Booked Spots with the Same Product Category
	 */

	select	@clashing_count = IsNull(count(pack.package_id),0)
	from	campaign_spot spot,
			campaign_package pack,
			film_campaign fc
	where	spot.complex_id = @complex_id 
	and		spot.screening_date = @screening_date 
	and		spot.spot_status <> 'P' 
	and		spot.campaign_no <> @campaign_no 
	and		spot.package_id = pack.package_id 
	and		pack.product_category = @pcat 
	and		(pack.product_subcategory = @sub_product_category 
	or		@sub_product_category = 0 
    or		isnull(pack.product_subcategory,0) = 0)
	and		fc.campaign_no = spot.campaign_no 
	and		fc.campaign_no = pack.campaign_no 
	and		(@screen_no = -1
	or		spot.film_plan_id = @screen_no)

    /*
     * Check the clashing count same criteria as above but where the client clash is on if it is on for this campaign
     */      
     
	if @client_clash = 'Y' and @product_clash = 'N'
	begin
		select	@client_clash_count = IsNull(count(pack.package_id),0)
		from	campaign_spot spot,
				campaign_package pack,
				film_campaign fc
		where	spot.complex_id = @complex_id 
		and		spot.screening_date = @screening_date 
		and		spot.spot_status <> 'P' 
		and		spot.campaign_no <> @campaign_no 
		and		spot.package_id = pack.package_id 
		and		pack.product_category = @pcat 
		and		(pack.product_subcategory = @sub_product_category 
		or		@sub_product_category = 0 
		or		isnull(pack.product_subcategory,0) = 0) 
		and		fc.campaign_no = spot.campaign_no 
		and		fc.campaign_no = pack.campaign_no 
		and		fc.client_id = @client_id 
		and		pack.client_clash = 'Y' 
		and		pack.allow_product_clashing = 'N'
		and		(@screen_no = -1
		or		spot.film_plan_id = @screen_no)	
	end
    
	if @product_clash = 'Y'
	begin
		select	@product_clash_count  = IsNull(count(pack.package_id),0)
		from	campaign_spot spot,
				campaign_package pack,
				film_campaign fc
		where	spot.complex_id = @complex_id 
		and		spot.screening_date = @screening_date 
		and		spot.spot_status <> 'P' 
		and		spot.campaign_no <> @campaign_no 
		and		spot.package_id = pack.package_id 
		and		pack.product_category = @pcat 
		and		(pack.product_subcategory = @sub_product_category 
		or		@sub_product_category = 0 
		or		isnull(pack.product_subcategory,0) = 0) 
		and		fc.campaign_no = spot.campaign_no 
		and		fc.campaign_no = pack.campaign_no 
		and		pack.allow_product_clashing = 'Y'
		and		(@screen_no = -1
		or		spot.film_plan_id = @screen_no)	
	end
             
	/*
	 * Get Count of Booked Spots with the Same Product Category from the Same Campaign
	 * With a Package Code less than the package being checked.
	 */
     
     if @package_clash = 'N'
     begin
		select	@campaign_clash_count = isnull(count(pack.package_id),0)
		from	campaign_spot spot,
				campaign_package pack
		where	spot.complex_id = @complex_id 
		and		spot.screening_date = @screening_date 
		and		spot.campaign_no = @campaign_no 
		and		spot.package_id = pack.package_id 
		and		pack.package_code < @package_code 
		and		pack.product_category = @pcat 
		and		(pack.product_subcategory = @sub_product_category 
		or		@sub_product_category = 0 
		or		isnull(pack.product_subcategory,0) = 0)
		and		(@screen_no = -1
		or		spot.film_plan_id = @screen_no)	
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

		insert into #clash values (@screening_date, @complex_id, @package_id, @row_type, @clash_limit, @screen_no)

	 end

	/*
     * Fetch Next Spot
     */

	fetch spot_csr into	@spot_count, @complex_id, @screening_date, @pcat, @pcat_sub, @row_type, @client_clash, @product_clash, @client_clash_sub, @screen_no
end

close spot_csr
deallocate spot_csr
select @spot_csr_open = 0

/*
 * Return Clash List
 */

select		screening_date,
			complex_id,
			package_id,
			row_type,
			min(spot_count)
from		#clash
group by	screening_date,
			complex_id,
			package_id,
			row_type
order by	screening_date asc,
			complex_id asc,
			package_id asc

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
