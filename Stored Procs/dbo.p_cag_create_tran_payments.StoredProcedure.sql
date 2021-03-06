/****** Object:  StoredProcedure [dbo].[p_cag_create_tran_payments]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_create_tran_payments]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_create_tran_payments]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_create_tran_payments]   @cinema_agreement_id    int,
                                         @accounting_period      datetime

--with recompile 
as
/* Proc name:   p_cag_create_tran_payments
 * Author:      Grant Carlson
 * Date:        2/10/2003
 * Description: Creates payments based on entitlements
 *              that have not been processed. Excludes overage
 *              entitlements, these are paid using p_cag_create_overage_payment
 *
 * Changes:
*/                              
declare @proc_name varchar(30)
select @proc_name = 'p_cag_create_tran_payments'

declare @error        		 int,
        @err_msg             varchar(150),
        --@error                  int,
        @process_period      datetime,
        @revenue_source      char(1),
        @trantype_id         int,
        @currency_code       char(3),
        @rent_payment_id     int,
        @payment_tran_id     int,
        @tran_desc           varchar(255),
        @tran_subdesc        varchar(255),
        @tran_date           datetime,
        @nett_amount         money,
        @gst_rate            numeric(6,4),
        @gst_amount          money,
        @gross_amount        money,
        @show_on_statement   char(1),
        @payment_status_code char(1),
        @payment_method_code char(1),
        @payment_date        datetime,
        @payee               varchar(50),
        @payment_desc        varchar(255),
        @acct_bsb            char(6),
        @acct_number         varchar(20),
        @acct_ref            varchar(30),
        @payment_no          int,
        @payment_presented   char(1),
        @creation_date       datetime,
        @30day_accounting_period		datetime,
        @60day_accounting_period		datetime,
        @payment_type_code          char(1),
        @standard_payment_cycle     smallint,
        @next_standard_payment_due  datetime,
        @excess_payment_cycle       smallint,
        @next_excess_payment_due    datetime,
        @payment_cycle_months       tinyint,
        @generate_payments           char(1),
        @entitlements_exist          char(1),
        @excess_status               tinyint,
        @create_standard_payment     char(1),
        @tran_category               char(1),
        @tran_category_reg_pay       char(1),
        @tran_category_overage_pay   char(1),
        @cancel_transaction          char(1),
        @trantype_excess_entitlement int,
        @tran_status_cancelled          char(1),
        @tran_status_processed          char(1),
        @tran_status_hold               char(1),
        @tran_status_pending            char(1),
        @agreement_type                 char(1),
        @rows int

exec p_audit_proc @proc_name,'start'

exec @error = p_get_next_accounting_period @accounting_period, 1, @30day_accounting_period OUTPUT
if @error = -1 return -1
exec @error = p_get_next_accounting_period @accounting_period, 2, @60day_accounting_period OUTPUT
if @error = -1 return -1

select  @tran_category_reg_pay = 'P',
        @tran_category_overage_pay = 'X',
        @error = 0,
        @entitlements_exist = 'N',
        @trantype_excess_entitlement = null,
        @tran_status_cancelled = 'X',
        @tran_status_processed = 'P',
        @tran_status_hold = 'H',
        @tran_status_pending = 'D',
        @revenue_source = 'X' -- not required



select  @trantype_excess_entitlement = trantype_id
from    transaction_type
where   trantype_code = 'CAGEE'
if @@rowcount = 0 or @trantype_excess_entitlement is null
begin
 	select @err_msg =  'Could not find trantype CAGEE in transaction_type table .'
    goto error
end

select  @agreement_type = agreement_type,
        @currency_code = currency_code,
        @payment_method_code = payment_method_code,
        @payment_type_code = payment_type_code,
        @standard_payment_cycle = standard_payment_cycle,
        @generate_payments = generate_payments,
        @next_standard_payment_due = isnull(next_standard_payment_due,@accounting_period),
        @payee = payee,
        @acct_bsb = acct_bsb,
        @acct_number = acct_number
from    cinema_agreement
where   cinema_agreement_id = @cinema_agreement_id

