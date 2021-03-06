/****** Object:  StoredProcedure [dbo].[p_eom_billing_inclusions]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_billing_inclusions]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_billing_inclusions]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[p_eom_billing_inclusions]	@campaign_no				int,
												@accounting_period			datetime
as

set nocount on

/*
 * Declare Variables
 */

declare		@error        					int,
			@rowcount     					int,
			@errorode						int,
			@inclusion_id					int,
			@inclusion_desc					varchar(255),
			@inclusion_qty					int,
			@inclusion_charge				money,
			@nett_charge					money,
			@tran_code						varchar(5),
			@inclusion_csr_open				tinyint,
			@tran_id						int,
			@child_tran_id              	int,
			@gst_exempt						char(1),
			@campaign_country				char(1),
			@acomm_nett						money,
			@tran_notes                 	varchar(255),
			@inclusion_acomm                numeric(6,4),
			@acomm_tran_code            	varchar(5),
			@trantype_desc					varchar(50),
			@commission						numeric(6,4),
			@account_id						int,
			@pre_gst_calc					money,
			@exempt_gst_total				money,
			@pre_gst_total					money,
			@post_gst_total					money,
			@exempt_tran_id					int,
			@pre_gst_rate					numeric(6,4),
			@post_gst_rate					numeric(6,4),
			@gst_rate						numeric(6,4),
			@gst_changeover					datetime,
			@account_country				char(1)
        
/*
 * Initialise Cursor Flags
 */

select	@inclusion_csr_open = 0,
		@child_tran_id = 0

/*
 * Begin Transaction
 */

begin transaction

select			@pre_gst_rate = country.gst_rate,
				@gst_changeover = country.changeover_date,
				@post_gst_rate = country.new_gst_rate,
				@campaign_country = country.country_code,
				@gst_exempt = fc.gst_exempt
from			film_campaign fc,
				branch,
				country
where			fc.campaign_no = @campaign_no 
and				fc.branch_code = branch.branch_code 
and				branch.country_code = country.country_code

select @error = @@error,
       @rowcount = @@rowcount

if (@error !=0 or @rowcount=0)
begin
	raiserror ('Error', 16, 1)
	return -100
end	


if @gst_exempt = 'Y'
begin
    select  @pre_gst_rate = 0.0
    select  @post_gst_rate = 0.0
end

/*
 * Declare Cursors
 */

declare 		inclusion_csr cursor static for
select			inc.inclusion_id,
				inc.inclusion_desc,
				inc.inclusion_qty,
				inc.inclusion_charge,
				tt.trantype_code,
				inc.commission,
				inc.account_no
from 			inclusion inc,
				inclusion_type_category_xref inc_xref,
				transaction_type tt
where 			inc.campaign_no = @campaign_no 
and				inc.billing_period = @accounting_period 
and				inc.invoice_client = 'Y' 
and				inc.inclusion_charge > 0 
and				inc.tran_id is null 
and				inc_xref.trantype_id = tt.trantype_id 
and				inc_xref.inclusion_type = inc.inclusion_type 
and				inc_xref.inclusion_category = inc.inclusion_category 
and				inc.inclusion_format = 'S' 
and				inc.inclusion_status <> 'P' 
and				inc.inclusion_category in ('S','M') 
order by 		inc.inclusion_id
for 			read only
	
/*
 * Loop through Inclusions
 */

open inclusion_csr
select @inclusion_csr_open = 1
fetch inclusion_csr into @inclusion_id, @inclusion_desc, @inclusion_qty, @inclusion_charge, @tran_code, @commission, @account_id
while(@@fetch_status = 0)
begin

	select			@tran_id = 0,
					@child_tran_id = 0

	/*
	 *
	 */

	if @account_id is null
		select 		@account_id = onscreen_account_id
		from		film_campaign
		where		film_campaign.campaign_no = @campaign_no
    
    select		@account_country = country_code
    from		account
    where		account_id = @account_id
    
    if @account_country <> @campaign_country
    begin
		select @gst_rate = 0
		select @inclusion_desc = ' International ' + @inclusion_desc 
	end
	else
	begin
		if(@accounting_period >= @gst_changeover)
			select @gst_rate = @post_gst_rate
		else
			select @gst_rate = @pre_gst_rate
	end
    
   /*
    * Calculate Nett Total
    */

	select @nett_charge = @inclusion_qty * @inclusion_charge
    

   /*
    * Create Transaction
    */

	exec @errorode = p_ffin_create_transaction @tran_code,
                                            @campaign_no,
											@account_id,
                                            @accounting_period,
                                            @inclusion_desc,
                                            null,
                                            @nett_charge,
                                            @gst_rate,
											'Y',
                                            @tran_id OUTPUT

	if(@errorode !=0)
	begin
		rollback transaction
		goto error
	end

    if @commission > 0
    begin
		if @tran_code = 'FANBI'
			select			@acomm_tran_code = 'FANAC'
		else if @tran_code = 'LLABI'
			select			@acomm_tran_code = 'LLAAC'
		else if @tran_code = 'TLABI'
			select			@acomm_tran_code = 'TLAAC'
		else if @tran_code = 'PLABI'
			select			@acomm_tran_code = 'PLAAC'
		else
			select			@acomm_tran_code = 'KTACM'

		select @inclusion_desc = @inclusion_desc + ' A\Comm' 
		select @nett_charge = @nett_charge * @commission * -1
	   /*
	    * Create Transaction
	    */
	
		exec @errorode = p_ffin_create_transaction @acomm_tran_code,
	                                            @campaign_no,
	                                            @account_id,
												@accounting_period,
	                                            @inclusion_desc ,
	                                            null,
	                                            @nett_charge,
	                                            @gst_rate,
												'Y',
                                                @child_tran_id OUTPUT

	   /*
	    *	Allocate Agency Commision to Billing
	    */

	    exec @errorode = p_ffin_allocate_transaction @child_tran_id, @tran_id, @nett_charge, @accounting_period
	    if(@errorode !=0)
	    begin
		    rollback transaction
		    goto error
	    end

    end
    

   /*
    * Update Inclusion
    */

	if @tran_id > 0
	begin

		update		inclusion
		set			tran_id = @tran_id
		where		inclusion_id = @inclusion_id

		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end	

	   /* 
		* Update Inclusion Xref
		*/

		insert into inclusion_tran_xref
		values (@inclusion_id, @tran_id) 

		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end	
	end

	if @child_tran_id > 0 
	begin
		insert into inclusion_tran_xref
		values (@inclusion_id, @child_tran_id) 

		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end	
	end
	/*
	 * Allocate Advanced Payments
	 */

	exec @errorode = p_ffin_payment_allocation @campaign_no
	if(@errorode !=0)
	begin
		rollback transaction
		goto error
	end

   /*
    * Fetch Next
    */

	fetch inclusion_csr into @inclusion_id, @inclusion_desc, @inclusion_qty, @inclusion_charge, @tran_code, @commission, @account_id
end

close inclusion_csr
select @inclusion_csr_open = 0

/*
 * deallocates
 */

deallocate inclusion_csr

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	 if (@inclusion_csr_open = 1)
     begin
		 close inclusion_csr
		 deallocate inclusion_csr
	 end
	 raiserror ('Error: Failed to Generate Inclusion Billings for Campaign %1!',11,1, @campaign_no)
	 return -1
GO
