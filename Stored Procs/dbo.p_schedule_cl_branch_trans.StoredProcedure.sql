/****** Object:  StoredProcedure [dbo].[p_schedule_cl_branch_trans]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_schedule_cl_branch_trans]
GO
/****** Object:  StoredProcedure [dbo].[p_schedule_cl_branch_trans]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_schedule_cl_branch_trans] @campaign_no   integer,
				@print_id      integer,
                @branch_code   char(2),
                @scheduled_qty integer
as
set nocount on 
declare  @error      integer,
			@branch_qty integer,
			@ptran_id   integer,
			@tran_qty   integer,
			@errorode      integer

begin transaction

select @tran_qty = 0

if not @campaign_no is null
begin
	select @branch_qty = IsNull(sum(branch_qty),0)
	  from cinelight_print_transaction
	 where campaign_no = @campaign_no and
			 print_id = @print_id and
			 ptran_type_code = 'I'
	
	select @tran_qty = @scheduled_qty - @branch_qty	
end 

if @tran_qty > 0
begin

	execute @errorode = p_get_sequence_number 'cinelight_print_transaction',5,@ptran_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
   	return -1
	end

	insert into cinelight_print_transaction (
          ptran_id,
          campaign_no,
          print_id,
          branch_code,
          ptran_type_code,
          ptran_status_code,
          cinelight_id,
          ptran_date,
          branch_qty,
          cinema_qty )
 values ( @ptran_id,
          @campaign_no,
		  @print_id,
          @branch_code,
          'I',
          'S',
          Null,
          getdate(),
          @tran_qty,
          0 )              

	select @error = @@error
   if ( @error !=0 )
   begin
		rollback transaction
		raiserror ('Error inserting Cinelight Print Transaction', 16, 1)
   	return @error
	end	

end

commit transaction

return 0
GO
