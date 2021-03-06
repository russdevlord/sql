/****** Object:  StoredProcedure [dbo].[p_eom_film_print_consolidation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_film_print_consolidation]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_film_print_consolidation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_eom_film_print_consolidation] @campaign_no		integer,
                                      		 @print_id			integer,
                                           @tran_date			datetime
as

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @errorode						integer,
        @errno						integer,
        @branch_code				char(2),
        @complex_id				integer,
        @print_qty				integer,
        @tran_id					integer,
        @print_medium               char(1),
        @three_d_type               integer

/*
 * Begin Transaction
 */

begin transaction

/*
 * Loop Branch
 */
 declare branch_csr cursor static for
  select branch_code,
         sum(branch_qty),
        print_medium,
                three_d_Type
    from print_transactions
   where campaign_no = @campaign_no and
         print_id = @print_id and
         branch_code is not null and
         branch_qty <> 0 and
         ptran_type <> 'S'
group by branch_code,
        print_medium,
                three_d_Type
  having sum(branch_qty) <> 0
order by branch_code
     for read only

open branch_csr
fetch branch_csr into @branch_code, @print_qty, @print_medium, @three_d_Type
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

	insert into print_transactions (
          ptran_id,
          campaign_no,
          print_id,
          branch_code,
          ptran_type,
          ptran_status,
          ptran_date,
          branch_qty,
          cinema_qty,
          ptran_desc , print_medium, three_d_Type, branch_nominal_qty, cinema_nominal_qty) values (
          @tran_id,
          @campaign_no,
          @print_id,
          @branch_code,
          'S', --System
          'C', --Confirmed
          @tran_date,
          @print_qty,
          0,
          'EOM - Print Tran Consolidation', @print_medium, @three_d_Type , @print_qty,0)

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

	fetch branch_csr into @branch_code, @print_qty, @print_medium, @three_d_Type

end
close branch_csr
deallocate branch_csr

/*
 * Loop Cinemas
 */

 declare cinema_csr cursor static for
  select complex_id,
         sum(cinema_qty), print_medium, three_d_Type
    from print_transactions
   where campaign_no = @campaign_no and
         print_id = @print_id and
         complex_id is not null and
         cinema_qty <> 0 and
         ptran_type <> 'S'
group by complex_id , print_medium, three_d_Type    
  having sum(cinema_qty) <> 0
order by complex_id
     for read only

open cinema_csr
fetch cinema_csr into @complex_id, @print_qty, @print_medium, @three_d_Type
while(@@fetch_status = 0)
begin

	/*
	 * Create Print Transaction
	 */

	execute @errorode = p_get_sequence_number 'print_transactions', 5, @tran_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		close cinema_csr
		return -1
	end

	insert into print_transactions (
          ptran_id,
          campaign_no,
          print_id,
          complex_id,
          ptran_type,
          ptran_status,
          ptran_date,
          branch_qty,
          cinema_qty,
          ptran_desc , print_medium, three_d_Type, branch_nominal_qty, cinema_nominal_qty) values (
          @tran_id,
          @campaign_no,
          @print_id,
          @complex_id,
          'S', --System
          'C', --Confirmed
          @tran_date,
          0,
          @print_qty,
          'EOM - Print Tran Consolidation', @print_medium, @three_d_Type ,0,@print_qty)


	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		close cinema_csr
		return -1
	end	

	/*
    * Fetch Next
    */

	fetch cinema_csr into @complex_id, @print_qty, @print_medium, @three_d_Type

end
close cinema_csr
deallocate cinema_csr

/*
 * Remove Previous Print Transactions
 */

delete print_transactions
 where campaign_no = @campaign_no and
       print_id = @print_id and
       ptran_type <> 'S'

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
