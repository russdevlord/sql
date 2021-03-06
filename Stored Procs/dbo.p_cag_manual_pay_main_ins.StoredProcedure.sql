/****** Object:  StoredProcedure [dbo].[p_cag_manual_pay_main_ins]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_manual_pay_main_ins]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_manual_pay_main_ins]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_manual_pay_main_ins]      @cinema_agreement_id     int,
                                           @accounting_period       datetime,
                                           @process_period          datetime,
                                           @currency_code           char(3),
                                           @tran_subdesc            varchar(255),
                                           @tran_date               datetime,
                                           @nett_amount             money,
                                           @gst_rate                numeric(6,4),
                                           @gst_amount              money,
                                           @gross_amount            money,
                                           @show_on_statement       char(1),
                                           @entitlement_tran_id     int OUTPUT

as
/* Proc name:   p_cag_manual_pay_main_ins
 * Author:      Grant Carlson
 * Date:        17/3/2004
 * Description: Used for creating manual payments.
 *
 * Part of a 3-phase creation process:
 *
 * p_cag_manual_pay_main_ins:  Creates Entitlement Transaction record,
 *                              passes back entitlement tran_id (@entitlement_tran_id)
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
 * Changes:
 *
*/                              



declare @proc_name varchar(30)
select @proc_name = 'p_cag_manual_pay_main_ins'

declare @error        				int,
        @err_msg                    varchar(150),
        --@error                         int,
        @revenue_source_adjustment  char(1),
        @tran_category              char(1),
        @tran_status_pending        char(1),
        @allocation_tran_id         int,
        @agreement_type             char(1),
        @trantype_id                int,
        @tran_desc                  varchar(255)
        
exec p_audit_proc @proc_name,'start'

select  @error = 0,
        @revenue_source_adjustment = 'A',
        @tran_status_pending = 'D',
        @tran_category = 'A' -- entitlement adjustment
        
select  @agreement_type = agreement_type
from    cinema_agreement
where   cinema_agreement_id = @cinema_agreement_id

begin transaction

--        exec p_sfin_format_date @csr_origin_period, 2, @origin_period_str OUTPUT
--        select @tran_desc = @tran_desc + ' (' + @origin_period_str + ')'

    exec @error = p_cag_cinagree_get_trantype  @agreement_type,
                                            @tran_category,
                                            @revenue_source_adjustment,
                                            @trantype_id OUTPUT,
                                            @tran_desc OUTPUT
    if @error = -1
        goto rollbackerror


    exec @error = p_cag_cinagree_trans_ins @cinema_agreement_id,
                                        @trantype_id,
                                        @process_period,
                                        @accounting_period,
                                        @tran_date,
                                        @show_on_statement,
                                        @currency_code,
                                        @nett_amount,
                                        @gst_rate,
                                        @gst_amount,
                                        @gross_amount,
                                        @tran_desc,
                                        @tran_subdesc,
                                        @tran_status_pending,
                    @entitlement_tran_id OUTPUT

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
                @entitlement_tran_id, 
                null, 
                @revenue_source_adjustment,
                @accounting_period, 
                @tran_date)
    select @error = @@error
    if @error != 0
    begin
        goto rollbackerror
    end

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
