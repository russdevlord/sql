/****** Object:  StoredProcedure [dbo].[p_account_invoice_breakdown]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_account_invoice_breakdown]
GO
/****** Object:  StoredProcedure [dbo].[p_account_invoice_breakdown]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_account_invoice_breakdown] @invoice_id			integer

as

set nocount on 

declare @error     					integer

select 		case inv.invoice_date when '1-jul-2015' then '30-jun-2015' else inv.invoice_date end as invoice_date,
			fc.campaign_no,
			fc.product_desc,
			ct.tran_id,
			ct.tran_desc +  ' - Ref: ' + convert(varchar(10),tran_id),
			'',
			'',
			ct.tran_date,
			a.account_name,
			inv.company_id
from 		invoice inv,
			film_campaign fc,
			campaign_transaction ct,
			account a,
			transaction_type tt
where 		inv.invoice_id = @invoice_id 
and			ct.campaign_no = fc.campaign_no 
and			inv.invoice_id = ct.invoice_id 
and			ct.nett_amount >= 0 
and			inv.account_id = a.account_id
and			tt.tran_category_code = 'B' 
and			ct.tran_type = tt.trantype_id
and			ct.show_on_statement = 'Y'
order by 	ct.tran_id

return 0
GO
