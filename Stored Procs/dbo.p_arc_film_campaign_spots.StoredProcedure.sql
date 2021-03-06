/****** Object:  StoredProcedure [dbo].[p_arc_film_campaign_spots]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_arc_film_campaign_spots]
GO
/****** Object:  StoredProcedure [dbo].[p_arc_film_campaign_spots]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_arc_film_campaign_spots] @campaign_no		int
as

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @errorode						integer,
        @errno						integer,
        @complex_id				integer,
        @package_id				integer,
        @cancelled_count		integer,
        @scheduled_count		integer,
        @bonus_count				integer,
        @unalloc_count			integer,
        @makeup_count			integer,
        @spot_csr_open			tinyint,
        @status					char(1)
 


/*
 * Initialise Cursor Flags
 */

select @spot_csr_open = 0

/*
 * Check Campaign Status
 */

select @status = campaign_status
  from film_campaign
 where campaign_no = @campaign_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Film Campaign Spot Archive: Error retrieving campaign status.', 16, 1)
	return -1
end

if(@status = 'Z') --Archived
begin
	raiserror ('Film Campaign Spot Archive: Campaign has already been archived. Processing Halted.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Existing Archive Data
 */

delete film_campaign_spot_archive
 where campaign_no = @campaign_no

select @errno = @@error
if	(@errno != 0)
	goto error

/*
 * Loop Packages
 */

 declare spot_csr cursor static for
  select distinct 
         complex_id,
         package_id
    from campaign_spot spot
   where campaign_no = @campaign_no
order by complex_id,
         package_id
     for read only

open spot_csr
select @spot_csr_open = 1
fetch spot_csr into @complex_id, @package_id
while(@@fetch_status = 0)
begin

	/*
	 * Calculate Cancelled Spots
	 */

	select @cancelled_count = count(spot_id)
	  from campaign_spot
	 where campaign_no = @campaign_no and
			 complex_id = @complex_id and
			 package_id = @package_id and
			 spot_status = 'C' --Cancelled

	/*
	 * Calculate Scheduled Spots
	 */

	select @scheduled_count = count(spot_id)
	  from campaign_spot
	 where campaign_no = @campaign_no and
			 complex_id = @complex_id and
			 package_id = @package_id and
			 spot_type in ('S','A') --Scheduled, Addition

	/*
	 * Calculate Bonus Spots
	 */

	select @bonus_count = count(spot_id)
	  from campaign_spot
	 where campaign_no = @campaign_no and
			 complex_id = @complex_id and
			 package_id = @package_id and
			 spot_type in ('B','C','N') --Bonus, Contra, NoCharge

	/*
	 * Calculate Unallocated Spots
	 */

	select @unalloc_count = count(spot_id)
	  from campaign_spot
	 where campaign_no = @campaign_no and
			 complex_id = @complex_id and
			 package_id = @package_id and
			 spot_status in ('U','N') --Unallocated, NoShow

	/*
	 * Calculate Makeups Spots
	 */

	select @makeup_count = count(spot_id)
	  from campaign_spot
	 where campaign_no = @campaign_no and
			 complex_id = @complex_id and
			 package_id = @package_id and
			 spot_type = 'M' --Makeup

	/*
	 * Insert Archive Record
	 */

	insert into film_campaign_spot_archive ( 
			 campaign_no,
			 complex_id,
			 package_id,
			 cancelled_count,
			 scheduled_count,
			 bonus_count,
			 unalloc_count,
			 makeup_count ) values (
			 @campaign_no,
			 @complex_id,
			 @package_id,
			 @cancelled_count,
			 @scheduled_count,
			 @bonus_count,
			 @unalloc_count,
			 @makeup_count )

	select @errno = @@error
	if (@errno != 0)
		goto error

	/*
	 * Fetch Next
	 */

	fetch spot_csr into @complex_id, @package_id

end
close spot_csr
select @spot_csr_open = 0
deallocate spot_csr

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
	 if(@spot_csr_open = 1)
    begin
		 close spot_csr
		 deallocate spot_csr
	 end

	 return -1
GO
