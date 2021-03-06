/****** Object:  StoredProcedure [dbo].[p_cag_eom_pre_processing]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_eom_pre_processing]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_eom_pre_processing]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_eom_pre_processing]    @accounting_period    datetime,
                                        @cinema_agreement_id  int = null
as
/* Proc name:   p_cag_eom_pre_processing
 * Author:      Grant Carlson
 * Date:        3/2/2004
 * Description: Manages agreement and policy status codes
 *
 * Changes: 
 *
*/ 

declare @proc_name varchar(30)
select  @proc_name = 'p_cag_eom_pre_processing'

exec p_audit_proc @proc_name,'start'

declare @error        				int,
        @err_msg                    varchar(150)
     

begin transaction

    /* Close any agreements and policies that have passed their processing_end date */
    exec @error = p_cag_close_agreements   'T',
                                        @accounting_period,
                                        @cinema_agreement_id
    if @error != 0
        goto rollbackerror

    /* Activate policies that have reached their processing start period */
    update  cinema_agreement_policy
    set     cinema_agreement_policy.policy_status_code = 'A',
            cinema_agreement_policy.active_flag = 'Y'
    where   cinema_agreement_policy.processing_start_date <= @accounting_period
    and     cinema_agreement_policy.policy_status_code = 'N' -- New Policies
    and     ((  cinema_agreement_policy.cinema_agreement_id = @cinema_agreement_id) 
            OR (@cinema_agreement_id is null))
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
