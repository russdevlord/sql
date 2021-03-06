/****** Object:  StoredProcedure [dbo].[p_cag_create_tran_entitlement]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_create_tran_entitlement]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_create_tran_entitlement]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_create_tran_entitlement]   @cinema_agreement_id    int,
                                            @accounting_period      datetime,
                                            @agreement_type         char(1),
                                            @cag_entitlement_id     int = null,
                                            @entitlement_tran_id        int OUTPUT

--with recompile 
as
/* Proc name:   p_cag_create_tran_entitlement
 * Author:      Grant Carlson
 * Date:        2/10/2003
 * Description: Creates transactions based on records from cinema_agreement_entitlement
 *              that have not been processed. Excess/Overage entitlements handled seperately.
 *              If @cag_entitlement_id is passed then create transaction for that entitlement only.
 *
 * Changes:
*/                              
declare @proc_name varchar(30)
select @proc_name = 'p_cag_create_tran_entitlement'

declare @error        				int,
        @err_msg                    varchar(150),
        --@error                         int,
        @entitlements_csr_open      tinyint,
        @origin_currency_amt        money,
        @trantype_id                int,
        @tran_id                    int,
        @tran_date                  datetime,
        @tran_desc                  varchar(255),
        @tran_sub_desc              varchar(255),
        @tran_category              char(1),
        @csr_revenue_source         char(1),
        @csr_trans_nett_amount      money,
        @csr_origin_period          datetime,
        @origin_currency_code       char(3),
        @currency_code              char(3),
        @string_currency            varchar(30),
        @allocation_tran_id         int,
        @excess_status              tinyint,
        @tran_status_pending        char(1),
        @origin_period_str			varchar(11),
        @revenue_source_adjustment  char(1)
        

exec p_audit_proc @proc_name,'start'
        
select  @tran_date = @accounting_period,
        @error = 0,
        @tran_status_pending = 'D',
        @revenue_source_adjustment = 'A'

if @cag_entitlement_id is null
begin
    if @agreement_type = 'F' -- group by origin period for fixed in advance entitlements
        declare entitlements_csr cursor static for
        select  cae.origin_period,
                cae.revenue_source,
                cae.currency_code,
                cae.origin_currency_code,
                sum(cae.origin_currency_amt),
                sum(cae.nett_amount)
        from    cinema_agreement_entitlement cae
        where   cae.cinema_agreement_id = @cinema_agreement_id
        and     cae.tran_id is null
        and     cae.excess_status = 0
        group by cae.origin_period,
                cae.revenue_source,
                cae.currency_code,
                cae.origin_currency_code
        order by cae.origin_period,
                 cae.revenue_source
        for read only
    else
        declare entitlements_csr cursor static for
        select  cae.accounting_period,
                cae.revenue_source,
                cae.currency_code,
                cae.origin_currency_code,
                sum(cae.origin_currency_amt),
                sum(cae.nett_amount)
        from    cinema_agreement_entitlement cae
        where   cae.cinema_agreement_id = @cinema_agreement_id
        and     cae.tran_id is null
        and     cae.excess_status = 0
        group by cae.accounting_period,
                cae.revenue_source,
                cae.currency_code,
                cae.origin_currency_code
        order by cae.accounting_period,
                 cae.revenue_source
        for read only
end
else
begin
        declare entitlements_csr cursor static for
        select  cae.accounting_period,
                cae.revenue_source,
                cae.currency_code,
                cae.origin_currency_code,
                cae.origin_currency_amt,
                cae.nett_amount
        from    cinema_agreement_entitlement cae
        where   cae.cag_entitlement_id = @cag_entitlement_id
        for read only
end

