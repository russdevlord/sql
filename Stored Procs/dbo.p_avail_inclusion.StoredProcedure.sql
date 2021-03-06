/****** Object:  StoredProcedure [dbo].[p_avail_inclusion]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_avail_inclusion]
GO
/****** Object:  StoredProcedure [dbo].[p_avail_inclusion]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_avail_inclusion]  	 @complex_id				int,
									 @start_date				datetime,
									 @end_date					datetime,
									 @prod_cat					int,
									 @inclusion_format			char(1),
									 @product_subcategory		int
as

/*
 * Declare Variables
 */

declare @screening_date		datetime,
        @max_ads			int,
        @avail_ads			int,
        @book_ads			int,
        @date_csr_open		int,
        @clash_limit		int,
        @errorode				int,
        @clash_count		int,
        @avail_clash		int,
		@prod_count     	int,
		@prints				int

/*
 * Create Table to Hold Availability Information
 */

create table #avails
(
	complex_id			int		        null,
	screening_date		datetime		null,
	avail_ads			int		        null,
    avail_clash			int		        null
)

/*
 * Initialise Variables
 */

select @date_csr_open = 0

select @prints = 1

/*
 * Loop Through Dates
 */

if @inclusion_format = 'R' 
begin
	declare	date_csr cursor static for
	select 	fsd.screening_date,
			1,
			1
	from 	film_screening_dates fsd
	where 	fsd.screening_date between @start_date and @end_date 
	for read only
end
else
begin
	declare	date_csr cursor static for
	select 	fsd.screening_date,
			1,
			1
	from 	outpost_screening_dates fsd
	where 	fsd.screening_date between @start_date and @end_date 
	for read only
end


