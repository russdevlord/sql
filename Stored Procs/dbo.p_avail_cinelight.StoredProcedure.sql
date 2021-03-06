/****** Object:  StoredProcedure [dbo].[p_avail_cinelight]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_avail_cinelight]
GO
/****** Object:  StoredProcedure [dbo].[p_avail_cinelight]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_avail_cinelight]  	@cinelight_id		int,
									@start_date			datetime,
									@end_date		    datetime,
									@prod_cat			int,
									@prints				int,
									@duration			int,
									@campaign_type		char(1),
									@product_subcategory	int
as

/*
 * Declare Variables
 */

declare @screening_date		datetime,
        @max_ads			int,
        @avail_ads			int,
        @book_ads			int,
        @max_time			int,
        @avail_time			int,
        @book_time			int,
        @date_csr_open		int,
        @clash_limit		int,
        @errorode				int,
        @clash_count		int,
        @avail_clash		int,
		@prod_count     	int,
		@complex_id			int

/*
 * Create Table to Hold Availability Information
 */

create table #avails
(
	cinelight_id		int		        null,
	screening_date		datetime		null,
	avail_ads			int		        null,
    avail_clash			int		        null,
	avail_time			int				null
)

/*
 * Initialise Variables
 */
 
select 	@date_csr_open = 0

select 	@complex_id = complex_id
from	cinelight
where	cinelight_id = @cinelight_id

/*
 * Loop Through Dates
 */

if @campaign_type = 'S' 
begin
	declare	date_csr cursor LOCAL static for
	select 	cd.screening_date,
			max_ads,
			max_time,
			1
	from 	cinelight_date cd
	where 	cd.screening_date between @start_date and @end_date 
	and 	cd.cinelight_id = @cinelight_id
	for read only
end 
else if @campaign_type = 'C'
begin
	declare	date_csr cursor LOCAL static for
	select 	cd.screening_date,
			max_ads_trailers,
			max_time_trailers,
			1
	from 	cinelight_date cd
	where 	cd.screening_date between @start_date and @end_date 
	and 	cd.cinelight_id = @cinelight_id
	for read only
end

open date_csr
select @date_csr_open = 1
fetch date_csr into @screening_date, @max_ads, @max_time, @clash_limit
while(@@fetch_status=0)
begin

	select @avail_clash = 999

	/*
	 * Calculate Bookings
	 */

	if(@prod_cat > 0)
	begin

		select 	@book_ads = isnull(sum(pack.prints),0),
				@book_time = isnull(sum(pack.duration),0)
		from 	cinelight_spot spot,
				film_campaign fc,
				cinelight_package pack
					LEFT OUTER JOIN product_subcategory ON pack.product_subcategory = product_subcategory.product_subcategory_id
		where 	spot.cinelight_id = @cinelight_id and
				spot.screening_date = @screening_date and
				spot.spot_status <> 'D' and
				spot.spot_status <> 'P' and
				spot.package_id = pack.package_id and
				spot.campaign_no = fc.campaign_no and
				pack.campaign_no = fc.campaign_no and
				((@campaign_type = 'S' and pack.screening_trailers = 'S') or
				(@campaign_type = 'C' and (pack.screening_trailers = 'D' or	pack.screening_trailers = 'C')))
		AND		( product_subcategory.product_subcategory_id = @product_subcategory OR @product_subcategory = 0 OR @product_subcategory IS NULL )


		select 	@prod_count = isnull(count(pack.package_id),0)
		from 	cinelight_spot spot,
				film_campaign fc,
				cinelight cl,
				cinelight_package pack
					LEFT OUTER JOIN product_subcategory ON pack.product_subcategory = product_subcategory.product_subcategory_id
		where 	spot.screening_date = @screening_date and
				spot.cinelight_id = cl.cinelight_id and
				cl.complex_id = @complex_id and
				spot.spot_status <> 'D' and
				spot.spot_status <> 'P' and
				spot.package_id = pack.package_id and
				pack.product_category = @prod_cat and
				spot.campaign_no = fc.campaign_no and
				pack.campaign_no = fc.campaign_no and
				((@campaign_type = 'S' and pack.screening_trailers = 'S') or
				(@campaign_type = 'C' and (pack.screening_trailers = 'D' or	pack.screening_trailers = 'C')))
		AND	( product_subcategory.product_subcategory_id = @product_subcategory OR @product_subcategory = 0 OR @product_subcategory IS NULL )

		if(@prod_count is null or @prod_count < 1)
			select @clash_count = 0
		else
			select @clash_count = @prod_count
		
		select @avail_clash = @clash_limit - @clash_count
		
	end
	else
	begin

		select 	@book_ads = Isnull(sum(pack.prints),0),
				@book_time = isnull(sum(pack.duration),0)
		from 	cinelight_spot spot,
				film_campaign fc,
				cinelight_package pack
					LEFT OUTER JOIN product_subcategory ON pack.product_subcategory = product_subcategory.product_subcategory_id
		where 	spot.cinelight_id = @cinelight_id and
				spot.screening_date = @screening_date and
				spot.spot_status <> 'D' and
				spot.spot_status <> 'P' and
				spot.package_id = pack.package_id and
				spot.campaign_no = fc.campaign_no and
				pack.campaign_no = fc.campaign_no and
				((@campaign_type = 'S' and pack.screening_trailers = 'S') or
				(@campaign_type = 'C' and (pack.screening_trailers = 'D' or	pack.screening_trailers = 'C'))	)
		AND	( product_subcategory.product_subcategory_id = @product_subcategory OR @product_subcategory = 0 OR @product_subcategory IS NULL )

	end

	/*
	 * Determine Availability
	 */
	 
	-- DYI 2012-09-12 Added to avoid division by zero 
	select @avail_ads = @max_ads - @book_ads
	if(@prints <> 0)
		begin
			select @avail_ads = round((@avail_ads / @prints) - 0.5, 0)
		end
		
	select @avail_time = @max_time - @book_time
	if(@duration <> 0)
		begin
			select @avail_time = round((@avail_time / @duration) - 0.5, 0)
		end

	insert into #avails values (@cinelight_id,
                                @screening_date, 
                                @avail_ads,
                                @avail_clash,
								@avail_time )

	/*
	 * Fetch Next
	 */

	fetch date_csr into @screening_date, @max_ads, @max_time, @clash_limit

end

close date_csr
deallocate date_csr

/*
 * Return Overbooked Data
 */

select 	avl.cinelight_id,
		avl.screening_date,
		avl.avail_ads,
		avl.avail_clash,
		avl.avail_time,
		fm.film_market_desc,
		fm.film_market_no,
		cl.cinelight_desc,
		cplx.complex_id,
		cplx.complex_name,
        cbg.cinelight_booking_group_id,
        cbg.cinelight_booking_group_desc
from 	#avails avl,
		complex cplx,
		cinelight cl,
		film_market fm,
        cinelight_booking_group cbg
where 	avl.cinelight_id = cl.cinelight_id
and		cplx.film_market_no = fm.film_market_no
and		cl.complex_id = cplx.complex_id
and     cl.cinelight_booking_group_id = cbg.cinelight_booking_group_id


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
