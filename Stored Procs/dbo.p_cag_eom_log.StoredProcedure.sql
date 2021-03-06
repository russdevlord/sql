/****** Object:  StoredProcedure [dbo].[p_cag_eom_log]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_eom_log]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_eom_log]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_eom_log]       @mode char(1),
                                @accounting_period    datetime,
                                @cinema_agreement_id  int,
                                @run_status char(1)
as
/* Proc name:   p_cag_eom_log
 * Author:      Grant Carlson
 * Date:        19/2/2004
 * Description: Creates EOM log entries
 *
 * Changes: 
 *
*/ 

declare @error        				int,
        @err_msg                    varchar(150),
        --@error                         int,
        @log_id                     int,
        @run_user_name              varchar(30),
        @run_date                   datetime

return 0

exec @error = p_get_sequence_number 'cag_eom_log', 5, @log_id OUTPUT
if @error != 0
begin
    select @err_msg = 'Error executing p_get_sequence_number'
    goto rollbackerror
end

select  @run_user_name = suser_name(),
        @run_date = getdate()

begin transaction

    INSERT INTO dbo.cag_eom_log
	    (log_id,
	     cinema_agreement_id,
	     accounting_period,
	     cag_eom_run_mode,
	     run_user_name,
	     run_date,
	     run_status)
    VALUES
	    (@log_id,
	     @cinema_agreement_id,
	     @accounting_period,
	     @mode,
	     @run_user_name,
	     @run_date,
	     @run_status)
         
    select @error = @@error
    if @error != 0
        goto rollbackerror

commit transaction


return 0

rollbackerror:
    rollback transaction
error:
    if @error >= 50000
        raiserror (@err_msg, 16, 1)

    return -1
GO
