/****** Object:  StoredProcedure [dbo].[p_active_exhibitor_labels]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_active_exhibitor_labels]
GO
/****** Object:  StoredProcedure [dbo].[p_active_exhibitor_labels]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_active_exhibitor_labels] @mode	integer
as

declare @add1         	varchar(50),
		@add2         	varchar(50),
		@town         	varchar(30),
		@state        	char(3),
		@postcode     	char(5),
		@line1        	varchar(50),
		@line2        	varchar(50),
		@line3        	varchar(50),
		@line4			varchar(50),
		@line5			varchar(50),
		@contact		varchar(50),
		@name			varchar(50),
		@phone			varchar(30),
		@fax			varchar(30),
		@exhibitor_id	int,
		@index			int,
		@whoto			varchar(50)

/*
 * Create the Temporary Loader Table
 */
create table #merge (
		etype			char(1)        null,
		exhibitor		int				null,
		add1			varchar(50)		null,
		add2			varchar(50)		null,
		add3			varchar(50)		null,
		add4			varchar(50)		null,
		add5			varchar(50)		null,
		phone			varchar(30)		null,
		fax				varchar(30)		null,
		whoto			varchar(50)		null
)	

/*
 * Loop through exhibitors
 */
 declare exib_csr cursor static for
  select e.exhibitor_id,
         e.contact,
         e.exhibitor_name,
         e.address_1,
         e.address_2,
         e.town_suburb,
         e.state_code,
         e.postcode,
         e.phone,
         e.fax
    from exhibitor e
   where e.exhibitor_status = 'A' and
         e.exhibitor_id <> 100
order by e.exhibitor_name
     for read only

open exib_csr
fetch exib_csr into @exhibitor_id,
                    @contact,
                    @name,
                    @add1,
                    @add2,
                    @town,
                    @state,
                    @postcode,
                    @phone,
                    @fax
                    
while(@@fetch_status=0)
begin

	/*
    * Fix Address
    */

	select @line1 = @contact
	select @line2 = @name
	select @line3 = @add1
	select @line4 = @add2
	select @line5 = ltrim(Isnull(@town,'') + ' ' + Isnull(@state,'') + ' ' + isnull(@postcode,''))

	if (@line4 is null) or (len(@line4) = 0) or (@line4 = '') or (@line4 = ' ')
	begin
		select @line4 = @line5
		select @line5 = ''
	end

	if (@line1 is null) or (len(@line1) = 0) or (@line1 = '') or (@line1 = ' ') or (@line1 = @line2)
	begin
		select @line1 = @line2
		select @line2 = @line3
		select @line3 = @line4
		select @line4 = @line5
		select @line5 = ''
	end

	/*
    * Calculate Whoto
    */

	select @index = charindex(' ', @contact)
	if(@index - 1 > 0)
		select @whoto = substring(@contact, 1, @index - 1)
	else
		select @whoto = @contact

	/*
    * Write Exhibitor Record
    */

	insert into #merge values (
				 'E',
				 @exhibitor_id,
				 @line1,
				 @line2,
				 @line3,
				 @line4,
				 @line5,
				 @phone,
				 @fax,
				 @whoto )
	
	/*
    * Do the Complex
    */
	 declare complex_csr cursor static for
	  select c.manager,
	         c.complex_name,
	         c.address_1,
	         c.address_2,
	         c.town_suburb,
	         c.state_code,
	         c.postcode,
	         c.phone,
	         c.fax
	    from complex c
	   where c.exhibitor_id = @exhibitor_id 
	   AND	c.film_complex_status <> 'C' --and slide_complex_status <> 'C'
	order by c.complex_name
	     for read only

	open complex_csr
	fetch complex_csr into @contact,
							     @name,
							     @add1,
							     @add2,
							     @town,
							     @state,
							     @postcode,
							     @phone,
							     @fax

	while(@@fetch_status=0)
	begin
	
		/*
		 * Fix Address
		 */
	
		select @line1 = @contact
		select @line2 = @name
		select @line3 = @add1
		select @line4 = @add2
		select @line5 = @town + ' ' + Isnull(@state,'') + ' ' + isnull(@postcode,'')
	
		if (@line4 is null) or (len(@line4) = 0) or (@line4 = '') or (@line4 = ' ')
		begin
			select @line4 = @line5
			select @line5 = ''
		end
	
		if (@line1 is null) or (len(@line1) = 0) or (@line1 = '') or (@line1 = ' ') or (@line1 = @line2)
		begin
			select @line1 = @line2
			select @line2 = @line3
			select @line3 = @line4
			select @line4 = @line5
			select @line5 = ''
		end

		/*
		 * Calculate Whoto
		 */
	
		select @index = charindex(' ', @contact)
		if(@index - 1 > 0)
			select @whoto = substring(@contact, 1, @index - 1)
		else
			select @whoto = @contact

		/*
		 * Write Complex Record
		 */
	
		if(@mode = 2)
		begin

			insert into #merge values (
					 'C',
					 @exhibitor_id,
					 @line1,
					 @line2,
					 @line3,
					 @line4,
					 @line5,
					 @phone,
					 @fax,
					 @whoto )
		end

		/*
       * Fetch Next Complex
       */

		fetch complex_csr into @contact,
									  @name,
									  @add1,
									  @add2,
									  @town,
									  @state,
									  @postcode,
									  @phone,
									  @fax

	end

	deallocate complex_csr

	/*
    * Fetch Next Exhibitor
    */

	fetch exib_csr into @exhibitor_id,
                    @contact,
                    @name,
                    @add1,
                    @add2,
                    @town,
                    @state,
                    @postcode,
                    @phone,
                    @fax

end

close exib_csr
deallocate  exib_csr

/*
 * Return Dataset
 */

select * from #merge

/*
 * Return Success
 */

return 0
GO
