/****** Object:  StoredProcedure [dbo].[sup_update_statistics]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[sup_update_statistics]
GO
/****** Object:  StoredProcedure [dbo].[sup_update_statistics]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create   proc [dbo].[sup_update_statistics]

as	

declare @table_name		varchar(50),
	@rowcount		int,
	@sql_string		varchar(400)

set nocount on

create table #table_list
(
name		varchar(50)	null,
count		int		null
)

insert into #table_list (name) select name from sysobjects where xtype  = 'U' and name <> 'SSIS Configurations'

declare table_csr cursor for
select name 
from 	#table_list
order by name

open table_csr
fetch table_csr into @table_name
while(@@fetch_status=0)
begin

	select  @sql_string = 'update statistics ' + @table_name + ' with fullscan, all'  
	
    print   @sql_string
    
	execute(@sql_string)

	fetch table_csr into @table_name
end

deallocate table_csr

return 0
GO
