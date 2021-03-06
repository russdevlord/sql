/****** Object:  StoredProcedure [dbo].[p_delete_complex_trans]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_complex_trans]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_complex_trans]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_delete_complex_trans] 	@campaign_no	  	integer,
									@print_id      		integer,
									@complex_id    		integer,
									@tran_in       		char(1),
									@tran_out      		char(1),
									@adjs          		char(1),
									@print_medium		char(1),
									@three_d_type		integer

as

declare @error      integer

begin transaction

if @tran_in = 'Y'
begin

	delete 	print_transactions
	where 	(campaign_no = @campaign_no 
	or 		@campaign_no is null ) 
	and 	print_id = @print_id 
	and 	complex_id = @complex_id 
	and 	ptran_status = 'S' 
	and 	ptran_type = 'T' 
	and 	cinema_qty > 0
	and		print_medium = @print_medium
	and 	three_d_type = @three_d_type

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	

end

if @tran_out = 'Y'
begin

	delete 	print_transactions
	where 	(campaign_no = @campaign_no 
	or		@campaign_no is null ) 
	and		print_id = @print_id 
	and		complex_id = @complex_id 
	and		ptran_status = 'S' 
	and		ptran_type = 'T' 
	and		cinema_qty < 0
	and		print_medium = @print_medium
	and 	three_d_type = @three_d_type

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	

end

if @adjs = 'Y'
begin

	delete 	print_transactions
	where 	(campaign_no = @campaign_no 
	or		@campaign_no is null ) 
	and		print_id = @print_id 
	and		complex_id = @complex_id 
	and		ptran_status = 'S' 
	and		ptran_type <> 'T' 
	and		branch_qty = 0
	and		print_medium = @print_medium
	and 	three_d_type = @three_d_type

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	

end

commit transaction
return 0
GO
