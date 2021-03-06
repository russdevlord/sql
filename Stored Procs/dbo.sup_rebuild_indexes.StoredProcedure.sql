/****** Object:  StoredProcedure [dbo].[sup_rebuild_indexes]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[sup_rebuild_indexes]
GO
/****** Object:  StoredProcedure [dbo].[sup_rebuild_indexes]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create  proc [dbo].[sup_rebuild_indexes]

/* Uses code from 
   
   David Wootton 11/01/2002
*/
 
as	

declare @table_name		varchar(50),
	    @sql_string		varchar(400),
        @fill_factor    varchar(10)

create table #table_list
(
name		varchar(50)	        null,
id          int                 null,
count		int		            null
)

insert into #table_list (name, id) select name, id from sysobjects where xtype = 'U'

declare     table_csr cursor for
select      #table_list.name,
            origfillfactor
from 	    #table_list,
            sysindexes
where       sysindexes.id = (select #table_list.id from #table_list where #table_list.id=sysindexes.id)     
group by    #table_list.name,
            origfillfactor
having      count(#table_list.name) >= 1
order by    #table_list.name


open table_csr
fetch table_csr into @table_name, @fill_factor
while(@@fetch_status=0)
begin

	select @sql_string = 'DBCC DBREINDEX ('+(@table_name ) +', '' '','+(@fill_factor)+') with NO_INFOMSGS'
	execute(@sql_string)

	fetch table_csr into @table_name, @fill_factor
end

deallocate table_csr

return 0
GO
