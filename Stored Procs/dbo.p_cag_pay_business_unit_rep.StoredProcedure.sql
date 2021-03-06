/****** Object:  StoredProcedure [dbo].[p_cag_pay_business_unit_rep]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_pay_business_unit_rep]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_pay_business_unit_rep]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_cag_pay_business_unit_rep] @accounting_period   datetime 
as

/* Proc name:   p_cag_pay_business_unit_rep
 * Author:      Victoria Tyshchenko
 * Date:        19/02/2004
 * Description: Report retrieves Paid and Pending payments grouped by business unit - revenue - campaign 
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date:   Mar 25 2004 11:06:28  $ 
 * $Author:   vtyshchenko  $ 
 * $Revision:   1.1  $
 * $Workfile:   cag_pay_business_unit_rep.sql  $
 *
*/ 

select  cat.process_period 'payment_period',
        bu.business_unit_desc,
        crs.revenue_desc,
        cae.accounting_period 'entitlement_period',
        ca.cinema_agreement_id,
        ca.agreement_desc,
        tt.trantype_desc,
        cae.currency_code,
        crp.payment_status_code,
        sum(cae.nett_amount) 'rent_paid'
from    cinema_agreement ca,
        cinema_agreement_entitlement cae, 
        cinema_agreement_transaction cat, 
        cinema_rent_payment_allocation cpa,
        cinema_rent_payment crp,
        transaction_type tt,
        business_unit bu,
        cinema_revenue_source crs
where cat.tran_id = cpa.payment_tran_id
and cpa.entitlement_tran_id = cae.tran_id
and cat.tran_id = crp.tran_id
and crp.payment_status_code in ('P','D')
and cat.trantype_id = tt.trantype_id
and tt.trantype_code in ('CAGPJ','CAGXP','CAGRP','CAGFP', 'CAGMP') -- payments
and cat.transaction_status_code = 'P'
and cat.process_period = @accounting_period
and cae.business_unit_id = bu.business_unit_id
and cae.revenue_source = crs.revenue_source
and cae.cinema_agreement_id = ca.cinema_agreement_id
group by ca.cinema_agreement_id,
        ca.agreement_desc,
        cae.accounting_period,
        cat.process_period,
        bu.business_unit_desc,
        crs.revenue_desc,
        tt.trantype_desc,
        cae.currency_code,
        crp.payment_status_code
order by  bu.business_unit_desc,       
          crs.revenue_desc,
          ca.cinema_agreement_id


return
GO
