/****** Object:  StoredProcedure [dbo].[p_confirmed_cl_print_qty]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_confirmed_cl_print_qty]
GO
/****** Object:  StoredProcedure [dbo].[p_confirmed_cl_print_qty]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_confirmed_cl_print_qty] @request_type  char(1),
											 @campaign_no	 integer,
                                  @print_id      integer,
                                  @branch_code   char(2),
                                  @cinelight_id    int,
                                  @confirmed_qty int OUTPUT
as

declare @error	  int

if @request_type = 'C'
begin

	select @confirmed_qty = IsNull(sum(cinema_qty),0)
	  from cinelight_print_transaction
	 where (campaign_no = @campaign_no or
		    @campaign_no is null) and
			 print_id = @print_id and
			 ptran_status_code = 'C' and
          cinelight_id = @cinelight_id

end
else if @request_type = 'B'
begin

	select @confirmed_qty = IsNull(sum(branch_qty),0)
	  from cinelight_print_transaction
	 where (campaign_no = @campaign_no or
		    @campaign_no is null) and
			 print_id = @print_id and
			 ptran_status_code = 'C' and
          branch_code = @branch_code

end

select @error = @@error
if (@error != 0)
begin
	raiserror ( 'Error', 16, 1) 
	return -1
end
else
	return 0
GO
