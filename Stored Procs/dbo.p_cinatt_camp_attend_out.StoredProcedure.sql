/****** Object:  StoredProcedure [dbo].[p_cinatt_camp_attend_out]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_camp_attend_out]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_camp_attend_out]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_camp_attend_out] @campaign_no integer, @attendance_out integer OUTPUT
as

/* GETS ACTUAL ATTENDANCE FIGURES FOR SELECTED CAMPAIGN 
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @errorode						integer,
        @errno						integer,
        @spot_csr_open			tinyint,
        @film_market_no			integer,
        @spot_id					integer,
        @complex_id				integer,
        @package_id				integer,
        @screening_date			datetime,
        @spot_status				char(1),
        @pack_code				char(1),
	     @actual_attendance		integer,
        @estimated_attendance	integer,
        @attendance				integer,
        @movie_id					integer,
        @actual					char(1)

select  @actual_attendance = 0,
        @estimated_attendance = 0



/* do not process if analysis not allowed */
if exists
        (select 1
         from   film_campaign
         where  campaign_no = @campaign_no
         and    attendance_analysis = 'Y')
begin

select  @actual_attendance = sum(attendance)
from    film_cinatt_actuals
where   campaign_no = @campaign_no



/*
    select @spot_csr_open = 0

    /*
     * Initialise Variables
     */

    select @actual_attendance = 0,
           @estimated_attendance = 0


	/*
	 * Declare Cursor
	 */

	 declare spot_csr cursor static for
	  select spot.spot_id,
	         spot.complex_id,
	         spot.package_id,
	         spot.screening_date
	    from campaign_spot spot,
	         campaign_package cpack,
	         complex cplx
	   where spot.campaign_no = @campaign_no and
	         spot.complex_id = cplx.complex_id and
	         spot.package_id = cpack.package_id and
	         spot.spot_status = 'X'
	order by spot.complex_id,
	         spot.spot_id
	     for read only

    /*
     * Loop Spots
     */

    open spot_csr
    select @spot_csr_open = 1
    fetch spot_csr into @spot_id,@complex_id,@package_id,@screening_date
    while(@@fetch_status = 0)
    begin

    	/*
        * Get Certificate Details
        */
        select @movie_id = null

    	select @movie_id = mh.movie_id
         from certificate_item ci,
              certificate_group cg,
              movie_history mh
        where ci.spot_reference = @spot_id and
              ci.certificate_group = cg.certificate_group_id and
              cg.certificate_group_id = mh.certificate_group

    	select @errno = @@error
    	if (@errno != 0)
    		goto error

    	/*
    	 * Call Attendance Procedure
    	 */

    	select @attendance = 0

    	if(@screening_date is not null)
    	begin

    		exec @errorode = p_cinatt_get_movie_attendance @screening_date,
    																  @complex_id,
    																  @movie_id,
    																  @attendance OUTPUT,
    																  @actual OUTPUT

    		if(@errorode !=0)
    		begin
    			goto error
    		end

    		if(@actual = 'Y')
    			select @actual_attendance = @actual_attendance + @attendance
    		else
    			select @estimated_attendance = @estimated_attendance + @attendance

    	end

    	/*
    	 * Fetch Next
    	 */

    	fetch spot_csr into @spot_id,@complex_id,@package_id,@screening_date

    end
    close spot_csr
    select @spot_csr_open = 0
    deallocate spot_csr

*/

end

select  @attendance_out = @actual_attendance + @estimated_attendance

/*
 * Return Success
 */

return 0

/*
 * Error Handler
 */

error:

	 if(@spot_csr_open = 1)
    begin
		 close spot_csr
		 deallocate spot_csr
	 end

	 return -1
GO
