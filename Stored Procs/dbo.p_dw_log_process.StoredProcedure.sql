USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_dw_log_process]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_dw_log_process]        @process_item_id int,
                                    @status char(1)
as
/* Proc name:   p_dw_log_process
 * Author:      Grant Carlson
 * Date:        12/10/2004
 * Description: Creates a DW process log entry
 *
 * Changes: 
 *
*/ 

declare @error        				int,
        @err_msg                    varchar(150),
       -- @error                         int,
        @run_user_name              varchar(30),
        @run_date                   datetime,
        @log_id                     int


exec @error = p_get_sequence_number 'dw_processing_log', 5, @log_id OUTPUT
if @error != 0
begin
    select @err_msg = 'Error executing p_get_sequence_number'
    select @error = 50000
    goto error
end

select  @run_user_name = suser_sname(),
        @run_date = getdate()

begin transaction

    insert into dw_processing_log
    values (@log_id,
            @process_item_id,
            @status,
            null,
            @run_user_name,
            @run_date)
            
    if @@error != 0
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
