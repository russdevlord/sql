USE [production]
GO
/****** Object:  StoredProcedure [dbo].[sup_object_permissions]    Script Date: 11/03/2021 2:30:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create  proc [dbo].[sup_object_permissions]

as	

declare @table_name		varchar(50),
	@rowcount		int,
	@sql_string		varchar(400)

create table #table_list
(
name		varchar(50)	null,
count		int		null
)

insert into #table_list (name) select name from sysobjects where xtype = 'P' or xtype = 'V' or xtype  = 'U' or xtype = 'FN' or xtype  = 'TF'

declare table_csr cursor for
select name 
from 	#table_list
order by name

open table_csr
fetch table_csr into @table_name
while(@@fetch_status=0)
begin
	select @sql_string = 'grant execute on '  + @table_name + ' to public'

	execute(@sql_string)

	select @sql_string = 'grant execute on '  + @table_name + ' to VMCONTROL\Cinvendo Users'

	execute(@sql_string)

	select @sql_string = 'grant references on '  + @table_name + ' to public'

	execute(@sql_string)

	select @sql_string = 'grant references on '  + @table_name + ' to VMCONTROL\Cinvendo Users'

	execute(@sql_string)
	fetch table_csr into @table_name
end

deallocate table_csr

return 0
GO
