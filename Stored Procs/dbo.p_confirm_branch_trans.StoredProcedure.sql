/****** Object:  StoredProcedure [dbo].[p_confirm_branch_trans]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_confirm_branch_trans]
GO
/****** Object:  StoredProcedure [dbo].[p_confirm_branch_trans]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_confirm_branch_trans] 	@campaign_no	integer,
									@print_id       integer,
									@branch_code    char(2),
									@tran_date      datetime,
									@incoming       char(1),
									@tran_in        char(1),
									@tran_out       char(1),
									@adjs           char(1),
									@print_medium	char(1),
									@three_d_type	int
as

declare @error				integer,
        @ptran_id			integer,
        @errorode				integer,
        @tran_qty			integer,
        @complex_id			integer,
        @actual_qty			integer,
        @complex_name		varchar(50),
        @branch_name 		varchar(50)

/*
 * Setup Confirmed date
 */

if @tran_date = NULL
	select @tran_date = getdate()
 
/*
 * Get Branch Name
 */

select @branch_name = branch_name
  from branch
 where branch_code = @branch_code

select @branch_name = @branch_name + ' Branch'

/*
 * Begin Processing
 */

begin transaction

if @tran_in = 'Y'
begin
	declare 	in_csr cursor static for
	select 		pt.ptran_id,
				pt.branch_qty,
				pt.complex_id,
				cplx.complex_name
	from 		print_transactions pt,
				complex cplx
	where 		(pt.campaign_no = @campaign_no 
	or			@campaign_no is null) 
	and			pt.print_id = @print_id 
	and			pt.branch_code = @branch_code 
	and			pt.ptran_status = 'S' 
	and			pt.ptran_type = 'T' 
	and			pt.branch_qty > 0 
	and			pt.complex_id = cplx.complex_id
	and			pt.print_medium = @print_medium
	and			pt.three_d_type = @three_d_type

	open in_csr
	fetch in_csr into @ptran_id, @tran_qty, @complex_id, @complex_name
	while(@@fetch_status = 0)
	begin

		exec @errorode = p_confirmed_print_qty 'C', @campaign_no, @print_id, @branch_code, @complex_id, @print_medium, @three_d_type, @actual_qty OUTPUT

		if (@errorode != 0)
		begin
			rollback transaction
			close in_csr
         	deallocate in_csr
			return -1
		end

		if @tran_qty > @actual_qty
		begin
			rollback transaction
			raiserror (50007, 11,1, @tran_qty, @complex_name, @branch_name)
			close in_csr
         	deallocate in_csr
			return -1
		end

		update 	print_transactions
		set 	ptran_status = 'C',
				ptran_date = @tran_date
		where 	ptran_id = @ptran_id

		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ( 'Error', 16, 1) 
			close in_csr
         	deallocate in_csr
			return @error
		end	

	   fetch in_csr into @ptran_id, @tran_qty, @complex_id, @complex_name

	end

	close in_csr
   deallocate in_csr

end

if @tran_out = 'Y'
begin

declare out_csr cursor static for
	select 	pt.ptran_id,
			pt.cinema_qty,
			cplx.complex_name
	from 	print_transactions pt,
			complex cplx
	where 	(pt.campaign_no = @campaign_no 
	or		@campaign_no is null) 
	and		pt.print_id = @print_id 
	and		pt.branch_code = @branch_code 
	and		pt.ptran_status = 'S' 
	and		pt.ptran_type = 'T' 
	and		pt.branch_qty < 0 
	and		pt.complex_id = cplx.complex_id
	and		pt.print_medium = @print_medium
	and		pt.three_d_type = @three_d_type

	open out_csr
	fetch out_csr into @ptran_id, @tran_qty, @complex_name
	while(@@fetch_status = 0)
	begin

		exec @errorode = p_confirmed_print_qty 'B', @campaign_no, @print_id, @branch_code, 0, @print_medium, @three_d_type, @actual_qty OUTPUT
		if (@errorode != 0)
		begin
			rollback transaction
			close out_csr
         	deallocate out_csr
			return -1
		end

		if @tran_qty > @actual_qty
		begin
			rollback transaction
			raiserror (50007,11,1, @tran_qty, @branch_name, @complex_name)
			close out_csr
         	deallocate out_csr
			return @error
		end

		update 	print_transactions
		set 	ptran_status = 'C',
				ptran_date = @tran_date
		where 	ptran_id = @ptran_id

		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ( 'Error', 16, 1) 
			close out_csr
         	deallocate out_csr
			return @error
		end	

	   fetch out_csr into @ptran_id, @tran_qty, @complex_name

	end

	close out_csr
   deallocate out_csr

end

if @incoming = 'Y'
begin
	
	update 	print_transactions
	set 	ptran_status = 'C',
			ptran_date = @tran_date
	where 	campaign_no = @campaign_no 
	and 	print_id = @print_id 
	and 	branch_code = @branch_code 
	and 	ptran_status = 'S' 
	and 	ptran_type = 'I'
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type


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

	update 	print_transactions
	set	 	ptran_status = 'C',
			ptran_date = @tran_date
	where 	campaign_no = @campaign_no 
	and		print_id = @print_id 
	and		branch_code = @branch_code 
	and		ptran_status = 'S' 
	and		ptran_type <> 'I' 
	and		cinema_qty = 0
	and		print_medium = @print_medium
	and		three_d_type = @three_d_type

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
