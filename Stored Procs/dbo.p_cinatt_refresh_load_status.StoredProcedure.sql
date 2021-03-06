/****** Object:  StoredProcedure [dbo].[p_cinatt_refresh_load_status]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_refresh_load_status]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_refresh_load_status]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cinatt_refresh_load_status]

as

/* Refreshes external_data_load_status with new outstanding loads if required */

declare @error              integer,
        @err_msg            varchar(50),
        @provider_id        integer,
        @screening_date     datetime


declare provider_csr cursor static for
select  distinct provider_id
from    external_data_providers
where   status = 'A'
for read only


open provider_csr
fetch provider_csr into @provider_id
while(@@fetch_status = 0)
begin
	declare date_csr cursor static for
	select  screening_date
	from    film_screening_dates
	where   screening_date < dateadd(dd,-8,getdate())
	and     screening_date > (select max(required_load_date) from external_data_load_status where provider_id = @provider_id)
	and     screening_date_status = 'X'

    open date_csr
    fetch date_csr into @screening_date
    while(@@fetch_status = 0)
    begin
        exec @error = p_cinatt_update_load_status @provider_id, @screening_date, 'N'
        if @error <> 0
        begin
            close provider_csr
            deallocate provider_csr            
            close date_csr
            deallocate date_csr            
            select @err_msg = 'Error refreshing attendance load status table'
            raiserror (@err_msg, 16, 1)
            return -1
        end         
        fetch date_csr into @screening_date
    end /*while*/ 
    close date_csr
	deallocate date_csr
    fetch provider_csr into @provider_id
end /*while*/

close provider_csr
deallocate provider_csr            


return 0
GO
