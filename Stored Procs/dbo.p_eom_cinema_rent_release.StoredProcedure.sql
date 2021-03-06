/****** Object:  StoredProcedure [dbo].[p_eom_cinema_rent_release]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_cinema_rent_release]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_cinema_rent_release]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_eom_cinema_rent_release] @campaign_no				int,
                                      @accounting_period		datetime
as

/*
 * Declare Variables
 */

declare @error        		int,
        @rowcount     		int

/*
 * Begin Transaction
 */

begin transaction


/*
 * Release Spot Liability
 */

  update spot_liability
     set release_period = @accounting_period
    from campaign_spot spot,
         film_screening_dates fsd
   where spot_liability.spot_id = spot.spot_id and
         spot_liability.release_period is null and
         spot.campaign_no = @campaign_no and
         spot.screening_date = fsd.screening_date and
         fsd.screening_date_status = 'X' and
		 spot.spot_status = 'X'

	select @error = @@error 
	if @error !=0
	begin
		 rollback transaction
		 raiserror ('Error: Failed to release spot liability for campaign : %1!',11,1, @campaign_no)
		 return -1
	end	

/*
 * Release Spot Liability
 */

  update cinelight_spot_liability
     set release_period = @accounting_period
    from cinelight_spot spot,
         film_screening_dates fsd
   where cinelight_spot_liability.spot_id = spot.spot_id and
         cinelight_spot_liability.release_period is null and
         spot.campaign_no = @campaign_no and
         spot.screening_date = fsd.screening_date and
         fsd.screening_date_status = 'X' and
		 spot.spot_status = 'X'

	select @error = @@error 
	if @error !=0
	begin
		 rollback transaction
		 raiserror ('Error: Failed to release spot liability for campaign : %1!',11,1, @campaign_no)
		 return -1
	end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
