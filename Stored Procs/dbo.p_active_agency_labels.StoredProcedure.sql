/****** Object:  StoredProcedure [dbo].[p_active_agency_labels]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_active_agency_labels]
GO
/****** Object:  StoredProcedure [dbo].[p_active_agency_labels]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_active_agency_labels]
as

declare	@agency_id			integer,
			@agency_name		varchar(50),
			@address_1			varchar(50),
			@address_2			varchar(50),
			@town_suburb		varchar(30),
			@state				char(3),
			@postcode			varchar(5),
			@phone				varchar(20),
			@fax					varchar(20),
			@email				varchar(50),
			@line1				varchar(50),
			@line2				varchar(50),
			@line3				varchar(50),
			@line4				varchar(50)

/*
 * Create the Temporary Loader Table
 */

create table #label
(
	state					char(3)			null,
	agency_name			varchar(50)		null,
	line_1				varchar(50)    null,
	line_2				varchar(50)    null,
	line_3				varchar(50)    null,
	line_4				varchar(50)    null,
	phone					varchar(20)		null,
	fax					varchar(20)		null,
	email					varchar(50)		null
)

/*
 * Declare Cursors
 */

 declare agency_csr cursor static for
  select agency.agency_id
    from agency
   where agency.agency_status = 'A'
order by agency.agency_id
     for read only

open agency_csr
fetch agency_csr into @agency_id
while (@@fetch_status = 0)
begin
   /*
    * Load Agency details
    */

   select @agency_name = agency.agency_name,
          @address_1 = agency.address_1,
          @address_2 = agency.address_2,
          @town_suburb = agency.town_suburb,
          @state = agency.state_code,
          @postcode = agency.postcode,
          @phone = agency.phone,
          @fax = agency.fax,
          @email = agency.email
     from agency
    where agency.agency_id = @agency_id

   /*
    * Assign the Adress Lines
    */

   select @line1 = @agency_name
   select @line2 = @address_1
   select @line3 = @address_2
   select @line4 = ltrim(isnull(@town_suburb, '') + ' ' + isnull(@state, '') + ' ' + isnull(@postcode, ''))

   if @line3 = NULL or len(@line3) = 0
   begin
	   select @line3 = @line4
   	select @line4 = ''
   end

   if @line1 = NULL or len(@line1) = 0
   begin
	   select @line1 = @line2
	   select @line2 = @line3
	   select @line3 = @line4
   	select @line4 = ''
   end

   insert into #label values (@state, @agency_name, @line1, @line2, @line3, @line4, @phone, @fax, @email)

   fetch agency_csr into @agency_id
end
close agency_csr
deallocate agency_csr

/*
 * Return contents of the table
 */

select * from #label

return 0
GO
