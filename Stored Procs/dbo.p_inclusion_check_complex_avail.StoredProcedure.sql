/****** Object:  StoredProcedure [dbo].[p_inclusion_check_complex_avail]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_inclusion_check_complex_avail]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_check_complex_avail]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_inclusion_check_complex_avail] 	   @campaign_no 	integer,
											       @complex_id		integer,
											       @inclusion_id	integer

as

/*
 * Declare Variables
 */

declare @error					integer,
		@spot_csr_open			tinyint,
		@complex_date			integer,
		@screening_date			datetime,
		@safety_limit			smallint,
		@safety_check			integer,
		@spot_count				integer,
		@campaign_count			integer,
		@row_type				char(10),
		@inclusion_format		char(1)

/*
 * Create a table for returning the screening dates and complex ids
 */

create table #unavail
(
	screening_date		datetime,
	complex_id			integer,
	inclusion_id		integer,
	row_type			char(10),
 	spot_count			integer
)

/*
 * Initialise Variables
 */

select @spot_csr_open = 0

/*
 * Declare Cursors
 */ 

 declare spot_csr cursor static for
  select spot.screening_date,
         spot.complex_id,
         count(spot.spot_id),
		 'Screening'
    from inclusion_spot spot,
         film_complex_downtime fcd,
		 inclusion inc
   where spot.campaign_no = @campaign_no and
         spot.complex_id = @complex_id and
         spot.inclusion_id = @inclusion_id and
         spot.screening_date = fcd.screening_date and
         spot.complex_id = fcd.complex_id and
		 inc.inclusion_id = spot.inclusion_id and
		 inc.inclusion_format <> 'R' 
group by spot.complex_id,
         spot.screening_date
union all
  select spot.billing_date,
         spot.complex_id,
         count(spot.spot_id),
		 'Billing'
    from inclusion_spot spot,
         film_complex_downtime fcd,
		 inclusion inc
   where spot.campaign_no = @campaign_no and
         spot.complex_id = @complex_id and
         spot.inclusion_id = @inclusion_id and
         spot.screening_date = fcd.screening_date and
         spot.complex_id = fcd.complex_id and
		 inc.inclusion_id = spot.inclusion_id and
		 inc.inclusion_format <> 'R' 
group by spot.complex_id,
         spot.billing_date
union all
  select spot.op_screening_date,
         spot.outpost_venue_id,
         count(spot.spot_id),
		 'Screening'
    from inclusion_spot spot,
         outpost_venue_downtime fcd,
		 inclusion inc
   where spot.campaign_no = @campaign_no and
         spot.outpost_venue_id = @complex_id and
         spot.inclusion_id = @inclusion_id and
         spot.op_screening_date = fcd.screening_date and
         spot.outpost_venue_id = fcd.outpost_venue_id and
		 inc.inclusion_id = spot.inclusion_id and
		 inc.inclusion_format = 'R' 
group by spot.outpost_venue_id,
         spot.op_screening_date
union all
  select spot.op_billing_date,
         spot.outpost_venue_id,
         count(spot.spot_id),
		 'Billing'
    from inclusion_spot spot,
         outpost_venue_downtime fcd,
		 inclusion inc
   where spot.campaign_no = @campaign_no and
         spot.outpost_venue_id = @complex_id and
         spot.inclusion_id = @inclusion_id and
         spot.op_screening_date = fcd.screening_date and
         spot.outpost_venue_id = fcd.outpost_venue_id and
		 inc.inclusion_id = spot.inclusion_id and
		 inc.inclusion_format = 'R' 
group by spot.outpost_venue_id,
         spot.op_billing_date
order by spot.complex_id,
         spot.screening_date
     for read only



/*
 * Loop through Spots
 */

open spot_csr
fetch spot_csr into @screening_date, 
					@complex_id, 
                    @spot_count,
					@row_type

while(@@fetch_status=0)
begin

	if(@row_type <> 'Screening')
		select @spot_count = 0

	insert into #unavail values (@screening_date, @complex_id, @inclusion_id, @row_type, @spot_count)

	/*
    * Fetch Next Spot
    */

	fetch spot_csr into @screening_date, 
					    @complex_id, 
					    @spot_count,
					    @row_type

end

close spot_csr
deallocate spot_csr

/*
 * Return Unavail List
 */

  select screening_date,
         complex_id,
         inclusion_id,
		 row_type,
         spot_count
    from #unavail
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
