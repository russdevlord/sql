/****** Object:  StoredProcedure [dbo].[p_sfin_billing_run_inclusions]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_billing_run_inclusions]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_billing_run_inclusions]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sfin_billing_run_inclusions] @campaign_no				char(7),
                                    		@sales_period				datetime
as

/*
 * Declare Variables
 */

declare @error        				integer,
        @rowcount     				integer,
        @errorode							integer,	
        @track_id						integer,
        @track_desc					varchar(255),
        @track_qty					integer,
        @track_charge				money,
        @nett_charge					money,
        @tran_date					datetime,
        @tran_code					varchar(5),
        @track_csr_open				tinyint,
        @tran_id						integer,
		  @negative_track_id			integer

/*
 * Initialise Cursor Flags
 */

select @track_csr_open = 0

/*
 * Begin Transaction
 */

begin transaction

/*
 * Declare Cursors
 */

 declare track_csr cursor static for
  select st.slide_track_id,
         st.track_desc,
         st.track_qty,
         st.track_charge,
         st.tran_date,
         tt.trantype_code
    from slide_track st,
         transaction_type tt
   where st.campaign_no = @campaign_no and
         st.billing_period = @sales_period and
         st.invoice_client = 'Y' and
         st.track_charge > 0 and
         st.tran_id is null and
         st.tran_type = tt.trantype_id
order by st.slide_track_id,
         st.tran_date
     for read only
	

/*
 * Loop through Inclusions
 */

open track_csr
select @track_csr_open = 1
fetch track_csr into @track_id, @track_desc, @track_qty, @track_charge, @tran_date, @tran_code
while(@@fetch_status = 0)
begin

	/*
    * Calculate Nett Total
    */

	select @nett_charge = @track_qty * @track_charge

	/*
    * Reverse Track Id to pass into create tran so that it picks up the creation of a inclusion.
    */

	select @negative_track_id = @track_id * -1

	/*
    * Create Transaction
    */

	exec @errorode = p_sfin_create_transaction @tran_code,
                                           @campaign_no,
														 @negative_track_id,
                                           @tran_date,
                                           @track_desc,
                                           @nett_charge,
                                           null,
                                           null,
                                           null,
                                           @tran_id OUTPUT

	if(@errorode !=0)
	begin
		rollback transaction
		goto error
	end

	/*
    * Update Inclusion
    */

	update slide_track
      set tran_id = @tran_id
    where slide_track_id = @track_id

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end	

	/*
	 * Allocate Advanced Payments
	 */

	exec @errorode = p_sfin_payment_allocation @campaign_no, @tran_id
	if(@errorode !=0)
	begin
		rollback transaction
		goto error
	end

	/*
    * Fetch Next
    */

	fetch track_csr into @track_id, @track_desc, @track_qty, @track_charge, @tran_date, @tran_code

end

close track_csr
select @track_csr_open = 0

/*
 * Deallocate Cursors
 */

deallocate track_csr

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	 if (@track_csr_open = 1)
    begin
		 close track_csr
		 deallocate track_csr
	 end
	 return -1
GO
