/****** Object:  StoredProcedure [dbo].[sup_table_space]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[sup_table_space]
GO
/****** Object:  StoredProcedure [dbo].[sup_table_space]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[sup_table_space]

as	

declare     @rowcount		    int,
	        @sql_string		    varchar(400),
            @tablename          varchar(128) ,
            @tableownername     varchar(128),
            @id                 int,
            @pages              int

set nocount on
     
select @tableownername = 'dbo'     

create table #spt_space
(
tablename   varchar(128)    null,
rows        int             null,
reserved    dec(15)         null,
data        dec(15)         null,
indexp      dec(15)         null,
unused      dec(15)         null,
percentage  money           null 
)

insert into #spt_space (tablename) select name from sysobjects where xtype = 'U'

declare     table_csr cursor for
select      tablename 
from 	    #spt_space
order by    tablename

open table_csr
fetch table_csr into @tablename
while(@@fetch_status=0)
begin

    if (@tableownername = ' ')
        select  @id=id
        from    sysobjects
        where   name =@tablename
        and     (xtype ='U'
        or      xtype ='S')
    else
        select  @id=id
        from    sysobjects
        where   name =@tablename
        and     (xtype ='U'
        or      xtype ='S')
        and     uid=user_id(@tableownername)
        
    /*
    **  Now calculate the summary data.
    **  reserved: sum(reserved) where indid in (0, 1, 255)
    */
    
    update  #spt_space 
    set     reserved = (select sum(reserved)
                        from sysindexes
                        where indid in (0, 1, 255)
                        and id = @id)
    where   tablename = @tablename
                    
    /*
    ** data: sum(dpages) where indid < 2
    **  + sum(used) where indid = 255 (text)
    */

    select      @pages = sum(dpages)
    from        sysindexes
    where       indid < 2
    and         id = @id

    select      @pages = @pages + isnull(sum(used), 0)
    from        sysindexes
    where       indid = 255
    and         id = @id

    update      #spt_space
    set         data = @pages
    where       tablename = @tablename

    /* index: sum(used) where indid in (0, 1, 255) - data */

    update      #spt_space
    set         indexp = (select sum(used)
    from        sysindexes
    where       indid in (0, 1, 255)
    and         id = @id) - data
    where       tablename = @tablename
                
    /* unused: sum(reserved) - sum(used) where indid in (0, 1, 255) */
    update      #spt_space
    set         unused = reserved
                - ( select sum(used)
                    from        sysindexes
                    where       indid in (0, 1, 255)
                    and id = @id)
    where       tablename = @tablename
                    
    update  #spt_space
    set     rows = i.rows
    from    sysindexes i
    where   i.indid < 2
    and     i.id = @id
    and     tablename = @tablename

    update  #spt_space
    set     percentage=(convert(money,indexp)/convert(money,data))*100
    where   reserved!=0
    and     data!=0
    and     tablename = @tablename

    update  #spt_space
    set     percentage=0.00
    where   reserved=0
    and     tablename = @tablename
        
    update  #spt_space
    set     reserved=reserved * d.low / 1024.,
            data=data * d.low / 1024.,
            indexp=indexp * d.low / 1024.,
            unused=unused * d.low / 1024.
    from    master.dbo.spt_values d
    where   d.number = 1
    and     d.type = 'E'
    and     tablename = @tablename


	fetch table_csr into @tablename
end

deallocate table_csr

select  tablename,
        rows,
        reserved,
        data,
        indexp,
        unused,
        percentage
from    #spt_space
order by tablename


return 0
GO
