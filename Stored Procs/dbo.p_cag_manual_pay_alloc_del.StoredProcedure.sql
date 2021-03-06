/****** Object:  StoredProcedure [dbo].[p_cag_manual_pay_alloc_del]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_manual_pay_alloc_del]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_manual_pay_alloc_del]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_manual_pay_alloc_del]     @cinema_agreement_id int,
                                           @accounting_period   datetime,
                                           @cag_entitlement_id  int                              
                                   

as
/* Proc name:   p_cag_manual_pay_alloc_del
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
select  @proc_name = 'p_cag_manual_pay_alloc_del'

declare @error        				int,
        @err_msg                    varchar(150)
        

exec p_audit_proc @proc_name,'start'

begin transaction

        delete  cinema_agreement_entitlement
        where   cinema_agreement_id = @cinema_agreement_id
        and     cag_entitlement_id = @cag_entitlement_id
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
