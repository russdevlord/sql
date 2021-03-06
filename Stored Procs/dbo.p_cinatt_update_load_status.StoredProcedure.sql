/****** Object:  StoredProcedure [dbo].[p_cinatt_update_load_status]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_update_load_status]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_update_load_status]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cinatt_update_load_status]   @provider_id integer, @screening_date datetime, @load_complete char(1)
                                          
as

declare @data_type_cinatt   tinyint,
        @error              integer,
        @errorount             integer,
        @country_code       char(1)

select @data_type_cinatt = 1

begin tran

    update  external_data_load_status
    set     load_complete = @load_complete
    where   external_data_type_id = @data_type_cinatt and
            provider_id = @provider_id and
            required_load_date = @screening_date

    select @error = @@error, @errorount = @@rowcount
    if @error <> 0
        goto error

    if @errorount = 0 /* no rows updated so have to insert new group */
    begin
        /* insert this provider id record */
        insert into external_data_load_status
        values(@data_type_cinatt, @provider_id, @screening_date, @load_complete)
        if @@error <> 0
            goto error

        select  @country_code = country_code
        from    external_data_providers
        where   provider_id = @provider_id

        /* create initial records for all other active providers in the same country group */
        insert into external_data_load_status 
        select  @data_type_cinatt,
                provider_id,
                @screening_date,
                'N'
        from    external_data_available
        where   external_data_type_id = @data_type_cinatt
        and     status = 'A'
        and     provider_id <> @provider_id
        and     provider_id in (select provider_id from external_data_providers where country_code = @country_code)
        and     provider_id not in (select provider_id from external_data_load_status where external_data_type_id = @data_type_cinatt and required_load_date = @screening_date)
        if @@error <> 0
            goto error
    end

commit tran

return 0

error:
    rollback tran
    return -1
GO
