USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_cl_branch_trans]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_delete_cl_branch_trans] @campaign_no	 integer,
											 @print_id      integer,
                                  @branch_code   char(2),
                                  @incoming      char(1),
                                  @tran_in       char(1),
                                  @tran_out      char(1),
                                  @adjs          char(1)
as

declare @error      int

begin transaction

if @incoming = 'Y'
begin

	delete cinelight_print_transaction
    where (campaign_no = @campaign_no or
			 @campaign_no is null ) and
			 print_id = @print_id and
          branch_code = @branch_code and
          ptran_status_code = 'S' and
          ptran_type_code = 'I'

	select @error = @@error
   if ( @error !=0 )
   begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
   	return @error
	end	

end

if @tran_in = 'Y'
begin

	delete cinelight_print_transaction
    where (campaign_no = @campaign_no or
			 @campaign_no is null ) and
			 print_id = @print_id and
          branch_code = @branch_code and
          ptran_status_code = 'S' and
          ptran_type_code = 'T' and
          branch_qty > 0

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

	delete cinelight_print_transaction
    where (campaign_no = @campaign_no or
			 @campaign_no is null ) and
			 print_id = @print_id and
          branch_code = @branch_code and
          ptran_status_code = 'S' and
          ptran_type_code = 'T' and
          branch_qty < 0

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

	delete cinelight_print_transaction
    where (campaign_no = @campaign_no or
			 @campaign_no is null ) and
			 print_id = @print_id and
          branch_code = @branch_code and
          ptran_status_code = 'S' and
          ptran_type_code <> 'T' and
          cinema_qty = 0

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
