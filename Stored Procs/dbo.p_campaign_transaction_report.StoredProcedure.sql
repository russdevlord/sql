/****** Object:  StoredProcedure [dbo].[p_campaign_transaction_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_transaction_report]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_transaction_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC [dbo].[p_campaign_transaction_report] @accounting_period		datetime,
										  @country_code				char(1)
as

/*
 * Select and report data
 */

 select fc.campaign_no as campaign_no,
         fc.product_desc as product_desc,
         max(ct.tran_desc) as tran_desc,   
         max(ct.gross_amount) as gross_amount,   
         max(ct.nett_amount) as nett_amount,   
         max(ct.gst_amount) as gst_amount,   
         sum(pay_gst) as pay_gst,  
         max(ct.tran_date) as tran_date,   
         ct.tran_id,   
         st.accounting_period,   
         max(country.country_code) as country_code,   
         max(country.country_name) as country_name,
         max(branch.branch_code) as branch_code,   
         max(branch.branch_name) as branch_name,
         max(ct.tran_type) as tran_type,
         max(ct.tran_category) as tran_category,
		 bu.business_unit_desc as business_unit_desc,
		 trantype_desc,
		 tran_category_desc,
		 ct.show_on_statement
    from statement st,   
         campaign_transaction ct,   
         branch,
         country,
         film_campaign fc,
         business_unit bu,
         transaction_allocation ta,
         transaction_type,
         transaction_category
   where st.accounting_period = @accounting_period and
         st.statement_id = ct.statement_id and  
         ct.gross_amount > 0 and
         ct.tran_id = ta.to_tran_id and
         st.accounting_period = @accounting_period and
         ct.campaign_no = fc.campaign_no and
         fc.branch_code = branch.branch_code and
         fc.business_unit_id = bu.business_unit_id and
         branch.country_code = country.country_code and
         country.country_code = @country_code /*and
         fc.campaign_type < 5*/ and
         ct.tran_type = transaction_type.trantype_id and
         ct.tran_category = transaction_category.tran_category_code and
		 fc.business_unit_id not in (6,7,8)
group by fc.campaign_no,
         fc.product_desc,
         ct.tran_id,   
         st.accounting_period,
         bu.business_unit_desc,
		 trantype_desc,
		 tran_category_desc,
		 ct.show_on_statement
union
 select fc.campaign_no as campaign_no,
         fc.product_desc as product_desc,
         max(ct.tran_desc) as tran_desc,   
         max(ct.gross_amount) as gross_amount,   
         max(ct.nett_amount) as nett_amount,   
         max(ct.gst_amount) as gst_amount,   
         sum(pay_gst) as pay_gst,  
         max(ct.tran_date) as tran_date,   
         ct.tran_id,   
         st.accounting_period,   
         max(country.country_code) as country_code,   
         max(country.country_name) as country_name,
         max(branch.branch_code) as branch_code,   
         max(branch.branch_name) as branch_name,
         max(ct.tran_type) as tran_type,
         max(ct.tran_category) as tran_category,
		 bu.business_unit_desc as business_unit_desc,
		 trantype_desc,
		 tran_category_desc,
		 ct.show_on_statement
    from statement st,   
         campaign_transaction ct,   
         branch,
         country,
         film_campaign fc,
         business_unit bu,
         transaction_allocation ta,
         transaction_type,
         transaction_category
   where st.accounting_period = @accounting_period and
         st.statement_id = ct.statement_id and  
         ct.gross_amount > 0 and
         ct.tran_id = ta.from_tran_id and
         st.accounting_period = @accounting_period and
         ct.campaign_no = fc.campaign_no and
         fc.branch_code = branch.branch_code and
         fc.business_unit_id = bu.business_unit_id and
         branch.country_code = country.country_code and
         country.country_code = @country_code /*and
         fc.campaign_type < 5*/ and
         ct.tran_type = transaction_type.trantype_id and
         ct.tran_category = transaction_category.tran_category_code and
		 fc.business_unit_id not in (6,7,8)
group by fc.campaign_no,
         fc.product_desc,
         ct.tran_id,   
         st.accounting_period,
         bu.business_unit_desc,
		 trantype_desc,
		 tran_category_desc,
		 ct.show_on_statement
union
  select fc.campaign_no as campaign_no,
         fc.product_desc as product_desc,
         max(ct.tran_desc) as tran_desc,   
         max(ct.gross_amount) as tran_amount,   
         max(ct.nett_amount) as nett_amount,   
         max(ct.gst_amount) as gst_amount,   
         sum(pay_gst) as pay_gst,  
         max(ct.tran_date) as tran_date,   
         ct.tran_id,   
         st.accounting_period,   
         max(country.country_code) as country_code,   
         max(country.country_name) as country_name,
         max(branch.branch_code) as branch_code,   
         max(branch.branch_name) as branch_name,
         max(ct.tran_type) as tran_type,
         max(ct.tran_category) as tran_category,
		 bu.business_unit_desc as business_unit_desc,
		 trantype_desc,
		 tran_category_desc,
		 ct.show_on_statement
    from statement st,   
         campaign_transaction ct,   
         branch,
         country,
         film_campaign fc,
         business_unit bu,
         transaction_allocation ta,
         transaction_type,
         transaction_category
   where st.accounting_period = @accounting_period and
         st.statement_id = ct.statement_id and  
         ct.gross_amount <= 0 and
         ct.tran_id = ta.from_tran_id and
         st.accounting_period = @accounting_period and
         ct.campaign_no = fc.campaign_no and
         fc.branch_code = branch.branch_code and
         fc.business_unit_id = bu.business_unit_id and
         branch.country_code = country.country_code and
         country.country_code = @country_code /*and
         fc.campaign_type < 5*/and
         ct.tran_type = transaction_type.trantype_id and
         ct.tran_category = transaction_category.tran_category_code and
		 fc.business_unit_id not in (6,7,8)
group by fc.campaign_no,
         fc.product_desc,
         tran_id,   
         st.accounting_period,
         bu.business_unit_desc,
		 trantype_desc,
		 tran_category_desc,
		 ct.show_on_statement
/*
 * Return
 */

return 0
GO
