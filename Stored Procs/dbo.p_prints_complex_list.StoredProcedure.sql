/****** Object:  StoredProcedure [dbo].[p_prints_complex_list]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_prints_complex_list]
GO
/****** Object:  StoredProcedure [dbo].[p_prints_complex_list]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_prints_complex_list]	@complex_id   integer

as

set nocount on 

declare @actual_qty       		integer,
		@scheduled_qty_in 		integer,
		@scheduled_qty_out 		integer,
		@nom_actual_qty       	integer,
		@nom_scheduled_qty_in 	integer,
		@nom_scheduled_qty_out 	integer,
		@campaign_no 			integer,   
		@product_desc			varchar(100),   
		@delivery_branch		varchar(2),   
		@complex_name			varchar(50),   
		@print_id				integer,   
		@print_name				varchar(50),
		@print_status			char(1),
		@dead_period			datetime,
		@print_status_name		varchar(10),
		@error		 			integer,
		@print_medium			char(1),
		@three_d_type			integer

create table #complex_prints (
		campaign_no 			integer			null,   
		product_desc			varchar(100)	null,   
		delivery_branch			varchar(2)		null,   
		complex_name			varchar(50)		null,   
		print_id				integer			null,   
		print_name				varchar(50)		null,
		print_status			char(1)			null,
		dead_period				datetime		null,
		actual_qty       		integer			null,
		scheduled_qty_in 		integer			null,
		scheduled_qty_out 		integer			null,
		nom_actual_qty       	integer			null,
		nom_scheduled_qty_in 	integer			null,
		nom_scheduled_qty_out 	integer			null,
		print_status_name		varchar(10)		null,
		print_medium			char(1)			null,
		three_d_type			int				null
)

begin transaction

declare 	prints_csr cursor static for
SELECT 		pt.campaign_no,   
			min(fc.product_desc),   
			min(fc.delivery_branch),   
			c.complex_name,   
			pt.print_id,   
			fp.print_name,
			fp.print_status,
			fp.dead_period,
			pt.print_medium,
			pt.three_d_type
FROM		film_print AS fp INNER JOIN
			print_transactions AS pt ON fp.print_id = pt.print_id INNER JOIN
			complex AS c ON pt.complex_id = c.complex_id LEFT OUTER JOIN
			film_campaign AS fc ON pt.campaign_no = fc.campaign_no
WHERE		(pt.complex_id = @complex_id)
GROUP BY 	pt.campaign_no,
			pt.complex_id,   
			c.complex_name,   
			pt.print_id,   
			fp.print_name,
			fp.print_status,
			fp.dead_period,
			pt.print_medium,
			pt.three_d_type

open prints_csr
fetch prints_csr into @campaign_no,@product_desc,@delivery_branch,@complex_name,@print_id,@print_name,@print_status,@dead_period,@print_medium,@three_d_type
while(@@fetch_status = 0)
begin

	select 	@actual_qty = isnull(sum(cinema_qty),0),
			@nom_actual_qty = isnull(sum(cinema_nominal_qty),0)
	from 	print_transactions
	where 	print_id = @print_id 
	and		complex_id = @complex_id 
	and		ptran_status = 'C' 
	and		campaign_no = @campaign_no
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type

	select 	@scheduled_qty_in = isnull(sum(cinema_qty),0),
			@nom_scheduled_qty_in = isnull(sum(cinema_nominal_qty),0)
	from 	print_transactions
	where 	print_id = @print_id 
	and		complex_id = @complex_id 
	and		ptran_status = 'S' 
	and		cinema_qty >= 0 
	and 	campaign_no = @campaign_no
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	
	select 	@scheduled_qty_out = isnull(sum(cinema_qty),0),
			@nom_scheduled_qty_out = isnull(sum(cinema_nominal_qty),0)
	from 	print_transactions
	where 	print_id = @print_id 
	and		complex_id = @complex_id 
	and		ptran_status = 'S' 
	and		cinema_qty < 0 
	and		campaign_no = @campaign_no
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type

	if (@actual_qty <> 0 or  @scheduled_qty_in <> 0 or @scheduled_qty_out <> 0) 			
	begin
		
		if (@print_status = 'A')
		begin
			select @print_status_name = "Active"
		end
		if	(@print_status = 'E')
		begin
			select @print_status_name = 'Expired'
		end		
		if	(@print_status = 'X')
		begin
			select @print_status_name = 'Dead'
		end		

		insert into #complex_prints (
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
			nom_actual_qty,
			nom_scheduled_qty_in,
			nom_scheduled_qty_out,
			print_status_name,
			print_medium,
			three_d_type ) 
		values (
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
			isnull(@nom_actual_qty,0),
			isnull(@nom_scheduled_qty_in,0),
			isnull(@nom_scheduled_qty_out,0),
			@print_status_name,
			@print_medium,
			@three_d_type
		)
		
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end
	end

	fetch prints_csr into @campaign_no,@product_desc,@delivery_branch,@complex_name,@print_id,@print_name,@print_status,@dead_period,@print_medium,@three_d_type
end	
close prints_csr
deallocate prints_csr

commit transaction

select * from #complex_prints

return 0

error:

	raiserror ('Error retrieving', 16, 1)
	close prints_csr
	return -1
GO
