/****** Object:  StoredProcedure [dbo].[p_campaign_transaction_report_detailed]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_transaction_report_detailed]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_transaction_report_detailed]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_campaign_transaction_report_detailed] @accounting_period		datetime,
										  @country_code				char(1)
as

/*
 * Select and report data
 */

 select fc.campaign_no as campaign_no,
		fc.product_desc as product_desc,
		fc.campaign_status as campaign_status,
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
		isnull((case  
			when tt.trantype_id in (1,5,35,40) then (	select	sum(spot_amount) 
														from	spot_liability 
														where	creation_period = @accounting_period 
														and		liability_type in (1,5,34,38)
														and		spot_id in (select dbo.f_spot_redirect(spot_id) from film_spot_xref where tran_id = ct.tran_id))
			when tt.trantype_id in (73) then (			select	sum(spot_amount) 
														from	cinelight_spot_liability 
														where	creation_period = @accounting_period 
														and		liability_type in (11)
														and		spot_id in (select dbo.f_cl_spot_redirect(spot_id) from cinelight_spot_xref where tran_id = ct.tran_id))														
			when tt.trantype_id in (82) then (			select	sum(spot_amount) 
														from	inclusion_spot_liability 
														where	/*creation_period = @accounting_period 
														and		*/liability_type in (14)
														and		spot_id in (select dbo.f_inc_spot_redirect(spot_id) from inclusion_spot_xref where tran_id = ct.tran_id))														
			when tt.trantype_id in (2,6,36,41) then (	select	sum(spot_amount) 
														from	spot_liability 
														where	creation_period = @accounting_period 
														and		liability_type in (2,6,35,39)
														and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period ))
			when tt.trantype_id in (74) then (			select	sum(spot_amount) 
														from	cinelight_spot_liability 
														where	creation_period = @accounting_period 
														and		liability_type in (12)
														and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period ))
			when tt.trantype_id in (89) then (			select	sum(spot_amount) 
														from	inclusion_spot_liability 
														where	creation_period = @accounting_period 
														and		liability_type in (15)
														and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period ))
			when tt.trantype_id in (3)			then (	select	sum(summed_spot_amount)
														from	(select	sum(spot_amount) as summed_spot_amount
																from	spot_liability 
																where	creation_period = @accounting_period 
																and		liability_type in (3)
																and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period )
																union all
																select	sum(spot_amount) 
																from	cinelight_spot_liability 
																where	creation_period = @accounting_period 
																and		liability_type in (3)
																and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period )
																union all
																select	sum(spot_amount) 
																from	inclusion_spot_liability 
																where	creation_period = @accounting_period 
																and		liability_type in (3)
																and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period )) as temp_table)
			else 0
		end),0) as liabilty
    from statement st,   
         campaign_transaction ct,   
         branch,
         country,
         film_campaign fc,
         business_unit bu,
         transaction_allocation ta,
         transaction_type tt
   where st.accounting_period = @accounting_period and
         st.statement_id = ct.statement_id and  
         ct.gross_amount > 0 and
         ct.tran_id = ta.to_tran_id and
         st.accounting_period = @accounting_period and
         ct.campaign_no = fc.campaign_no and
         fc.branch_code = branch.branch_code and
         fc.business_unit_id = bu.business_unit_id and
         branch.country_code = country.country_code and
         country.country_code = @country_code and
         ct.tran_type = tt.trantype_id and
		 fc.business_unit_id not in (6,7,8)

group by fc.campaign_no,
         fc.product_desc,
         ct.tran_id,   
         st.accounting_period,
         fc.campaign_status,
         bu.business_unit_desc,
		 trantype_desc,
		 tt.trantype_id
union
 select fc.campaign_no as campaign_no,
         fc.product_desc as product_desc,
         fc.campaign_status,
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
		isnull((case  
			when tt.trantype_id in (1,5,35,40) then (	select	sum(spot_amount) 
														from	spot_liability 
														where	creation_period = @accounting_period 
														and		liability_type in (1,5,34,38)
														and		spot_id in (select dbo.f_spot_redirect(spot_id) from film_spot_xref where tran_id = ct.tran_id))
			when tt.trantype_id in (73) then (			select	sum(spot_amount) 
														from	cinelight_spot_liability 
														where	creation_period = @accounting_period 
														and		liability_type in (11)
														and		spot_id in (select dbo.f_cl_spot_redirect(spot_id) from cinelight_spot_xref where tran_id = ct.tran_id))														
			when tt.trantype_id in (82) then (			select	sum(spot_amount) 
														from	inclusion_spot_liability 
														where	/*creation_period = @accounting_period 
														and		*/liability_type in (14)
														and		spot_id in (select dbo.f_inc_spot_redirect(spot_id) from inclusion_spot_xref where tran_id = ct.tran_id))														
			when tt.trantype_id in (2,6,36,41) then (	select	sum(spot_amount) 
														from	spot_liability 
														where	creation_period = @accounting_period 
														and		liability_type in (2,6,35,39)
														and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period ))
			when tt.trantype_id in (74) then (			select	sum(spot_amount) 
														from	cinelight_spot_liability 
														where	creation_period = @accounting_period 
														and		liability_type in (12)
														and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period ))
			when tt.trantype_id in (89) then (			select	sum(spot_amount) 
														from	inclusion_spot_liability 
														where	creation_period = @accounting_period 
														and		liability_type in (15)
														and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period ))
			when tt.trantype_id in (3)			then (	select	sum(summed_spot_amount)
														from	(select	sum(spot_amount) as summed_spot_amount
																from	spot_liability 
																where	creation_period = @accounting_period 
																and		liability_type in (3)
																and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period )
																union all
																select	sum(spot_amount) 
																from	cinelight_spot_liability 
																where	creation_period = @accounting_period 
																and		liability_type in (3)
																and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period )
																union all
																select	sum(spot_amount) 
																from	inclusion_spot_liability 
																where	creation_period = @accounting_period 
																and		liability_type in (3)
																and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period )) as temp_table)
			else 0
		end),0) as liabilty
    from statement st,   
         campaign_transaction ct,   
         branch,
         country,
         film_campaign fc,
         business_unit bu,
         transaction_allocation ta,
         transaction_type tt
   where st.accounting_period = @accounting_period and
         st.statement_id = ct.statement_id and  
         ct.gross_amount > 0 and
         ct.tran_id = ta.from_tran_id and
         st.accounting_period = @accounting_period and
         ct.campaign_no = fc.campaign_no and
         fc.branch_code = branch.branch_code and
         fc.business_unit_id = bu.business_unit_id and
         branch.country_code = country.country_code and
         country.country_code = @country_code  and
         ct.tran_type = tt.trantype_id and
		 fc.business_unit_id not in (6,7,8)
