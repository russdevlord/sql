/****** Object:  StoredProcedure [dbo].[p_film_inv_billings_by_bra_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_inv_billings_by_bra_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_film_inv_billings_by_bra_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_film_inv_billings_by_bra_rpt] @accounting_period		datetime,
				       @country_code			char(1),
                                       @branch_code             char(2) = null
as

/*
 * Select Dataset
 */
      
select st.campaign_no as campaign_no,
       fc.product_desc as product_desc,
       b.branch_code as branch_code,
       b.country_code as country_code,
       ct.tran_id as tran_id,
       ct.tran_date as tran_date,
       ct.tran_desc as tran_desc,
       ct.nett_amount as nett_amount,
       ct.tran_type as tran_type,
       tt.trantype_desc as trantype_desc,
       sr.first_name as first_name,
       sr.last_name as last_name,
       sr.status as rep_status,
       bu.business_unit_desc as business_unit_desc
  from business_unit bu,
       film_campaign fc,
       statement st,
       campaign_transaction ct,
       transaction_type tt,
       branch b,
       sales_rep sr
 where fc.business_unit_id = bu.business_unit_id and
       fc.campaign_no = ct.campaign_no and
       ct.statement_id = st.statement_id and
       ct.tran_type = tt.trantype_id and
       st.accounting_period = @accounting_period and
       fc.branch_code = b.branch_code and
       (b.country_code = @country_code OR @country_code is null) and
       (b.branch_code = @branch_code OR @branch_code is null) and
       ct.tran_category = 'B' and
       fc.rep_id = sr.rep_id and
       fc.campaign_type < 5

/*
 * Return Success
 */
 
return 0
GO
