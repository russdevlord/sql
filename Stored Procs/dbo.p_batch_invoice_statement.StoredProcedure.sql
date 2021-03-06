/****** Object:  StoredProcedure [dbo].[p_batch_invoice_statement]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_batch_invoice_statement]
GO
/****** Object:  StoredProcedure [dbo].[p_batch_invoice_statement]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create  proc [dbo].[p_batch_invoice_statement] AS
/*==============================================================*
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1   18-Feb-2011 DYI  Initial Revision			*
 *  2   21-Feb-2011 DYI  Commented out New Statement bit, due	*
 *	to business decided not to split Statements		*
 *                                                              *
 *==============================================================*/

DECLARE		@invoice_id 		    int
DECLARE 	@account_id 		    int
DECLARE 	@company_id		        int
DECLARE		@campaign_no		    int
DECLARE		@account_statement_id	int
DECLARE		@statement_id		    int
DECLARE 	@accounting_period	    datetime
DECLARE		@old_invoice_id		    int
DECLARE		@new_invoice_id		    int

DECLARE		@balance_current	    money
DECLARE		@balance_30		        money
DECLARE		@balance_60		        money
DECLARE		@balance_90		        money
DECLARE		@balance_120		    money
DECLARE		@balance_credit		    money
DECLARE		@balance_outstanding	money
DECLARE		@balance_forward	    money

declare		@errorode			        int

set nocount on

select 		ct.account_id,
            company_id = MAX(CASE When ac.country_code = 'Z' Then 2 ELSE case fc.business_unit_id when 6 then 3 else 1 end END) ,
            campaign_num = COUNT( DISTINCT ct.campaign_no),
            ct.account_statement_id,
            ct.invoice_id,
            gross_amount = SUM( gross_amount),
            st.accounting_period
into		#temp_account_invoices
from 		campaign_transaction ct, 
            film_campaign fc,
            account ac,
            statement st
where		ct.invoice_id = 0 
and         ct.tran_category <> 'C' 
and         ct.campaign_no = fc.campaign_no
and		    ct.account_id = ac.account_id
and         st.statement_id = ct.statement_id
GROUP BY	ct.account_id, 
            st.accounting_period, 
            ct.account_statement_id, 
            ct.invoice_id
order by 	ct.account_id, 
			ct.invoice_id, 
			ct.account_statement_id, 
			campaign_num

select 		ct.account_id,
            ct.campaign_no,
            ct.invoice_id,
            gross_amount = SUM( ct.gross_amount),
            st.accounting_period,
            tci.company_id
into		#temp_account_campaign
from 		campaign_transaction ct,
            #temp_account_invoices tci,
            statement st
where		ct.invoice_id = 0 
and         ct.tran_category <> 'C'
and		    ct.invoice_id = tci.invoice_id
and		    ct.account_id = tci.account_id
and         st.statement_id = ct.statement_id
GROUP BY	ct.campaign_no, 
            ct.account_id, st.accounting_period,
            ct.invoice_id, tci.company_id
ORDER BY 	ct.account_id, 
			tci.company_id, 
			gross_amount, 
			ct.invoice_id


declare 	account_cursor cursor for 
select		account_id,
            invoice_id,
            company_id,
            campaign_no,
            accounting_period
from 		#temp_account_campaign
order by 	account_id,
		company_id
for read only

CREATE 	TABLE 	#tmp_invoice (
invoice_id              int         not null,
account_id              int         not null,
invoice_date            datetime    null,
invoice_total           money       null,
company_id              int not     null,
account_statement_id    int not     null,
old_invoice_id          int not     null)

open account_cursor
fetch account_cursor into @account_id, @invoice_id, @company_id, @campaign_no, @accounting_period
while @@fetch_status = 0
begin
	-- Generate New Invoice	
	execute @errorode = p_get_sequence_number 'invoice', 5, @new_invoice_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		raiserror ('p_batch_invoice_statement: Get Invoice_ID failed.', 16, 1)
		return -1
	end

	insert 	into invoice (
            invoice_id,
            account_id,
            invoice_date,
            invoice_total,
            company_id,
            account_statement_id)
	SELECT 	@new_invoice_id, 
            @account_id, 
            @accounting_period, 
            sum(gross_amount), 
            @company_id,
            0
	from 	campaign_transaction 
	where 	account_id = @account_id 
    and     campaign_no = @campaign_no 
    and     invoice_id = @invoice_id


	-- Update Transaction with New Invoice
	update	campaign_transaction
	SET	    invoice_id = @new_invoice_id
	where 	invoice_id = @invoice_id 
    and     account_id = @account_id 
    and     campaign_no = @campaign_no
    and     statement_id in (select statement_id from statement where campaign_no = @campaign_no and accounting_period = @accounting_period)
		
	fetch account_cursor into @account_id, @invoice_id, @company_id, @campaign_no, @accounting_period
end

close account_cursor
deallocate account_cursor

return 0
GO
