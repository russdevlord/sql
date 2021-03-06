/****** Object:  StoredProcedure [dbo].[p_swap_payment_deposit]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_swap_payment_deposit]
GO
/****** Object:  StoredProcedure [dbo].[p_swap_payment_deposit]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_swap_payment_deposit] 		@tran_id				integer

as
set nocount on 
declare 	@tran_desc		varchar(50),
		  	@tran_type     integer,
			@batch_item_no	integer,
			@error			integer

                                                                                

select @tran_desc = tran_desc, 
		 @tran_type = tran_type, 
       @batch_item_no = batch_item_no
  from slide_transaction
 where tran_id = @tran_id

                                                                     

if @tran_type <> 53 and @tran_type <> 57
begin
	raiserror ('You may only use this function with a Payment or a Deposit', 16, 1)
	return -1
end

                             

begin transaction

                                                                                            

if @tran_type = 57
begin
	
	update slide_transaction
   	set tran_desc = 'Payment Received, Thankyou.', tran_type = 53
	 where tran_id = @tran_id

	select @error = @@error
	if (@error !=0)
		begin
			rollback transaction
			raiserror ('p_swap_payment_deposit : Update Error', 16, 1)
			return -1
		end	

	if @batch_item_no is not null 
	begin

		update batch_item
		   set pay_type = 'P'
		 where batch_item_no = @batch_item_no
		
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			raiserror ('Update Error(2)', 16, 1)
			return -1
		end	
	end
end

else if @tran_type = 53
begin
	update slide_transaction
   	set tran_desc = 'Deposit of Signing of contract - Thankyou.', tran_type = 57
	 where tran_id = @tran_id

	select @error = @@error
	if (@error !=0)
		begin
			rollback transaction
			raiserror ('Update error (3)', 16, 1)
			return -1
		end	

	if @batch_item_no is not null 
	begin
	
			update batch_item
			   set pay_type = 'D'
			 where batch_item_no = @batch_item_no

		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ('Update Error (3)', 16, 1)
			return -1
		end
   end
end

                             

commit transaction
return 0
GO
