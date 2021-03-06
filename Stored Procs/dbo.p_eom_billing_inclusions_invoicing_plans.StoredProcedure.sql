/****** Object:  StoredProcedure [dbo].[p_eom_billing_inclusions_invoicing_plans]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_billing_inclusions_invoicing_plans]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_billing_inclusions_invoicing_plans]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[p_eom_billing_inclusions_invoicing_plans] @campaign_no			int,
																																	@accounting_period		datetime
as

set nocount on

/*
 * Declare Variables
 */

declare @error        								int,
				@rowcount     							int,
				@errorode									int,
				@inclusion_id						int,
				@inclusion_desc					varchar(255),
				@tran_desc					varchar(255),
				@inclusion_qty						int,
				@inclusion_charge				money,
				@inclusion_credit				money,
				@nett_charge						money,
				@tran_code							varchar(5),
				@inclusion_csr_open			tinyint,
				@tran_id									int,
				@child_tran_id              			int,
								@tran_credit_id									int,
				@child_credit_tran_id              			int,
				@gst_exempt							char(1),
				@campaign_country			char(1),
				@acomm_nett						money,
				@acomm_credit						money,
				@tran_notes                 			varchar(255),
				@inclusion_acomm            numeric(6,4),
				@acomm_tran_code          	varchar(5),
				@trantype_desc              	varchar(50),
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
				@gst_changeover					datetime
        
/*
 * Initialise Cursor Flags
 */

select @inclusion_csr_open = 0

select	@rowcount = count(*)
from	film_campaign_standalone_invoice
where	campaign_no = @campaign_no

select @error = @@error

if (@error !=0 )
begin
		 raiserror ('Error: Failed to Generate Inclusion Invoicing Plans for Campaign %1!',11,1, @campaign_no)
	return -100
end	

