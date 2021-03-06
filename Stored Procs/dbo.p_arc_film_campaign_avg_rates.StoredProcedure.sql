/****** Object:  StoredProcedure [dbo].[p_arc_film_campaign_avg_rates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_arc_film_campaign_avg_rates]
GO
/****** Object:  StoredProcedure [dbo].[p_arc_film_campaign_avg_rates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_arc_film_campaign_avg_rates] @campaign_no		int
as

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @errorode						integer,
        @errno						integer,
        @package_id				integer,
        @spot_count				integer,
        @average_rate			money,
        @pack_csr_open			tinyint
 
/*
 * Initialise Cursor Flags
 */

select @pack_csr_open = 0

/*
 * Begin Transaction
 */

begin transaction

/*
 * Loop Packs
 */
 declare pack_csr cursor static for
  select package_id
    from campaign_package
   where campaign_no = @campaign_no
order by package_id
     for read only

open pack_csr
select @pack_csr_open = 1
fetch pack_csr into @package_id
while(@@fetch_status = 0)
begin

	/*
	 * Calculate Average Spot Rate and Count
	 */

	select @spot_count = isnull(count(spot.spot_id),0),
          @average_rate = isnull(round(avg(spot.charge_rate),2),0.0)
     from campaign_spot spot
    where spot.package_id = @package_id and
			 spot.campaign_no = @campaign_no and
          spot.charge_rate > 0 and
		 	 (spot.spot_type = 'S' or
			 spot.spot_type = 'Y')

	/*
	 * Update Package
	 */

	update campaign_package
      set average_rate = @average_rate,
          spot_count = @spot_count
    where package_id = @package_id
 
	select @errno = @@error
	if (@errno != 0)
		goto error

	/*
	 * Fetch Next
	 */

	fetch pack_csr into @package_id

end
close pack_csr
select @pack_csr_open = 0
deallocate pack_csr

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	rollback transaction
	if(@pack_csr_open = 1)
	begin
		close pack_csr
		deallocate pack_csr
	end

	return -1
GO
