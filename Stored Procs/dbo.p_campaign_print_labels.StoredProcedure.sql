/****** Object:  StoredProcedure [dbo].[p_campaign_print_labels]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_print_labels]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_print_labels]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_campaign_print_labels] 	@campaign_no	integer,
										@print_id		integer,
										@label_option 	char(1),
										@print_medium	char(1),
										@three_d_type	int
as

declare @complex_id			integer,
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
		@print_date		 	datetime

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
	start_date		datetime		null,
	print_id		integer			null,
	film_market		integer			null,
	print_date		datetime		null	
)

create table #campaign_complex
(
	complex_id		integer
)


insert 	into #campaign_complex
select 	fpc.complex_id
from 	film_plan fp,
		film_plan_complex fpc
where 	fp.film_plan_id = fpc.film_plan_id 
and		fp.campaign_no = @campaign_no

insert 	into #campaign_complex
select 	complex_id
from 	film_campaign_complex
where 	campaign_no = @campaign_no

insert 	into #campaign_complex
select 	complex_id
from 	inclusion_cinetam_settings 
where	inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no)


/*
 * Define Cursor to Retrieve Summary and Label Information
 */

declare 	label_csr cursor static for
select		complex_id
from 		#campaign_complex
group by	complex_id
order by 	complex_id
for 		read only

/*
 * Loop Through the Records inserting rows into the label table
 */

open  label_csr
fetch label_csr into @complex_id	
while (@@fetch_status = 0)
begin
	
	if @label_option = 'A'
	begin
		select 	@schedule = max(temp_table.count)
		from 	(select 	count(ppack.print_id) as count
				from 		campaign_spot spot,
							campaign_package cp,
							print_package ppack
				where 		spot.package_id = cp.package_id and
							cp.package_id = ppack.package_id and
							ppack.print_id = @print_id and
							spot.complex_id = @complex_id and
							spot.campaign_no = @campaign_no			 
				group by 	spot.screening_date) as temp_table
		
		select 	@plan = fpc.max_screens
		from 	film_plan fp,
				film_plan_complex fpc,
				print_package pp
		where 	fp.film_plan_id = fpc.film_plan_id and
				fp.package_id = pp.package_id and
				fp.campaign_no = @campaign_no and
				fpc.complex_id = @complex_id and
				pp.print_id = @print_id
		
		select @label_count = isnull(@schedule, 0) + isnull(@plan, 0)
	end
	else if @label_option = 'S'
	begin
		select 	@proposed = isnull(sum(cinema_qty),0)
		from 	print_transactions 
		where 	print_id = @print_id and	
				campaign_no = @campaign_no and
				complex_id = @complex_id and
				ptran_type in ('T','A') and
				ptran_status = 'S' and
				branch_qty < 0 and
				(print_medium = @print_medium or @print_medium = 'A') and
				(three_d_type = @three_d_type or @three_d_type = 0)
		
		select @label_count = @proposed
	end

	if @label_count > 0
	begin
	
		select 	@complex_name	= complex_name,
				@add1 = address_1,
				@add2 = address_2,
				@town = town_suburb,
				@postcode = postcode,
				@state = state_code,
				@film_market = film_market_no
		from 	complex
		where 	complex_id = @complex_id
		
		select 	@line1 = 'Attention: The Projectionist'
		
		select 	@line2 = @complex_name
		select 	@line3 = @add1
		select 	@line4 = @add2
		select 	@line5 = @town + ' ' + @state + ' ' + @postcode
		
		if @line3 = Null or @line3 = ''
		begin
			select 	@line3 = @line4
			select 	@line4 = @line5
			select 	@line5 = ''
		end
		
		if @line4 = Null or @line4 = ''
		begin
			select 	@line4 = @line5
			select 	@line5 = ''
		end
		
		select 	@campaign_desc = product_desc
		from 	film_campaign
		where 	campaign_no = @campaign_no
		
		select 	@print_name = print_name,
				@print_date = print_date
		from 	film_print
		where 	print_id = @print_id
		
		select 	@start_date = min(spot.screening_date)
		from 	campaign_spot spot,
				campaign_package cp,
				print_package ppack
		where 	spot.package_id = cp.package_id and
				cp.package_id = ppack.package_id and
				ppack.print_id = @print_id and
				spot.complex_id = @complex_id and
				spot.campaign_no = @campaign_no
		
		select 	@plan_start_date = min(fpd.screening_date)
		from 	film_plan fp,
				film_plan_complex fpc,
				film_plan_dates fpd,
				print_package pp
		where 	fp.film_plan_id = fpc.film_plan_id and
				fp.film_plan_id = fpd.film_plan_id and	
				fp.package_id = pp.package_id and
				fp.campaign_no = @campaign_no and
				fpc.complex_id = @complex_id and
				pp.print_id = @print_id
		
		select 	@start_date = isnull(@start_date, @plan_start_date)
		
		if @plan_start_date < @start_date
		begin
			select @start_date = @plan_start_date
		end
		
		select 	@count = 1
		while 	@count <= @label_count
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
			@print_date )

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

select *, @print_medium from #label
GO
