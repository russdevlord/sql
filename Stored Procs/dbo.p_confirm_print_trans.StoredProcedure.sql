/****** Object:  StoredProcedure [dbo].[p_confirm_print_trans]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_confirm_print_trans]
GO
/****** Object:  StoredProcedure [dbo].[p_confirm_print_trans]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_confirm_print_trans] @ptran_id  int
as

declare @error        	integer,
		@print_id     	integer,
		@campaign_no	integer,
		@errorode     		integer,
		@branch_qty   	integer,
		@actual_qty   	integer,
		@cinema_qty   	integer,
		@complex_id   	integer,
		@ptran_type   	char(1),
		@branch_code  	char(2),
		@complex_name 	varchar(50),
		@branch_name  	varchar(50),
		@print_medium	char(1),
		@three_d_type	int

/*
 * Select Print Tran into Variables
 */

select 	@ptran_type   	= pt.ptran_type,
		@campaign_no	= pt.campaign_no,
		@print_id     	= pt.print_id,
		@branch_qty   	= pt.branch_qty,
		@cinema_qty   	= pt.cinema_qty,
		@complex_id   	= pt.complex_id,
		@branch_code  	= pt.branch_code,
		@complex_name 	= complex.complex_name,
		@branch_name  	= branch.branch_name,
		@print_medium 	= pt.print_medium,
		@three_d_type 	= pt.three_d_type
--from 	print_transactions pt,
--		complex,
--		branch
--where	pt.ptran_id = @ptran_id 
--and		pt.complex_id *= complex.complex_id 
--and		pt.branch_code *= branch.branch_code
  FROM	print_transactions AS pt 
		LEFT OUTER JOIN branch ON pt.branch_code = branch.branch_code
		LEFT OUTER JOIN complex ON pt.complex_id = complex.complex_id 
  WHERE (pt.ptran_id = @ptran_id) 

if @@rowcount = 0
	return -1

/*
 * Validate Transaction
 */

begin transaction

if @ptran_type = 'T'
begin

	if @cinema_qty > 0
	begin

		exec @errorode = p_confirmed_print_qty 'B', @campaign_no, @print_id, @branch_code, @complex_id, @print_medium, @three_d_type, @actual_qty OUTPUT
		if (@errorode != 0)
		begin
			rollback transaction
			raiserror ('Error determining qtys', 16, 1)
			return -1
		end

		if @cinema_qty > @actual_qty
		begin
			rollback transaction
			raiserror ('Cannot confirm a Transfer of print(s) due to insuffient stock on hand at branch. All requested confirmations have been rolled back.', 16, 1)
			return -1
		end

	end
	else
	begin

		exec @errorode = p_confirmed_print_qty 'C', @campaign_no, @print_id, @branch_code, @complex_id, @print_medium, @three_d_type, @actual_qty OUTPUT
		if (@errorode != 0)
		begin
			rollback transaction
			raiserror ('Error determining qtys', 16, 1)
			return -1
		end
		
		if @branch_qty > @actual_qty
		begin
			rollback transaction
			raiserror ('Cannot confirm a Transfer of print(s) due to insuffient stock on hand at branch. All requested confirmations have been rolled back.', 16, 1)
			return -1
		end

	end

end

/*
 * Update Print Transaction
 */

update 	print_transactions
set 	ptran_status = 'C'
where 	ptran_id = @ptran_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Error', 16, 1)
	return -1
end	

commit transaction
return 0
GO
