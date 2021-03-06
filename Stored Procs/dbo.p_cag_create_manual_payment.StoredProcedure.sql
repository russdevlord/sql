/****** Object:  StoredProcedure [dbo].[p_cag_create_manual_payment]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_create_manual_payment]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_create_manual_payment]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_create_manual_payment]    @cinema_agreement_id    int,
                                           @accounting_period      datetime,
                                           @process_period      datetime,
                                           @trantype_id            int,
                                           @business_unit_id        int,
                                           @pay_now             char(1),
                                           @currency_code       char(3),
                                           @tran_desc           varchar(255),
                                           @tran_subdesc        varchar(255),
                                           @tran_date           datetime,
                                           @nett_amount         money,
                                           @gst_rate            numeric(6,4),
                                           @gst_amount          money,
                                           @gross_amount        money,
                                           @show_on_statement   char(1),
                                           @payment_type_code   char(1),
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
                                           @transaction_status  char(1) = 'P',
                                           @rent_payment_id     int = null OUTPUT,
                                           @payment_tran_id     int = null OUTPUT
                                   
                                   

as
/* Proc name:   p_cag_create_manual_payment
 * Author:      Grant Carlson
 * Date:        16/1/2004
 * Description: Used for creating manual payments.
 * Creates an entitlement, payment transaction record and cinema_rent_payment record
 *              
 *
 * Changes:
*/                              
declare @proc_name varchar(30)
select @proc_name = 'p_cag_create_manual_payment'

declare @error        				int,
        @err_msg                    varchar(150),
        --@error                         int,
        @tran_status_cancelled          char(1),
        @revenue_source_adjustment  char(1),
        @trantype_desc              varchar(255),
        @entitlement_tran_id        int,
        @tran_category              char(1),
        @tran_status_processed      char(1),
        @tran_status_hold      char(1),
        @tran_status_pending      char(1),
        @allocation_tran_id         int,
        @entitlement_amount         money,
        @payment_amount             money,
        @agreement_type             char(1),
        @cag_entitlement_id         int
        
        
        

exec p_audit_proc @proc_name,'start'

select  @error = 0,
        @tran_status_cancelled = 'X',
        @revenue_source_adjustment = 'A',
        @tran_status_processed = 'P',
        @tran_status_hold = 'H',
        @tran_status_pending = 'D'
        
select  @agreement_type = agreement_type
from    cinema_agreement
where   cinema_agreement_id = @cinema_agreement_id

begin transaction

--     if @nett_amount > 0 -- payments must be -ve, calling procs ensure that -ve payments don't come through here
--         select @nett_amount = -1.0 * @nett_amount
        
    select  @entitlement_amount = @nett_amount,
            @payment_amount = -1.0 * @nett_amount


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
            null,
            @accounting_period,
            @accounting_period,
            @revenue_source_adjustment,
            @business_unit_id,
            @currency_code,
            @currency_code,
            null,
            @entitlement_amount,
            @entitlement_amount,
            0)

    select @error = @@error
    if @error != 0
        goto rollbackerror


    /* Create Entitlement Transaction */
    exec @error = p_cag_create_tran_entitlement    @cinema_agreement_id,
                                                @accounting_period,
                                                @agreement_type,
                                                @cag_entitlement_id,
                                                @entitlement_tran_id OUTPUT
    if @error = -1
        goto rollbackerror

    update  cinema_agreement_transaction
    set     tran_subdesc = @tran_subdesc,
            tran_date = @tran_date
    where   tran_id = @entitlement_tran_id
    select @error = @@error
    if @error != 0
        goto rollbackerror

    if @pay_now = 'Y'
    begin
        /* Create Payment */
        select @tran_category = 'J' -- payment adjustment
        exec @error = p_cag_cinagree_get_trantype  null,
                                                @tran_category,
                                                @revenue_source_adjustment,
                                                @trantype_id OUTPUT,
                                                @trantype_desc OUTPUT


                select  @payment_desc = @trantype_desc
            
                select  @payment_status_code = 'D',
                        @payment_presented = 'N'

                exec @error =  p_cag_create_payment   @cinema_agreement_id,
                                                   @accounting_period,
                                                   @process_period,
                                                   @trantype_id,
                                                   @currency_code,
                                                   @trantype_desc,
                                                   null,
                                                   @tran_date,
                                                   @payment_amount,
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
                where   entitlement_tran_id = @entitlement_tran_id
                select @error = @@error
                if @error <> 0
                    goto rollbackerror

                update  cinema_agreement_transaction
                set     process_period = @accounting_period,
                        show_on_statement = 'Y',
                        transaction_status_code = @tran_status_processed,
                        tran_date = @tran_date
                where   tran_id = @entitlement_tran_id
                select @error = @@error
                if @error <> 0
                    goto rollbackerror

                update  cinema_agreement_transaction
                set     process_period = @accounting_period
                where   tran_id = @payment_tran_id
                select @error = @@error
                if @error <> 0
                    goto rollbackerror
                    
            end --create payment now

commit transaction

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
