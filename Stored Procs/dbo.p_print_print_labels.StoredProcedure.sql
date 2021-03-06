/****** Object:  StoredProcedure [dbo].[p_print_print_labels]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_print_print_labels]
GO
/****** Object:  StoredProcedure [dbo].[p_print_print_labels]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_print_print_labels] 	@print_id		integer,
									@label_option 	char(1)
as
set nocount on 
declare @complex_id		 	integer,
		@campaign_desc	 	varchar(100),
		@complex_name	 	varchar(50),
		@add1				varchar(50),
		@add2				varchar(50),
		@town				varchar(30),
		@state				char(3),
		@postcode			char(5),
		@manager			varchar(50),
		@print_name		 	varchar(50),
		@start_date      	datetime,
		@plan_start_date 	datetime,
		@proposed			integer,
		@schedule			integer,
		@plan				integer,
		@count				integer,
		@label_count		integer,
		@line1				varchar(50),
		@line2				varchar(50),
		@line3				varchar(50),
		@line4				varchar(50),
		@line5				varchar(50),
		@film_market 	 	integer,
		@print_date			datetime,
		@error				integer

/*
 * Create Temporary Table to store Labels
 */

create table #label
(
	line_1			varchar(50)		null,
	line_2			varchar(50)		null,
	line_3			varchar(50)		null,
	line_4			varchar(50)		null,
	line_5			varchar(50)		null,
	print_name 		varchar(50)		null,
	print_id		integer			null,
	film_market		integer			null,
	print_date     	datetime		null
)

/*
 * Define Cursor to Retrieve Summary and Label Information
 */

create table #campaign_complex
(
	complex_id		integer
)

insert 		into #campaign_complex
select 		distinct complex_id
from 		print_transactions pt
where 		pt.print_id = @print_id
and			complex_id is not null
and			print_medium = 'F'

/*
 * Loop Through the Records inserting rows into the label table
 */

declare 	label_csr cursor static for
select 		complex_id
from 		#campaign_complex
group by 	complex_id
order by 	complex_id
for 		read only

open label_csr
fetch label_csr into @complex_id	
while (@@fetch_status = 0)
begin
	
	select 	@label_count = isnull(count(cinema_no),0)
	from 	cinema
	where 	complex_id = @complex_id

	if @label_count > 0
	begin
	
		select 	@complex_name	= complex_name,
				@add1 = address_1,
				@add2 = address_2,
				@town = town_suburb,
				@postcode = postcode,
				@state = state_code,				 
				@manager = manager,
				@film_market = film_market_no
		from 	complex
		where 	complex_id = @complex_id

		if @manager = Null or len(@manager) = 0
			select @line1 = 'Attention: The Manager'
		else
			select @line1 = 'Attention: ' + @manager

		select @line2 = @complex_name
		select @line3 = @add1
		select @line4 = @add2
		select @line5 = @town + ' ' + @state + ' ' + @postcode

		if @line3 = Null or @line3 = ''
		begin
			select @line3 = @line4
			select @line4 = @line5
			select @line5 = ''
		end

		if @line4 = Null or @line4 = ''
		begin
			select @line4 = @line5
         	select @line5 = ''
		end

		select 	@print_name = print_name,
				@print_date = print_date
		from 	film_print
		where 	print_id = @print_id

		select @count = 1
		while @count <= @label_count
		begin
			insert into #label values (
			@line1,
			@line2,
			@line3,
			@line4,
			@line5,
			@print_name,
			@print_id,
			@film_market,
			@print_date)

			select @error = @@error
			if @error != 0 
			begin
				raiserror ('Error inserting into temp table.', 16, 1)
				close label_csr
				deallocate label_csr
				return -1
			end
			select @count = @count + 1
		end

	end

	fetch label_csr into @complex_id
end
close label_csr
deallocate label_csr

/*
 * Return Labels
 */

select * from #label
GO
