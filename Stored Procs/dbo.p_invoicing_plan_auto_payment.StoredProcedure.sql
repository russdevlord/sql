/****** Object:  StoredProcedure [dbo].[p_invoicing_plan_auto_payment]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_invoicing_plan_auto_payment]
GO
/****** Object:  StoredProcedure [dbo].[p_invoicing_plan_auto_payment]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create proc [dbo].[p_invoicing_plan_auto_payment]

as		

declare				@error													int,
						@campaign_no										int,
						@payment_amount								money,
						@payment_production							money,
						@invoice_amount									money,
						@invoice_payment_type_code				int,
						@account_id										int,
						@tran_id												int,
						@confimation_date								datetime,
						@tran_date											datetime


set nocount on

/*
 * begin transaction
 */

begin transaction

/*
 * loop through open campaigns with invoice plans
 */

declare				campaign_csr cursor for
select				film_campaign.campaign_no,
						invoice_payment_type_code,
						case when inclusion.account_no is null then film_campaign.onscreen_account_id else inclusion.account_no end as account_id
from					film_campaign
inner join			film_campaign_standalone_invoice on film_campaign.campaign_no = film_campaign_standalone_invoice.campaign_no
inner join			inclusion on film_campaign_standalone_invoice.inclusion_id = inclusion.inclusion_id
where				film_campaign.campaign_status in ('L','F')
order by			film_campaign.campaign_no
for					read only

open campaign_csr
fetch campaign_csr into @campaign_no, @invoice_payment_type_code, @account_id
while(@@fetch_status = 0)
begin

	/*
	 *	get payment amount
	 */
	
	select			@payment_amount = isnull(sum(gross_amount) ,0)
	from			campaign_transaction 
	where			campaign_no = @campaign_no
	and				account_id = @account_id
	and				tran_type = 3

	select			@payment_production = isnull(sum(alloc.gross_amount),0)
	from			campaign_transaction as pay_tran
	inner join		transaction_allocation as alloc on pay_tran.tran_id = alloc.from_tran_id
	inner join		campaign_transaction as prod_tran on alloc.to_tran_id = prod_tran.tran_id
	where			pay_tran.campaign_no = @campaign_no
	and				pay_tran.account_id = @account_id
	and				pay_tran.tran_type = 3
	and				prod_tran.tran_category = 'M'
	and				left(isnull(prod_tran.tran_notes, ''), 7) <> 'Takeout'

	select			@payment_amount = -1 * (isnull(@payment_amount,0) - isnull(@payment_production,0))

	if @payment_amount > 0
	begin

		/*
		 * Loop invoices - asc for invoicing and desc for direct debit and credit card
		*/

		if @invoice_payment_type_code = 3
		begin
			declare					invoice_csr cursor for
			select					bill_trans.tran_id, 
										transaction_payment_confirmation.confimation_date,
										bill_trans.tran_date, 
										sum(transaction_allocation.gross_amount) as invoice_amount 
			from						campaign_transaction bill_trans
			inner join				transaction_allocation on bill_trans.tran_id = transaction_allocation.to_tran_id
			left outer join		campaign_transaction alloc_trans on transaction_allocation.from_tran_id = alloc_trans.tran_id
			left outer join		transaction_payment_confirmation on bill_trans.tran_id = transaction_payment_confirmation.tran_id
			where					bill_trans.campaign_no = @campaign_no
			and						bill_trans.account_id = @account_id
			and						bill_trans.tran_type = 164
			and						(alloc_trans.tran_type is null
			or							alloc_trans.tran_type <> 166)
			and						bill_trans.reversal = 'N'
			group by				bill_trans.tran_id,
										transaction_payment_confirmation.confimation_date,
										bill_trans.tran_date
			order by				isnull(transaction_payment_confirmation.confimation_date, '31-dec-2100') asc,
										bill_trans.tran_date asc
		end
		else
		begin
			declare					invoice_csr cursor for
			select					bill_trans.tran_id, 
										transaction_payment_confirmation.confimation_date,
										bill_trans.tran_date, 
										sum(transaction_allocation.gross_amount) as invoice_amount 
			from						campaign_transaction bill_trans
			inner join				transaction_allocation on bill_trans.tran_id = transaction_allocation.to_tran_id
			left outer join		campaign_transaction alloc_trans on transaction_allocation.from_tran_id = alloc_trans.tran_id
			left outer join		transaction_payment_confirmation on bill_trans.tran_id = transaction_payment_confirmation.tran_id
			where					bill_trans.campaign_no = @campaign_no
			and						bill_trans.account_id = @account_id
			and						bill_trans.tran_type = 164
			and						(alloc_trans.tran_type is null
			or							alloc_trans.tran_type <> 166)
			and						bill_trans.reversal = 'N'
			group by				bill_trans.tran_id,
										transaction_payment_confirmation.confimation_date,
										bill_trans.tran_date
			order by				isnull(transaction_payment_confirmation.confimation_date, '31-dec-2100') asc,
										bill_trans.tran_date desc
		end
			
		open invoice_csr
		fetch invoice_csr into @tran_id, @confimation_date, @tran_date, @invoice_amount
		while(@@fetch_status = 0)
		begin
				select @payment_amount = @payment_amount - @invoice_amount

				if @payment_amount >= 0 
				begin
					if @confimation_date is null
					begin
						insert into transaction_payment_confirmation (tran_id, confimation_date) values (@tran_id, getdate())

						select @error = @@error

						if @error <> 0
						begin
							raiserror ('Error: Could not insert payment detail for invoicing_plan', 16, 1)
							rollback transaction
							return -1
						end
					end
				end

			fetch invoice_csr into @tran_id, @confimation_date, @tran_date, @invoice_amount
		end

		close invoice_csr
		deallocate invoice_csr
	end
	
	fetch campaign_csr into @campaign_no, @invoice_payment_type_code, @account_id
end

commit transaction
return 0
GO
