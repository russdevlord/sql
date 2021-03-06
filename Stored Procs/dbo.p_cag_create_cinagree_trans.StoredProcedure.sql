/****** Object:  StoredProcedure [dbo].[p_cag_create_cinagree_trans]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_create_cinagree_trans]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_create_cinagree_trans]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_create_cinagree_trans]     @cinema_agreement_id    int,
                                            @accounting_period      datetime

as
/* Proc name:   p_cag_create_cinagree_trans
 * Author:      Grant Carlson
 * Date:        2/10/2003
 * Description: Creates transactions based on records from cinema_agreement_revenue
 *              that have not been processed.
 *
 * Changes: 28/1/2004 GC, REDUNDANT PROC - MOVED CODE TO p_cag_process_cinagree
*/                              
declare @proc_name varchar(30)
select @proc_name = 'p_cag_create_cinagree_trans'

declare @error        				int,
        @err_msg                    varchar(150),
       -- @error                         int,
        @agreement_type             char(1),
        @tmp_id                     int

exec p_audit_proc @proc_name,'start'

select @error = 0

select  @agreement_type = agreement_type
from    cinema_agreement
where   cinema_agreement_id = @cinema_agreement_id

begin transaction
    exec @error = p_cag_create_tran_entitlement   @cinema_agreement_id, @accounting_period, @agreement_type, null,@tmp_id OUTPUT
    if @error = -1 goto error

    exec @error = p_cag_create_tran_payments   @cinema_agreement_id, @accounting_period
    if @error = -1 goto error    

    if @agreement_type = 'M'
    begin
        exec @error = p_cag_create_overage_entitle   @cinema_agreement_id, @accounting_period, @agreement_type
        if @error = -1 goto error
        
        exec @error = p_cag_create_overage_payment   @cinema_agreement_id, @accounting_period, 'Y'
        if @error = -1 goto error
    end

commit transaction

exec p_audit_proc @proc_name,'end'

return 0

rollbackerror:
    rollback transaction
error:
    if @error >= 50000
        raiserror (@err_msg, 16, 1)

    return -1
GO
