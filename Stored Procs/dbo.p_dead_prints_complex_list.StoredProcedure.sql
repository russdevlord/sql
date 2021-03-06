/****** Object:  StoredProcedure [dbo].[p_dead_prints_complex_list]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_dead_prints_complex_list]
GO
/****** Object:  StoredProcedure [dbo].[p_dead_prints_complex_list]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_dead_prints_complex_list]  @accounting_period	datetime

as

create table #complex_prints
(
	campaign_no 			int				not null,   
   product_desc			varchar(100)	not null,   
   delivery_branch		varchar(2)		not null,   
   complex_name			varchar(50)		not null,   
   print_id					int				not null,   
   print_name				varchar(50)		not null,
	print_status			char(1)			not null,
	dead_period				datetime			not null,
	actual_qty       		int				not null,
   scheduled_qty_in 		int				not null,
   scheduled_qty_out 	int				not null,
	print_status_name		varchar(10)		not null,
	address_1				varchar(50)		not null,
	address_2				varchar(50)		null,
	town_suburb				varchar(30)		not null,
	postcode					varchar(5)		not null,
	manager					varchar(50)		null,
	state_code				char(3)			not null
)

declare 	@actual_qty       	int,
        	@scheduled_qty_in 	int,
       	@scheduled_qty_out 	int,
			@campaign_no 			int,   
         @product_desc			varchar(100),   
         @delivery_branch		varchar(2),   
         @complex_name			varchar(50),   
         @print_id				int,   
         @print_name				varchar(50),
			@print_status			char(1),
			@dead_period			datetime,
			@print_status_name	varchar(10),
			@error		 			int,
			@complex_id				int,
			@address_1				varchar(50),
			@address_2				varchar(50),
			@town_suburb			varchar(30),
			@postcode				varchar(5),
			@manager					varchar(50),
			@state_code				char(3)

begin transaction

 declare prints_csr cursor static for
  SELECT print_transactions.campaign_no,   
         min(film_campaign.product_desc),   
         min(film_campaign.delivery_branch),   
         complex.complex_id,
			complex.complex_name,   
         print_transactions.print_id,   
         film_print.print_name,
			film_print.print_status,
			film_print.dead_period,
			complex.address_1,
			complex.address_2,
			complex.town_suburb,
			complex.postcode,
			complex.manager,
			complex.state_code
    FROM film_print,   
         print_transactions,   
         complex,   
         film_campaign  
   WHERE film_print.print_id = print_transactions.print_id and  
         print_transactions.complex_id = complex.complex_id and  
         print_transactions.campaign_no = film_campaign.campaign_no and  
         film_print.print_status = 'X' and
			datediff(mm, film_print.dead_period, @accounting_period) >=3
GROUP BY print_transactions.campaign_no,   
         complex.complex_id,
			complex.complex_name,   
         print_transactions.print_id,   
         film_print.print_name,
			film_print.print_status,
			film_print.dead_period,
			complex.address_1,
			complex.address_2,
			complex.town_suburb,
			complex.postcode,
			complex.manager,
			complex.state_code

open prints_csr
fetch prints_csr into @campaign_no,
							 @product_desc,
							 @delivery_branch,
							 @complex_id,
							 @complex_name,
							 @print_id,
							 @print_name,
							 @print_status,
							 @dead_period,
							 @address_1,
							 @address_2,
							 @town_suburb,
							 @postcode,
							 @manager,
							 @state_code

while(@@fetch_status = 0)
begin
			
	select @print_status_name = 'Dead'

	select @actual_qty = sum(cinema_qty)
	  from print_transactions
	 where print_id = @print_id and
			 complex_id = @complex_id and
			 ptran_status = 'C'
	
	select @scheduled_qty_in = sum(cinema_qty)
	  from print_transactions
	 where print_id = @print_id and
			 complex_id = @complex_id and
			 ptran_status = 'S' and
			 cinema_qty >= 0
	
	select @scheduled_qty_out = sum(cinema_qty)
	  from print_transactions
	 where print_id = @print_id and
			 complex_id = @complex_id and
			 ptran_status = 'S' and
			 cinema_qty < 0

	insert into #complex_prints
	(
		campaign_no,   
		product_desc,   
		delivery_branch,   
		complex_name,   
		print_id,   
		print_name,
		print_status,
		dead_period,
		actual_qty,
		scheduled_qty_in,
		scheduled_qty_out,
		print_status_name,
		address_1,
		address_2,
		town_suburb,
		postcode,
		manager,
		state_code
	) values
	(
		@campaign_no,
		@product_desc, 
		@delivery_branch, 
		@complex_name, 
		@print_id, 
		@print_name,
		@print_status,
		@dead_period,
		isnull(@actual_qty,0),
		isnull(@scheduled_qty_in,0),
		isnull(@scheduled_qty_out,0),
		@print_status_name,
		@address_1,
		@address_2,
		@town_suburb,
		@postcode,
		@manager,
		@state_code
	)
	
	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end
fetch prints_csr into  @campaign_no,
							  @product_desc,
							  @delivery_branch,
							  @complex_id,
							  @complex_name,
							  @print_id,
							  @print_name,
							  @print_status,
							  @dead_period,
							  @address_1,
							  @address_2,
							  @town_suburb,
							  @postcode,
							  @manager,
							  @state_code
end	

close prints_csr
deallocate prints_csr

commit transaction

select * from #complex_prints

return 0

error:

	raiserror ('Error retrieving dead prints for each complex. ', 16, 1)
	close prints_csr
	return -1
GO
