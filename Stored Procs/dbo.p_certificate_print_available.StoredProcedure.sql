/****** Object:  StoredProcedure [dbo].[p_certificate_print_available]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_print_available]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_print_available]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_certificate_print_available] 	@complex_id			integer,
											@screening_date		datetime,
											@print_id			integer,
											@print_medium		char(1),
											@three_d_type		int
as

/*
 * Declare Variables
 */

declare @error     		integer,
		  @prints_used		integer,
		  @total_prints	integer,
		  @prints_avail	integer

/*
 * Check the status of the complex
 */

select 	@total_prints = isnull(sum(cinema_qty),0)
from 	print_transactions
where 	complex_id = @complex_id
and		ptran_status = 'C' 
and		print_id = @print_id
and		print_medium = @print_medium
and		three_d_type = @three_d_type

select 	@prints_used = isnull(count(ci.certificate_item_id),0)
from 	certificate_item ci,
		certificate_group cg
where 	ci.certificate_group = cg.certificate_group_id 
and		cg.screening_date = @screening_date 
and		cg.complex_id = @complex_id 
and		ci.print_id = @print_id
and		ci.print_medium = @print_medium
and		ci.three_d_type = @three_d_type

select @prints_avail = @total_prints - @prints_used

/*
 * Return
 */

select @prints_avail

return 0
GO
