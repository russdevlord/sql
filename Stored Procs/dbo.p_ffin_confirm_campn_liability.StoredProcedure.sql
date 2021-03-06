/****** Object:  StoredProcedure [dbo].[p_ffin_confirm_campn_liability]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_confirm_campn_liability]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_confirm_campn_liability]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_ffin_confirm_campn_liability]  @campaign_no int 

as

/*
 *  Checks if all liabilty were carring over correctly
 */
 
declare @error                	int,
        @cnt                  	int,
        @source_amount        	money,
        @tmp_amount           	money,
        @dest_amount          	money,
        @ret                  	int,
        @cutoff_period        	datetime,
        @rowcount             	int,
		@err_msg	      		varchar(300)	

/*
 * Get Cinema Agreement Cut Over Period
 */


select @cutoff_period = convert(datetime, parameter_string) 
  from system_parameters 
 where parameter_name = 'cinema_agreement_cut'

select @error = @@error,
       @rowcount = @@rowcount
       
if @error != 0 or @rowcount != 1 
begin
    rollback transaction
    raiserror ('p_ffin_confirm_campn_liability:Campaign cannot be confirmed.There was an error obtaining Cinema Agreement Cut Over Period.', 16, 1)
    return -100
end

/*
 *   Check whether campaign carries any liability for other campaigns at all   
 */            
 
 select @cnt = count(spot_id) 
   from campaign_spot
  where campaign_no = @campaign_no
    and spot_id in (select spot_id 
                      from delete_charge_spots
                     where campaign_no = @campaign_no)
     
if @@error != 0
    goto ERROR
    
 select @cnt = isnull(@cnt,0) + count(spot_id) 
   from cinelight_spot
  where campaign_no = @campaign_no
    and spot_id in (select spot_id 
                      from delete_charge_cinelight_spots
                     where campaign_no = @campaign_no)
     
if @@error != 0
    goto ERROR

if @cnt = 0
    return 0

/*
 * All source D&C spots should be billed                                                                     
 */

 select @cnt = count(cs.spot_id)
   from delete_charge_spots dcs,
        delete_charge dc,
        campaign_spot cs
  where dcs.delete_charge_id = dc.delete_charge_id 
    and dcs.source_dest = 'S'
    and dc.destination_campaign = @campaign_no 
    and cs.campaign_no = dc.destination_campaign
    and dcs.spot_id = cs.spot_id 
    and cs.tran_id is null
    
if @@error != 0
        goto ERROR

 select @cnt = isnull(@cnt, 0) + count(cs.spot_id)
   from delete_charge_cinelight_spots dcs,
        delete_charge dc,
        cinelight_spot cs
  where dcs.delete_charge_id = dc.delete_charge_id 
    and dcs.source_dest = 'S'
    and dc.destination_campaign = @campaign_no 
    and cs.campaign_no = dc.destination_campaign
    and dcs.spot_id = cs.spot_id 
    and cs.tran_id is null
    
if @@error != 0
        goto ERROR

if @cnt > 0
begin
    raiserror ('p_ffin_confirm_campn_liability:Campaign cannot be confirmed.It contains Makegood spots for not billed spots', 16, 1)
    goto ERROR
end

/*
 * Check that MakeGood Rates for all Destination Spots add up to the Charge/MakeGood Rates of the source spots 
 */

 select @source_amount = round(isnull(sum(avg_rate),0),2)
   from campaign_spot,
        delete_charge_spots,
        delete_charge,
		statrev_spot_rates
  where spot_type <> 'D'
    and campaign_spot.spot_id = delete_charge_spots.spot_id
    and delete_charge_spots.delete_charge_id = delete_charge.delete_charge_id 
    and source_dest = 'S'
    and destination_campaign = @campaign_no 
    and	statrev_spot_rates.spot_id = campaign_spot.spot_id    
	and	statrev_spot_rates.revenue_group <= 3

if @@error != 0
    goto ERROR

 select @source_amount = isnull(@source_amount, 0) + round( isnull(sum(avg_rate),0),2)
   from cinelight_spot,
        delete_charge_cinelight_spots,
        delete_charge,
		statrev_spot_rates
  where spot_type <> 'D'
    and cinelight_spot.spot_id = delete_charge_cinelight_spots.spot_id
    and delete_charge_cinelight_spots.delete_charge_id = delete_charge.delete_charge_id 
    and source_dest = 'S'
    and destination_campaign = @campaign_no     
    and	statrev_spot_rates.spot_id = cinelight_spot.spot_id    
	and	statrev_spot_rates.revenue_group = 4

if @@error != 0
    goto ERROR




 select @dest_amount = round(isnull(sum(makegood_rate),0),2)
   from campaign_spot,
        delete_charge_spots,
        delete_charge
  where delete_charge_spots.delete_charge_id =  delete_charge.delete_charge_id 
    and delete_charge_spots.spot_id = campaign_spot.spot_id
    and source_dest = 'D'
    and destination_campaign = @campaign_no
    
