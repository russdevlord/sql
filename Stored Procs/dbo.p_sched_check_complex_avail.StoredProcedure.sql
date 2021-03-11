USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_sched_check_complex_avail]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sched_check_complex_avail] @campaign_no 	integer,
											       @complex_id		integer,
											       @package_id		integer

as

/*
 * Declare Variables
 */

declare @error						integer,
        @spot_csr_open			tinyint,
        @complex_date			integer,
        @screening_date			datetime,
	     @safety_limit			smallint,
	     @safety_check			integer,
        @spot_count				integer,
		  @campaign_count			integer,
		  @package_code			char(4),
		  @row_type					char(10)

/*
 * Create a table for returning the screening dates and complex ids
 */

create table #unavail
(
	screening_date		datetime,
	complex_id			integer,
	package_id			integer,
	row_type				char(10),
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
    from campaign_spot spot,
         film_complex_downtime fcd
   where spot.campaign_no = @campaign_no and
         spot.complex_id = @complex_id and
         spot.package_id = @package_id and
         spot.screening_date = fcd.screening_date and
         spot.complex_id = fcd.complex_id
group by spot.complex_id,
         spot.screening_date
union all
  select spot.billing_date,
         spot.complex_id,
         count(spot.spot_id),
			'Billing'
    from campaign_spot spot,
         film_complex_downtime fcd
   where spot.campaign_no = @campaign_no and
         spot.complex_id = @complex_id and
         spot.package_id = @package_id and
         spot.screening_date = fcd.screening_date and
         spot.complex_id = fcd.complex_id
group by spot.complex_id,
         spot.billing_date
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

	insert into #unavail values (@screening_date, @complex_id, @package_id, @row_type, @spot_count)

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
         package_id,
			row_type,
         spot_count
    from #unavail
order by screening_date asc,
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
