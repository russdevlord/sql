/****** Object:  StoredProcedure [dbo].[p_eom_film_campaign_preclose]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_film_campaign_preclose]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_film_campaign_preclose]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_eom_film_campaign_preclose] @campaign_no				int,
                                         @accounting_period		datetime
as

/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode						int,
        @spot_id					int,
        @lid						int,
        @complex_id					int,
        @release_period				datetime,
        @spot_csr_open				tinyint,
        @liab_csr_open				tinyint,
        @cinema_rent				money,
        @rent_total					money,
        @can_amount					money,
        @can_rent					money

/*
 * Initialise Cursor Flags
 */

select @spot_csr_open = 0
select @liab_csr_open = 0

/*
 * Begin Transaction
 */

begin transaction

/*
 * Loop Through Spots
 */

 declare spot_csr cursor static for
  select spot_id,
         complex_id
    from campaign_spot
   where campaign_no = @campaign_no and
         screening_date is null
order by spot_id
     for read only

open spot_csr
select @spot_csr_open = 1
fetch spot_csr into @spot_id, @complex_id
while(@@fetch_status = 0)
begin

	/*
    * Initialise Variables
    */
	
	select @rent_total = 0

	/*
    * Loop through Liability for this Spot
    */

 	declare liab_csr cursor static for
	  select spot_liability_id,
	         release_period,
	         cinema_rent
	    from spot_liability
	   where spot_id = @spot_id and
	         cinema_rent <> 0
	     for read only

	open liab_csr
	select @liab_csr_open = 1
	fetch liab_csr into @lid, @release_period, @cinema_rent
	while(@@fetch_status = 0)
	begin

		if(@release_period = Null)
		begin
			
			/*
          * Add to the Rent total
          */

			select @rent_total = @rent_total + @cinema_rent

			/*
          * Update Spot Liability
          */

			update spot_liability
            set release_period = @accounting_period
          where spot_liability_id = @lid

			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	

		end

		/*
       * Fetch Next Liability
       */

		fetch liab_csr into @lid, @release_period, @cinema_rent

	end
	close liab_csr
	deallocate liab_csr
	select @liab_csr_open = 0
	
	/*
    * Calculate Cancellation Liability Total
    */
	
	select @can_rent = 0 - @rent_total

	/*
    * Insert Cancellation Liability
    */

	if(@can_rent <> 0)
	begin

		/*
		 * Get Liability Id
		 */
		
		execute @errorode = p_get_sequence_number 'spot_liability', 5, @lid OUTPUT
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end

		/*
		 * Insert Liability Record
		 */
		
		insert into spot_liability (
				 spot_liability_id,
				 spot_id,
				 complex_id,
				 liability_type,
				 creation_period,
             	 release_period,
				 spot_amount,
             	 cinema_amount,
				 cinema_rent,
                 cancelled,
                 original_liability ) values (
				 @lid,
				 @spot_id,
				 @complex_id,
				 99,
				 @accounting_period,
				 @accounting_period,
				 0,
             	 0,
				 @can_rent,
                 0,
                 0)
		
		
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end	


	end

	/*
    * Fetch Next Spot
    */

fetch spot_csr into @spot_id, @complex_id

end
close spot_csr
select @spot_csr_open = 0
deallocate spot_csr


 declare spot_csr cursor static for
  select spot_id,
         complex_id
    from cinelight_spot,
		 cinelight
   where campaign_no = @campaign_no and
         screening_date is null and
		 cinelight_spot.cinelight_id = cinelight.cinelight_id
order by spot_id
     for read only

