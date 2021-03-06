/****** Object:  StoredProcedure [dbo].[p_cinatt_process_attendance]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_process_attendance]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_process_attendance]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_cinatt_process_attendance]  @batch_id   integer

as

declare @error          		integer,
        @err_msg                varchar(100),
        --@error                     integer,
        @provider_csr_open      tinyint,
        @provider_id            integer,
        @screening_date         datetime


begin transaction

delete cinema_attendance from cinema_attendance_process cap where cap.batch_id = @batch_id and cap.screening_date = cinema_attendance.screening_date and cap.provider_id = cinema_attendance.provider_id


select @error = @@error
if ( @error !=0 )
begin
    rollback transaction
    select @err_msg = 'Error deleting records! It is possible this file has been imported already.'
    raiserror (@err_msg, 16, 1)
    return -1
end

insert into cinema_attendance(  movie_id       ,
                                complex_id     ,
                                screening_date ,
                                provider_id    ,
                                batch_id       ,
                                attendance     ,
                                country        ,
                                confirmed      )
select   movie_id       ,
         complex_id     ,
         screening_date ,
         provider_id    ,
         batch_id       ,
         sum(attendance),
         country        ,
         confirmed
from    cinema_attendance_process
where   batch_id = @batch_id
group by movie_id       ,
         complex_id     ,
         screening_date ,
         provider_id    ,
         batch_id       ,
         country        ,
         confirmed

select @error = @@error
if ( @error !=0 )
begin
    rollback transaction
    select @err_msg = 'Error saving! It is possible this file has been imported already.'
    raiserror (@err_msg, 16, 1)
    return -1
end

    /* update load status table to indicate successfull data load */
    select @provider_csr_open = 0

	/*
 	 * Declare Cursor
 	 */
	
	declare provider_csr cursor static for
	select  distinct provider_id, screening_date
	from    cinema_attendance_process
	where   batch_id = @batch_id
	for read only

    open provider_csr
    select @provider_csr_open = 1
    fetch provider_csr into @provider_id, @screening_date
    while(@@fetch_status = 0)
    begin
        exec @error = p_cinatt_update_load_status @provider_id, @screening_date, 'Y'
        if @error <> 0
        begin
            close provider_csr
            deallocate provider_csr            
            rollback transaction
            select @err_msg = 'Error updating attendance load status table'
            raiserror (@err_msg, 16, 1)
            return -1
        end         
        fetch provider_csr into @provider_id, @screening_date
    end /*while*/

	close provider_csr
	deallocate provider_csr  

    delete  cinema_attendance_process
    where   batch_id = @batch_id
    select @error = @@error
    if ( @error !=0 )
    begin
        rollback transaction
        select @err_msg = 'Error deleting data in cinema_attendance_process table'
        raiserror (@err_msg, 16, 1)
        return -1
    end

commit transaction


return 0
GO
