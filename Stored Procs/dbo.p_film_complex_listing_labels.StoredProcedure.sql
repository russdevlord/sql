/****** Object:  StoredProcedure [dbo].[p_film_complex_listing_labels]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_complex_listing_labels]
GO
/****** Object:  StoredProcedure [dbo].[p_film_complex_listing_labels]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_film_complex_listing_labels] @mode				integer,
                                     @groupby			integer
as

declare	@complex_id		integer,
			@complex_code	char(5),
			@manager			varchar(50),
			@complex_name	varchar(50),
			@address_1		varchar(50),
			@address_2		varchar(50),
			@town_suburb	varchar(30),
			@state			char(3),
			@postcode		char(5),
			@phone			char(20),
			@fax				char(20),
			@contact			varchar(50),
			@line1			varchar(50),
			@line2			varchar(50),
			@line3			varchar(50),
			@line4			varchar(50),
			@line5			varchar(50),
			@index			integer,
			@contract_code	char(3)

/*
 * Create the Temporary Loader Table
 */

create table #label
(
	complex_id		integer			null,
	line_1			varchar(50)    null,
	line_2			varchar(50)    null,
	line_3			varchar(50)    null,
	line_4			varchar(50)    null,
	line_5			varchar(50)    null,
	phone				varchar(30)		null,
	fax				varchar(30)		null,
	contact			varchar(30)		null,
	contract			char(3)			null
)

/*
 * Declare Cursors
 */

declare complex_csr cursor static for
 select complex.complex_id
   from complex,
        film_market
  where complex.film_market_no= film_market.film_market_no and
        @groupby = 2 and
        complex.film_complex_status <> 'C'
 union
 select complex.complex_id
   from complex
  where @groupby <> 2 and
        complex.film_complex_status <> 'C'
order by complex_id
for read only

open complex_csr
fetch complex_csr into @complex_id
while (@@fetch_status = 0)
begin
   /*
    * Load address details from the Complex table
    */
   select @manager = complex.manager,
          @complex_name = complex.complex_name,
          @address_1 = complex.address_1,
          @address_2 = complex.address_2,
          @town_suburb = complex.town_suburb,
          @postcode = complex.postcode,
          @phone = complex.phone,
          @fax = complex.fax,
			 @contract_code = complex.contractor_code
     from complex
    where complex_id = @complex_id

   /*
    * Assign the Adress Lines
    */

   select @line1 = @manager
   select @line2 = @complex_name
   select @line3 = @address_1
   select @line4 = @address_2
   select @line5 = @town_suburb + ' ' + @state + ' ' + @postcode

   if @line4 = NULL or len(@line4) = 0
   begin
   	select @line4 = @line5
	   select @line5 = ''
   end

   if @line3 = NULL or len(@line3) = 0
   begin
	   select @line3 = @line4
   	select @line4 = @line5
	   select @line5 = ''
   end

   if @line1 = NULL or len(@line1) = 0
   begin
	   select @line1 = @line2
	   select @line2 = @line3
	   select @line3 = @line4
   	select @line4 = @line5
	   select @line5 = ''
   end

	/*
    * Calculate Contact
    */

	select @index = charindex(' ', @manager)
	if(@index - 1 > 0)
		select @contact = substring(@manager, 1, @index - 1)
	else
		select @contact = @manager

   insert into #label values (@complex_id, @line1, @line2, @line3, @line4, @line5, @phone, @fax, @contact, @contract_code)

   fetch complex_csr into @complex_id
end
close complex_csr
deallocate complex_csr

/*
 * Return contents of the table
 */

select * from #label

return
GO
