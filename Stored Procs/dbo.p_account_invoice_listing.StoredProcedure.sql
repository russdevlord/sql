/****** Object:  StoredProcedure [dbo].[p_account_invoice_listing]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_account_invoice_listing]
GO
/****** Object:  StoredProcedure [dbo].[p_account_invoice_listing]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROC [dbo].[p_account_invoice_listing]		@account_id	int
as
/*==============================================================*
 * DESC:- lists all the invoices for a selected account         *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1   5-Mar-2008 DH  Initial Build                            *
 *  2	4-Feb-2011 DYI	Added Campign No to output              *
 *==============================================================*/
declare @errorode			int,
        @tran_id		int
/*
 * Build a list of invoices for the account
 */
select	inv.invoice_id,   
		inv.invoice_status,   
		inv.invoice_date,   
		inv.invoice_total,   
		convert(money,0) AS invoice_payments,   
		inv.account_statement_id,
		inv.company_id
into	#tmp_invoice
from	invoice inv
where	inv.account_id = @account_id

/*
 * Apply any payments
 */
update #tmp_invoice
set		invoice_payments = (select	isnull(sum(ta.gross_amount),0) 
                             from	transaction_allocation ta, campaign_transaction ct, transaction_type tt
                            where	ta.to_tran_id IN (select tran_id from campaign_transaction where invoice_id = #tmp_invoice.invoice_id) 
		and  ta.from_tran_id is not null 
		and  ta.gross_amount < 0
		and  tt.trantype_id = ct.tran_type
		and  tt.tran_category_code = 'C'
		and  ct.tran_id = ta.from_tran_id)
		
/*
 * Set the invoice status 
 */
update	#tmp_invoice
set		invoice_status = case when invoice_payments = 0 then 'O'
                             when ABS(invoice_payments) <> ABS(invoice_total) then 'X'
                             else 'P'
                        end
/*
	04-02-2011 DYI Added campaign 
*/
SELECT DISTINCT ct.invoice_id, ct.campaign_no, fc.product_desc
INTO	#tmp_account_campaign_invoice
FROM	campaign_transaction ct, film_campaign fc
WHERE	ct.account_id = @account_id AND 
		ct.invoice_id IS NOT NULL AND ct.invoice_id > 0 AND
		ct.campaign_no = fc.campaign_no

select	t.invoice_id,
		t.invoice_status,
		t.invoice_date,
		t.invoice_total,
		t.invoice_payments,
		t.account_statement_id,
		t.company_id,
		tt.campaign_no,
		tt.product_desc
from	#tmp_invoice t, #tmp_account_campaign_invoice tt
where	t.invoice_id = tt.invoice_id 

return 0
GO
