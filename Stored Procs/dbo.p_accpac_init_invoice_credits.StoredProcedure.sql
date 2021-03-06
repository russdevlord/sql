/****** Object:  StoredProcedure [dbo].[p_accpac_init_invoice_credits]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_accpac_init_invoice_credits]
GO
/****** Object:  StoredProcedure [dbo].[p_accpac_init_invoice_credits]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_accpac_init_invoice_credits]   @country_code			char(1),
											@accounting_period		datetime
as
/* Proc name:   p_accpac_init_invoice_credits
 * Author:      Grant Carlson
 * Date:        15/10/2004
 * Description: Called as part of AccPac Interface to populate invoices with CinVendo (AR) Transactions
 *
 * Changes: 
 *
*/ 

declare @error        				int,
        @err_msg                    varchar(150),
        --@error                         int,
        @proc_name                  varchar(50),
        @status_awaiting            char(1),
        @status_failed              char(1),
        @interface_status_new       char(1)

set nocount on
       
select  @status_awaiting = 'A',
        @status_failed = 'F',
        @interface_status_new = 'N'

select  @proc_name = object_name(@@PROCID)

/*
exec @error = p_dw_start_process @proc_name
if @error != 0
	goto error
*/

begin transaction

    INSERT INTO accpac_integration.dbo.invoice_credits
	    (idcust,
	     tran_id,
         invoice_tran_id,
	     campaign,
	     date,
         accounting_period,
	     gl_prefix,
	     campaign_desc,
	     tran_desc,
	     amount,
	     amount_gst,
	     trantype_code,
	     status,
         country_code)
    select  vc.accpac_customer_id,
            convert(char(10),'F' + convert(varchar(9),ct.tran_id)), -- film trans prefixed with F
            'F' + convert(varchar(9),ta.to_tran_id) as invoice_tran_id, 
            convert(char(7),ct.campaign_no),
            ct.tran_date,
            @accounting_period,
            tt.gl_code,
            fc.product_desc,
            ct.tran_desc,
            ta.gross_amount,
            ta.gst_amount,
            tt.trantype_code,
            @interface_status_new,
            @country_code
    from    film_campaign fc,
            branch br,
            campaign_transaction ct,
            statement fs,
            v_accpac_customer vc,
            transaction_type tt,
            transaction_allocation ta
    where   fc.branch_code = br.branch_code
    and     br.country_code = @country_code
    and     fc.agency_deal = 'Y'
    and     fc.billing_agency = vc.vm_customer_id
    and     vc.customer_type = 'A'
    and     fc.campaign_no = ct.campaign_no
    and     ct.tran_type = tt.trantype_id
    and		ta.from_tran_id = ct.tran_id
    and     ct.statement_id = fs.statement_id
    and     fs.accounting_period < @accounting_period
    and     ct.tran_category = 'D'
    and     fc.campaign_status in ('F','L') -- ****** TEMP REMOVE
    UNION
    select  vc.accpac_customer_id,
            convert(char(10),'F' + convert(varchar(9),ct.tran_id)),
            'F' + convert(varchar(9),ta.to_tran_id) as invoice_tran_id, 
            convert(char(7),ct.campaign_no),
            ct.tran_date,
            @accounting_period,
            tt.gl_code,
            fc.product_desc,
            ct.tran_desc,
            ta.gross_amount,
            ta.gst_amount,
            tt.trantype_code,
            @interface_status_new,
            @country_code
    from    film_campaign fc,
            branch br,
            campaign_transaction ct,
            statement fs,
            v_accpac_customer vc,
            transaction_type tt,
            transaction_allocation ta
    where   fc.branch_code = br.branch_code
    and     br.country_code = @country_code
    and     fc.agency_deal = 'N'
    and     fc.client_id = vc.vm_customer_id
    and     vc.customer_type = 'C'
    and     fc.campaign_no = ct.campaign_no
    and     ct.tran_type = tt.trantype_id
    and     ct.statement_id = fs.statement_id
    and     fs.accounting_period < @accounting_period
    and     ct.tran_category = 'D'
    and     fc.campaign_status in ('F','L') -- ****** TEMP REMOVE    
    UNION 
    select  vc.accpac_customer_id,
            convert(char(10),'S' + convert(varchar(9),st.tran_id)), -- slide trans prefixed with S
            'S' + convert(varchar(9),ta.to_tran_id) as invoice_tran_id, 
            st.campaign_no,
            st.tran_date,
            @accounting_period,
            tt.gl_code,
            sc.name_on_slide,
            st.tran_desc,
            ta.gross_amount,
            ta.gst_amount,
            tt.trantype_code,
            @interface_status_new,
            @country_code
    from    slide_campaign sc,
            branch br,
            slide_transaction st,
            slide_allocation ta,
            v_accpac_customer vc,
            transaction_type tt
    where   sc.branch_code = br.branch_code
    and     br.country_code = @country_code
    and     sc.agency_deal = 'Y'
    and     sc.agency_id = vc.vm_customer_id
    and     vc.customer_type = 'A'
    and     sc.campaign_no = st.campaign_no
    and     st.tran_type = tt.trantype_id
    and		ta.from_tran_id = st.tran_id
    and     st.accounting_period < @accounting_period
    and     st.tran_category ='D'
    and     sc.is_closed = 'N' -- ***** TEMP REMOVE
    UNION
    select  vc.accpac_customer_id,
            convert(char(10),'S' + convert(varchar(9),st.tran_id)),
            'S' + convert(varchar(9),ta.to_tran_id) as invoice_tran_id, 
            st.campaign_no,
            st.tran_date,
            @accounting_period,
            tt.gl_code,
            sc.name_on_slide,
            st.tran_desc,
            ta.gross_amount,
            ta.gst_amount,
            tt.trantype_code,
            @interface_status_new,
            @country_code
    from    slide_campaign sc,
            branch br,
            slide_transaction st,
            slide_allocation ta,
            v_accpac_customer vc,
            transaction_type tt
    where   sc.branch_code = br.branch_code
    and     br.country_code = @country_code
    and     sc.agency_deal = 'N'
    and     sc.client_id = vc.vm_customer_id
    and     vc.customer_type = 'C'
    and     sc.campaign_no = st.campaign_no
    and     st.tran_type = tt.trantype_id
    and		ta.from_tran_id = st.tran_id
    and     st.accounting_period < @accounting_period
    and     st.tran_category = 'D'
    and     sc.is_closed = 'N' -- ***** TEMP REMOVE
    if @@error != 0
        goto rollbackerror

commit transaction

--exec @error = p_dw_exit_process @proc_name

return 0

rollbackerror:
    rollback transaction
error:
    if @error >= 50000
        raiserror (@err_msg, 16, 1)

--    exec @error = p_dw_exit_process @proc_name,@status_failed


    return -1
GO
