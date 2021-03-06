/****** Object:  StoredProcedure [dbo].[p_op_sched_check_avail]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_sched_check_avail]
GO
/****** Object:  StoredProcedure [dbo].[p_op_sched_check_avail]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_sched_check_avail] @campaign_no 	integer,
									@outpost_panel_id		integer,
									@package_id		integer

as

/*
 * Declare Variables
 */

declare @error						integer,
        @spot_csr_open			tinyint,
        @outpost_venue_date			integer,
        @screening_date			datetime,
	     @safety_limit			smallint,
	     @safety_check			integer,
        @spot_count				integer,
		  @campaign_count			integer,
		  @package_code			char(4),
		  @row_type					char(10)

/*
 * Create a table for returning the screening dates and outpost_venue ids
 */

create table #unavail
(
	screening_date		datetime,
	outpost_panel_id		integer,
	package_id			integer,
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

declare 	spot_csr cursor static for
select 		spot.screening_date,
			spot.outpost_panel_id,
			count(spot.spot_id),
			'Screening'
from 		outpost_spot spot,
			outpost_panel cl,
			film_outpost_venue_downtime fcd
where 		spot.campaign_no = @campaign_no and
			spot.outpost_panel_id = @outpost_panel_id and
			spot.package_id = @package_id and
			spot.screening_date = fcd.screening_date and
			spot.outpost_panel_id = cl.outpost_panel_id and
			cl.outpost_venue_id = fcd.outpost_venue_id
group by 	spot.outpost_panel_id,
			spot.screening_date
union all
select 		spot.billing_date,
			spot.outpost_panel_id,
			count(spot.spot_id),
			'Billing'
from 		outpost_spot spot,
			outpost_panel cl,
			film_outpost_venue_downtime fcd
where 		spot.campaign_no = @campaign_no and
			spot.outpost_panel_id = @outpost_panel_id and
			spot.package_id = @package_id and
			spot.screening_date = fcd.screening_date and
			spot.outpost_panel_id = cl.outpost_panel_id and
			cl.outpost_venue_id = fcd.outpost_venue_id
group by 	spot.outpost_panel_id,
			spot.billing_date
order by 	spot.outpost_panel_id,
			spot.screening_date
for read only



/*
 * Loop through Spots
 */

open spot_csr
fetch spot_csr into @screening_date, 
					@outpost_panel_id, 
                    @spot_count,
					@row_type

while(@@fetch_status=0)
begin

	if(@row_type <> 'Screening')
		select @spot_count = 0

	insert into #unavail values (@screening_date, @outpost_panel_id, @package_id, @row_type, @spot_count)

	/*
    * Fetch Next Spot
    */

	fetch spot_csr into @screening_date, 
							  @outpost_panel_id, 
							  @spot_count,
							  @row_type

end

close spot_csr
deallocate spot_csr

/*
 * Return Unavail List
 */

  select screening_date,
         outpost_panel_id,
         package_id,
		 row_type,
         spot_count
    from #unavail
order by screening_date asc,
		 outpost_panel_id asc,
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
