/****** Object:  StoredProcedure [dbo].[p_prints_scheduled_branch]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_prints_scheduled_branch]
GO
/****** Object:  StoredProcedure [dbo].[p_prints_scheduled_branch]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_prints_scheduled_branch] 	@campaign_no		integer,
										@print_id    		integer,
										@branch_code 		char(2)

as

declare @actual_qty       			int,
        @scheduled_qty_in 			int,
        @scheduled_qty_out 			int,
        @incoming_qty      			int,
		@nom_actual_qty       		int,
        @nom_scheduled_qty_in 		int,
        @nom_scheduled_qty_out 		int,
        @nom_incoming_qty      		int,
		@print_medium				char(1),
		@three_d_type				integer

set nocount on 

create table #branch_prints
(
actual_qty       		int			null,
scheduled_qty_in 		int			null,
scheduled_qty_out 		int			null,
incoming_qty			int			null,
nom_actual_qty       	int			null,
nom_scheduled_qty_in 	int			null,
nom_scheduled_qty_out 	int			null,
nom_incoming_qty		int			null,
print_medium			char(1)		null,
three_d_type			integer		null
)

declare 	medium_three_d_csr cursor for 
select		print_medium,
			three_d_type
from		print_medium,
			three_d
order by	print_medium,
			three_d_type

open medium_three_d_csr
fetch medium_three_d_csr into @print_medium, @three_d_type
while(@@fetch_status = 0)
begin

	select 	@actual_qty = isnull(sum(branch_qty),0),
			@nom_actual_qty = isnull(sum(branch_nominal_qty),0)
	from 	print_transactions
	where 	(campaign_no = @campaign_no 
	or		(@campaign_no = null 
	and		campaign_no is null)) 
	and		print_id = @print_id 
	and		branch_code = @branch_code 
	and		ptran_status = 'C'
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	
	select 	@scheduled_qty_in = isnull(sum(branch_qty),0),
			@nom_scheduled_qty_in = isnull(sum(branch_nominal_qty),0)
	from 	print_transactions
	where 	(campaign_no = @campaign_no 
	or		(@campaign_no = null 
	and		campaign_no is null))
	and		print_id = @print_id 
	and		branch_code = @branch_code
	and		ptran_status = 'S' 
	and		branch_qty >= 0
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	
	select 	@scheduled_qty_out = isnull(sum(branch_qty),0),
			@nom_scheduled_qty_out = isnull(sum(branch_nominal_qty),0)
	from 	print_transactions
	where 	(campaign_no = @campaign_no 
	or		(@campaign_no = null 
	and		campaign_no is null)) 
	and		print_id = @print_id 
	and		branch_code = @branch_code 
	and		ptran_status = 'S' 
	and		branch_qty < 0
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	
	select 	@incoming_qty = isnull(sum(branch_qty),0),
			@nom_incoming_qty = isnull(sum(branch_nominal_qty),0)
	from 	print_transactions
	where 	(campaign_no = @campaign_no 
	or		(@campaign_no = null 
	and		campaign_no is null)) 
	and		print_id = @print_id 
	and		branch_code = @branch_code 
	and		ptran_type = 'I'
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	
	if @actual_qty <> 0 or @scheduled_qty_in <> 0 or @scheduled_qty_out <> 0 or @nom_actual_qty <> 0 or @nom_scheduled_qty_in <> 0 or @nom_scheduled_qty_out <> 0 or @incoming_qty <> 0 or @nom_incoming_qty <> 0
	begin
		insert into #branch_prints
		(
		actual_qty,
		scheduled_qty_in,
		scheduled_qty_out,
		incoming_qty,
		nom_actual_qty,
		nom_scheduled_qty_in,
		nom_scheduled_qty_out,
		nom_incoming_qty,
		print_medium,
		three_d_type
		)
		values
		(
		@actual_qty,
		@scheduled_qty_in,
		@scheduled_qty_out,
		@incoming_qty,
		@nom_actual_qty,
		@nom_scheduled_qty_in,
		@nom_scheduled_qty_out,
		@nom_incoming_qty,
		@print_medium,
		@three_d_type
		)
	end

	fetch medium_three_d_csr into @print_medium, @three_d_type

end

select 	actual_qty,
		scheduled_qty_in,
		scheduled_qty_out,
		incoming_qty,
		nom_actual_qty,
		nom_scheduled_qty_in,
		nom_scheduled_qty_out,
		nom_incoming_qty,
		print_medium,
		three_d_type
from 	#branch_prints

return 0
GO
