/****** Object:  StoredProcedure [dbo].[p_cinelights_process_campaign]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelights_process_campaign]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelights_process_campaign]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * p_cinelights_process_campaign
 * --------------------------
 * This procedure calls p_cinelights_process_campaign automatically every day
 *
 * Created/Modified
 */

CREATE PROC [dbo].[p_cinelights_process_campaign]   @cinelight_campaign_no int,
                                            @campaign_no           int,
                                            @cinelight_ref         varchar(10),
                                            @campaign_name         varchar(30),
                                            @start_date            datetime,
                                            @end_date              datetime,
                                            @production_cost       money

--with recompile
as

/* Declare Variables */
declare     @error              int,
            @rowcount           int


SET NOCOUNT ON 

begin transaction

    update dbo.cinelight_campaigns
	set 	campaign_no = @campaign_no,
			cinelight_ref = @cinelight_ref,
			campaign_name = @campaign_name,
			start_date = @start_date,
			end_date = @end_date,
			production_cost = @production_cost
     where  cinelight_campaign_no = @cinelight_campaign_no
    select 	@rowcount = @@rowcount,
            @error = @@error

    if @error <> 0
	    return @error

    if @rowcount = 0 -- no update which means that we need to insert new record
    begin
        INSERT INTO dbo.cinelight_campaigns
	        (cinelight_campaign_no,
	         campaign_no,
	         cinelight_ref,
	         campaign_name,
	         start_date,
	         end_date,
	         production_cost)
        VALUES
	        (@cinelight_campaign_no,
	         @campaign_no,
	         @cinelight_ref,
	         @campaign_name,
	         @start_date,
	         @end_date,
	         @production_cost)
    end --if

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
