/****** Object:  StoredProcedure [dbo].[p_sfin_eom_recon_trans]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_eom_recon_trans]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_eom_recon_trans]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sfin_eom_recon_trans] @accounting_period		datetime,
                                   @country_code			char(1)
as

/*
 * Declare Variables
 */

declare @error        				integer,
        @rowcount     				integer,
        @errorode						integer,
        @opening_balance			money,
        @opening_gst				money,
        @opening_gross				money,
        @closing_balance			money,
        @branch_nett				money,
        @branch_gst					money,
        @branch_gross				money,
        @branch_code				char(2),
        @prev_accounting_period	    datetime,
        @branch_csr_open			tinyint



/*
 * Create Temporary Table
 */

create table #recon_branch
(
	branch_code				char(2)			null,
   opening_balance		money				null,
   closing_balance		money				null,
	branch_nett				money				null,
	branch_gst				money				null,
	branch_gross			money				null
)

create table #recon_trans
(
	branch_code				char(2)			null,
   trantype_id				integer			null,
	transaction_nett		money				null,
	transaction_gst		money				null,
	transaction_gross		money				null
)

/*
 * Get Previouse Accounting Period
 */

select @prev_accounting_period = max(end_date)
  from accounting_period
 where end_date < @accounting_period

/*
 * Declare Cursor
 */

 declare branch_csr cursor static for
  select branch_code
    from branch
   where country_code = @country_code
order by branch_code
     for read only

/*
 * Loop Branches
 */

open branch_csr
select @branch_csr_open = 1
fetch branch_csr into @branch_code
while(@@fetch_status = 0)
begin

	/*
    * Initialise Variables
    */

	select @opening_balance = 0,
          @closing_balance = 0,
          @branch_nett = 0,
          @branch_gst = 0,
          @branch_gross = 0

	/*
	 * Select Last Months Closing Balance
	 */
	
	select @opening_balance = isnull(sum(sas.balance_outstanding),0)
	  from slide_accounting_statement sas,
			 slide_campaign sc
	 where sas.accounting_period = @prev_accounting_period and
			 sas.campaign_no = sc.campaign_no and
			 sc.branch_code = @branch_code

	/*
    * Calculate Transaction Total
    */

	select @branch_nett = isnull(sum(sas.nett_amount),0)
	  from slide_transaction sas,
			 slide_campaign sc
	 where sas.accounting_period = @accounting_period and
			 sas.campaign_no = sc.campaign_no and
			 sc.branch_code = @branch_code
	
	select @branch_gst = isnull(sum(sas.gst_amount),0)
	  from slide_transaction sas,
			 slide_campaign sc
	 where sas.accounting_period = @accounting_period and
			 sas.campaign_no = sc.campaign_no and
			 sc.branch_code = @branch_code
	
	select @branch_gross = isnull(sum(sas.gross_amount),0)
	  from slide_transaction sas,
			 slide_campaign sc
	 where sas.accounting_period = @accounting_period and
			 sas.campaign_no = sc.campaign_no and
			 sc.branch_code = @branch_code

	/*
	 * Calculate Closing Balance
	 */
	
	select @closing_balance = isnull(@opening_balance + @branch_gross, 0)
	
	insert into #recon_branch (
			 branch_code,
			 opening_balance,
			 closing_balance,
			 branch_nett,
			 branch_gst,
			 branch_gross ) values (
			 @branch_code,
			 @opening_balance,
			 @closing_balance,
			 @branch_nett,
			 @branch_gst,
			 @branch_gross )

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		return -1
	end

	insert into #recon_trans
   select slide_campaign.branch_code,
          slide_transaction.tran_type,
          isnull( sum( nett_amount ), 0 ) as nett_amount,
          isnull( sum( gst_amount ), 0 ) as gst_amount,
          isnull( sum( gross_amount ), 0 ) as gross_amount
     from slide_transaction,
          slide_campaign
    where slide_transaction.campaign_no = slide_campaign.campaign_no and
          slide_transaction.accounting_period = @accounting_period and
          slide_campaign.branch_code = @branch_code 
/*    and slide_transaction.tran_type >= 50 */

 group by slide_campaign.branch_code,
          slide_transaction.tran_type,
          slide_transaction.tran_category

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		return -1
	end

	insert into #recon_trans
   select @branch_code,
          tt_1.trantype_id,
          0,
          0,
          0
     from transaction_type tt_1
    where /* tt_1.trantype_id >= 50 and */
          not exists ( select #recon_trans.trantype_id
                         from #recon_trans
                        where #recon_trans.branch_code = @branch_code and
                              #recon_trans.trantype_id = tt_1.trantype_id )

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		return -1
	end

	/*
	 * Fetch Next
	 */

	fetch branch_csr into @branch_code

end
close branch_csr
deallocate branch_csr
select @branch_csr_open = 0

/*
 * Return Dataset
 */

  select @country_code as country_code,
         #recon_branch.branch_code,
         br.branch_name,
         tc.tran_category_code,
         tc.tran_category_desc,
         tt.trantype_code,
         tt.trantype_desc,
         #recon_branch.opening_balance,
         #recon_branch.closing_balance,
         #recon_branch.branch_nett,
         #recon_branch.branch_gst,
         #recon_branch.branch_gross,
         #recon_trans.transaction_nett,
         #recon_trans.transaction_gst,
         #recon_trans.transaction_gross
    from #recon_branch,
         #recon_trans,
         branch br,
         transaction_type tt,
         transaction_category tc
   where #recon_branch.branch_code = #recon_trans.branch_code and
         #recon_branch.branch_code = br.branch_code and
         #recon_trans.trantype_id = tt.trantype_id and
         tt.tran_category_code = tc.tran_category_code
order by #recon_branch.branch_code,
         tt.trantype_code

/*
 * Return
 */

return 0

/*
 * Error Handler
 */

error:

	if (@branch_csr_open = 1)
   begin
		close branch_csr
		deallocate branch_csr
	end

	return -1
GO
