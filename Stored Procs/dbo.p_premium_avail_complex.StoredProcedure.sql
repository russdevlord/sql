/****** Object:  StoredProcedure [dbo].[p_premium_avail_complex]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_premium_avail_complex]
GO
/****** Object:  StoredProcedure [dbo].[p_premium_avail_complex]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_premium_avail_complex]  	@complex_id			int,
										@start_date			datetime,
										@end_date		    datetime,
										@prints				int,
										@duration			int,
										@prod_cat			int,
										@media_product_id  	smallint
as

/*
 * Declare Variables
 */

set nocount on 

declare @screening_date			datetime,
        @max_time				int,
        @max_ads				int,
        @avail_time				int,
        @avail_ads				int,
        @book_time				int,
        @book_ads				int,
        @date_csr_open			int,
        @clash_limit			int,
        @errorode					int,
        @clash_count			int,
        @avail_clash			int,
		@prod_count     		int,
		@premium_variance		numeric(6,4),
		@non_prem_spon_count	int,
		@reading_count			int


/*
 * Create Table to Hold Availability Information
 */

create table #avails
(
	complex_id			int		        null,
	screening_date		datetime		null,
    avail_time			int		        null,
	avail_ads			int		        null,
    avail_clash			int		        null
)

/*
 * Initialise Variables
 */

select @date_csr_open = 0

if(@prints = 0)
	select @prints = 1

if(@duration = 0)
	select @duration = 1

select 	@reading_count = count(complex_id)
from	complex
where 	complex_id = @complex_id
and		exhibitor_id = 187 

/*
 * Loop Through Dates
 */

/*
 * Declare Cursor
 */

if @prod_cat > 0 
	declare	date_csr cursor static for
	select 	cd.screening_date,
			cd.movie_target,
			round(case when @media_product_id = 1 then (cd.clash_safety_limit * pd.film_ad_percent) else (cd.clash_safety_limit * pd.dmg_ad_percent) end,0)
	from 	complex_date cd,
			product_date pd
	where 	cd.complex_id = @complex_id and
			cd.screening_date between @start_date and @end_date and
			pd.screening_date = cd.screening_date and
			pd.product_category_id = @prod_cat
	
	for read only
else
	declare	date_csr cursor static for
	select 	cd.screening_date,
			cd.movie_target,
			cd.clash_safety_limit
	from 	complex_date cd
	where 	cd.complex_id = @complex_id and
			cd.screening_date between @start_date and @end_date
	for read only

open date_csr
select @date_csr_open = 1
fetch date_csr into @screening_date, @max_ads, @clash_limit
while(@@fetch_status=0)
begin


	select 	@non_prem_spon_count = count(spot_id)
	from	campaign_spot,
			campaign_package
	where	campaign_spot.package_id = campaign_package.package_id
	and		campaign_spot.complex_id = @complex_id
	and		campaign_spot.screening_date = @screening_date
	and		campaign_spot.spot_status <> 'P'
	and		campaign_package.all_movies = 'Y'
	and		campaign_package.premium_screen_type = 'N'

	if @non_prem_spon_count > 0 
		select @premium_variance = 0.0
	else if @reading_count > 1 
		select @premium_variance = 0.250
	else
		select @premium_variance = 0.5

	select 	@max_ads = round(@max_ads * @premium_variance,0)
	select	@clash_limit = round(@clash_limit * @premium_variance,0)
	
	select 	@avail_clash = 9999

	/*
	 * Calculate Bookings
	 */

	select @book_ads = Isnull(count(pack.prints),0)
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
          (pack.screening_trailers = 'B' or
           pack.screening_trailers = 'F')

	select @prod_count = IsNull(count(pack.package_id),0)
	  from campaign_spot spot,
		   campaign_package pack,
           film_campaign fc
	 where spot.screening_date = @screening_date and
		   spot.complex_id = @complex_id and
		   spot.spot_status <> 'D' and
		   spot.spot_status <> 'P' and
		   spot.package_id = pack.package_id and
		   pack.product_category = @prod_cat and
           spot.campaign_no = fc.campaign_no and
           pack.campaign_no = fc.campaign_no 


	if @prod_cat > 0
	begin
		if(@prod_count is null or @prod_count < 1)
			select @clash_count = 0
		else
			select @clash_count = @prod_count

		select @avail_clash = @clash_limit - @clash_count
	end

	/*
	 * Determine Availability
	 */
 
	select @avail_time = 15
	select @avail_ads = @max_ads - @book_ads

	insert into #avails values (@complex_id,
                                @screening_date, 
                                @avail_time, 
                                @avail_ads,
                                @avail_clash )

	/*
	 * Fetch Next
	 */

	fetch date_csr into @screening_date, @max_ads, @clash_limit

end

close date_csr
deallocate date_csr
SELECT @date_csr_open = 0

/*
 * Return Overbooked Data
 */

  select avl.complex_id,
         avl.screening_date,
         avl.avail_time,
	     avl.avail_ads,
         avl.avail_clash,
         fm.film_market_desc,
         fm.film_market_no,
         cplx.complex_name
    from #avails avl,
         complex cplx,
		 film_market fm
   where avl.complex_id = cplx.complex_id and
         cplx.film_market_no = fm.film_market_no

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
