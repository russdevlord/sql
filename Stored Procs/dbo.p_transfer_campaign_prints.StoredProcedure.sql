/****** Object:  StoredProcedure [dbo].[p_transfer_campaign_prints]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_transfer_campaign_prints]
GO
/****** Object:  StoredProcedure [dbo].[p_transfer_campaign_prints]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_transfer_campaign_prints] 	@campaign_no 		integer,
										@print_id  			integer,
										@new_campaign_no	integer,
										@ptran_date			datetime,
										@print_medium		char(1),
										@three_d_type		integer
as

set nocount on 

declare 	@error					integer,
			@ptran_id				integer,
			@branch_code			char(2),
			@ptran_type				char(1),
			@ptran_status			char(1),
			@complex_id				integer,
			@branch_qty				integer,
			@cinema_qty				integer,
			@branch_nominal_qty		integer,
			@cinema_nominal_qty		integer,
			@ptran_desc_out			varchar(50),
			@ptran_desc_in			varchar(50),
			@new_complex			integer,	
			@complex_exists			integer,
			@print_exists			integer,
			@complex_count			integer

/*
 * Set variables to null
 */

select @complex_exists = null
select @complex_count = null
select @print_exists = null

/*
 * Determine if destination campaign has same prints and complexes as source campaign
 */

select 	@print_exists = count(print_id)
from 	film_campaign_prints
where 	campaign_no = @new_campaign_no 
and		print_id = @print_id
and		print_medium = @print_medium
and		three_d_type = @three_d_type

if @print_exists is null or @print_exists = 0
begin
	raiserror ('This print does not exist in the destination campaign.  Please add this print to the campaign before continuing.', 16, 1)
	return -1
end


/*
 * begin transaction
 */

begin transaction                                                

/*
 * Transfer Prints
 */

select @ptran_desc_out = 'Transfered to Campaign No: ' + str(@new_campaign_no, 7)

select @ptran_desc_in = 'Transfered from Campaign No: ' + str(@campaign_no, 7)

declare 	camp_prints_csr cursor static for 
select 		branch_code,
			ptran_type,
			ptran_status,
			complex_id,
			branch_qty,
			cinema_qty,
			branch_nominal_qty,
			cinema_nominal_qty
from 		print_transactions
where 		campaign_no = @campaign_no 
and 		print_id = @print_id
and			print_medium = @print_medium
and			three_d_type = @three_d_type
order by 	complex_id
for 		read only

open camp_prints_csr
fetch camp_prints_csr into @branch_code, @ptran_type, @ptran_status, @complex_id, @branch_qty, @cinema_qty , @branch_nominal_qty, @cinema_nominal_qty 
while(@@fetch_status = 0)
begin

	execute @error = p_get_sequence_number 'print_transactions',5,@ptran_id OUTPUT
	if (@error !=0)
	begin
		goto error
	end
	
	insert into print_transactions
	(
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
	ptran_desc,
	print_medium,
	three_d_type
	) values 
	(
	@ptran_id,
	@campaign_no,
	@print_id,
	@branch_code,
	@ptran_type,
	@ptran_status,
	@complex_id,
	@ptran_date,
	@branch_qty * -1,
	@cinema_qty * -1,
	@branch_nominal_qty * -1,
	@cinema_nominal_qty * -1,
	@ptran_desc_out,
	@print_medium,
	@three_d_type
	)	
	
	select @error = @@error
	if (@error !=0)
	begin
		goto error
	end
	
	execute @error = p_get_sequence_number 'print_transactions',5,@ptran_id OUTPUT
	if (@error !=0)
	begin
		goto error
	end
	
	insert into print_transactions
	(
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
	ptran_desc,
	print_medium,
	three_d_type
	) values 
	(
	@ptran_id,
	@new_campaign_no,
	@print_id,
	@branch_code,
	@ptran_type,
	@ptran_status,
	@complex_id,
	@ptran_date,
	@branch_qty,
	@cinema_qty,
	@branch_nominal_qty,
	@cinema_nominal_qty,
	@ptran_desc_in,
	@print_medium,
	@three_d_type
	)	
	
	select @error = @@error
	if (@error !=0)
	begin
		goto error
	end

	fetch camp_prints_csr into @branch_code, @ptran_type, @ptran_status, @complex_id, @branch_qty, @cinema_qty, @branch_nominal_qty, @cinema_nominal_qty 
end	

close camp_prints_csr
deallocate camp_prints_csr

/*
 * Commit and Return
 */

commit transaction
return 1

/*
 * Error handler
 */
error:
	rollback transaction	
	raiserror ('p_transfer_campaign_prints: Error Occured', 16, 1)
	close camp_prints_csr
	deallocate camp_prints_csr
	return -1
GO