open spot_csr
select @spot_csr_open = 1
fetch spot_csr into @spot_id, @complex_id
while(@@fetch_status = 0)
begin

	/*
    * Initialise Variables
    */
	
	select @rent_total = 0

	/*
    * Loop through Liability for this Spot
    */

 	declare liab_csr cursor static for
	  select spot_liability_id,
	         release_period,
	         cinema_rent
	    from cinelight_spot_liability
	   where spot_id = @spot_id and
	         cinema_rent <> 0
	     for read only

	open liab_csr
	select @liab_csr_open = 1
	fetch liab_csr into @lid, @release_period, @cinema_rent
	while(@@fetch_status = 0)
	begin

		if(@release_period = Null)
		begin
			
			/*
          * Add to the Rent total
          */

			select @rent_total = @rent_total + @cinema_rent

			/*
          * Update Spot Liability
          */

			update cinelight_spot_liability
            set release_period = @accounting_period
          where spot_liability_id = @lid

			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	

		end

		/*
       * Fetch Next Liability
       */

		fetch liab_csr into @lid, @release_period, @cinema_rent

	end
	close liab_csr
	deallocate liab_csr
	select @liab_csr_open = 0
	
	/*
    * Calculate Cancellation Liability Total
    */
	
	select @can_rent = 0 - @rent_total

	/*
    * Insert Cancellation Liability
    */

	if(@can_rent <> 0)
	begin

		/*
		 * Get Liability Id
		 */
		
		execute @errorode = p_get_sequence_number 'cinelight_spot_liability', 5, @lid OUTPUT
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end

		/*
		 * Insert Liability Record
		 */
		
		insert into cinelight_spot_liability (
				 spot_liability_id,
				 spot_id,
				 complex_id,
				 liability_type,
				 creation_period,
             release_period,
				 spot_amount,
             cinema_amount,
				 cinema_rent,
                 cancelled,
                 original_liability ) values (
				 @lid,
				 @spot_id,
				 @complex_id,
				 99,
				 @accounting_period,
				 @accounting_period,
				 0,
             	 0,
				 @can_rent,
                 0,
                 0)
		
		
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end	


	end

	/*
    * Fetch Next Spot
    */

fetch spot_csr into @spot_id, @complex_id

end
close spot_csr
select @spot_csr_open = 0
deallocate spot_csr

 declare spot_csr cursor static for
  select spot_id,
         complex_id
    from inclusion_spot
   where campaign_no = @campaign_no and
         screening_date is null 
order by spot_id
     for read only

open spot_csr
select @spot_csr_open = 1
fetch spot_csr into @spot_id
while(@@fetch_status = 0)
begin

	/*
    * Initialise Variables
    */
	
	select @rent_total = 0

	select @complex_id = complex_id
	from inclusion_spot where spot_id = @spot_id
	/*
    * Loop through Liability for this Spot
    */

 	declare liab_csr cursor static for
	  select spot_liability_id,
	         release_period,
	         cinema_rent
	    from inculsion_spot_liability
	   where spot_id = @spot_id and
	         cinema_rent <> 0
	     for read only

	open liab_csr
	select @liab_csr_open = 1
	fetch liab_csr into @lid, @release_period, @cinema_rent
	while(@@fetch_status = 0)
	begin

		if(@release_period = Null)
		begin
			
			/*
          * Add to the Rent total
          */

			select @rent_total = @rent_total + @cinema_rent

			/*
          * Update Spot Liability
          */

			update inculsion_spot_liability
            set release_period = @accounting_period
          where spot_liability_id = @lid

			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	

		end

		/*
       * Fetch Next Liability
       */

		fetch liab_csr into @lid, @release_period, @cinema_rent

	end
	close liab_csr
	deallocate liab_csr
	select @liab_csr_open = 0
	
	/*
    * Calculate Cancellation Liability Total
    */
	
	select @can_rent = 0 - @rent_total

	/*
    * Insert Cancellation Liability
    */

	if(@can_rent <> 0)
	begin

		/*
		 * Get Liability Id
		 */
		
		execute @errorode = p_get_sequence_number 'inculsion_spot_liability', 5, @lid OUTPUT
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end

		/*
		 * Insert Liability Record
		 */
		
		insert into inculsion_spot_liability (
				 spot_liability_id,
				 spot_id,
				 complex_id,
				 liability_type,
				 creation_period,
             release_period,
				 spot_amount,
             cinema_amount,
				 cinema_rent,
                 cancelled,
                 original_liability ) values (
				 @lid,
				 @spot_id,
				 @complex_id,
				 99,
				 @accounting_period,
				 @accounting_period,
				 0,
             	 0,
				 @can_rent,
                 0,
                 0)
		
		
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end	


	end

	/*
    * Fetch Next Spot
    */

fetch spot_csr into @spot_id

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

	 if (@spot_csr_open = 1)
    begin
		 close spot_csr
		 deallocate spot_csr
	 end
	 if (@liab_csr_open = 1)
    begin
		 close liab_csr
		 deallocate liab_csr
	 end
  	 raiserror ('Error: Failed to Relaase Spot Allocations for Closing Campaign %1!',11,1, @campaign_no)
	 return -1
GO
