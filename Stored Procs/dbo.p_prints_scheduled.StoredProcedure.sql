/****** Object:  StoredProcedure [dbo].[p_prints_scheduled]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_prints_scheduled]
GO
/****** Object:  StoredProcedure [dbo].[p_prints_scheduled]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_prints_scheduled] 	@campaign_no 		integer,
                               	@print_id    		integer,
								@print_medium		char(1),
								@three_d_type		integer
as

set nocount on 

declare @cinema_qty       		int,
		@vm_qty           		int,
		@requested_qty     		int,
		@incoming_qty      		int,
		@scheduled_qty     		int,
		@nom_cinema_qty       	int,
		@nom_vm_qty           	int,
		@nom_requested_qty     	int,
		@nom_incoming_qty      	int,
		@nom_scheduled_qty     	int

select 	@cinema_qty = sum(cinema_qty),
		@nom_cinema_qty = sum(cinema_nominal_qty)
from 	print_transactions
where 	campaign_no = @campaign_no 
and  	print_id = @print_id 
and 	ptran_status = 'C'
and		print_medium = @print_medium
and 	three_d_type = @three_d_type

select 	@vm_qty = sum(branch_qty),
		@nom_vm_qty = sum(branch_nominal_qty)
from 	print_transactions
where 	campaign_no = @campaign_no 
and 	print_id = @print_id 
and 	ptran_status = 'C'
and		print_medium = @print_medium
and 	three_d_type = @three_d_type

select 	@requested_qty = requested_qty,
		@nom_requested_qty = nominal_qty
from 	film_campaign_prints
where 	campaign_no = @campaign_no 
and 	print_id = @print_id
and		print_medium = @print_medium
and 	three_d_type = @three_d_type


select 	@incoming_qty = sum(branch_qty),
		@nom_incoming_qty = sum(branch_nominal_qty)
from 	print_transactions
where 	campaign_no = @campaign_no 
and 	print_id = @print_id 
and 	ptran_type = 'I'
and		print_medium = @print_medium
and 	three_d_type = @three_d_type

select 	@scheduled_qty = sum(branch_qty),
 		@nom_scheduled_qty = sum(branch_nominal_qty)
from 	print_transactions
where 	campaign_no = @campaign_no 
and 	print_id = @print_id 
and 	ptran_type = 'I' 
and 	ptran_status = 'S'
and		print_medium = @print_medium
and 	three_d_type = @three_d_type

select 	IsNull(@cinema_qty,0),
		IsNull(@vm_qty,0),
		IsNull(@requested_qty,0),
		IsNull(@incoming_qty,0),
		IsNull(@requested_qty,0),
		IsNull(@nom_cinema_qty,0),
		IsNull(@nom_vm_qty,0),
		IsNull(@nom_requested_qty,0),
		IsNull(@nom_incoming_qty,0),
		IsNull(@nom_requested_qty,0)
GO
