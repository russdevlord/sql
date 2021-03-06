/****** Object:  StoredProcedure [dbo].[p_cl_all_prints_sch_complex]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cl_all_prints_sch_complex]
GO
/****** Object:  StoredProcedure [dbo].[p_cl_all_prints_sch_complex]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cl_all_prints_sch_complex] @cinelight_id 	integer
as

declare @actual_qty       	integer,
        @scheduled_qty_in 	integer,
        @scheduled_qty_out integer,
		  @print_id				integer


/*
 * Declare Temp table
 */ 

create table #complex_prints
(
	print_id					integer 		null,
	actual_qty				integer		null,
	scheduled_qty_in		integer		null,
	scheduled_qty_out		integer		null
)

/*
 * Declare Cursors
 */

 declare complex_prints_csr cursor static for
  select distinct print_id
    from cinelight_print_transaction
   where campaign_no is null and
		   cinelight_id = @cinelight_id 
order by print_id
	  for read only


open complex_prints_csr
fetch complex_prints_csr into @print_id
while(@@fetch_status=0)
begin

	select @actual_qty = sum(cinema_qty)
	  from cinelight_print_transaction
	 where campaign_no is null and
			 print_id = @print_id and
			 cinelight_id = @cinelight_id and
			 ptran_status_code = 'C'
	
	select @scheduled_qty_in = sum(cinema_qty)
	  from cinelight_print_transaction
	 where campaign_no is null and
			 print_id = @print_id and
			 cinelight_id = @cinelight_id and
			 ptran_status_code = 'S' and
			 cinema_qty >= 0
	
	select @scheduled_qty_out = sum(cinema_qty)
	  from cinelight_print_transaction
	 where campaign_no is null and
			 print_id = @print_id and
			 cinelight_id = @cinelight_id and
			 ptran_status_code = 'S' and
			 cinema_qty < 0

	insert into #complex_prints 
					(	print_id,
						actual_qty,
						scheduled_qty_in,
						scheduled_qty_out) values
						(@print_id,
						 IsNull(@actual_qty,0),
						 IsNull(@scheduled_qty_in,0),
						 IsNull(@scheduled_qty_out,0))

	fetch complex_prints_csr into @print_id
end

close complex_prints_csr
deallocate complex_prints_csr

select * from #complex_prints

return 0
GO
