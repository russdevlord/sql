/****** Object:  StoredProcedure [dbo].[p_op_client_prog_report_main]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_client_prog_report_main]
GO
/****** Object:  StoredProcedure [dbo].[p_op_client_prog_report_main]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_client_prog_report_main] 	@film_campaign_program_id		integer,
													@screening_date					datetime
    
as

declare @campaign_no	integer,
		  @contact		varchar(50),
        @name			varchar(50),
        @address1		varchar(50),
        @address2		varchar(50),
        @address3		varchar(50),
		  @fax			varchar(20),
		  @email			varchar(50),
        @line1			varchar(50),
        @line2			varchar(50),
        @line3			varchar(50),
        @line4			varchar(50),
        @line5			varchar(50),
        @product_desc varchar(100)

/*
 * Retrieve the client programming address information
 */

select @campaign_no = fcp.campaign_no,
		 @contact = fcp.contact,
		 @name = fcp.company,
		 @address1 = fcp.address_1,
		 @address2 = fcp.address_2,
		 @address3	= fcp.address_3,
		 @fax = fcp.fax,
		 @email = fcp.email
  from film_campaign_program fcp
 where fcp.film_campaign_program_id = @film_campaign_program_id

/*
 * Build Address Lines
 */

if @contact is not null
	select @line1 = @contact

select @line2 = @name
select @line3 = @address1
select @line4 = @address2
select @line5 = @address3

if @line1 is null or len(@line1) = 0
begin
	select @line1 = @line2
	select @line2 = @line3
	select @line3 = @line4
	select @line4 = @line5
	select @line5 = ''
	if @line3 is null or len(@line3) = 0
	begin
		select @line3 = @line4
		select @line4 = ''
	end
end
else
if @line4 is NULL or len(@line4) = 0
begin
	select @line4 = @line5
	select @line5 = ''
end

/*
 * Return Dataset
 */

select @product_desc = product_desc
  from film_campaign fc
 where campaign_no = @campaign_no

select @screening_date as screening_date,
       @campaign_no as campaign_no,
       @product_desc as product_desc,
       @line1 as address1,
       @line2 as address2,
       @line3 as address3,
       @line4 as address4,
       @line5 as addres5,
		 @fax as fax,
		 @email as email
GO
