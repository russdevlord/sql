/****** Object:  StoredProcedure [dbo].[p_cag_create_overage_entitle]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_create_overage_entitle]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_create_overage_entitle]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_create_overage_entitle]    @cinema_agreement_id    int,
                                            @accounting_period      datetime,
                                            @agreement_type         char(1)

--with recompile 
as
/* Proc name:   p_cag_create_overage_entitle
 * Author:      Grant Carlson
 * Date:        15/12/2003
 * Description: Creates overage entitlement transactions. Grouping is done by accounting period.
 *
 * Changes:
*/                              
declare @proc_name varchar(30)
select @proc_name = 'p_cag_create_overage_entitle'

declare @error        				int,
        @err_msg                    varchar(150),
        --@error                         int,
        @trantype_id                int,
        @tran_id                    int,
        @tran_date                  datetime,
        @tran_desc                  varchar(255),
        @tran_sub_desc              varchar(255),
        @tran_category              char(1),
        @csr_accounting_period      datetime,
        @csr_currency_code          char(3),
        @allocation_tran_id         int,
        @guarantee_amt              money,
        @variable_amt               money,
        @overage_amt                money,
        @status_on_hold             char(1)

exec p_audit_proc @proc_name,'start'
        
select  @tran_date = getdate(),
        @error = 0,
        @status_on_hold = 'H'

      
declare entitlements_csr cursor static for
select  cae.accounting_period,
        cae.currency_code
from    cinema_agreement_entitlement cae
where   cae.cinema_agreement_id = @cinema_agreement_id
and     cae.tran_id is null
and     cae.excess_status = 1
group by cae.accounting_period,
         cae.currency_code
order by cae.accounting_period,
         cae.currency_code
for read only

begin transaction
    open entitlements_csr
    fetch entitlements_csr into @csr_accounting_period, @csr_currency_code
    while @@fetch_status = 0
    begin

        select  @guarantee_amt = isnull(sum(cae.nett_amount),0)
        from    cinema_agreement_entitlement cae
        where   cae.cinema_agreement_id = @cinema_agreement_id
        and     cae.accounting_period = @csr_accounting_period
        and     cae.currency_code = @csr_currency_code
        and     cae.tran_id is not null
        and     cae.revenue_source = 'P'
        and     cae.excess_status = 0
     
        select  @variable_amt = isnull(sum(cae.nett_amount),0)
        from    cinema_agreement_entitlement cae
        where   cae.cinema_agreement_id = @cinema_agreement_id
        and     cae.accounting_period = @csr_accounting_period
        and     cae.currency_code = @csr_currency_code
        and     cae.tran_id is null
        and     cae.excess_status = 1

        select @overage_amt = @variable_amt - @guarantee_amt

        select @tran_category = 'M'
        exec @error = p_cag_cinagree_get_trantype  @agreement_type,
                                                @tran_category,
                                                'P',
                                                @trantype_id OUTPUT,
                                                @tran_desc OUTPUT
        if @error = -1
            goto rollbackerror

        select @tran_sub_desc = ''

        exec @error = p_cag_cinagree_trans_ins @cinema_agreement_id,
                                            @trantype_id,
                                            @csr_accounting_period,
                                            null,
                                            @tran_date,
                                            'N',
                                            @csr_currency_code,
                                            @overage_amt,
                                            null,
                                            null,
                                            null,
                                            @tran_desc,
                                            @tran_sub_desc,
                                            @status_on_hold,
                                            @tran_id OUTPUT

        if @error = -1
            goto rollbackerror

        exec @error = p_get_sequence_number 'cinema_rent_payment_allocation', 5, @allocation_tran_id OUTPUT
        if @error = -1
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
                    'P',
                    @accounting_period, 
                    getdate())
        select @error = @@error
        if @error != 0
        begin
            goto rollbackerror
        end
    
        update  cinema_agreement_entitlement
        set     tran_id = @tran_id
        where   cinema_agreement_id = @cinema_agreement_id
        and     accounting_period = @csr_accounting_period
        and     currency_code = @csr_currency_code
        and     tran_id is null
        and     excess_status = 1
        if @@error != 0
            goto rollbackerror
        
        fetch entitlements_csr into @csr_accounting_period, @csr_currency_code
    end --while

commit transaction

deallocate entitlements_csr

exec p_audit_proc @proc_name,'end'

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
