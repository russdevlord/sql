/****** Object:  StoredProcedure [dbo].[p_ffin_add_agency_commission]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_add_agency_commission]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_add_agency_commission]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_ffin_add_agency_commission] 	@tran_id			int,
													@new_commission		numeric(6,4)

as

declare	@error        										int,
				@rowcount     									int,
				@errorode												int,
				@next_period									datetime,
				@billing_date									datetime,
				@acomm_nett									money,
				@acomm_gross									money,
				@pre_gst_calc									money,
				@exempt_gst_total							money,
				@pre_gst_total									money,
				@post_gst_total								money,
				@exempt_tran_id								int,
				@pre_tran_id									int,
				@post_tran_id									int,
				@acomm_tran_id								int,
				@agency_comm									numeric(6,4),			
				@pre_gst_rate									numeric(6,4),
				@post_gst_rate								numeric(6,4),
				@gst_changeover								datetime,
				@offset												int,
				@bill_csr_open									tinyint,
				@spot_csr_open								tinyint,
				@status												char(1),
				@rate													money,
				@makegood_rate								money,
				@tran_desc     									varchar(255),
				@tran_notes    									varchar(255),
				@period_desc    								varchar(255),
				@period_detailed_desc					varchar(255),
				@period_start									datetime,
				@campaign_country							char(1),
				@country_code									char(1),
				@month_name									char(3),
				@mode_desc										varchar(9),
				@gst_desc_on									char(1),
				@spot_id											int,		
				@complex_id										int,
				@spot_type										char(1),
				@mode												tinyint,
				@makegood_total								money,
				@agency_deal									char(1),
				@currency_string								varchar(30),
				@media_product_desc						varchar(30),
				@media_product_id							integer,
				@billing_tran_code							varchar(5),
				@acomm_tran_code							varchar(5),
				@t_billing_tran_code						varchar(5),
				@gst_exempt									char(1),
				@media_product_mode					int,
				@working_acomm								numeric(6,4),
				@takeout_exempt_tran_id				int,
				@takeout_pregst_tran_id				int,
				@takeout_postgst_tran_id				int,
				@trantype_desc								varchar(255),
				@takeout_desc									varchar(255),
				@account_id										int,
				@campaign_no									int,
				@tran_Date										datetime,
				@invoice_id										int,
				@account_statement_id					int,
				@alloc_date										datetime

set nocount on

/*
 * Initalise GST Full Description
 */

select			@gst_desc_on = 'Y'

select			@alloc_date = min(end_date)
from			accounting_period
where			status <> 'X'   

/*
 * Determine GST Rates, Agency Commission and Campaign Country
 */

begin transaction

select @agency_comm = @new_commission,
       @pre_gst_rate = country.gst_rate,
       @gst_changeover = country.changeover_date,
       @post_gst_rate = country.new_gst_rate,
       @campaign_country = country.country_code,
       @agency_deal = fc.agency_deal,
       @gst_exempt = fc.gst_exempt,
		@campaign_no = fc.campaign_no
  from film_campaign fc,
       branch,
       country
 where fc.campaign_no in (select campaign_no from campaign_transaction where tran_id = @tran_id) and
       fc.branch_code = branch.branch_code and
       branch.country_code = country.country_code

select @error = @@error,
       @rowcount = @@rowcount

if (@error !=0 or @rowcount=0)
begin
	raiserror ('Error getting campaign details', 16, 1)
	rollback transaction
	return -100
end	

select 	@billing_tran_code = trantype_code,
		@post_gst_total = nett_amount,
		@tran_desc = tran_desc,
		@account_id = account_id,
		@tran_date = tran_date,
		@invoice_id = invoice_id,
		@account_statement_id = account_statement_id
from	campaign_transaction,
		transaction_type
where	tran_id = @tran_id
and		campaign_transaction.tran_type = transaction_type.trantype_id


select @error = @@error,
       @rowcount = @@rowcount

if (@error !=0 or @rowcount=0)
begin
	raiserror ('Error getting transaction details', 16, 1)
	rollback transaction
	return -100
end	

if @billing_tran_code = 'FBILL'
	select @acomm_tran_code = 'FACOM'

if @billing_tran_code = 'TBILL'
	select @acomm_tran_code = 'TACOM'

if @billing_tran_code = 'MPFBL'
	select @acomm_tran_code = 'MPFAC'

