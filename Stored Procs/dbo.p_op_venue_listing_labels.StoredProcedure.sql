/****** Object:  StoredProcedure [dbo].[p_op_venue_listing_labels]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_venue_listing_labels]
GO
/****** Object:  StoredProcedure [dbo].[p_op_venue_listing_labels]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_venue_listing_labels] @mode				integer,
                                     @groupby			integer,
												 @film				tinyint
as

declare	@outpost_venue_id		integer,
			@outpost_venue_code	char(5),
			@manager			varchar(50),
			@outpost_venue_name	varchar(50),
			@address_1			varchar(50),
			@address_2			varchar(50),
			@town_suburb		varchar(30),
			@state				char(3),
			@postcode			char(5),
			@phone				char(20),
			@fax				char(20),
			@contact			varchar(50),
			@line1				varchar(50),
			@line2				varchar(50),
			@line3				varchar(50),
			@line4				varchar(50),
			@line5				varchar(50),
			@index				integer,
			@contract_code 		char(3)

/*
 * Create the Temporary Loader Table
 */

create table #label
(
	outpost_venue_id		integer			null,
	line_1			varchar(50)    null,
	line_2			varchar(50)    null,
	line_3			varchar(50)    null,
	line_4			varchar(50)    null,
	line_5			varchar(50)    null,
	phone				varchar(30)		null,
	fax				varchar(30)		null,
	contact			varchar(30)		null,
	contract_code	char(3)			null
)

/*
 * Declare Cursors
 */

declare outpost_venue_csr cursor static for
 select outpost_venue.outpost_venue_id
   from outpost_venue,
        film_market
  where outpost_venue.market_no= film_market.film_market_no and
        @groupby = 2 and
        outpost_venue.outpost_venue_status_code <> 'C'
 union
 select outpost_venue.outpost_venue_id
   from outpost_venue
  where @groupby <> 2 and
        outpost_venue.outpost_venue_status_code <> 'C'
order by outpost_venue_id
for read only



open outpost_venue_csr
fetch outpost_venue_csr into @outpost_venue_id
while (@@fetch_status = 0)
begin
   /*
    * Load address details from the outpost_venue table
    */
   select @manager = outpost_venue.manager,
          @outpost_venue_name = outpost_venue.outpost_venue_name,
          @address_1 = outpost_venue.address_1,
          @address_2 = outpost_venue.address_2,
          @town_suburb = outpost_venue.town_suburb,
          @postcode = outpost_venue.postcode,
          @phone = outpost_venue.phone,
          @fax = outpost_venue.fax
     from outpost_venue
    where outpost_venue_id = @outpost_venue_id

   /*
    * Assign the Adress Lines
    */

   select @line1 = @manager
   select @line2 = @outpost_venue_name
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

   insert into #label values (@outpost_venue_id, @line1, @line2, @line3, @line4, @line5, @phone, @fax, @contact, @contract_code)

   fetch outpost_venue_csr into @outpost_venue_id
end
close outpost_venue_csr
deallocate outpost_venue_csr

/*
 * Return contents of the table
 */

select * from #label

return 0
GO
