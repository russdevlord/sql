/****** Object:  StoredProcedure [dbo].[p_op_venue_labels_all]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_venue_labels_all]
GO
/****** Object:  StoredProcedure [dbo].[p_op_venue_labels_all]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_op_venue_labels_all] @country_code	char(1),
                                 @attention		smallint,
                                 @pages			smallint
as

declare @outpost_venue_id	 integer
declare @outpost_venue_name varchar(50)
declare @add1         varchar(50)
declare @add2         varchar(50)
declare @manager      varchar(50)
declare @project      varchar(50)
declare @town         varchar(30)
declare @state        char(3)
declare @postcode     char(5)
declare @count        smallint
declare @line1        varchar(50)
declare @line2        varchar(50)
declare @line3        varchar(50)
declare @line4        varchar(50)
declare @line5        varchar(50)
declare @limit        smallint

                                             

create table #label
(
	 line_1    varchar(50)    null,
    line_2    varchar(50)    null,
    line_3    varchar(50)    null,
    line_4    varchar(50)    null,
    line_5    varchar(50)    null
)

                          

 declare outpost_venue_csr cursor static for
  select c.outpost_venue_id
    from outpost_venue c,
         branch b
   where c.outpost_venue_status_code <> 'C' and
         c.branch_code = b.branch_code and
         b.country_code = @country_code
order by c.branch_code,
         c.outpost_venue_name
     for read only


open outpost_venue_csr
fetch outpost_venue_csr into @outpost_venue_id
while(@@fetch_status=0)
begin

	                              
	
	select @count = 1,
	       @line1 = null,
	       @line2 = null,
	       @line3 = null,
	       @line4 = null,
	       @line5 = null,
	       @limit = 14 * @pages
	
	                                                         
	
	select @outpost_venue_name = outpost_venue_name,
			 @add1 = address_1,
			 @add2 = address_2,
			 @town = town_suburb,
			 @state = state_code,
			 @postcode = postcode,
			 @manager = manager
	  from outpost_venue
	 where outpost_venue_id = @outpost_venue_id
	
	                                     
	
	if @attention = 1
		select @line1 = 'Attention: ' + @manager
	
	if @attention = 2
		select @line1 = 'Attention: ' + @project
	
	select @line2 = @outpost_venue_name
	select @line3 = @add1
	select @line4 = @add2
	select @line5 = @town + ' ' + @state + ' ' + @postcode
	
	if @line1 = NULL or len(@line1) = 0
	begin
		select @line1 = @line2
		select @line2 = @line3
		select @line3 = @line4
		select @line4 = @line5
		select @line5 = ''
		if @line3 = NULL or len(@line3) = 0
		begin
			select @line3 = @line4
			select @line4 = ''
		end
	end
	else
	if @line4 = NULL or len(@line4) = 0
	begin
		select @line4 = @line5
		select @line5 = ''
	end
	
	                                           
	
	while @count <= @limit
	begin 
		insert into #label values (@line1,@line2,@line3,@line4,@line5)
		select @count = @count + 1		
	end

	                            

	fetch outpost_venue_csr into @outpost_venue_id

end

close outpost_venue_csr
deallocate outpost_venue_csr

                                        

select * from #label
GO
