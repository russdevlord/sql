/****** Object:  StoredProcedure [dbo].[p_schedule_branch_trans]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_schedule_branch_trans]
GO
/****** Object:  StoredProcedure [dbo].[p_schedule_branch_trans]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_schedule_branch_trans] @campaign_no   				integer,
									@shell_code					char(7),
									@print_id      				integer,
									@branch_code   				char(2),
									@print_medium				char(1),
									@three_d_type				integer,
									@scheduled_qty 				integer,
									@scheduled_nominal_qty		integer
as

declare @error      		integer,
		@branch_qty 		integer,
		@nom_branch_qty 	integer,
		@ptran_id   		integer,
		@tran_qty   		integer,
		@nom_tran_qty  		integer,
		@errorode      		integer

set nocount on 

select 	@tran_qty = 0,
		@nom_tran_qty = 0

if not @campaign_no is null
begin
	select 	@branch_qty = IsNull(sum(branch_qty),0),
			@nom_branch_qty = IsNull(sum(branch_nominal_qty),0)
	from 	print_transactions
	where	campaign_no = @campaign_no 
	and		print_id = @print_id 
	and		ptran_type = 'I'
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type

	select  @tran_qty = @scheduled_qty - @branch_qty,
			@nom_tran_qty = @scheduled_nominal_qty - @nom_branch_qty
end 

if not @shell_code is null
begin
	select 	@branch_qty = IsNull(sum(branch_qty),0),
			@nom_branch_qty = IsNull(sum(branch_nominal_qty),0)
	from 	print_transactions
	where 	campaign_no is null 
	and		print_id = @print_id 
	and		ptran_type = 'I'
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type
	
	select 	@scheduled_qty = sum(shell_max_prints),
			@scheduled_nominal_qty = sum(shell_max_prints)
	from 	film_shell,
			film_shell_xref
	where 	film_shell.shell_code = @shell_code 
	and		film_shell.shell_code = film_shell_xref.shell_code
	
	if @scheduled_qty is null
		select 	@scheduled_qty = sum(movie_target),
				@scheduled_nominal_qty = sum(movie_target)
		from 	complex,
				film_shell_xref 
		where 	complex.complex_id = film_shell_xref.complex_id 
		and		film_shell_xref.shell_code = @shell_code
	
	select 	@tran_qty = @scheduled_qty - @branch_qty,
			@nom_tran_qty = @scheduled_nominal_qty - @nom_branch_qty	
end

if @tran_qty > 0 or @nom_tran_qty > 0
begin

	begin transaction

	execute @errorode = p_get_sequence_number 'print_transactions',5,@ptran_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
   	return -1
	end

	insert into print_transactions (
	ptran_id,
	campaign_no,
	print_id,
	branch_code,
	ptran_type,
	ptran_status,
	complex_id,
	ptran_date,
	branch_qty,
	cinema_qty,
	branch_nominal_qty,
	cinema_nominal_qty,
	print_medium,
	three_d_type
	)
	values ( @ptran_id,
	@campaign_no,
	@print_id,
	@branch_code,
	'I',
	'S',
	Null,
	getdate(),
	@tran_qty,
	0,
	@nom_tran_qty,
	0,
	@print_medium,
	@three_d_type
	)              

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ('Error inserting Print Transaction', 16, 1)
		return @error
	end	

	commit transaction

end
return 0
GO
