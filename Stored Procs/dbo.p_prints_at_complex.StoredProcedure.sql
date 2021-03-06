/****** Object:  StoredProcedure [dbo].[p_prints_at_complex]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_prints_at_complex]
GO
/****** Object:  StoredProcedure [dbo].[p_prints_at_complex]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_prints_at_complex]  	@campaign_no 	integer,
									@print_id   	integer,
									@complex_id 	integer,
									@print_medium	char(1),
									@three_d_type	integer,
									@actual_qty		integer OUTPUT
as

set nocount on 

declare @error       	integer

select 	@actual_qty = sum(cinema_qty)
from 	print_transactions
where 	(campaign_no = @campaign_no 
or		(@campaign_no is null 
and		campaign_no is null)) 
and		print_id = @print_id 
and		complex_id = @complex_id 
and		ptran_status = 'C'
and		print_medium = @print_medium
and		three_d_type = @three_d_type

return 0
GO
