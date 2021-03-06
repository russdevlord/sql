/****** Object:  View [dbo].[v_invoicing_plan_atb]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_invoicing_plan_atb]
GO
/****** Object:  View [dbo].[v_invoicing_plan_atb]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_invoicing_plan_atb]
as
select		tran_table.campaign_no, 
			tran_table.tran_id, 
			tran_table.tran_date, 
			tran_table.account_id,
			tran_table.gross_amount + sum(transaction_allocation.gross_amount) as gross_amount 
from		campaign_transaction tran_table, 
			campaign_transaction alloc_table, 
			transaction_allocation
where 		tran_table.tran_type = 164 
and 		alloc_table.tran_type = 165
and			tran_table.reversal = 'N'
and			tran_table.tran_id = transaction_allocation.to_tran_id
and			alloc_table.tran_id = transaction_allocation.from_tran_id
group by	tran_table.campaign_no, 
			tran_table.tran_id, 
			tran_table.tran_date, 
			tran_table.account_id,
			tran_table.gross_amount
union
select		campaign_no,
			tran_id, 
			tran_date,
			account_id,
			gross_amount
from		campaign_transaction
where		tran_type = 164
and			reversal = 'N'
and			tran_id not in (select		tran_table.tran_id
							from		campaign_transaction tran_table, 
										campaign_transaction alloc_table, 
										transaction_allocation
							where 		tran_table.tran_type = 164 
							and 		alloc_table.tran_type  = 165 
							and			tran_table.tran_id = transaction_allocation.to_tran_id
							and			alloc_table.tran_id = transaction_allocation.from_tran_id)
GO
