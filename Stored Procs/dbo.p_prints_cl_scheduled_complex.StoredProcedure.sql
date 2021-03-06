/****** Object:  StoredProcedure [dbo].[p_prints_cl_scheduled_complex]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_prints_cl_scheduled_complex]
GO
/****** Object:  StoredProcedure [dbo].[p_prints_cl_scheduled_complex]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_prints_cl_scheduled_complex] @campaign_no 	integer,
					@print_id   	integer,
                    @cinelight_id 	integer
as
set nocount on 
declare @actual_qty       	int,
        @scheduled_qty_in 	int,
        @scheduled_qty_out int

select @actual_qty = sum(cinema_qty)
  from cinelight_print_transaction
 where (campaign_no = @campaign_no or
		 (@campaign_no = null and
		 campaign_no is null)) and
		 print_id = @print_id and
       cinelight_id = @cinelight_id and
       ptran_status_code = 'C'

select @scheduled_qty_in = sum(cinema_qty)
  from cinelight_print_transaction
 where (campaign_no = @campaign_no or
		 (@campaign_no = null and
		 campaign_no is null)) and
		 print_id = @print_id and
       cinelight_id = @cinelight_id and
       ptran_status_code = 'S' and
       cinema_qty >= 0

select @scheduled_qty_out = sum(cinema_qty)
  from cinelight_print_transaction
 where (campaign_no = @campaign_no or
		 (@campaign_no = null and
		 campaign_no is null)) and
		 print_id = @print_id and
       cinelight_id = @cinelight_id and
       ptran_status_code = 'S' and
       cinema_qty < 0

select IsNull(@actual_qty,0),
       IsNull(@scheduled_qty_in,0),
       IsNull(@scheduled_qty_out,0)
GO