group by fc.campaign_no,
         fc.product_desc,
         ct.tran_id,   
         fc.campaign_status,
         st.accounting_period,
         bu.business_unit_desc,
		 trantype_desc,
		 tt.trantype_id
union
  select fc.campaign_no as campaign_no,
         fc.product_desc as product_desc,
         fc.campaign_status,
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
		isnull((case  
			when tt.trantype_id in (1,5,35,40) then (	select	sum(spot_amount) 
														from	spot_liability 
														where	creation_period = @accounting_period 
														and		liability_type in (1,5,34,38)
														and		spot_id in (select dbo.f_spot_redirect(spot_id) from film_spot_xref where tran_id = ct.tran_id))
			when tt.trantype_id in (73) then (			select	sum(spot_amount) 
														from	cinelight_spot_liability 
														where	creation_period = @accounting_period 
														and		liability_type in (11)
														and		spot_id in (select dbo.f_cl_spot_redirect(spot_id) from cinelight_spot_xref where tran_id = ct.tran_id))														
			when tt.trantype_id in (82) then (			select	sum(spot_amount) 
														from	inclusion_spot_liability 
														where	/*creation_period = @accounting_period 
														and		*/liability_type in (14)
														and		spot_id in (select dbo.f_inc_spot_redirect(spot_id) from inclusion_spot_xref where tran_id = ct.tran_id))														
			when tt.trantype_id in (2,6,36,41) then (	select	sum(spot_amount) 
														from	spot_liability 
														where	creation_period = @accounting_period 
														and		liability_type in (2,6,35,39)
														and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period ))
			when tt.trantype_id in (74) then (			select	sum(spot_amount) 
														from	cinelight_spot_liability 
														where	creation_period = @accounting_period 
														and		liability_type in (12)
														and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period ))
			when tt.trantype_id in (89) then (			select	sum(spot_amount) 
														from	inclusion_spot_liability 
														where	creation_period = @accounting_period 
														and		liability_type in (15)
														and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period ))
			when tt.trantype_id in (3)			then (	select	sum(summed_spot_amount)
														from	(select	sum(spot_amount) as summed_spot_amount
																from	spot_liability 
																where	creation_period = @accounting_period 
																and		liability_type in (3)
																and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period )
																union all
																select	sum(spot_amount) 
																from	cinelight_spot_liability 
																where	creation_period = @accounting_period 
																and		liability_type in (3)
																and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period )
																union all
																select	sum(spot_amount) 
																from	inclusion_spot_liability 
																where	creation_period = @accounting_period 
																and		liability_type in (3)
																and		allocation_id in (select allocation_id from transaction_allocation where ct.tran_id = from_tran_id and process_period = @accounting_period )) as temp_table)
			else 0
		end),0) as liabilty
    from statement st,   
         campaign_transaction ct,   
         branch,
         country,
         film_campaign fc,
         business_unit bu,
         transaction_allocation ta,
         transaction_type tt
   where st.accounting_period = @accounting_period and
         st.statement_id = ct.statement_id and  
         ct.gross_amount <= 0 and
         ct.tran_id = ta.from_tran_id and
         st.accounting_period = @accounting_period and
         ct.campaign_no = fc.campaign_no and
         fc.branch_code = branch.branch_code and
         fc.business_unit_id = bu.business_unit_id and
         branch.country_code = country.country_code and
         country.country_code = @country_code  and
         ct.tran_type = tt.trantype_id and
		 fc.business_unit_id not in (6,7,8)
group by fc.campaign_no,
         fc.product_desc,
         fc.campaign_status,
         tran_id,   
         st.accounting_period,
         bu.business_unit_desc,
		 trantype_desc,
		 tt.trantype_id
order by tt.trantype_desc

/*
 * Return
 */

return 0
GO
