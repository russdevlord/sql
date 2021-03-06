/****** Object:  StoredProcedure [dbo].[p_sfin_miscellaneous_credit]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_miscellaneous_credit]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_miscellaneous_credit]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_miscellaneous_credit] @campaign_no			char(7),
                                        @credit_nett			money,
                                        @tran_date				datetime,
                                        @credit_gst_rate		decimal(6,4),
 									    @batch_item_no		    int
as

/*
 * Declare Valiables
 */ 

declare @error							int,
        @sqlstatus					    int,
        @errorode							int,
        @misc_csr_open				    tinyint,
        @new_tran_desc				    varchar(255),
        @tran_type_code			    	char(5),
        @tran_amount					money,
        @misc_credit_id				    int,
        @misc_total					    money,
        @misc_amount					money,
        @misc_tran_id				    int,
        @misc_tran_age				    int,
        @misc_gst_rate				    numeric(6,4),
        @misc_credit					money,
        @unc_amount					    money,
        @alloc_nett					    money,
        @alloc_gross					money,
        @control_nett				    money,
        @is_closed					    char(1)



/*
 * Check Campaign Closed
 */

select @is_closed = is_closed
  from slide_campaign
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	raiserror ('Miscellaneous Credit - Error Retrieving Campaign Information.', 16, 1)
	return -1
end

if(@is_closed = 'Y')
begin
	raiserror ('Miscellaneous Credit - Campaign is Closed.', 16, 1)
	return -1
end

/*
 * Correct Sign on Nett Amount
 */

select @control_nett = @credit_nett
select @credit_nett = @credit_nett * -1
 
/*
 * Check to see how much has already been credited
 */

select @misc_total = isnull(sum(st.nett_amount),0)
  from slide_transaction st,
       transaction_type tt
 where campaign_no = @campaign_no and
       st.tran_type = tt.trantype_id and
       st.gst_rate = @credit_gst_rate and
     ( st.tran_category = 'M' or
       tt.trantype_code = 'SMCR' )

select @error = @@error
if (@error !=0)
begin
	raiserror ('Error Retrieving Transaction Information.', 16, 1)
	return -1
end

/*
 * Return if Miscellaneous Credit Request is too Large
 */

if((@misc_total + @credit_nett) < 0)
begin
	raiserror ('Miscellaneous Credit - The credit amount will result in a credit value which is larger than the original miscellaneous charges applied.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Create Miscellaneous Credit Transaction
 */

select @new_tran_desc = 'Miscellaneous Credit',
       @tran_type_code = 'SMCR',
       @tran_amount = @credit_nett

execute @errorode = p_sfin_create_transaction @tran_type_code,
                                           @campaign_no,
                                           NULL,
                                           @tran_date,
                                           @new_tran_desc,
                                           @tran_amount,
                                           @credit_gst_rate,
                                           @batch_item_no,
														 NULL,
                                           @misc_credit_id OUTPUT
                                          
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

/*
 * Initialise Variables
 */

select @misc_csr_open = 0

/*
 * Declare Cursors
 */ 
 
 declare misc_csr cursor static for
  select st.tran_id,
         st.tran_age,
         st.gst_rate,
         st.nett_amount
    from slide_transaction st
   where st.campaign_no = @campaign_no and
         st.tran_category = 'M' and
         st.gst_rate = @credit_gst_rate
--group by st.tran_id,
--         st.tran_age,   
--		 st.gst_rate
order by st.tran_age DESC,
         st.tran_id ASC
     for read only

/*
 * Miscellaneous Charge Loop
 * -------------------------
 * The system will loop through all miscellaneous charges in reverse order
 * reversing allocations and then applying the miscellaneous credits.
 *
 */

open misc_csr
select @misc_csr_open = 1
fetch misc_csr into @misc_tran_id, @misc_tran_age, @misc_gst_rate, @misc_amount
while (@@fetch_status = 0 and @control_nett > 0)
begin

	/*
    * Calculate any Miscellaneous Credits Already Applied
    */

	select @misc_credit = isnull(sum(sa.nett_amount),0)
      from slide_allocation sa,
           slide_transaction st
     where sa.to_tran_id = @misc_tran_id and
           sa.from_tran_id = st.tran_id and
           st.tran_category = 'D'

	/*
    * Calculate Unallocate Amount
    */

	select @unc_amount = @misc_amount + @misc_credit
	if(@unc_amount >  @control_nett)
		select @unc_amount = @control_nett

	select @control_nett = @control_nett - @unc_amount

	/*
	 * Reverse any Allocations to the Miscellaneous Charge
	 */
	
	select @alloc_nett = @unc_amount * -1
	select @alloc_gross = round((@alloc_nett * (1 + @credit_gst_rate)),2)

	execute @errorode = p_sfin_transaction_unallocate @misc_tran_id, 'N', @alloc_gross
	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end

	/*
     * Allocate Miscellaneous Credit
     */

	select @tran_amount = @alloc_nett
	execute @errorode = p_sfin_allocate_transaction @misc_credit_id, @misc_tran_id, @tran_amount
	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end

	/*
     * Fetch Next
     */

	fetch misc_csr into @misc_tran_id, @misc_tran_age, @misc_gst_rate, @misc_amount

end
deallocate misc_csr

/*
 * Update Slide Distribution Table
 */

execute @errorode = p_sfin_charge_distribution @campaign_no,
                                            @credit_nett
                                          
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

/*
 * Call Payment Allocations
 */

execute @errorode = p_sfin_payment_allocation @campaign_no
if (@errorode !=0)
begin
	rollback transaction
	goto error
end

/*
 * Call Balance Update
 */

execute @errorode = p_sfin_slide_campaign_balance @campaign_no
if (@errorode !=0)
begin
	rollback transaction
	goto error
end

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	if (@misc_csr_open = 1)
   begin
		close misc_csr
		deallocate misc_csr
	end

	return -1
GO