if @@error != 0
    goto ERROR

 select @dest_amount = isnull(@dest_amount,0) + round(isnull(sum(makegood_rate),0),2)
   from cinelight_spot,
        delete_charge_cinelight_spots,
        delete_charge
  where delete_charge_cinelight_spots.delete_charge_id =  delete_charge.delete_charge_id 
    and delete_charge_cinelight_spots.spot_id = cinelight_spot.spot_id
    and source_dest = 'D'
    and destination_campaign = @campaign_no
    
if @@error != 0
    goto ERROR

if @source_amount != @dest_amount
begin
    raiserror ('p_ffin_confirm_campn_liability:Campaign cannot be confirmed.  Source Amount <> Destination Amount', 16, 1)
    goto ERROR
end


/*
 * Check that None of the Source Campaign Spot Liabilities have been Released - Update - Allow billings before cutover date to be released
 */
       
 select @cnt = count(sl.spot_id)
   from spot_liability sl,
        delete_charge dc,
        delete_charge_spots dcs,
        liability_type lt
  where sl.release_period is not null
    and dc.delete_charge_id = dcs.delete_charge_id
    and dcs.source_dest = 'S'
    and dc.destination_campaign = @campaign_no
    and dcs.spot_id = sl.spot_id
    and sl.liability_type = lt.liability_type_id
    and lt.liability_category_id = 6 -- Collection

if @@error != 0
    goto ERROR

 select @cnt = isnull(@cnt,0) + count(sl.spot_id)
   from spot_liability sl,
        delete_charge dc,
        delete_charge_spots dcs,
        campaign_spot cs,
        liability_type lt
  where sl.release_period is not null
    and dc.delete_charge_id = dcs.delete_charge_id
    and dcs.source_dest = 'S'
    and cs.spot_id = sl.spot_id
    and cs.billing_period >= @cutoff_period
    and dc.destination_campaign = @campaign_no
    and dcs.spot_id = sl.spot_id
    and sl.liability_type = lt.liability_type_id
    and lt.liability_category_id <> 6 -- Collection

if @@error != 0
    goto ERROR

 select @cnt = isnull(@cnt,0) + count(sl.spot_id)
   from cinelight_spot_liability sl,
        delete_charge dc,
        delete_charge_cinelight_spots dcs,
        liability_type lt
  where sl.release_period is not null
    and dc.delete_charge_id = dcs.delete_charge_id
    and dcs.source_dest = 'S'
    and dc.destination_campaign = @campaign_no
    and dcs.spot_id = sl.spot_id
    and sl.liability_type = lt.liability_type_id
    and lt.liability_category_id = 6 -- Collection

if @@error != 0
    goto ERROR

 select @cnt = isnull(@cnt,0) + count(sl.spot_id)
   from cinelight_spot_liability sl,
        delete_charge dc,
        delete_charge_cinelight_spots dcs,
        cinelight_spot cs,
        liability_type lt
  where sl.release_period is not null
    and dc.delete_charge_id = dcs.delete_charge_id
    and dcs.source_dest = 'S'
    and cs.spot_id = sl.spot_id
    and cs.billing_period >= @cutoff_period
    and dc.destination_campaign = @campaign_no
    and dcs.spot_id = sl.spot_id
    and sl.liability_type = lt.liability_type_id
    and lt.liability_category_id <> 6 -- Collection

if @@error != 0
    goto ERROR

if @cnt > 0
begin
    raiserror ('p_ffin_confirm_campn_liability: Campaign cannot be confirmed.  It contains destination spots for RELEASED source spots', 16, 1)
    goto ERROR
end

/*
 *   Flag all Liabilty for the Source Campaign Spots as Cancelled
 */
 
begin transaction

update spot_liability
   set spot_liability.cancelled = 1
  from delete_charge_spots,
       delete_charge
 where spot_liability.cancelled = 0
   and spot_liability.spot_id = delete_charge_spots.spot_id
   and delete_charge_spots.delete_charge_id =  delete_charge.delete_charge_id 
   and source_dest = 'S'
   and destination_campaign = @campaign_no       

if @@error != 0
begin
    rollback transaction
    goto ERROR
end

update cinelight_spot_liability
   set cinelight_spot_liability.cancelled = 1
  from delete_charge_cinelight_spots,
       delete_charge
 where cinelight_spot_liability.cancelled = 0
   and cinelight_spot_liability.spot_id = delete_charge_cinelight_spots.spot_id
   and delete_charge_cinelight_spots.delete_charge_id =  delete_charge.delete_charge_id 
   and source_dest = 'S'
   and destination_campaign = @campaign_no       

if @@error != 0
begin
    rollback transaction
    goto ERROR
end

/*
 * set 'CONFIRM' flag to 'Y' for source D&C
 */

 update delete_charge
    set confirmed = 'Y' 
  where destination_campaign = @campaign_no

if @@error != 0
begin
    rollback transaction
    goto ERROR
end
     
/*
 *   Create New Spot Liabilities and Makegood Credit - Update the Cinema Rate on the Destination Spots
 */

EXECUTE @ret = p_spot_liability_generation @campaign_no, 5, Null, 1

if @ret != 0 
begin
    rollback transaction
    goto ERROR
end

commit transaction
return 0

ERROR:
    raiserror ('p_ffin_confirm_campn_liability: Failed to Move Campaign Liability.  Campaign Not Confirmed.', 16, 1)
    return -1
GO
