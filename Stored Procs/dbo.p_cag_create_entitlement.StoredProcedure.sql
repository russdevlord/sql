/****** Object:  StoredProcedure [dbo].[p_cag_create_entitlement]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_create_entitlement]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_create_entitlement]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_create_entitlement]    @cinema_agreement_id    int,
                                        @complex_id             int,
                                        @revenue_source         char(1),
                                        @policy_id              int,
                                        @accounting_period		datetime,
                                        @origin_period          datetime,
                                        @agreement_type         char(1),
                                        @rent_mode              char(1),
                                        @cag_currency_code      char(3),
                                        @entitlement_adjustment money

--with recompile 
as
/* Proc name:   p_cag_create_entitlement
 * Author:      Grant Carlson
 * Date:        3/12/2003
 * Description: Creates entitlement records in cinema_agreement_entitlement by applying
 *              policies to records in cinema_agreement_revenue
 *
 * Changes:
*/                              
declare @proc_name varchar(30)
select @proc_name = 'p_cag_create_entitlement'

declare @error        				int,
        @err_msg                    varchar(150),
        --@error                         int,
        @business_unit_id           smallint,
        @tran_nett_amount           money,
        @origin_currency_amt        money,
        @var_tran_nett_amount       money,
        @var_origin_currency_amt    money,
        @xs_tran_nett_amount        money,
        @xs_origin_currency_amt     money,
        @trantype_id                int,
        @tran_process_period        datetime,
        @tran_id                    int,
        @tran_date                  datetime,
        @tran_desc                  varchar(255),
        @tran_sub_desc              varchar(255),
        @tran_category              char(1),
        @fixed_amount               money,
        @csr_revenue_source         char(1),
        @csr_trans_nett_amount      money,
        @revenue_currency_code      char(3),
        @string_currency            varchar(30),
        @allocation_tran_id         int,
        @cag_entitlement_id         int,
        @excess_status              tinyint,
        @revenue_source_adjustment  char(1),
        @business_unit_fixed_rent   smallint

exec p_audit_proc @proc_name,'start'
        
select  @tran_date = getdate(),
        @error = 0,
        @revenue_source_adjustment = 'A',
        @business_unit_fixed_rent = 4

declare cinagree_revenue_sel_csr cursor static for
select  cr.currency_code,
        cr.business_unit_id,
        cr.excess_status
from    cinema_agreement_revenue cr, liability_type lt, liability_category lc, liability_category_rent_xref lcrx
where   cr.cag_entitlement_id is null
and     cr.release_period is null
and     cr.cinema_agreement_id = @cinema_agreement_id
and     cr.complex_id = @complex_id
and     cr.origin_period = @origin_period
and     cr.revenue_source = @revenue_source
and     cr.liability_type_id = lt.liability_type_id
and     lt.liability_category_id = lc.liability_category_id
and     lcrx.liability_category_id = lc.liability_category_id
and     lcrx.rent_mode = @rent_mode
group by cr.currency_code,
         cr.business_unit_id,
         cr.excess_status
for read only

