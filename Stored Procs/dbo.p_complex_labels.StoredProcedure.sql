/****** Object:  StoredProcedure [dbo].[p_complex_labels]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_complex_labels]
GO
/****** Object:  StoredProcedure [dbo].[p_complex_labels]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_complex_labels] @complex_id int,
                             @attention  smallint,
                             @pages      smallint
as

declare @complex_name varchar(50)
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
declare @contract		 char(3)

/*
 * Create the Temporary Loader Table
 */

create table #label
(
	 line_1    varchar(50)    null,
    line_2    varchar(50)    null,
    line_3    varchar(50)    null,
    line_4    varchar(50)    null,
    line_5    varchar(50)    null,
	 contract  char(3)		  null
)

/*
 * Initialize Count
 */

select @count = 1
select @limit = 14 * @pages

/*
 * Load address details from the Complex table
 */

select @complex_name = complex_name,
       @add1 = address_1,
       @add2 = address_2,
       @town = town_suburb,
       @state = state_code,
       @postcode = postcode,
       @manager = manager,
       @project = projectionist,
		 @contract = contractor_code
  from complex
 where complex_id = @complex_id

/*
 * Assign the Adress Lines
 */

if @attention = 1
	select @line1 = 'Attention: ' + @manager

if @attention = 2
	select @line1 = 'Attention: ' + @project

select @line2 = @complex_name
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

/*
 * Loop to fill the #label table
 */

while @count <= @limit
begin 
	insert into #label values (@line1,@line2,@line3,@line4,@line5,@contract)
	select @count = @count + 1		
end

/*
 * Return contents of the table
 */

select * from #label
GO
