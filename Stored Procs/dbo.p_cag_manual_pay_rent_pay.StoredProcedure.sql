/****** Object:  StoredProcedure [dbo].[p_cag_manual_pay_rent_pay]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_manual_pay_rent_pay]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_manual_pay_rent_pay]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_manual_pay_rent_pay]       @cinema_agreement_id    int,
                                            @accounting_period      datetime,
                                            @cag_entitlement_tran_id    int,
                                            @payment_type_code           char(1),
                                            @payment_status_code         char(1),
                                            @payment_method_code         char(1),
                                            @payment_date                datetime,
                                            @payee                       varchar(50),
                                            @payment_desc                varchar(255),
                                            @acct_bsb                    char(6),
                                            @acct_number                 varchar(20),
                                            @acct_ref                    varchar(30),
                                            @payment_no                  int,
                                            @payment_presented           char(1)
                                           
as
/* Proc name:   p_cag_manual_pay_rent_pay
 * Author:      Grant Carlson
 * Date:        17/3/2004
 * Description: Used for creating manual payments.
 *
 * Part of a 3-phase creation process:
 *
 * p_cag_manual_pay_main_ins:  Creates Entitlement Transaction record,
 *                              passes back entitlement tran_id
 * p_cag_manual_pay_main_upd:  Used to update existing payments
 *               
 * p_cag_manual_pay_alloc_upd: When first called (INS) creates entitlement records adds FK
 *                              using entitlement tran_id from p_cag_manual_pay_main_ins.
 *                              UPD mode updates entitlement records
 *
 * p_cag_manual_pay_alloc_del: Deletes / updates entitlement records and deletes allocation records
 *               
 * p_cag_manual_pay_rent_pay:  Creates rent payment records  
 *              
 *
 * Changes:
*/                              
declare @proc_name varchar(30)
select @proc_name = 'p_cag_manual_pay_rent_pay'

declare @error        				int,
        @err_msg                    varchar(150),
       -- @error                         int,
        @tran_status_cancelled          char(1),
        @revenue_source_adjustment  char(1),
        @trantype_desc              varchar(255),
        @tran_category              char(1),
        @tran_status_processed      char(1),
        @tran_status_hold      char(1),
        @tran_status_pending      char(1),
        @allocation_tran_id         int,
        @entitlement_amount         money,
        @payment_amount             money,
        @agreement_type             char(1),
        @cag_entitlement_id         int,
        @creation_date       datetime,
        @process_period      datetime,
        @trantype_id            int,
        @currency_code       char(3),
        @tran_date           datetime,
        @nett_amount         money,
        @gst_rate            numeric(6,4),
        @gst_amount          money,
        @gross_amount        money,
        @show_on_statement   char(1),
        @tran_subdesc        varchar(255),
        @rent_payment_id     int,
        @payment_tran_id     int
        

exec p_audit_proc @proc_name,'start'

select  @error = 0,
        @creation_date = getdate(),
        @tran_status_cancelled = 'X',
        @revenue_source_adjustment = 'A',
        @tran_status_processed = 'P',
        @tran_status_hold = 'H',
        @tran_status_pending = 'D'
        
select  @agreement_type = agreement_type
from    cinema_agreement
where   cinema_agreement_id = @cinema_agreement_id

begin transaction
        
    select  @process_period = process_period,
	        @currency_code = currency_code,
	        @tran_date = tran_date,
	        @nett_amount = nett_amount,
	        @gst_rate = gst_rate,
	        @gst_amount = gst_amount,
	        @gross_amount = gross_amount,
	        @show_on_statement = show_on_statement
    from    cinema_agreement_transaction
    where   tran_id = @cag_entitlement_tran_id

    select @tran_category = 'J' -- payment adjustment
    exec @error = p_cag_cinagree_get_trantype  null,
                                            @tran_category,
                                            @revenue_source_adjustment,
                                            @trantype_id OUTPUT,
                                            @trantype_desc OUTPUT


    select  @payment_status_code = 'D',
            @payment_presented = 'N'

    exec @error =  p_cag_create_payment   @cinema_agreement_id,
                                       @accounting_period,
                                       @process_period,
                                       @trantype_id,
                                       @currency_code,
                                       @trantype_desc,
                                       @tran_subdesc,
                                       @tran_date,
                                       @nett_amount,
                                       @gst_rate,
                                       @gst_amount,
                                       @gross_amount,
                                       @show_on_statement,
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
    where   entitlement_tran_id = @cag_entitlement_tran_id
    select @error = @@error
    if @error <> 0
        goto rollbackerror

    update  cinema_agreement_transaction
    set     process_period = @process_period,
            show_on_statement = @show_on_statement,
            transaction_status_code = @tran_status_processed,
            tran_date = @tran_date
    where   tran_id = @cag_entitlement_tran_id
    select @error = @@error
    if @error <> 0
        goto rollbackerror

    update  cinema_agreement_transaction
    set     process_period = @accounting_period
    where   tran_id = @payment_tran_id
    select @error = @@error
    if @error <> 0
        goto rollbackerror
                    
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