if @rowcount >  0
begin

	/*
	 * Begin Transaction
	 */

	begin transaction

	select @pre_gst_rate = country.gst_rate,
		   @gst_changeover = country.changeover_date,
		   @post_gst_rate = country.new_gst_rate,
		   @campaign_country = country.country_code,
		   @gst_exempt = fc.gst_exempt
	  from film_campaign fc,
		   branch,
		   country
	 where fc.campaign_no = @campaign_no and
		   fc.branch_code = branch.branch_code and
		   branch.country_code = country.country_code

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

	if(@accounting_period >= @gst_changeover)
		select @gst_rate = @post_gst_rate
	else
		select @gst_rate = @pre_gst_rate


	/*
	 * Declare Cursors
	 */

	declare 	inclusion_csr cursor static for
	select 		inc.inclusion_id,
						inc.inclusion_desc,
						inc.inclusion_qty,
						sum(spot.charge_rate),
						tt.trantype_code,
						inc.commission,
						inc.account_no
	from 			inclusion inc,
						inclusion_spot spot,
						inclusion_type_category_xref inc_xref,
						transaction_type tt
	where 		inc.campaign_no = @campaign_no
	and				spot.inclusion_id = inc.inclusion_id
	and				spot.campAign_no = inc.campaign_no
	and				spot.billing_period = @accounting_period 
	and				inc.invoice_client = 'Y' 
	and				spot.charge_rate > 0 
	and				spot.tran_id is null 
	and				inc_xref.trantype_id = tt.trantype_id 
	and				inc_xref.inclusion_type = inc.inclusion_type 
	and				inc_xref.inclusion_category = inc.inclusion_category 
	and				inc.inclusion_format = 'I' 
	and				inc.inclusion_status <> 'P' 
	and				inc.inclusion_category in ('G')
	group by	inc.inclusion_id,
						inc.inclusion_desc,
						inc.inclusion_qty,
						tt.trantype_code,
						inc.commission,
						inc.account_no
	order by 	inc.inclusion_id
	for 		read only
		
	/*
	 * Loop through Inclusions
	 */

	open inclusion_csr
	select @inclusion_csr_open = 1
	fetch inclusion_csr into @inclusion_id, @inclusion_desc, @inclusion_qty, @inclusion_charge, @tran_code, @commission, @account_id
	while(@@fetch_status = 0)
	begin

		/*
		 * Get account if isnt different from the campaign
		 */

		if @account_id is null
			select 	@account_id = onscreen_account_id
			from	film_campaign
			where	film_campaign.campaign_no = @campaign_no
	    
	   /*
		* Create Transaction
		*/

		select @acomm_nett = 0
		exec @errorode = p_ffin_create_transaction	@tran_code,
												@campaign_no,
												@account_id,
												@accounting_period,
												@inclusion_desc,
												null,
												@inclusion_charge,
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

			select @tran_desc = @inclusion_desc + ' A\Comm' 
			select @acomm_nett = @inclusion_charge * @commission * -1
			
		   /*
			* Create Transaction
			*/
		
			exec @errorode = p_ffin_create_transaction	'GACOM',
													@campaign_no,
													@account_id,
													@accounting_period,
													@tran_desc ,
													null,
													@acomm_nett,
													@gst_rate,
													'Y',
													@child_tran_id OUTPUT


		   /*
			*	Allocate Agency Commision to Billing
			*/

			exec @errorode = p_ffin_allocate_transaction @child_tran_id, @tran_id, @acomm_nett, @accounting_period
			if(@errorode !=0)
			begin
				rollback transaction
				goto error
			end
			
			/*
			 * Insert into inclusion spot xref
			 */

			insert into inclusion_spot_xref select spot_id, @child_tran_id from inclusion_spot where inclusion_id = @inclusion_id
		and 		billing_period = @accounting_period
			
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	
			
		end
	    																								
		   /*
			* Create Transaction
			*/
		
		select @tran_desc = @inclusion_desc + '  - Credit' 
		select @inclusion_credit = (@inclusion_charge + @acomm_nett) * -1
			
		exec @errorode = p_ffin_create_transaction	'GBCRD',
												@campaign_no,
												@account_id,
												@accounting_period,
												@tran_desc ,
												null,
												@inclusion_credit,
												@gst_rate,
												'Y',
												@tran_credit_id OUTPUT				
																								
		exec @errorode = p_ffin_allocate_transaction @tran_credit_id, @tran_id, @inclusion_credit, @accounting_period
			if(@errorode !=0)
			begin
				rollback transaction
				goto error
			end

	    
	   /*
		* Update Inclusion
		*/

		update inclusion_spot
		   set tran_id = @tran_id,
				spot_status = 'X'
		 where inclusion_id = @inclusion_id
		and 		billing_period = @accounting_period 

		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end	
		
		/*
		 * Insert into inclusion spot xref
		 */


		insert into inclusion_spot_xref select spot_id, @tran_id from inclusion_spot where inclusion_id = @inclusion_id
		and 		billing_period = @accounting_period  
		
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end	
		
		insert into inclusion_spot_xref select spot_id, @tran_credit_id from inclusion_spot where inclusion_id = @inclusion_id
		and 		billing_period = @accounting_period
		
		select @error = @@error
		if (@error !=0)
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
	
	update	campaign_transaction
	set		show_on_statement = 'N'
	from	v_campaign_invoicing_periods
	where	campaign_transaction.campaign_no = v_campaign_invoicing_periods.campaign_no
	and		campaign_transaction.campaign_no = @campaign_no
	and		tran_type in (select trantype_id from transaction_type where tran_category_code in ('B','Z') and trantype_id not in (164,165))
	and		tran_date = @accounting_period
	and		tran_date between inv_plan_start_date and inv_plan_end_date

	

	select @error = @@error

	if (@error !=0 )
	begin
		 raiserror ('Error: Failed to Generate Inclusion Invoicing Plans for Campaign %1!',11,1, @campaign_no)
		rollback transaction
		return -100
	end	

	/*
	 * Commit and Return
	 */
	
	commit transaction
end
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
