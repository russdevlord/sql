/****** Object:  StoredProcedure [dbo].[p_avail_clashing]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_avail_clashing]
GO
/****** Object:  StoredProcedure [dbo].[p_avail_clashing]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_avail_clashing] @complex_id		integer,
									  @screening_date	datetime,
                             @prod_cat			integer,
                             @prod_spots		integer OUTPUT
as

/*
 * Declare Variables
 */

declare @prod_count	integer

/*
 * Calculate Spot already Booked
 */

	select @prod_count = IsNull(count(pack.package_id),0)
     from campaign_spot spot,
          campaign_package pack
    where spot.screening_date = @screening_date and
			 spot.complex_id = @complex_id and
          spot.spot_status <> 'D' and
          spot.spot_status <> 'P' and
          spot.package_id = pack.package_id and
          pack.product_category = @prod_cat

	if(@prod_count is null or @prod_count < 1)
		select @prod_spots = 0
	else
		select @prod_spots = @prod_count

/*
 * Return Success
 */

return 0
GO
