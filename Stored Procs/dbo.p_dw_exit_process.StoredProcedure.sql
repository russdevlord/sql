/****** Object:  StoredProcedure [dbo].[p_dw_exit_process]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_dw_exit_process]
GO
/****** Object:  StoredProcedure [dbo].[p_dw_exit_process]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_dw_exit_process]       @sp_name    varchar(50),
                                    @run_status char(1) = 'A'

as
/* Proc name:   p_dw_exit_process
 * Author:      Grant Carlson
 * Date:        12/10/2004
 * Description: Called at the completion of a DW interface process
 *
 * Changes: 
 *
*/ 

declare @error        				int,
        @err_msg                    varchar(150),
        --@error                         int,
        @rows                       int,
        @log_id                     int,
        @run_user_name              varchar(30),
        @run_date                   datetime,
        @process_id                 int,
        @process_item_id            int,
        @process_order              tinyint,
        @status_running             char(1),
        @status_awaiting            char(1),
        @status_failed              char(1),
        @process_status             char(1),
        @process_item_status        char(1),
        @total_process_items        tinyint

return 0

select  @run_user_name = suser_sname(),
        @run_date = getdate(),
        @status_running = 'R',
        @status_awaiting = 'A',
        @status_failed = 'F'

select  @process_id             = pli.process_id,
        @process_item_id        = pli.process_item_id,
        @process_order          = pli.process_order,
        @process_status         = pl.run_status,
        @process_item_status    = pli.run_status
from    dw_process_list pl,
        dw_process_list_items pli
where   pl.process_id = pli.process_id
and     pli.sp_name = @sp_name

if @@rowcount = 0 
begin
    exec @error =  p_dw_log_process @process_item_id, @status_failed
    select @err_msg =  'Error in p_dw_exit_process: Unknown proceedure name @sp_name = ' + @sp_name
    goto error
end


begin transaction

    update  dw_process_list_items
    set     run_status = @run_status,
            last_run_date = @run_date
    from    dw_process_list
    where   dw_process_list_items.sp_name = @sp_name
    and     dw_process_list_items.process_id = dw_process_list.process_id
    and     dw_process_list.run_status = @status_running
    and     dw_process_list_items.run_status = @status_running
        
    select @rows = @@rowcount, @error = @@error
    if @error != 0
    begin
        goto rollbackerror
    end

    if @rows = 0 -- means that the process couldn't be started for some reason
    begin
        exec @error =  p_dw_log_process @process_item_id, @status_failed
        select @err_msg =  'Error in p_dw_exit_process: Could not exit process sucessfully ' + @sp_name
        goto rollbackerror
    end

    exec @error =  p_dw_log_process @process_item_id, @run_status

    select  @total_process_items = count(process_order)
    from    dw_process_list_items
    where   process_id = @process_id 

    if @process_order = @total_process_items -- this is the last item in the process
    begin
        update  dw_process_list
        set     run_status = @status_awaiting
        where   process_id = @process_id 
        and     run_status = @status_running

        select @rows = @@rowcount, @error = @@error
        if @error != 0
        begin
            exec @error =  p_dw_log_process @process_item_id, @status_failed
            goto rollbackerror
        end

        if @rows = 0 -- means that the process couldn't be started for some reason
        begin
            exec @error =  p_dw_log_process @process_item_id, @status_failed
            select @err_msg = 'Error in p_dw_exit_process: Could not exit Process for Process Item: ' + @sp_name
            goto rollbackerror
        end
    end

commit transaction

return 0

rollbackerror:
    rollback transaction
error:
    if @error >= 50000
        raiserror (@err_msg, 16, 1)

    return -1
GO
