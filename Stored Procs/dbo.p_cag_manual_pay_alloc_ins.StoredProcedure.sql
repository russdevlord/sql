/****** Object:  StoredProcedure [dbo].[p_cag_manual_pay_alloc_ins]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_manual_pay_alloc_ins]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_manual_pay_alloc_ins]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_cag_manual_pay_alloc_ins]      @cinema_agreement_id    int,
                                            @accounting_period      datetime,
                                            @entitlement_tran_id    int,
                                            @origin_period          datetime,
                                            @currency_code          char(3),
                                            @business_unit_id       int,
                                            @nett_amount            money,
											@complex_id				int                                   
                                   

as
/* Proc name:   p_cag_manual_pay_alloc_ins
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
 * p_cag_manual_pay_alloc_ins: When first called (INS) creates entitlement records adds FK
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
select  @proc_name = 'p_cag_manual_pay_alloc_ins'

declare @error        				int,
        @err_msg                    varchar(150),
       -- @error                         int,
        @revenue_source_adjustment  char(1),
        @cag_entitlement_id         int
        

exec p_audit_proc @proc_name,'start'

select  @error = 0,
        @revenue_source_adjustment = 'A'

if @cinema_agreement_id is null
    select  @cinema_agreement_id = cinema_agreement_id,
            @accounting_period = accounting_period,
            @origin_period = process_period,
            @currency_code = currency_code
    from    cinema_agreement_transaction
    where   tran_id = @entitlement_tran_id

begin transaction

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
            @revenue_source_adjustment,
            @business_unit_id,
            @currency_code,
            @currency_code,
            @entitlement_tran_id,
            @nett_amount,
            @nett_amount,
            0)

    select @error = @@error
    if @error != 0
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
