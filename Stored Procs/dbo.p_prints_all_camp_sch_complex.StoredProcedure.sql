/****** Object:  StoredProcedure [dbo].[p_prints_all_camp_sch_complex]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_prints_all_camp_sch_complex]
GO
/****** Object:  StoredProcedure [dbo].[p_prints_all_camp_sch_complex]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_prints_all_camp_sch_complex] 	@campaign_no 	integer,
					                        @print_id   	integer,
	                                        @complex_id 	integer,
											@print_medium	char(1),
											@three_d_type	integer
as
set nocount on 
declare @actual_qty       		int,
        @scheduled_qty_in 		int,
        @scheduled_qty_out 		int,
		@nom_actual_qty       	int,
        @nom_scheduled_qty_in 	int,
        @nom_scheduled_qty_out 	int

/*
 * Get Print Qtys
 */

select 	@actual_qty = sum(cinema_qty),
		@nom_actual_qty = sum(cinema_nominal_qty)
from 	print_transactions
where 	(campaign_no = @campaign_no 
or		campaign_no is null) 
and		print_id = @print_id 
and		complex_id = @complex_id 
and		ptran_status = 'C'
and		print_medium = @print_medium
and		three_d_type = @three_d_type

select 	@scheduled_qty_in = sum(cinema_qty),
		@nom_scheduled_qty_in = sum(cinema_nominal_qty)
from 	print_transactions
where 	(campaign_no = @campaign_no 
or		campaign_no is null) 
and		print_id = @print_id 
and		complex_id = @complex_id 
and		ptran_status = 'S' 
and		cinema_qty >= 0
and		print_medium = @print_medium
and		three_d_type = @three_d_type

select 	@scheduled_qty_out = sum(cinema_qty),
		@nom_scheduled_qty_out = sum(cinema_nominal_qty)
from 	print_transactions
where	(campaign_no = @campaign_no 
or		campaign_no is null) 
and		print_id = @print_id 
and		complex_id = @complex_id 
and		ptran_status = 'S' 
and		cinema_qty < 0
and		print_medium = @print_medium
and		three_d_type = @three_d_type

select 	IsNull(@actual_qty,0),
		IsNull(@scheduled_qty_in,0),
		IsNull(@scheduled_qty_out,0),
		@print_medium,
		@three_d_type

return 0
GO
