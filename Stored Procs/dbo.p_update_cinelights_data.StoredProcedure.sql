/****** Object:  StoredProcedure [dbo].[p_update_cinelights_data]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_update_cinelights_data]
GO
/****** Object:  StoredProcedure [dbo].[p_update_cinelights_data]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
 * p_update_cinelights_data
 * --------------------------
 * This procedure calls p_update_cinelights_data automatically every day
 *
 * Created/Modified
 */

CREATE PROC [dbo].[p_update_cinelights_data]
--with recompile
as

/* Declare Variables */
declare     @error              int,
            @accounting_period  datetime


SET NOCOUNT ON 

select  @accounting_period = min(end_date)
from    accounting_period
where   status = 'O'

set	@error = @@error
if @error <> 0
	return @error

begin transaction

    /* Refresh cinelights_data */
    /*
    delete from cinelights_data where billing_period >= @accounting_period
    set	@error = @@error
    if @error <> 0
	    return @error
    */

    -- Update changed spots
    update  cinelights_data
    set 	cinelights_data.campaign_no = v_cinelights_data.campaign_no,
		    cinelights_data.business_unit_id = v_cinelights_data.business_unit_id,
		    cinelights_data.media_product_id = v_cinelights_data.media_product_id,
		    cinelights_data.agency_deal = v_cinelights_data.agency_deal,
		    cinelights_data.cinelight_ref = v_cinelights_data.cinelight_ref,
		    cinelights_data.billing_period = v_cinelights_data.billing_period,
		    cinelights_data.billing_date = v_cinelights_data.billing_date,
		    cinelights_data.billing_status = v_cinelights_data.billing_status,
		    cinelights_data.charge_rate = convert(money,v_cinelights_data.charge_rate),
		    cinelights_data.production_rate = convert(money,v_cinelights_data.production_rate),
		    cinelights_data.rate = convert(money,v_cinelights_data.rate),
		    cinelights_data.campaign_name = v_cinelights_data.campaign_name,
		    cinelights_data.branch_code = v_cinelights_data.branch_code,
		    cinelights_data.client_id = v_cinelights_data.client_id,
		    cinelights_data.agency_id = v_cinelights_data.agency_id,
		    cinelights_data.rep_id = v_cinelights_data.rep_id 
    from    v_cinelights_data
    where   cinelights_data.cinelight_campaign_no = v_cinelights_data.cinelight_campaign_no
    and     cinelights_data.screening_week = v_cinelights_data.screening_week
    and     cinelights_data.cinelight_id = v_cinelights_data.cinelight_id
    set	@error = @@error
    if (@error !=0)
    begin
        goto rollbackerror
    end        

    -- Delete removed spots
    delete  cinelights_data
    from    v_cinelights_data
    where exists (select  1
                    from    v_cinelights_data
                    where   cinelights_data.cinelight_campaign_no = v_cinelights_data.cinelight_campaign_no)
    and not exists (select  1
                    from    v_cinelights_data
                    where   cinelights_data.cinelight_campaign_no = v_cinelights_data.cinelight_campaign_no
                    and     cinelights_data.screening_week = v_cinelights_data.screening_week
                    and     cinelights_data.cinelight_id = v_cinelights_data.cinelight_id)
    set	@error = @@error
    if (@error !=0)
    begin
        goto rollbackerror
    end        

    -- delete removed campaigns
    delete  cinelights_data
    where exists (select  1
                  from    v_cinelights_excel_campaigns
                  where   cinelights_data.cinelight_campaign_no = v_cinelights_excel_campaigns.cinelight_campaign_no)
    and not exists (select  1
                    from    v_cinelights_excel_billings
                    where   cinelights_data.cinelight_campaign_no = v_cinelights_excel_billings.cinelight_campaign_no)
    set	@error = @@error
    if (@error !=0)
    begin
        goto rollbackerror
    end        

                   
    -- Insert new spots
    insert into cinelights_data
    select	cinelight_campaign_no,
		    cinelight_id,
		    screening_week,
		    campaign_no,
		    business_unit_id,
		    media_product_id,
		    agency_deal,
		    cinelight_ref,
		    billing_period,
		    billing_date,
		    billing_status,
		    convert(money,charge_rate),
		    convert(money,production_rate),
		    convert(money,rate),
		    campaign_name,
		    branch_code,
		    client_id,
		    agency_id,
		    rep_id
    from	v_cinelights_data
    where not exists (select  1
                      from    cinelights_data
                      where   cinelights_data.cinelight_campaign_no = v_cinelights_data.cinelight_campaign_no
                      and     screening_week = v_cinelights_data.screening_week
                      and     cinelight_id = v_cinelights_data.cinelight_id)
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
