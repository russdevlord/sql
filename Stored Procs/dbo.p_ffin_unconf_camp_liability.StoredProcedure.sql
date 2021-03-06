/****** Object:  StoredProcedure [dbo].[p_ffin_unconf_camp_liability]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_unconf_camp_liability]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_unconf_camp_liability]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_ffin_unconf_camp_liability]  @campaign_no int
as

/* 
 *
 * SP checks if campaign carries any liabilty from 'source' campaigns (MakeUp,MakeGood spots)
 * or passed on any liability to 'destination' campaigns
 *
 * Transfers Makeup/MakeGood spot liabilties back to source campaigns if possible
 * otherwise campaign can not be unconfirm
 *
 */
 
declare @error                  int,
        @cnt                    int,
        @spot_id                int,
        @source_spot_id         int,
        @source_campaign_no     int,
        @source_liability       tinyint,
        @dest_liability         tinyint,
        @spot_type              char(1),
        @source_complex_id      int,
        @spot_liability_id      int 


/*
 *   Check whether campaign carries any liability at all   
 */ 
            
 select @cnt = count(spot_id) 
   from campaign_spot
  where campaign_no = @campaign_no
    and (spot_type in ('D', 'M', 'V')
     or spot_redirect is not Null 
     or spot_id in (select spot_id 
                      from delete_charge_spots
                     where campaign_no = @campaign_no ))       
        
if @@error != 0
begin
    raiserror ('p_ffin_unconf_camp_liability: Determining if campaign has released liability.', 16, 1)
    return -1
end 

 select @cnt = isnull(@cnt,0) + count(spot_id) 
   from cinelight_spot
  where campaign_no = @campaign_no
    and (spot_type in ('D', 'M', 'V')
     or spot_id in (select spot_id 
                      from delete_charge_cinelight_spots
                     where campaign_no = @campaign_no ))       
        
if @@error != 0
begin
    raiserror ('p_ffin_unconf_camp_liability: Determining if campaign has released liability.', 16, 1)
    return -1
end 

if @cnt = 0
    return 0

/*
 * check that the SOURCE campaigns for MAKEGOOD spots ware not closed 
 */

 select @cnt = count(film_campaign.campaign_no) 
   from delete_charge,
        film_campaign
  where delete_charge.destination_campaign = @campaign_no 
    and delete_charge.source_campaign = film_campaign.campaign_no
    and film_campaign.campaign_status = 'X'
                                 
if @@error != 0
begin
    raiserror ('p_ffin_unconf_camp_liability: Determining if campaign is linked to any closed campaigns', 16, 1)
    return -1
end 

if @cnt > 0 
begin
    raiserror ('p_ffin_unconf_camp_liability:Campaign cannot be unconfirmed.  It contains MakeGood spots for closed campaigns.', 16, 1)
    return -1
end

/*
 * Check that Destination Spot Liabilities(MAKEGOODs) have NOT been released 
 */

 select @cnt = count(delete_charge_spots.spot_id) 
   from delete_charge_spots,
        delete_charge,
        spot_liability
  where delete_charge_spots.delete_charge_id = delete_charge.delete_charge_id 
    and delete_charge_spots.source_dest = 'S' 
    and delete_charge.destination_campaign = @campaign_no 
    and spot_liability.spot_id = delete_charge_spots.spot_id
    and spot_liability.release_period is not null

if @@error != 0
begin
    raiserror ('p_ffin_unconf_camp_liability: Determining if Campaign has any released liabilty.', 16, 1)
    return -1
end

 select @cnt = isnull(@cnt,0) + count(delete_charge_cinelight_spots.spot_id) 
   from delete_charge_cinelight_spots,
        delete_charge,
        cinelight_spot_liability
  where delete_charge_cinelight_spots.delete_charge_id = delete_charge.delete_charge_id 
    and delete_charge_cinelight_spots.source_dest = 'S' 
    and delete_charge.destination_campaign = @campaign_no 
    and cinelight_spot_liability.spot_id = delete_charge_cinelight_spots.spot_id
    and cinelight_spot_liability.release_period is not null

if @@error != 0
begin
    raiserror ('p_ffin_unconf_camp_liability: Determining if Campaign has any released liabilty.', 16, 1)
    return -1
end

if @cnt > 0 
begin
    raiserror ('p_ffin_unconf_camp_liability:Campaign cannot be unconfirmed. It is the destination campiagns source for D & C spots that have already been released.', 16, 1)
    return -1
end
      
/*
 * Begin transaction
 */
 
begin transaction

/*
 *   Delete(MakeUp)/Cancel(MakeGood) Spot Liabilty Records for Destination Spots
 */

update spot_liability
  set cancelled = 0
where cancelled = 1
  and spot_id in (select spot_id 
                   from  delete_charge_spots,
                         delete_charge
                   where delete_charge_spots.delete_charge_id = delete_charge.delete_charge_id and
                         delete_charge_spots.source_dest = 'S' and
                         delete_charge.destination_campaign = @campaign_no )
if @@error != 0
begin
    raiserror ('Error: Uncancelling Spot Liability on Source Campaigns.', 16, 1)
    goto ERROR
end

delete spot_liability
where cancelled = 0 
  and spot_id in (select spot_id 
                   from  delete_charge_spots,
                         delete_charge
                   where delete_charge_spots.delete_charge_id = delete_charge.delete_charge_id and
                         delete_charge_spots.source_dest = 'D' and
                         delete_charge.destination_campaign = @campaign_no )
if @@error != 0
begin
    raiserror ('p_ffin_unconf_camp_liability: Deleting Transfered liablility.', 16, 1)
    goto ERROR
end

update cinelight_spot_liability
  set cancelled = 0
where cancelled = 1
  and spot_id in (select spot_id 
                   from  delete_charge_cinelight_spots,
                         delete_charge
                   where delete_charge_cinelight_spots.delete_charge_id = delete_charge.delete_charge_id and
                         delete_charge_cinelight_spots.source_dest = 'S' and
                         delete_charge.destination_campaign = @campaign_no )
if @@error != 0
begin
    raiserror ('Error: Uncancelling Spot Liability on Source Campaigns.', 16, 1)
    goto ERROR
end

delete cinelight_spot_liability
where cancelled = 0 
  and spot_id in (select spot_id 
                   from  delete_charge_cinelight_spots,
                         delete_charge
                   where delete_charge_cinelight_spots.delete_charge_id = delete_charge.delete_charge_id and
                         delete_charge_cinelight_spots.source_dest = 'D' and
                         delete_charge.destination_campaign = @campaign_no )
if @@error != 0
begin
    raiserror ('p_ffin_unconf_camp_liability: Deleting Transfered liablility.', 16, 1)
    goto ERROR
end


commit transaction
if (@@error != 0)
begin
    raiserror ('p_ffin_unconf_camp_liability. DB error <commit>', 16, 1)
    goto ERROR
end
return 0

ERROR:
    rollback transaction
    return -1
GO
