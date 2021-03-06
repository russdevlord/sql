/****** Object:  StoredProcedure [dbo].[p_cinelights_process_billings]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelights_process_billings]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelights_process_billings]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * p_cinelights_process_billings
 * --------------------------
 * This procedure calls p_cinelights_process_billings automatically every day
 *
 * Created/Modified
 */

CREATE PROC [dbo].[p_cinelights_process_billings]   @cinelight_campaign_no int,
                                            @cinelight_id          int,
                                            @screening_week        datetime,
                                            @billing_status        char(1),
                                            @billing_period        datetime,
                                            @billing_date          datetime,
                                            @rate                  money,
                                            @charge_rate           money,
                                            @production_rate       money
--with recompile
as

/* Declare Variables */
declare     @error              int

SET NOCOUNT ON 

begin transaction

    INSERT INTO dbo.cinelight_billings
	    (cinelight_campaign_no,
	     cinelight_id,
	     screening_week,
	     billing_status,
	     billing_period,
	     billing_date,
	     rate,
	     charge_rate,
	     production_rate)
    VALUES
	    (@cinelight_campaign_no,
	     @cinelight_id,
	     @screening_week,
	     @billing_status,
	     @billing_period,
	     @billing_date,
	     @rate,
	     @charge_rate,
	     @production_rate)
    set	@error = @@error
    if (@error !=0)
    begin
        goto rollbackerror
    end        

commit transaction

SET NOCOUNT OFF 
return 0

rollbackerror:

--    if @error >= 50000
--        raiserror ( @error, 16, 1) 
        
    rollback transaction
    
    SET NOCOUNT OFF 
    
    return -1
GO