if @billing_tran_code = 'DBILL'
	select 	@acomm_tran_code = 'DACOM'

if @billing_tran_code = 'MPDBL'
	select 	@acomm_tran_code = 'MPDAC'

if @billing_tran_code = 'CBILL'
	select 	@acomm_tran_code = 'CACOM'

if @billing_tran_code = 'MPCLB'
	select @acomm_tran_code = 'MPCLA'

if @billing_tran_code = 'IBILL'
	select  @acomm_tran_code = 'IACOM'

if @billing_tran_code = 'MPCMB'
	select @acomm_tran_code = 'MPCMA'

if @billing_tran_code = 'RBILL'
	select @acomm_tran_code = 'RACOM'

if @billing_tran_code = 'RWLBI'
	select @acomm_tran_code = 'RWLAC'
	
if @billing_tran_code = 'SPBIL'
	select @acomm_tran_code = 'SPACM'
	
if @billing_tran_code = 'DDFE'
	select @acomm_tran_code = 'KTACB'

if @billing_tran_code = 'FTICB'
	select @acomm_tran_code = 'KTACB'

if @billing_tran_code = 'DCIMB'
	select @acomm_tran_code = 'KTACB'
	
if @billing_tran_code = 'DCIMA'
	select @acomm_tran_code = 'KTACB'

if @billing_tran_code = 'AMEXB'
	select @acomm_tran_code = 'KTACB'	

if @billing_tran_code = 'AMEXP'
	select @acomm_tran_code = 'KTACB'		

if @billing_tran_code = 'IPROD'
	select @acomm_tran_code = 'KTACB'		
	
if @billing_tran_code = 'FTNGB'
	select @acomm_tran_code = 'KTACB'	

if @billing_tran_code = 'FKINE'
	select @acomm_tran_code = 'KTACB'	

if @billing_tran_code = 'FPPRD'
	select @acomm_tran_code = 'KTACB'	
		
if @billing_tran_code = 'FPPRB'
	select @acomm_tran_code = 'KTACB'	
	
if @billing_tran_code = 'ABILL'
	select @acomm_tran_code = 'AACOM'	
	
if @billing_tran_code = 'GBILL'
	select @acomm_tran_code = 'GACOM'	

if @billing_tran_code = 'FTNGT'
	select @acomm_tran_code = 'KTACB'	

if @billing_tran_code = 'FTICK'
	select @acomm_tran_code = 'KTACB'	

if @billing_tran_code = 'CRPRD'
	select @acomm_tran_code = 'KTACB'	

if @billing_tran_code = 'FANBI'
	select @acomm_tran_code = 'FANAC'	
	
	

select @acomm_nett = round(@post_gst_total * @agency_comm,2)	* -1

select @acomm_gross = @acomm_nett + round(@acomm_nett * @post_gst_rate,2)

select @tran_desc = 'A/Comm on ' + @tran_desc
		
if(@post_gst_rate > 0 and @gst_desc_on = 'Y' and @acomm_nett <> 0)
    select @tran_notes = 'GST@' + convert(varchar(4),convert(numeric(3,1),round(@post_gst_rate * 100,1))) + '% ' + @period_detailed_desc
else
    select @tran_notes = @period_detailed_desc

exec @errorode = p_ffin_create_transaction @acomm_tran_code,
								        @campaign_no,
										@account_id,
								        @tran_date,
								        @tran_desc,
                                        @tran_notes,
								        @acomm_nett,
								        @post_gst_rate,
										'Y',
								        @acomm_tran_id OUTPUT
if(@errorode !=0)
begin
	raiserror ('Failed to create acomm tran', 16, 1)
	rollback transaction
	return -100
end					    
		
/*
*	Allocate Agency Commision to Billing
*/

exec @errorode = p_ffin_allocate_transaction @acomm_tran_id, @tran_id, @acomm_nett, @alloc_date

if(@errorode !=0)
begin
	raiserror ('Failed to create acomm tran', 16, 1)
	rollback transaction
	return -100
end					    

update 	campaign_transaction 
set 	invoice_id = @invoice_id,
		account_statement_id = @account_statement_id
where 	tran_id = @acomm_tran_id

select @errorode = @@error
if(@errorode !=0)
begin
	raiserror ('Failed to create acomm tran', 16, 1)
	rollback transaction
	return -100
end					    

/*
 * Commit and Return
 */

commit transaction
return 0
GO