if ((@next_standard_payment_due <= @accounting_period) and (@generate_payments = 'Y'))
begin
    begin transaction
        select  @nett_amount = sum(cat.nett_amount)
        from    cinema_rent_payment_allocation cra, 
                cinema_agreement_transaction cat
        where   cra.payment_tran_id is null
        and     cra.entitlement_tran_id = cat.tran_id
        and     cat.cinema_agreement_id = @cinema_agreement_id
        and     cat.trantype_id != @trantype_excess_entitlement
        and     cat.transaction_status_code = @tran_status_pending

        if @@rowcount > 0
            select @entitlements_exist = 'Y'

        select  @payment_cycle_months = isnull(payment_months,0)
        from    cinema_agreement_payment_cycle
        where   payment_cycle_code = @standard_payment_cycle

        exec @error = p_get_next_accounting_period @accounting_period, @payment_cycle_months, @next_standard_payment_due OUTPUT
        if @error = -1
            goto rollbackerror

        update  cinema_agreement
        set     next_standard_payment_due = @next_standard_payment_due
        where   cinema_agreement_id = @cinema_agreement_id
        select @error = @@error
        if @error <> 0
            goto rollbackerror


        if ((@nett_amount > 0) AND (@entitlements_exist = 'Y'))
        begin
            exec @error = p_cag_cinagree_get_trantype  @agreement_type,
                                                    @tran_category_reg_pay,
                                                    @revenue_source,
                                                    @trantype_id OUTPUT,
                                                    @tran_desc OUTPUT
            if @error = -1
                goto rollbackerror

            select @process_period = 
            case when @payment_type_code = 'D' then @30day_accounting_period
                 when @payment_type_code = 'E' then @accounting_period
                 when @payment_type_code = 'F' then @60day_accounting_period
                 else @accounting_period end

            select @payment_desc = @tran_desc
            
            select  @payment_type_code = 'S', --standard payment
                    @payment_status_code = 'D',
                    @payment_presented = 'N',
                    @tran_date = @accounting_period,
                    @creation_date = getdate()

            exec @error =  p_cag_create_payment   @cinema_agreement_id,
                                               @accounting_period,
                                               @process_period,
                                               @trantype_id,
                                               @currency_code,
                                               @tran_desc,
                                               @tran_subdesc,
                                               @tran_date,
                                               @nett_amount,
                                               null,
                                               null,
                                               null,
                                               'Y',
                                               @payment_type_code,
                                               @payment_status_code,
                                               @payment_method_code,
                                               @payment_date,
                                               @payee,
                                               @payment_desc,
                                               @acct_bsb,
                                               @acct_number,
                                               @acct_ref,
                                               @payment_no,
                                               @payment_presented,
                                               @creation_date,
                                               @tran_status_processed,
                                               @rent_payment_id OUTPUT,
                                               @payment_tran_id OUTPUT
            if @error = -1
                goto rollbackerror

            update  cinema_rent_payment_allocation
            set     payment_tran_id = @payment_tran_id
            from    cinema_rent_payment_allocation cra, 
                    cinema_agreement_transaction cat
            where   cra.payment_tran_id is null
            and     cra.entitlement_tran_id = cat.tran_id
            and     cat.cinema_agreement_id = @cinema_agreement_id
            and     cat.trantype_id != @trantype_excess_entitlement
            and     cat.transaction_status_code = @tran_status_pending
            select @error = @@error
            if @error <> 0
                goto rollbackerror

            update  cinema_agreement_transaction
            set     process_period = @accounting_period,
                    show_on_statement = 'Y',
                    transaction_status_code = @tran_status_processed
            from    cinema_rent_payment_allocation cra
            where   cra.payment_tran_id = @payment_tran_id
            and     cra.entitlement_tran_id = cinema_agreement_transaction.tran_id
            select @error = @@error
            if @error <> 0
                goto rollbackerror

        end--if

    commit transaction

end --if @next_standard_payment_due = @accounting_period

exec p_audit_proc @proc_name,'end'

return 0

rollbackerror:
    rollback transaction
error:
    if @error >= 50000
    begin
        select @err_msg = @proc_name + ': ' + @err_msg
        raiserror (@err_msg, 16, 1)
    end

    return -1
GO
