/****** Object:  StoredProcedure [dbo].[p_cinelight_campaign_print_tracking]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelight_campaign_print_tracking]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_campaign_print_tracking]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cinelight_campaign_print_tracking] @campaign_no integer
as

declare 	@print_id    			integer,
			@actual_qty       	integer,
        	@scheduled_qty_in 	integer,
        	@scheduled_qty_out 	integer,
			@complex_qty			integer,
			@incoming_qty			integer,
			@requested_qty			integer,
			@calculated_qty		integer,
			@print_name				varchar(50),
			@error					integer

create table #cinelight_print_select
(
	print_id				integer			null,
	print_name			varchar(50)		null,
	requested_qty		integer			null,
	calculated_qty		integer			null,
	actual_qty	 		integer			null,
	scheduled_qty_in	integer			null,
	scheduled_qty_out	integer			null,	
	incoming_qty		integer			null,
	complex_qty			integer			null
)

/*
 * Declare cursor static for each print in the campaign
 */

declare print_csr cursor static for 
select print_id,
       requested_qty,
       calculated_qty
  from cinelight_campaign_print 
 where campaign_no = @campaign_no

/*
 * Get Totals for a particular campaign print
 */

open print_csr
fetch print_csr into @print_id, @requested_qty, @calculated_qty
while(@@fetch_status = 0)
	begin

	select @print_name = print_name 
     from cinelight_print
	 where print_id = @print_id

	select @actual_qty = sum(branch_qty)
	  from cinelight_print_transaction
	 where print_id = @print_id and
			 campaign_no = @campaign_no and
			 ptran_status_code = 'C'
	
	select @scheduled_qty_in = sum(branch_qty)
	  from cinelight_print_transaction
	 where print_id = @print_id and
			 ptran_status_code = 'S' and
			 campaign_no = @campaign_no and
			 branch_qty >= 0
	
	select @scheduled_qty_out = sum(branch_qty)
	  from cinelight_print_transaction
	 where print_id = @print_id and
			 ptran_status_code = 'S' and
			 campaign_no = @campaign_no and
			 branch_qty < 0
	
	select @incoming_qty = sum(branch_qty)
	  from cinelight_print_transaction
	 where print_id = @print_id and
			 campaign_no = @campaign_no and
			 ptran_type_code = 'I'
	
   select @complex_qty = sum(cinema_qty)
	  from cinelight_print_transaction
	 where print_id = @print_id and
			 campaign_no = @campaign_no and
			 ptran_status_code = 'C'

	insert into #cinelight_print_select
		(	print_id,
			print_name,
			requested_qty,
			calculated_qty,
			actual_qty,
			scheduled_qty_in,
			scheduled_qty_out,		
			incoming_qty,
			complex_qty
		) values
		( 	IsNull(@print_id,0), 
			IsNull(@print_name, ''),
			IsNull(@requested_qty,0),
			IsNull(@calculated_qty,0),
			IsNull(@actual_qty,0),
			IsNull(@scheduled_qty_in,0),
			IsNull(@scheduled_qty_out,0),
			IsNull(@incoming_qty,0),
			IsNull(@complex_qty,0)
		)
	
	select @error = @@error
	if (@error !=0)
	begin
		goto error
	end

	fetch print_csr into @print_id, @requested_qty, @calculated_qty
end	

close print_csr

/*
 * Return results
 */

select 	@campaign_no as campaign_no,
			print_id,
			print_name,
			requested_qty,
			calculated_qty,
			incoming_qty,
			actual_qty,
			scheduled_qty_in,
			scheduled_qty_out,
			complex_qty
from 		#cinelight_print_select
order by print_id

return 0

error:

	raiserror ('Error retrieving cinelights prints information', 16, 1)
	close print_csr
	return -1
GO
