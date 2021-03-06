/****** Object:  StoredProcedure [dbo].[p_eom_dandc_work_allocation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_dandc_work_allocation]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_dandc_work_allocation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * p_eom_dandc_work_allocation
 *
 * This procedure loops over all records in the work_spot_allocation table and allocates them
 * across all relevant spot liabilities that are liked via the delete and charge relationship.
 */
 

CREATE proc [dbo].[p_eom_dandc_work_allocation]  @source_campaign                int,
                                        @destination_campaign           int,
                                        @allocation_amount              numeric(18,4),
                                        @liability_type                 int,
                                        @allocation_id                  int

as

declare @error                          int,
        @errorode                          int,
        @count                          int,
        @next_destination               int,
        @record_exists                  int,
        @destination_amount             numeric(18,6),
        @total_amount                   numeric(18,6),
        @next_allocation_amount         numeric(18,6),
        @ratio                          numeric(24,23)
 
 declare source_csr cursor static for
  select destination_campaign
    from delete_charge dc
   where dc.source_campaign = @destination_campaign
     and confirmed = 'Y'
     
/*
 * 1st Cursor run - find all subsequent links and add those campaigns to the work table
 */
 
open source_csr
fetch source_csr into @next_destination
while(@@fetch_status=0)
begin

        select @destination_amount = isnull(sum(makegood_rate),0)
          from campaign_spot cs,
               delete_charge dc,
               delete_charge_spots dcs,
               delete_charge prev_dc,
               delete_charge_spots prev_dcs
         where dcs.spot_id = cs.spot_id
           and dcs.delete_charge_id = dc.delete_charge_id 
           and dcs.source_dest = 'S'
           and dc.confirmed = 'Y'
           and cs.spot_type = 'D'
           and dc.source_campaign = @destination_campaign
           and dc.destination_campaign = @next_destination
           and prev_dcs.spot_id = cs.spot_id
           and prev_dcs.delete_charge_id = prev_dc.delete_charge_id
           and prev_dcs.source_dest = 'D'
           and prev_dc.destination_campaign = @destination_campaign
           and prev_dc.source_campaign = @source_campaign
           and prev_dc.confirmed = 'Y'

    
        select @destination_amount = @destination_amount + isnull(sum(charge_rate),0)
          from campaign_spot cs,
               delete_charge dc,
               delete_charge_spots dcs,
               delete_charge prev_dc,
               delete_charge_spots prev_dcs
         where dcs.spot_id = cs.spot_id
           and dcs.delete_charge_id = dc.delete_charge_id 
           and dcs.source_dest = 'S'
           and dc.confirmed = 'Y'
           and cs.spot_type <> 'D'
           and dc.source_campaign = @destination_campaign
           and dc.destination_campaign = @next_destination
           and prev_dcs.spot_id = cs.spot_id
           and prev_dcs.delete_charge_id = prev_dc.delete_charge_id
           and prev_dcs.source_dest = 'D'
           and prev_dc.destination_campaign = @destination_campaign
           and prev_dc.source_campaign = @source_campaign
           and prev_dc.confirmed = 'Y'
           
        select @total_amount = isnull(sum(makegood_rate),0)
          from campaign_spot cs,
               delete_charge dc,
               delete_charge_spots dcs
         where dcs.spot_id = cs.spot_id
           and dcs.delete_charge_id = dc.delete_charge_id 
           and dcs.source_dest = 'D'
           and dc.confirmed = 'Y'
           and cs.spot_type = 'D'
           and dc.source_campaign = @source_campaign
           and dc.destination_campaign = @destination_campaign

    
        select @total_amount = @total_amount + isnull(sum(charge_rate),0)
          from campaign_spot cs,
               delete_charge dc,
               delete_charge_spots dcs
         where dcs.spot_id = cs.spot_id
           and dcs.delete_charge_id = dc.delete_charge_id 
           and dcs.source_dest = 'D'
           and dc.confirmed = 'Y'
           and cs.spot_type <> 'D'
           and dc.source_campaign = @source_campaign
           and dc.destination_campaign = @destination_campaign

        select @destination_amount = @destination_amount + isnull(sum(makegood_rate),0)
          from cinelight_spot cs,
               delete_charge dc,
               delete_charge_cinelight_spots dcs,
               delete_charge prev_dc,
               delete_charge_cinelight_spots prev_dcs
         where dcs.spot_id = cs.spot_id
           and dcs.delete_charge_id = dc.delete_charge_id 
           and dcs.source_dest = 'S'
           and dc.confirmed = 'Y'
           and cs.spot_type = 'D'
           and dc.source_campaign = @destination_campaign
           and dc.destination_campaign = @next_destination
           and prev_dcs.spot_id = cs.spot_id
           and prev_dcs.delete_charge_id = prev_dc.delete_charge_id
           and prev_dcs.source_dest = 'D'
           and prev_dc.destination_campaign = @destination_campaign
           and prev_dc.source_campaign = @source_campaign
           and prev_dc.confirmed = 'Y'

    
        select @destination_amount = @destination_amount + isnull(sum(charge_rate),0)
          from cinelight_spot cs,
               delete_charge dc,
               delete_charge_cinelight_spots dcs,
               delete_charge prev_dc,
               delete_charge_cinelight_spots prev_dcs
         where dcs.spot_id = cs.spot_id
           and dcs.delete_charge_id = dc.delete_charge_id 
           and dcs.source_dest = 'S'
           and dc.confirmed = 'Y'
           and cs.spot_type <> 'D'
           and dc.source_campaign = @destination_campaign
           and dc.destination_campaign = @next_destination
           and prev_dcs.spot_id = cs.spot_id
           and prev_dcs.delete_charge_id = prev_dc.delete_charge_id
           and prev_dcs.source_dest = 'D'
           and prev_dc.destination_campaign = @destination_campaign
           and prev_dc.source_campaign = @source_campaign
           and prev_dc.confirmed = 'Y'
           
        select @total_amount = @total_amount + isnull(sum(makegood_rate),0)
          from cinelight_spot cs,
               delete_charge dc,
               delete_charge_cinelight_spots dcs
         where dcs.spot_id = cs.spot_id
           and dcs.delete_charge_id = dc.delete_charge_id 
           and dcs.source_dest = 'D'
           and dc.confirmed = 'Y'
           and cs.spot_type = 'D'
           and dc.source_campaign = @source_campaign
           and dc.destination_campaign = @destination_campaign

    
        select @total_amount = @total_amount + isnull(sum(charge_rate),0)
          from cinelight_spot cs,
               delete_charge dc,
               delete_charge_cinelight_spots dcs
         where dcs.spot_id = cs.spot_id
           and dcs.delete_charge_id = dc.delete_charge_id 
           and dcs.source_dest = 'D'
           and dc.confirmed = 'Y'
           and cs.spot_type <> 'D'
           and dc.source_campaign = @source_campaign
           and dc.destination_campaign = @destination_campaign

    
        if @total_amount = 0
            select @next_allocation_amount = 0
        else
        begin
            select @ratio = convert(numeric(24,23), (@destination_amount / @total_amount))
            select @next_allocation_amount = convert(money, @ratio * convert(numeric(24,12), @allocation_amount))
        end
           
        if @next_allocation_amount > 0
        begin           
               
            select @record_exists = count(destination_campaign)
              from work_spot_allocation
             where destination_campaign = @next_destination
               and source_campaign = @destination_campaign
               and allocation_id = @allocation_id
               and liability_type = @liability_type
                   
            if @record_exists = 0
            begin
    
                insert into work_spot_allocation
                    (source_campaign,
                    destination_campaign,
                    allocation_amount,
                    liability_type,
                    allocation_id) values
                    (@destination_campaign,
                    @next_destination,
                    @next_allocation_amount,
                    @liability_type,
                    @allocation_id)
            
            end
        end
        
        exec @errorode = p_eom_dandc_work_allocation @destination_campaign, @next_destination, @allocation_amount, @liability_type, @allocation_id
    
    if @errorode != 0
    begin
        raiserror ('Error determining D & C relationships for spot liabiliity allocation.', 16, 1)
        return -100
    end 

    fetch source_csr into @next_destination
end

close source_csr
deallocate source_csr
 
return 0
GO
