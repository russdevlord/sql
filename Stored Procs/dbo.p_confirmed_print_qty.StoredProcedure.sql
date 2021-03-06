/****** Object:  StoredProcedure [dbo].[p_confirmed_print_qty]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_confirmed_print_qty]
GO
/****** Object:  StoredProcedure [dbo].[p_confirmed_print_qty]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_confirmed_print_qty] 	@request_type  		char(1),
									@campaign_no	 	integer,
									@print_id      		integer,
									@branch_code   		char(2),
									@complex_id    		int,
									@print_medium		char(1),
									@three_d_type		int,
									@confirmed_qty 		int OUTPUT
as

declare @error	  int

if @request_type = 'C'
begin
	
	select 	@confirmed_qty = IsNull(sum(cinema_qty),0)
	from 	print_transactions
	where 	(campaign_no = @campaign_no 
	or		@campaign_no is null) 
	and		print_id = @print_id 
	and		ptran_status = 'C' 
	and		complex_id = @complex_id
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type

end
else if @request_type = 'B'
begin

	select 	@confirmed_qty = IsNull(sum(branch_qty),0)
	from 	print_transactions
	where 	(campaign_no = @campaign_no 
	or		@campaign_no is null) 
	and		print_id = @print_id 
	and		ptran_status = 'C' 
	and		branch_code = @branch_code
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
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