open date_csr
select @date_csr_open = 1
fetch date_csr into @screening_date, @max_ads, @clash_limit
while(@@fetch_status=0)
begin

	select @avail_clash = 999

	/*
	 * Calculate Bookings
	 */

	if(@prod_cat > 0)
	begin

		if @inclusion_format <> 'R'
		begin
			select @book_ads = IsNull(count(inc.inclusion_id),0)
			  from inclusion_spot spot,
				   inclusion  inc,
	               film_campaign fc
			 where spot.complex_id = @complex_id and
				   spot.screening_date = @screening_date and
				   spot.spot_status <> 'D' and
				   spot.spot_status <> 'P' and
				   spot.inclusion_id = inc.inclusion_id and
	               spot.campaign_no = fc.campaign_no and
	               inc.campaign_no = fc.campaign_no 
	
			select @prod_count = IsNull(count(inc.inclusion_id),0)
			  from inclusion_spot spot,
				   inclusion inc
					LEFT OUTER JOIN product_subcategory ON inc.product_subcategory = product_subcategory.product_subcategory_id,
	               film_campaign fc,
				   complex cl
			 where spot.screening_date = @screening_date and
				   spot.complex_id = cl.complex_id and
				   cl.complex_id = @complex_id and
				   spot.spot_status <> 'D' and
				   spot.spot_status <> 'P' and
				   spot.inclusion_id = inc.inclusion_id and
				   inc.product_category_id = @prod_cat and
	               spot.campaign_no = fc.campaign_no and
	               inc.campaign_no = fc.campaign_no
	               -- DYI 2012-09-12
	               and (product_subcategory.product_subcategory_id = @product_subcategory OR @product_subcategory = 0 )
 		end
		else
		begin
			select @book_ads = IsNull(count(inc.inclusion_id),0)
			  from inclusion_spot spot,
				   inclusion  inc,
	               film_campaign fc
			 where spot.outpost_venue_id = @complex_id and
				   spot.op_screening_date = @screening_date and
				   spot.spot_status <> 'D' and
				   spot.spot_status <> 'P' and
				   spot.inclusion_id = inc.inclusion_id and
	               spot.campaign_no = fc.campaign_no and
	               inc.campaign_no = fc.campaign_no 
	
			select @prod_count = IsNull(count(inc.inclusion_id),0)
			  from inclusion_spot spot,
				   inclusion inc
					LEFT OUTER JOIN product_subcategory ON inc.product_subcategory = product_subcategory.product_subcategory_id,
	               film_campaign fc,
				   outpost_venue cl
			 where spot.op_screening_date = @screening_date and
				   spot.outpost_venue_id = cl.outpost_venue_id and
				   cl.outpost_venue_id = @complex_id and
				   spot.spot_status <> 'D' and
				   spot.spot_status <> 'P' and
				   spot.inclusion_id = inc.inclusion_id and
				   inc.product_category_id = @prod_cat and
	               spot.campaign_no = fc.campaign_no and
	               inc.campaign_no = fc.campaign_no 
	               -- DYI 2012-09-12
	               and (product_subcategory.product_subcategory_id = @product_subcategory OR @product_subcategory = 0 )
		end

		if(@prod_count is null or @prod_count < 1)
			select @clash_count = 0
		else
			select @clash_count = @prod_count

		select @avail_clash = @clash_limit - @clash_count

	end
	else
	begin

		if @inclusion_format <> 'R'
		begin
			select @book_ads = IsNull(count(inc.inclusion_id),0)
			  from inclusion_spot spot,
				   inclusion inc,
	               film_campaign fc
			 where spot.complex_id = @complex_id and
				   spot.screening_date = @screening_date and
				   spot.spot_status <> 'D' and
				   spot.spot_status <> 'P' and
				   spot.inclusion_id = inc.inclusion_id and
	               spot.campaign_no = fc.campaign_no and
	               inc.campaign_no = fc.campaign_no 
		end
		else
		begin
			select @book_ads = IsNull(count(inc.inclusion_id),0)
			  from inclusion_spot spot,
				   inclusion inc
					LEFT OUTER JOIN product_subcategory ON inc.product_subcategory = product_subcategory.product_subcategory_id,
	               film_campaign fc
			 where spot.complex_id = @complex_id and
					spot.screening_date = @screening_date and
					spot.spot_status <> 'D' and
					spot.spot_status <> 'P' and
					spot.inclusion_id = inc.inclusion_id and
					spot.campaign_no = fc.campaign_no and
					inc.campaign_no = fc.campaign_no
					 -- DYI 2012-09-12
					and (product_subcategory.product_subcategory_id = @product_subcategory OR @product_subcategory = 0 )
		end
	end

	/*
	 * Determine Availability
	 */
 
	select @avail_ads = @max_ads - @book_ads

	select @avail_ads = round((@avail_ads / @prints) - 0.5, 0)

	insert into #avails values (@complex_id,
                                @screening_date, 
                                @avail_ads,
                                @avail_clash )

	/*
	 * Fetch Next
	 */

	fetch date_csr into @screening_date, @max_ads, @clash_limit

end

close date_csr
deallocate date_csr

/*
 * Return Overbooked Data
 */

if @inclusion_format <> 'R'
begin
	select 	avl.complex_id,
			avl.screening_date,
			avl.avail_ads,
			avl.avail_clash,
			fm.film_market_desc,
			fm.film_market_no,
			cl.complex_name,
			cplx.complex_id,
			cplx.complex_name
	from 	#avails avl,
			complex cplx,
			complex cl,
			film_market fm
	where 	avl.complex_id = cl.complex_id
	and		cplx.film_market_no = fm.film_market_no
	and		cl.complex_id = cplx.complex_id
	
end
else
begin
	select 	avl.complex_id,
			avl.screening_date,
			avl.avail_ads,
			avl.avail_clash,
			fm.film_market_desc,
			fm.film_market_no,
			cl.outpost_venue_name,
			cplx.outpost_venue_id,
			cplx.outpost_venue_name
	from 	#avails avl,
			outpost_venue cplx,
			outpost_venue cl,
			film_market fm
	where 	avl.complex_id = cl.outpost_venue_id
	and		cplx.market_no = fm.film_market_no
	and		cl.outpost_venue_id = cplx.outpost_venue_id

end

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
