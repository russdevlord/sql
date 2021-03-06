/****** Object:  StoredProcedure [dbo].[p_cag_tmp_show_data]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_tmp_show_data]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_tmp_show_data]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_tmp_show_data] @accounting_period datetime, @cinema_agreement_id int = null as


select  'cinema_revenue' as table_name,
        cinema_revenue.complex_id, 
        cinema_revenue.accounting_period, 
        cinema_revenue.revenue_source, 
        cinema_revenue.business_unit_id, 
        cinema_revenue.origin_period, 
        cinema_revenue.liability_type_id, 
        cinema_revenue.currency_code, 
        cinema_revenue.cinema_amount 
from cinema_revenue where ((complex_id in (select complex_id 
                                                    from cinema_agreement_policy 
                                                    where cinema_agreement_id = @cinema_agreement_id)) OR @cinema_agreement_id is null) 
and (accounting_period = @accounting_period OR @accounting_period is null)
order by origin_period


select 'cinema_agreement_revenue' as table_name,
     cinema_agreement_revenue.revenue_id, 
cinema_agreement_revenue.cinema_agreement_id, 
cinema_agreement_revenue.complex_id, 
cinema_agreement_revenue.accounting_period, 
cinema_agreement_revenue.origin_period, 
cinema_agreement_revenue.release_period, 
cinema_agreement_revenue.revenue_source, 
cinema_agreement_revenue.business_unit_id, 
cinema_agreement_revenue.liability_type_id, 
cinema_agreement_revenue.policy_id, 
cinema_agreement_revenue.currency_code, 
cinema_agreement_revenue.cag_entitlement_id, 
 cinema_agreement_revenue.cinema_amount, 
 cinema_agreement_revenue.percentage_entitlement,
  cinema_agreement_revenue.agreement_days,
   cinema_agreement_revenue.period_days,
    cinema_agreement_revenue.excess_status, 
    cinema_agreement_revenue.cancelled 
    from cinema_agreement_revenue 
    where (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null)
and (release_period = @accounting_period OR @accounting_period is null)
    and cinema_agreement_revenue.cag_entitlement_id is not null
    order by origin_period
    
select 'cinema_agreement_entitlement' as table_name,
    cinema_agreement_entitlement.cag_entitlement_id, 
cinema_agreement_entitlement.cinema_agreement_id, 
cinema_agreement_entitlement.complex_id, 
cinema_agreement_entitlement.accounting_period, 
cinema_agreement_entitlement.origin_period, 
cinema_agreement_entitlement.revenue_source, 
cinema_agreement_entitlement.business_unit_id, 
cinema_agreement_entitlement.currency_code, 
cinema_agreement_entitlement.origin_currency_code,
 cinema_agreement_entitlement.tran_id, 
 cinema_agreement_entitlement.origin_currency_amt, 
 cinema_agreement_entitlement.nett_amount,
  cinema_agreement_entitlement.excess_status 
  from cinema_agreement_entitlement where (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null)
and (accounting_period = @accounting_period OR @accounting_period is null)
   order by origin_period
  
select 'cinema_agreement_transaction' as table_name,
cinema_agreement_transaction.tran_id, 
cinema_agreement_transaction.trantype_id, 
cinema_agreement_transaction.cinema_agreement_id, 
cinema_agreement_transaction.accounting_period, 
cinema_agreement_transaction.process_period, 
cinema_agreement_transaction.currency_code, 
cinema_agreement_transaction.statement_no, 
cinema_agreement_transaction.tran_desc, 
cinema_agreement_transaction.tran_subdesc, 
cinema_agreement_transaction.tran_date, 
cinema_agreement_transaction.nett_amount, 
cinema_agreement_transaction.gst_rate, 
cinema_agreement_transaction.gst_amount,
 cinema_agreement_transaction.gross_amount,
  cinema_agreement_transaction.show_on_statement, 
  cinema_agreement_transaction.transaction_status_code
  from cinema_agreement_transaction where (cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null)
and (process_period = @accounting_period OR @accounting_period is null)
  

SELECT 'cinema_agreement_statement' as table_name,
	t.cinema_agreement_id,
	t.statement_no,
	t.accounting_period,
	t.opening_balance,
	t.payments,
	t.entitlements,
	t.closing_balance,
	t.address_xref_id
 FROM dbo.cinema_agreement_statement t WHERE 
(cinema_agreement_id = @cinema_agreement_id OR @cinema_agreement_id is null)
and (accounting_period = @accounting_period OR @accounting_period is null)


return 0
GO
