/****** Object:  StoredProcedure [dbo].[p_cag_close_agreements]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_close_agreements]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_close_agreements]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_close_agreements]  @mode char(1),
                                    @accounting_period    datetime,
                                    @cinema_agreement_id  int = null
as
/* Proc name:   p_cag_close_agreements
 * Author:      Grant Carlson
 * Date:        3/2/2004
 * Description: Used to close agreements
 *              Modes: F=Force closed, T=Close agreements based their termination date
 *
 * Changes: 
 *
*/ 

declare @proc_name varchar(30)
select @proc_name = 'p_cag_close_agreements'

exec p_audit_proc @proc_name,'start'

declare @error        				int,
        @err_msg                    varchar(150)
     

begin transaction

    /* Close policies if the mode is Force OR past their processing period */
    update  cinema_agreement_policy
    set     cinema_agreement_policy.policy_status_code = 'C',
            cinema_agreement_policy.active_flag = 'N'
    where   
         ((  cinema_agreement_policy.cinema_agreement_id = @cinema_agreement_id) 
		OR (@cinema_agreement_id is null))
	AND ((@mode = 'F') 
         	OR (@mode = 'T' and (isnull(cinema_agreement_policy.processing_end_date,'1-jan-2100') < @accounting_period))
         	OR (@mode = 'T' and cinema_agreement_policy.cinema_agreement_id  in (  
  				select  cinema_agreement_id
		                from    cinema_agreement
                		where   cinema_agreement.agreement_status = 'A'
--                		and     @mode = 'T' 
                		and     isnull(cinema_agreement.termination_date,'1-jan-2100') < @accounting_period
                		and     (cinema_agreement.cinema_agreement_id = @cinema_agreement_id or @cinema_agreement_id is null) 
                		and     cinema_agreement.cinema_agreement_id not in
	               				(select  distinct cinema_agreement.cinema_agreement_id
	               				 from    cinema_agreement, cinema_agreement_statement
	                			 where   cinema_agreement_statement.cinema_agreement_id = cinema_agreement.cinema_agreement_id
	                			 and     cinema_agreement.agreement_status = 'A'
	                			group by cinema_agreement.cinema_agreement_id
 	                			having  (sum(cinema_agreement_statement.entitlements) + sum(cinema_agreement_statement.payments)) > 0) ) ) )

--    and     ((  cinema_agreement_policy.cinema_agreement_id = @cinema_agreement_id) OR (@cinema_agreement_id is null))
            
    select @error = @@error
    if @error != 0
        goto rollbackerror

-- select  ca.cinema_agreement_id,
--         (sum(cas.entitlements) + sum(cas.payments)) 'current_balance'
-- from    cinema_agreement ca, cinema_agreement_statement cas
-- where   cas.cinema_agreement_id = ca.cinema_agreement_id
-- and     ca.agreement_status = 'A'
-- group by ca.cinema_agreement_id

    /*  Cannot close agreements that have positive entitlement balances. */
    /*  The pre-eom check report will alert users to any campaigns that cannot be closed */
    update  cinema_agreement
    set     agreement_status = 'C'
    where   cinema_agreement.agreement_status = 'A'
    and     (   (@mode = 'F')
            OR  (@mode = 'T' and (isnull(cinema_agreement.termination_date,'1-jan-2030') < @accounting_period))
    and         ((cinema_agreement.cinema_agreement_id = @cinema_agreement_id) or (@cinema_agreement_id is null)))
    and     cinema_agreement.cinema_agreement_id not in
                                                   (select  ca.cinema_agreement_id
                                                    from    cinema_agreement ca, cinema_agreement_statement cas
                                                    where   cas.cinema_agreement_id = ca.cinema_agreement_id
                                                    and     ca.agreement_status = 'A'
                                                    group by ca.cinema_agreement_id
                                                    having  ((sum(cas.entitlements) + sum(cas.payments)) > 0))
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

    return -100
GO
