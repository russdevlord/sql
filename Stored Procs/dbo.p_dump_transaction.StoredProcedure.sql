/****** Object:  StoredProcedure [dbo].[p_dump_transaction]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_dump_transaction]
GO
/****** Object:  StoredProcedure [dbo].[p_dump_transaction]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_dump_transaction] @filepath        varchar(255)
as
set nocount on 
declare @error          int,
        @dump_device    varchar(50),
        @database_name  varchar(50),
	@msg		varchar(300),
		@sql_script		varchar(300)

-- select @database_name = db_name()
-- 
-- if @filepath is null 
--     select @dump_device = @database_name + '_log'
-- else
--     select @dump_device = @filepath
-- 
-- 	select @sql_script = 'backup log ' + @database_name + ' with no_log'
-- 	execute(@sql_script)
-- select @database_name = db_name()
-- 
-- if @filepath is null 
--     select @dump_device = @database_name + '_log'
-- else
--     select @dump_device = @filepath
-- 
-- dump transaction @database_name to @dump_device with no_log
-- 
-- select @error = @@error
-- if @error != 0
-- begin
-- 	select @msg = 'Error: Failed to dump logs on database:' +  @database_name
--     raiserror (@msg, 16, 1)
--     return -100
-- end

return 0
GO