begin transaction
    open entitlements_csr
    fetch entitlements_csr into @csr_origin_period, 
                                @csr_revenue_source, 
                                @currency_code, 
                                @origin_currency_code,
                                @origin_currency_amt,
                                @csr_trans_nett_amount
    while @@fetch_status = 0
    begin
        if @csr_revenue_source = @revenue_source_adjustment
            select @tran_category = 'A' -- entitlement adjustment
        else
            select @tran_category = 'E' -- stnd entitlement

        exec @error = p_cag_cinagree_get_trantype  @agreement_type,
                                                @tran_category,
                                                @csr_revenue_source,
                                                @trantype_id OUTPUT,
                                                @tran_desc OUTPUT
        if @error = -1
            goto rollbackerror

        exec p_sfin_format_date @csr_origin_period, 2, @origin_period_str OUTPUT
        select @tran_desc = @tran_desc + ' (' + @origin_period_str + ')'

        select @tran_sub_desc = ''
        if @currency_code <> @origin_currency_code -- there has been a currency conversion
        begin
            exec p_currency_to_string @origin_currency_amt, @string_currency OUTPUT
            select @tran_sub_desc = '(Converted from ' + @origin_currency_code + @string_currency + ')'
        end

        exec @error = p_cag_cinagree_trans_ins @cinema_agreement_id,
                                            @trantype_id,
                                            @csr_origin_period,
                                            @accounting_period,
                                            @tran_date,
                                            'Y',
                                            @currency_code,
                                            @csr_trans_nett_amount,
                                            null,
                                            null,
                                            null,
                                            @tran_desc,
                                            @tran_sub_desc,
                                            @tran_status_pending,
                                            @tran_id OUTPUT

        if @error = -1
            goto rollbackerror

        execute @error = p_get_sequence_number 'cinema_rent_payment_allocation', 5, @allocation_tran_id OUTPUT
        if (@error !=0)
            goto rollbackerror

        insert into cinema_rent_payment_allocation(
                    allocation_id,
                    entitlement_tran_id,
                    payment_tran_id,
                    revenue_source,
                    accounting_period,
                    entry_date)
        values (    @allocation_tran_id, 
                    @tran_id, 
                    null, 
                    @csr_revenue_source,
                    @accounting_period, 
                    getdate())
        select @error = @@error
        if @error != 0
        begin
            goto rollbackerror
        end
    
    
        if @cag_entitlement_id is null
        begin
            if @agreement_type = 'F'
            begin
                update  cinema_agreement_entitlement
                set     tran_id = @tran_id
                where   cinema_agreement_id = @cinema_agreement_id
                and     origin_period = @csr_origin_period
                and     revenue_source = @csr_revenue_source
                and     currency_code = @currency_code
                and     origin_currency_code = @origin_currency_code
                and     tran_id is null
                and     excess_status = 0
                if @@error != 0
                    goto rollbackerror
            end
            else
            begin
                update  cinema_agreement_entitlement
                set     tran_id = @tran_id
                where   cinema_agreement_id = @cinema_agreement_id
                and     accounting_period = @csr_origin_period
                and     revenue_source = @csr_revenue_source
                and     currency_code = @currency_code
                and     origin_currency_code = @origin_currency_code
                and     tran_id is null
                and     excess_status = 0
                if @@error != 0
                    goto rollbackerror
            end
        end
        else
        begin
            update  cinema_agreement_entitlement
            set     tran_id = @tran_id
            where   cag_entitlement_id = @cag_entitlement_id
            if @@error != 0
                goto rollbackerror
        end
        
        fetch entitlements_csr into @csr_origin_period, 
                                    @csr_revenue_source, 
                                    @currency_code, 
                                    @origin_currency_code,
                                    @origin_currency_amt,
                                    @csr_trans_nett_amount
    end --while

commit transaction

select  @entitlement_tran_id = @tran_id -- ONLY valid when single tran is created using @cag_entitlement_id

deallocate entitlements_csr

exec p_audit_proc @proc_name,'start'

return 0

rollbackerror:
    rollback transaction

error:
    deallocate entitlements_csr

    if @error >= 50000
    begin
        select @err_msg = @proc_name + ': ' + @err_msg
        raiserror (@err_msg, 16, 1)
    end

    return -1
GO
