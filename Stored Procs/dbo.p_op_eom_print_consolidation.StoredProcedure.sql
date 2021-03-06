/****** Object:  StoredProcedure [dbo].[p_op_eom_print_consolidation]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_eom_print_consolidation]
GO
/****** Object:  StoredProcedure [dbo].[p_op_eom_print_consolidation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_eom_print_consolidation] @campaign_no		integer,
                                      		 	@print_id			integer,
                                           		@tran_date			datetime
as

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @errorode					integer,
        @errno					integer,
        @branch_code			char(2),
        @outpost_panel_id				integer,
        @print_qty				integer,
        @tran_id				integer

/*
 * Begin Transaction
 */

begin transaction

/*
 * Loop Branch
 */

declare 	branch_csr cursor static for
select 		branch_code,
			sum(branch_qty)
from 		outpost_panel_print_transaction
where 		campaign_no = @campaign_no and
			print_id = @print_id and
			branch_code is not null and
			branch_qty <> 0 and
			ptran_type_code <> 'S'
group by 	branch_code
having 		sum(branch_qty) <> 0
order by 	branch_code
for 		read only

open branch_csr
fetch branch_csr into @branch_code, @print_qty
while(@@fetch_status = 0)
begin

	/*
	 * Create Print Transaction
	 */

	execute @errorode = p_get_sequence_number 'print_transactions', 5, @tran_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		close branch_csr
		return -1
	end

	insert into outpost_panel_print_transaction (
          ptran_id,
          campaign_no,
          print_id,
          branch_code,
          ptran_type_code,
          ptran_status_code,
          ptran_date,
          branch_qty,
          cinema_qty,
          ptran_desc ) values (
          @tran_id,
          @campaign_no,
          @print_id,
          @branch_code,
          'S', --System
          'C', --Confirmed
          @tran_date,
          @print_qty,
          0,
          'EOM - Print Tran Consolidation' )

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		close branch_csr
		return -1
	end	

	/*
    * Fetch Next
    */

	fetch branch_csr into @branch_code, @print_qty

end
close branch_csr
deallocate branch_csr

/*
 * Loop Cinemas
 */

declare 	outpost_panel_csr cursor static for
select 		outpost_panel_id,
			sum(cinema_qty)
from 		outpost_panel_print_transaction
where 		campaign_no = @campaign_no and
			print_id = @print_id and
			outpost_panel_id is not null and
			cinema_qty <> 0 and
			ptran_type_code <> 'S'
group by 	outpost_panel_id
having 		sum(cinema_qty) <> 0
order by 	outpost_panel_id
for 		read only

open outpost_panel_csr
fetch outpost_panel_csr into @outpost_panel_id, @print_qty
while(@@fetch_status = 0)
begin

	/*
	 * Create Print Transaction
	 */

	execute @errorode = p_get_sequence_number 'outpost_panel_print_transaction', 5, @tran_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		close outpost_panel_csr
		return -1
	end

	insert into outpost_panel_print_transaction (
          ptran_id,
          campaign_no,
          print_id,
          outpost_panel_id,
          ptran_type_code,
          ptran_status_code,
          ptran_date,
          branch_qty,
          cinema_qty,
          ptran_desc ) values (
          @tran_id,
          @campaign_no,
          @print_id,
          @outpost_panel_id,
          'S', --System
          'C', --Confirmed
          @tran_date,
          0,
          @print_qty,
          'EOM - Print Tran Consolidation' )


	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		close outpost_panel_csr
		return -1
	end	

	/*
    * Fetch Next
    */

	fetch outpost_panel_csr into @outpost_panel_id, @print_qty

end
close outpost_panel_csr
deallocate outpost_panel_csr

/*
 * Remove Previous Print Transactions
 */

delete outpost_panel_print_transaction
 where campaign_no = @campaign_no and
       print_id = @print_id and
       ptran_type_code <> 'S'

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
