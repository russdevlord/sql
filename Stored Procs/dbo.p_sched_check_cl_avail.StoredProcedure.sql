/****** Object:  StoredProcedure [dbo].[p_sched_check_cl_avail]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sched_check_cl_avail]
GO
/****** Object:  StoredProcedure [dbo].[p_sched_check_cl_avail]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sched_check_cl_avail] @campaign_no 	integer,
									@cinelight_id		integer,
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
	cinelight_id		integer,
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
			spot.cinelight_id,
			count(spot.spot_id),
			'Screening'
from 		cinelight_spot spot,
			cinelight cl,
			film_complex_downtime fcd
where 		spot.campaign_no = @campaign_no and
			spot.cinelight_id = @cinelight_id and
			spot.package_id = @package_id and
			spot.screening_date = fcd.screening_date and
			spot.cinelight_id = cl.cinelight_id and
			cl.complex_id = fcd.complex_id
group by 	spot.cinelight_id,
			spot.screening_date
union all
select 		spot.billing_date,
			spot.cinelight_id,
			count(spot.spot_id),
			'Billing'
from 		cinelight_spot spot,
			cinelight cl,
			film_complex_downtime fcd
where 		spot.campaign_no = @campaign_no and
			spot.cinelight_id = @cinelight_id and
			spot.package_id = @package_id and
			spot.screening_date = fcd.screening_date and
			spot.cinelight_id = cl.cinelight_id and
			cl.complex_id = fcd.complex_id
group by 	spot.cinelight_id,
			spot.billing_date
order by 	spot.cinelight_id,
			spot.screening_date
for read only



/*
 * Loop through Spots
 */

open spot_csr
fetch spot_csr into @screening_date, 
					@cinelight_id, 
                    @spot_count,
					@row_type

while(@@fetch_status=0)
begin

	if(@row_type <> 'Screening')
		select @spot_count = 0

	insert into #unavail values (@screening_date, @cinelight_id, @package_id, @row_type, @spot_count)

	/*
    * Fetch Next Spot
    */

	fetch spot_csr into @screening_date, 
							  @cinelight_id, 
							  @spot_count,
							  @row_type

end

close spot_csr
deallocate spot_csr

/*
 * Return Unavail List
 */

  select screening_date,
         cinelight_id,
         package_id,
		 row_type,
         spot_count
    from #unavail
order by screening_date asc,
		 cinelight_id asc,
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
