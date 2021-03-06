/****** Object:  StoredProcedure [dbo].[p_eom_billing_gen_preprocess]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_billing_gen_preprocess]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_billing_gen_preprocess]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE PROC [dbo].[p_eom_billing_gen_preprocess] @accounting_period	datetime
as

/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode						int,
		@temp						varchar(200)

/*
 * Begin Transaction
 */
 
begin transaction

/*
 * Update Campaign Spots
 */

     update campaign_spot
        set billing_period = @accounting_period 
      where campaign_spot.billing_period < @accounting_period and
		    campaign_spot.tran_id is null and 
		    campaign_spot.spot_type <> 'M' and
		    campaign_spot.spot_type <> 'V' and
		    campaign_spot.spot_type <> 'T' and
		    campaign_spot.spot_type <> 'F' and
		    campaign_spot.spot_type <> 'K' and
		    campaign_spot.spot_type <> 'A' and
		    campaign_spot.spot_status <> 'P'

    select @error = @@error
    if (@error !=0)
    begin
	    rollback transaction
	    select @temp = convert(varchar, @accounting_period, 105)
        raiserror ('Error: Failed to Update Spots for Prior Billing Period Changeover for Period %1!',11,1, @temp)
	    return -1
    end	

     update cinelight_spot
        set billing_period = @accounting_period 
      where cinelight_spot.billing_period < @accounting_period and
		    cinelight_spot.tran_id is null and 
		    cinelight_spot.spot_type <> 'M' and
		    cinelight_spot.spot_type <> 'V' and
		    cinelight_spot.spot_type <> 'T' and
		    cinelight_spot.spot_type <> 'F' and
		    cinelight_spot.spot_type <> 'K' and
			cinelight_spot.spot_type <> 'A' and
		    cinelight_spot.spot_status <> 'P'

    select @error = @@error
    if (@error !=0)
    begin
	    rollback transaction
	    select @temp = convert(varchar, @accounting_period, 105)
        raiserror ('Error: Failed to Update Cinelight Spots for Prior Billing Period Changeover for Period %1!',11,1, @temp)
	    return -1
    end	

     update inclusion_spot
        set billing_period = @accounting_period 
      where inclusion_spot.billing_period < @accounting_period and
		    inclusion_spot.tran_id is null and 
		    inclusion_spot.spot_type <> 'M' and
		    inclusion_spot.spot_type <> 'V' and
		    inclusion_spot.spot_type <> 'T' and
		    inclusion_spot.spot_type <> 'F' and
		    inclusion_spot.spot_type <> 'K' and
			inclusion_spot.spot_type <> 'A' and
		    inclusion_spot.spot_status <> 'P' and
			inclusion_spot.inclusion_id in (select inclusion_id from inclusion where invoice_client = 'Y')

    select @error = @@error
    if (@error !=0)
    begin
	    rollback transaction
	    select @temp = convert(varchar, @accounting_period, 105)
        raiserror ('Error: Failed to Update Inclusion Spots for Prior Billing Period Changeover for Period %1!',11,1, @temp)
	    return -1
    end	

    update  inclusion
    set     billing_period = @accounting_period 
    from    film_campaign fc
    where   billing_period < @accounting_period 
    and     billing_period is not null
    and     tran_id is null
    and     inclusion.campaign_no = fc.campaign_no
	and		invoice_client = 'Y'
    and     (fc.campaign_status = 'L' OR fc.campaign_status = 'F')
        
    select @error = @@error
    if (@error !=0)
    begin
	    rollback transaction
	    select @temp = convert(varchar, @accounting_period, 105)
        raiserror ('Error: Failed to Update Inclusions for Prior Billing Period Changeover for Period %1!',11,1, @temp)
	    return -1
    end	

     update outpost_spot
        set billing_period = @accounting_period 
      where outpost_spot.billing_period < @accounting_period and
		    outpost_spot.tran_id is null and 
		    outpost_spot.spot_type <> 'M' and
		    outpost_spot.spot_type <> 'V' and
		    outpost_spot.spot_type <> 'T' and
		    outpost_spot.spot_type <> 'F' and
		    outpost_spot.spot_type <> 'K' and
		    outpost_spot.spot_status <> 'P'

    select @error = @@error
    if (@error !=0)
    begin
	    rollback transaction
	    select @temp = convert(varchar, @accounting_period, 105)
        raiserror ('Error: Failed to Update Retail Spots for Prior Billing Period Changeover for Period %1!',11,1, @temp)
	    return -1
    end	


/*
 * Commit and Return
 */

commit transaction
return 0
GO
