/****** Object:  StoredProcedure [dbo].[p_shell_print_labels]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_shell_print_labels]
GO
/****** Object:  StoredProcedure [dbo].[p_shell_print_labels]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_shell_print_labels] @shell_code		char(7),
												@print_id		integer,
												@label_option 	char(1)
as

declare @complex_id		 integer,
		  @campaign_desc	 varchar(100),
        @complex_name	 varchar(50),
        @add1				 varchar(50),
        @add2				 varchar(50),
        @town				 varchar(30),
        @state				 char(3),
        @postcode			 char(5),
        @manager			 varchar(50),
        @print_name		 varchar(50),
        @start_date      datetime,
		  @plan_start_date datetime,
        @proposed			 integer,
        @schedule			 integer,
		  @plan				 integer,
        @count				 integer,
        @label_count		 integer,
        @line1				 varchar(50),
        @line2				 varchar(50),
        @line3				 varchar(50),
        @line4				 varchar(50),
        @line5				 varchar(50),
		  @film_market 	 integer,
		  @print_date		 datetime

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
	campaign_desc	varchar(100)	null,
	print_name 		varchar(50)		null,
	start_date		datetime			null,
	print_id			integer			null,
	film_market		integer			null,
	print_date     datetime			null
)


/*
 * Define Cursor to Retrieve Summary and Label Information
 */

create table #campaign_complex
(
	complex_id		integer
)

insert into #campaign_complex
  select fsc.complex_id
    from film_shell_xref fsc
   where fsc.shell_code = @shell_code


 declare label_csr cursor static for
  select complex_id
    from #campaign_complex
group by complex_id
order by complex_id
     for read only


/*
 * Loop Through the Records inserting rows into the label table
 */

open  label_csr
fetch label_csr into @complex_id	
while (@@fetch_status = 0)
begin
	
		select @label_count = isnull(count(cinema_no),0)
		  from cinema
 		 where complex_id = @complex_id

	if @label_count > 0
	begin
	
		select @complex_name	= complex_name,
				 @add1 = address_1,
				 @add2 = address_2,
				 @town = town_suburb,
				 @postcode = postcode,
				 @state = state_code,				 
             @manager = manager,
				 @film_market = film_market_no
		  from complex
  	 	 where complex_id = @complex_id

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

		select @campaign_desc = shell_desc
		  from film_shell
		 where shell_code = @shell_code

		select @print_name = print_name,
				 @print_date = print_date
		  from film_print
		 where print_id = @print_id

		select @count = 1
		while @count <= @label_count
		begin
			insert into #label values (
                @line1,
                @line2,
                @line3,
                @line4,
                @line5,
                @campaign_desc,
                @print_name,
                @start_date,
					 @print_id,
					 @film_market,
					 @print_date)
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
