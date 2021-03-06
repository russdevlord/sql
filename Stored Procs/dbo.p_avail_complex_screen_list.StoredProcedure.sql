/****** Object:  StoredProcedure [dbo].[p_avail_complex_screen_list]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_avail_complex_screen_list]
GO
/****** Object:  StoredProcedure [dbo].[p_avail_complex_screen_list]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_avail_complex_screen_list]  	@complex_id					int,
													@screening_date				datetime,
													@campaign_no				int,
													@package_id					int
as

/*
 * Declare Variables
 */

declare		@max_time							int,
			@max_ads							int,
			@avail_time							int,
			@avail_ads							int,
			@book_time							int,
			@book_ads							int,
			@date_csr_open						int,
			@clash_count						int,
			@errorode								int,
			@avail_clash						int,
			@prod_count     					int,
			@client_clash_count 				int,
			@allow_product_clashing_count 		int,
			@clash_limit						int,
			@product_category_id				int,
			@sub_product_category				int,
			@package_clash						char(1),
			@client_id							int,
			@screen_no							int,
			@client_clash						char(1),
			@allow_product_clashing				char(1)
		
/*
 * Get Package Code to Count Packages less than this one
 */

select		@product_category_id = product_category,
			@sub_product_category = isnull( product_subcategory,0),
			@client_clash = client_clash,
			@allow_product_clashing	 = allow_product_clashing	
from		campaign_package
where		package_id = @package_id
 
/*
 * Select Package Clash as well to obtain the correct amount of clashing campaigns.
 */
 
select		@package_clash = allow_pack_clashing,
			@client_id = client_id		
from		film_campaign 
where		campaign_no = @campaign_no

/*
 * Create Table to Hold Availability Information
 */

create table #avails
(
	complex_id			int			null,
	screen_no			int			null,
	screening_date		datetime	null,
    avail_time			int			null,
	avail_ads			int			null,
    avail_clash			int			null
)

/*
 * Loop Through Dates
 */
 
create table #constraints
(max_ads		int, 
max_time		int)

insert into #constraints exec p_certificate_cineads_constraints @complex_id
	
declare	date_csr cursor static for
select 	cd.screening_date,
		#constraints.max_ads,
		#constraints.max_time,
		1,
		cinema.cinema_no
from 	film_screening_dates cd,
		#constraints,
		cinema
where 	cd.screening_date = @screening_date
and		cinema.active_flag = 'Y'
and		cinema.complex_id = @complex_id
for read only


open date_csr
select @date_csr_open = 1
fetch date_csr into @screening_date, @max_ads, @max_time, @clash_limit, @screen_no
while(@@fetch_status=0)
begin

	select	@avail_clash = 9999,
			@avail_time = 0,
			@avail_ads = 0

	/*
	 * Calculate Bookings
	 */

	select	@book_time = Isnull(sum(pack.duration),0),
			@book_ads = Isnull(sum(pack.prints),0)
	from	campaign_spot spot,
			campaign_package pack,
			film_campaign fc
	where	spot.complex_id = @complex_id 
	and		spot.screening_date = @screening_date 
	and		spot.film_plan_id = @screen_no  
	and		spot.spot_status <> 'D' 
	and		spot.spot_status <> 'P' 
	and		spot.package_id = pack.package_id 
	and		spot.campaign_no = fc.campaign_no 
	and		pack.campaign_no = fc.campaign_no 

	select	@prod_count = IsNull(count(pack.package_id),0)
	from	campaign_spot spot,
			campaign_package pack,
			film_campaign fc
	where	spot.screening_date = @screening_date 
	and		spot.complex_id = @complex_id 
	and		spot.spot_status <> 'D' 
	and		spot.spot_status <> 'P' 
	and		spot.film_plan_id = @screen_no  
	and		spot.package_id = pack.package_id 
	and		pack.product_category = @product_category_id 
	and		spot.campaign_no = fc.campaign_no 
	and		pack.campaign_no = fc.campaign_no 
	AND		(pack.product_subcategory = @sub_product_category 
	OR		@sub_product_category = 0 
	OR		isnull(pack.product_subcategory,0) = 0)


			/*
			 * Check the clashing count same criteria as above but where the client clash is on if it is on for this campaign
			 */      
			
	if @client_clash = 'Y' and @allow_product_clashing = 'N'
	begin
		select 		@client_clash_count = IsNull(count(pack.package_id),0)
		from 		campaign_spot spot,
					campaign_package pack,
					film_campaign fc
		where 		spot.complex_id = @complex_id 
		and			spot.screening_date = @screening_date 
		and			spot.spot_status <> 'P' 
		and			spot.package_id = pack.package_id 
		and			spot.film_plan_id = @screen_no  
		and			pack.product_category = @product_category_id 
		and			fc.campaign_no = spot.campaign_no 
		and			fc.campaign_no = pack.campaign_no 
		and			fc.client_id = @client_id 
		and			pack.client_clash = 'Y' 
		and			pack.allow_product_clashing = 'N' 
		and			(pack.product_subcategory = @sub_product_category 
		OR			@sub_product_category = 0 
		OR			isnull(pack.product_subcategory,0) = 0)
	end
	
	if @allow_product_clashing = 'Y'
	begin
		select 		@allow_product_clashing_count  = IsNull(count(pack.package_id),0)
		from 		campaign_spot spot,
					campaign_package pack,
					film_campaign fc
		where 		spot.complex_id = @complex_id 
		and			spot.screening_date = @screening_date 
		and			spot.spot_status <> 'P' 
		and			spot.film_plan_id = @screen_no  
		and			spot.package_id = pack.package_id 
		and			pack.product_category = @product_category_id 
		and			fc.campaign_no = spot.campaign_no 
		and			fc.campaign_no = pack.campaign_no 
		and			pack.allow_product_clashing = 'Y' 
		and			(pack.product_subcategory = @sub_product_category 
		OR			@sub_product_category = 0 
		OR			isnull(pack.product_subcategory,0) = 0)
	end

	/*
	 * Get Count of Booked Spots with the Same Product Category from the Same Campaign
	 * With a Package Code less than the package being checked.
	 */

	select @prod_count = isnull(@prod_count,0) - (isnull(@client_clash_count,0) + isnull(@allow_product_clashing_count,0))
	
	if(@prod_count is null or @prod_count < 1)
		select @clash_count = 0
	else
		select @clash_count = @prod_count

	select @avail_clash = @clash_limit - @clash_count
	
	/*
	 * Determine Availability
	 */
 
	select @avail_time = @max_time - @book_time
	select @avail_ads = @max_ads - @book_ads

	insert into #avails values (@complex_id,
                                @screen_no,
                                @screening_date, 
                                @avail_time, 
                                @avail_ads,
                                @avail_clash )

	/*
	 * Fetch Next
	 */

	fetch date_csr into @screening_date, @max_ads, @max_time, @clash_count, @screen_no

end

close date_csr
deallocate date_csr

/*
 * Return Overbooked Data
 */

select	avl.avail_time,
		avl.avail_ads,
		avl.avail_clash,
		avl.screen_no
from	#avails avl

/*
 * Return Success
 */

return 0

/*
 * Error Handler
 */

error:

	if (@date_csr_open = 1)
    begin
		close date_csr
		deallocate date_csr
	end
	return -1
GO
