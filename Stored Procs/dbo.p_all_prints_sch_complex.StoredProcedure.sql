/****** Object:  StoredProcedure [dbo].[p_all_prints_sch_complex]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_all_prints_sch_complex]
GO
/****** Object:  StoredProcedure [dbo].[p_all_prints_sch_complex]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_all_prints_sch_complex] @complex_id 	integer
as

declare @actual_qty       		integer,
        @scheduled_qty_in 		integer,
        @scheduled_qty_out 		integer,
		@nom_actual_qty       	integer,
        @nom_scheduled_qty_in 	integer,
        @nom_scheduled_qty_out 	integer,
		@print_id				integer,
		@print_medium			char(1),
		@three_d_type			integer

/*
 * Declare Temp table
 */ 

create table #complex_prints
(
	print_id					integer 	null,
	actual_qty					integer		null,
	scheduled_qty_in			integer		null,
	scheduled_qty_out			integer		null,
	nom_actual_qty				integer		null,
	nom_scheduled_qty_in		integer		null,
	nom_scheduled_qty_out		integer		null,
	print_medium				char(1)		null,
	three_d_type				int			null
)

/*
 * Declare Cursors
 */

declare 	complex_prints_csr cursor static for
select 		distinct print_id,
			print_medium,
			three_d_type
from 		print_transactions
where 		campaign_no is null 
and			complex_id = @complex_id 
order by 	print_id
for 		read only

open complex_prints_csr
fetch complex_prints_csr into @print_id, @print_medium, @three_d_type
while(@@fetch_status=0)
begin

	select 	@actual_qty = sum(cinema_qty)
	from 	print_transactions
	where 	campaign_no is null
	and		print_id = @print_id 
	and		complex_id = @complex_id 
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	and		ptran_status = 'C'
	
	select 	@scheduled_qty_in = sum(cinema_qty)
	from 	print_transactions
	where 	campaign_no is null 
	and		print_id = @print_id 
	and		complex_id = @complex_id 
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	and		ptran_status = 'S' 
	and		cinema_qty >= 0
	
	select 	@scheduled_qty_out = sum(cinema_qty)
	from 	print_transactions
	where 	campaign_no is null 
	and		print_id = @print_id 
	and		complex_id = @complex_id 
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	and		ptran_status = 'S' 
	and		cinema_qty < 0
	
	select 	@nom_actual_qty = sum(cinema_nominal_qty)
	from 	print_transactions
	where 	campaign_no is null
	and		print_id = @print_id 
	and		complex_id = @complex_id 
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	and		ptran_status = 'C'
	
	select 	@nom_scheduled_qty_in = sum(cinema_nominal_qty)
	from 	print_transactions
	where 	campaign_no is null 
	and		print_id = @print_id 
	and		complex_id = @complex_id 
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	and		ptran_status = 'S' 
	and		cinema_qty >= 0
	
	select 	@nom_scheduled_qty_out = sum(cinema_nominal_qty)
	from 	print_transactions
	where 	campaign_no is null 
	and		print_id = @print_id 
	and		complex_id = @complex_id 
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	and		ptran_status = 'S' 
	and		cinema_qty < 0

	insert into #complex_prints 
	(
	print_id,
	actual_qty,
	scheduled_qty_in,
	scheduled_qty_out,
	nom_actual_qty,
	nom_scheduled_qty_in,
	nom_scheduled_qty_out,
	print_medium,
	three_d_type
	) values
	(
	@print_id,
	isnull(@actual_qty,0),
	isnull(@scheduled_qty_in,0),
	isnull(@scheduled_qty_out,0),
	isnull(@nom_actual_qty,0),
	isnull(@nom_scheduled_qty_in,0),
	isnull(@nom_scheduled_qty_out,0),
	@print_medium,
	@three_d_type
	)

	fetch complex_prints_csr into @print_id, @print_medium, @three_d_type
end

close complex_prints_csr
deallocate complex_prints_csr

select 	print_id,
		actual_qty,
		scheduled_qty_in,
		scheduled_qty_out,
		print_medium,
		three_d_type
from 	#complex_prints

return 0
GO
