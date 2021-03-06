/****** Object:  StoredProcedure [dbo].[p_certificate_print_usage]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_print_usage]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_print_usage]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_certificate_print_usage] 	@complex_id 		integer

as

set nocount on 

declare 		@actual_qty       			integer,
				@campaign_no 				integer,
				@print_id   				integer

select sum(cinema_qty)
  from print_transactions
 where (campaign_no = @campaign_no or
		 (@campaign_no = null and
		 campaign_no is null)) and
		 print_id = @print_id and
       complex_id = @complex_id and
       ptran_status = 'C'

return 0
GO
