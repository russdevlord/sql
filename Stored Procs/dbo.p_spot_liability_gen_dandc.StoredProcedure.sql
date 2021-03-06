/****** Object:  StoredProcedure [dbo].[p_spot_liability_gen_dandc]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_spot_liability_gen_dandc]
GO
/****** Object:  StoredProcedure [dbo].[p_spot_liability_gen_dandc]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_spot_liability_gen_dandc] @session_id			int,
                                       @campaign_no         int
as

/*
 * Declare Variables
 */

declare @error        						int,
        @rowcount     						int,
        @errorode								int,
        @tran_id						    int,
        @tran_amount						money,
        @billings_check						money,
        @cutoff_period                      datetime
        
/*
 * Begin Transaction
 */

begin transaction
   
/*
 * Loop Transactions (Source Campaigns)
 */

 declare tran_csr cursor static for
  select sl.tran_id,
         sum(sl.charge_rate)
    from work_spot_list sl
group by sl.tran_id
order by sl.tran_id
     for read only

open tran_csr
fetch tran_csr into @tran_id, @tran_amount
while(@@fetch_status = 0)
begin



    /*
     * Insert Liability into Work Spot Allocation Table
     */
    
	insert into work_spot_allocation (
				session_id,
				source_campaign,
				destination_campaign,
				allocation_amount,
				liability_type,
				alloc_primary)
	select 		@session_id,
				@tran_id,
				@campaign_no,
				sum(sl.spot_amount),
				sl.liability_type,
				@campaign_no
	from 		spot_liability sl,
				delete_charge dc,
				delete_charge_spots dcs
	where 		dc.destination_campaign = @campaign_no and
				dc.source_campaign = @tran_id and
				dc.delete_charge_id = dcs.delete_charge_id and
				dcs.spot_id = sl.spot_id and
				dcs.source_dest = 'S'
	group by 	sl.liability_type
	union    
	select 		@session_id,
				@tran_id,
				@campaign_no,
				sum(sl.spot_amount),
				sl.liability_type,
				@campaign_no
	from 		cinelight_spot_liability sl,
				delete_charge dc,
				delete_charge_cinelight_spots dcs
	where 		dc.destination_campaign = @campaign_no and
				dc.source_campaign = @tran_id and
				dc.delete_charge_id = dcs.delete_charge_id and
				dcs.spot_id = sl.spot_id and
				dcs.source_dest = 'S'
	group by 	sl.liability_type

	if (@@error !=0)
	begin
        raiserror ('Error: Failed to Insert Source D&C Liability into Work Table', 16, 1)
		rollback transaction
		goto error
	end	

    /*
     * Reconcile Destination Spot Liability with Source Destination Spot Liability - Alteration allow for released billings before cutover period
     */

    select @billings_check = 0
    
    select @billings_check = isnull(sum(allocation_amount),0)
      from work_spot_allocation wsa,
           liability_type ltyp
     where wsa.session_id = @session_id and
           wsa.source_campaign = @tran_id and
           wsa.destination_campaign = @campaign_no and
           wsa.liability_type = ltyp.liability_type_id and
           ltyp.liability_category_id = 1 --Billings

    select @billings_check = isnull(@billings_check,0)
    
/*    if(@billings_check <> @tran_amount)
    begin
        --raiserror ('Error: Reconciliation of Source Campaign Liability Failed to Balance - Src Spots: %1! Src Liability: %2!', 16, 1, @tran_amount, @billings_check)
        raiserror ('Error: Reconciliation of Source Campaign Liability Failed to Balance', 16, 1)
        rollback transaction
		goto error
    end
    */
    /*
     * Delete Billing Liability
     */
    
    delete work_spot_allocation
      from liability_type ltyp
     where session_id = @session_id and
           source_campaign = @tran_id and
           destination_campaign = @campaign_no and
           liability_type = ltyp.liability_type_id and
           ltyp.liability_category_id = 1 --Billings

	select @error = @@error
	if (@error !=0)
	begin
--        raiserror ('Error: Failed to Delete Source D&C Liability from Work Table - Src: Campaign %1! Dest: %2!', 16, 1, @tran_id, @campaign_no)
        raiserror ('Error: Failed to Delete Source D&C Liability from Work Table', 16, 1)
		rollback transaction
		goto error
	end	
    
    /*
     * Fetch Next
     */
     
    fetch tran_csr into @tran_id, @tran_amount

end
close tran_csr

/*
 * Call Liability generation
 */

execute @errorode = p_eom_spot_allocate_dclibility @session_id
if(@errorode !=0)
begin
    raiserror ('Error: Allocating the D&C Liability.', 16, 1)
	rollback transaction
	goto error
end

/*
 * Remove Rows from Work Table
 */

--delete work_spot_allocation
-- where session_id = @session_id

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:
    return -100
GO