begin transaction

    open cinagree_revenue_sel_csr
    fetch cinagree_revenue_sel_csr into @revenue_currency_code, @business_unit_id, @excess_status
    while (@@fetch_status = 0)
    begin
        select  @tran_nett_amount = null,
                @origin_currency_amt = null

        select  @tran_nett_amount = (sum(er.conversion_rate * cr.cinema_amount * cr.percentage_entitlement * ((1.0*cr.agreement_days) / (1.0*cr.period_days)))),
                @origin_currency_amt = (sum(cr.cinema_amount * cr.percentage_entitlement * ((1.0*cr.agreement_days) / (1.0*cr.period_days))))
        from    cinema_agreement_revenue cr, cinema_agreement ca, exchange_rates er, liability_type lt, liability_category lc, liability_category_rent_xref lcrx
        where   cr.cinema_agreement_id = @cinema_agreement_id
        and     cr.complex_id = @complex_id 
        and     cr.cinema_agreement_id = ca.cinema_agreement_id
        and     cr.revenue_source = @revenue_source
        and     cr.business_unit_id = @business_unit_id
        and     cr.origin_period = @origin_period
        and     cr.cag_entitlement_id is null
        and     cr.release_period is null
        and     cr.excess_status = @excess_status
        and     cr.currency_code = @revenue_currency_code
        and     cr.currency_code = er.currency_code_from
        and     ca.currency_code = er.currency_code_to
        and     er.accounting_period = @accounting_period
        and     cr.liability_type_id = lt.liability_type_id
        and     lt.liability_category_id = lc.liability_category_id
        and     lcrx.liability_category_id = lc.liability_category_id
        and     lcrx.rent_mode = @rent_mode

        if @tran_nett_amount is null -- most likely because exchange rate record missing
        begin
            select @err_msg = 'Error calculating @tran_nett_amount. Most likely caused by missing exchange rate for :' + convert(varchar(30),@accounting_period)
            goto rollbackerror
        end        

        if @rent_mode = 'C' or @rent_mode = 'S' -- collections/payments have a negative sign so must reverse
            select  @tran_nett_amount = -1.0 * @tran_nett_amount,
                    @origin_currency_amt = -1.0 * @origin_currency_amt

        execute @error = p_get_sequence_number 'cinema_agreement_entitlement', 5, @cag_entitlement_id OUTPUT
        if @error = -1
            goto rollbackerror

        insert cinema_agreement_entitlement(
                cag_entitlement_id,
                cinema_agreement_id,
                complex_id,
                accounting_period,
                origin_period,
                revenue_source,
                business_unit_id,
                currency_code,
                origin_currency_code,
                tran_id,
                origin_currency_amt,
                nett_amount,
                excess_status)
        values( @cag_entitlement_id,
                @cinema_agreement_id,
                @complex_id,
                @accounting_period,
                @origin_period,
                @revenue_source,
                @business_unit_id,
                @cag_currency_code,
                @revenue_currency_code,
                null,
                @origin_currency_amt,
                @tran_nett_amount,
                @excess_status)

        select @error = @@error
        if @error != 0
            goto rollbackerror


        /* update the entitlement tran id on all records just processed */
        update  cinema_agreement_revenue
        set     cinema_agreement_revenue.cag_entitlement_id = @cag_entitlement_id
        from    liability_type lt, liability_category lc, liability_category_rent_xref lcrx
        where   cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and     cinema_agreement_revenue.complex_id = @complex_id 
        and     cinema_agreement_revenue.revenue_source = @revenue_source
        and     cinema_agreement_revenue.business_unit_id = @business_unit_id
        and     cinema_agreement_revenue.origin_period = @origin_period
        and     cinema_agreement_revenue.currency_code = @revenue_currency_code
        and     cinema_agreement_revenue.cag_entitlement_id is null
        and     cinema_agreement_revenue.release_period is null
        and     cinema_agreement_revenue.excess_status = @excess_status
        and     cinema_agreement_revenue.liability_type_id = lt.liability_type_id
        and     lt.liability_category_id = lc.liability_category_id
        and     lcrx.liability_category_id = lc.liability_category_id
        and     lcrx.rent_mode = @rent_mode
        select @error = @@error
        if @error != 0
            goto rollbackerror

        fetch cinagree_revenue_sel_csr into @revenue_currency_code, @business_unit_id, @excess_status
    end --while cinagree_revenue_sel_csr
    
    /* update the release date on all records just processed */
    update  cinema_agreement_revenue
    set     release_period = @accounting_period
    where   cinema_agreement_id = @cinema_agreement_id
    and     origin_period = @origin_period
    and     revenue_source = @revenue_source
    and     complex_id = @complex_id 
    and     release_period is null
    select @error = @@error
    if @error != 0
        goto rollbackerror
   
    if (@entitlement_adjustment <> 0 AND @accounting_period = @origin_period)
    begin
        execute @error = p_get_sequence_number 'cinema_agreement_entitlement', 5, @cag_entitlement_id OUTPUT
        if @error = -1
            goto rollbackerror
        
        select  @business_unit_id = null
        select  @business_unit_id = bu.business_unit_id
        from    business_unit bu, media_product mp
        where   bu.primary_media_product = mp.media_product_id
        and     mp.revenue_source = @revenue_source

        if @business_unit_id is null or @@rowcount = 0
            select @business_unit_id = @business_unit_fixed_rent
        
        insert cinema_agreement_entitlement(
                cag_entitlement_id,
                cinema_agreement_id,
                complex_id,
                accounting_period,
                origin_period,
                revenue_source,
                business_unit_id,
                currency_code,
                origin_currency_code,
                tran_id,
                origin_currency_amt,
                nett_amount,
                excess_status)
        values( @cag_entitlement_id,
                @cinema_agreement_id,
                @complex_id,
                @accounting_period,
                @accounting_period,
                @revenue_source_adjustment,
                @business_unit_id,
                @cag_currency_code,
                @cag_currency_code,
                null,
                @entitlement_adjustment,
                @entitlement_adjustment,
                0)
        select @error = @@error
        if @error != 0
            goto rollbackerror
                
    end


commit transaction

deallocate cinagree_revenue_sel_csr

exec p_audit_proc @proc_name,'end'
    
return 0


rollbackerror:
    rollback transaction

error:

    deallocate cinagree_revenue_sel_csr
        
    if @error >= 50000
    begin
        select @err_msg = @proc_name + ': ' + @err_msg
        raiserror (@err_msg, 16, 1)
    end

    return -1
GO
