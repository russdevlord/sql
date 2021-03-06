/****** Object:  StoredProcedure [dbo].[p_avail_complex_screen]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_avail_complex_screen]
GO
/****** Object:  StoredProcedure [dbo].[p_avail_complex_screen]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_avail_complex_screen]  	@complex_id						int,
												@start_date						datetime,
												@end_date		    			datetime,
												@prints							int,
												@duration						int,
												@prod_cat						int,
												@media_product_id  				smallint,
												@allow_product_clashing			char(1),
												@client_clash 					char(1),
												@client_diff_product			char(1),
												@client_id 						int,
												@package_clash					char(1),
												@use_clashing_logic				char(1),
												@product_subcategory			int,
												@allow_sub_product_clashing		char(1),
												@screen_no						int

as

/*
 * Declare Variables
 */

declare		@screening_date						datetime,
			@max_time							int,
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
			@clash_limit						int
		
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
 * Initialise Variables
 */

select @date_csr_open = 0

if(@prints = 0)
	select @prints = 1

if(@duration = 0)
	select @duration = 1
	

select @product_subcategory = isnull(@product_subcategory, 0) 

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
		1
from 	film_screening_dates cd,
		#constraints
where 	cd.screening_date between @start_date and @end_date
for read only


open date_csr
select @date_csr_open = 1
fetch date_csr into @screening_date, @max_ads, @max_time, @clash_limit
while(@@fetch_status=0)
begin

	select @avail_clash = 9999

	/*
	 * Calculate Bookings
	 */

	if(@prod_cat > 0)
	begin

		select @book_time = Isnull(sum(pack.duration),0),
			   @book_ads = Isnull(sum(pack.prints),0)
		  from campaign_spot spot,
			   campaign_package pack,
               film_campaign fc
		 where spot.complex_id = @complex_id and
			   spot.screening_date = @screening_date and
               spot.film_plan_id = @screen_no  and
			   spot.spot_status <> 'D' and
			   spot.spot_status <> 'P' and
			   spot.package_id = pack.package_id and
               spot.campaign_no = fc.campaign_no and
               pack.campaign_no = fc.campaign_no 

		select @prod_count = IsNull(count(pack.package_id),0)
		  from campaign_spot spot,
			   campaign_package pack,
               film_campaign fc
		 where spot.screening_date = @screening_date and
			   spot.complex_id = @complex_id and
			   spot.spot_status <> 'D' and
			   spot.spot_status <> 'P' and
               spot.film_plan_id = @screen_no  and
			   spot.package_id = pack.package_id and
			   pack.product_category = @prod_cat and
               spot.campaign_no = fc.campaign_no and
               pack.campaign_no = fc.campaign_no AND
              (pack.product_subcategory = @product_subcategory OR 
              @product_subcategory = 0 
              OR isnull(pack.product_subcategory,0) = 0)


		if @use_clashing_logic = 'Y'
		begin
			/*
			 * Check the clashing count same criteria as above but where the client clash is on if it is on for this campaign
			 */      
			
			if @client_clash = 'Y' and @allow_product_clashing = 'N'
			begin
				select 	@client_clash_count = IsNull(count(pack.package_id),0)
				from 	campaign_spot spot,
						campaign_package pack,
						film_campaign fc
				where 	spot.complex_id = @complex_id and
						spot.screening_date = @screening_date and
						spot.spot_status <> 'P' and
						spot.package_id = pack.package_id and
						spot.film_plan_id = @screen_no  and
						pack.product_category = @prod_cat and
						fc.campaign_no = spot.campaign_no and
						fc.campaign_no = pack.campaign_no and
						fc.client_id = @client_id and
						pack.client_clash = 'Y' and
						pack.allow_product_clashing = 'N' and
						(pack.product_subcategory = @product_subcategory OR 
					  @product_subcategory = 0 
					  OR isnull(pack.product_subcategory,0) = 0)
			end
			
			if @allow_product_clashing = 'Y'
			begin
				select 	@allow_product_clashing_count  = IsNull(count(pack.package_id),0)
				from 	campaign_spot spot,
						campaign_package pack,
						film_campaign fc
				where 	spot.complex_id = @complex_id and
						spot.screening_date = @screening_date and
						spot.spot_status <> 'P' and
		               spot.film_plan_id = @screen_no  and
						spot.package_id = pack.package_id and
						pack.product_category = @prod_cat and
						fc.campaign_no = spot.campaign_no and
						fc.campaign_no = pack.campaign_no and
						pack.allow_product_clashing = 'Y' and
						(pack.product_subcategory = @product_subcategory OR 
					  @product_subcategory = 0 
					  OR isnull(pack.product_subcategory,0) = 0)
			end
			
			/*
			* Get Count of Booked Spots with the Same Product Category from the Same Campaign
			* With a Package Code less than the package being checked.
			*/

			
			select @prod_count = isnull(@prod_count,0) - (isnull(@client_clash_count,0) + isnull(@allow_product_clashing_count,0))
			
		end
		
		if(@prod_count is null or @prod_count < 1)
			select @clash_count = 0
		else
			select @clash_count = @prod_count

		select @avail_clash = @clash_limit - @clash_count
	

	end
	else
	begin

		select @book_time = Isnull(sum(pack.duration),0),
			   @book_ads = Isnull(sum(pack.prints),0)
		  from campaign_spot spot,
			   campaign_package pack,
               film_campaign fc
		 where spot.complex_id = @complex_id and
			   spot.screening_date = @screening_date and
			   spot.spot_status <> 'D' and
			   spot.spot_status <> 'P' and
			   spot.package_id = pack.package_id and
               spot.campaign_no = fc.campaign_no and
               pack.campaign_no = fc.campaign_no and
               spot.film_plan_id = @screen_no  and
				(pack.product_subcategory = @product_subcategory OR 
			  @product_subcategory = 0 
			  OR isnull(pack.product_subcategory,0) = 0)
	end

	/*
	 * Determine Availability
	 */
 
	select @avail_time = @max_time - @book_time
	select @avail_ads = @max_ads - @book_ads

	select @avail_time = round((@avail_time / @duration) - 0.5, 0)
	select @avail_ads = round((@avail_ads / @prints) - 0.5, 0)

	insert into #avails values (@complex_id,
                                @screen_no,
                                @screening_date, 
                                @avail_time, 
                                @avail_ads,
                                @avail_clash )

	/*
	 * Fetch Next
	 */

	fetch date_csr into @screening_date, @max_ads, @max_time, @clash_count

end

close date_csr
deallocate date_csr

/*
 * Return Overbooked Data
 */

select	avl.complex_id,
		avl.screening_date,
		avl.avail_time,
		avl.avail_ads,
		avl.avail_clash,
		fm.film_market_desc,
		fm.film_market_no,
		cplx.complex_name,
		avl.screen_no,
		cin.cinema_category
from	#avails avl,
		complex cplx,
		film_market fm, 
		cinema cin
where	avl.complex_id = cplx.complex_id 
and		cplx.film_market_no = fm.film_market_no 
and		avl.screen_no = cin.cinema_no
and		cplx.complex_id = cin.complex_id

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
