/****** Object:  StoredProcedure [dbo].[p_transfer_cl_complex_prints]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_transfer_cl_complex_prints]
GO
/****** Object:  StoredProcedure [dbo].[p_transfer_cl_complex_prints]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_transfer_cl_complex_prints]  @campaign_no 		integer,
                           				  @print_id  			integer,
										  @new_campaign_no	integer,
										  @ptran_date			datetime,
										  @cinelight_id		integer,
										  @return_code		integer OUTPUT
as
set nocount on 
declare 	@error					integer,
			@ptran_id				integer,
			@branch_code			char(2),
			@ptran_type				char(1),
			@ptran_status			char(1),
			@branch_qty				integer,
			@cinema_qty				integer,
			@ptran_desc_out		varchar(50),
			@ptran_desc_in			varchar(50),
			@cinelight_exists		integer,
			@print_exists			integer,
			@cinelight_count		integer	

begin transaction

select @print_exists = count(print_id)
  from cinelight_campaign_print
 where campaign_no = @new_campaign_no and
       print_id = @print_id

if @print_exists is null or @print_exists = 0
begin
	raiserror ('This print does not exist in the destination campaign.  Please add this print to the campaign before continuing.', 16, 1)
	select @return_code = -1
    rollback transaction
	return -1
end

select @cinelight_exists = count(cl_cc.cinelight_id)
from    cinelight_campaign_complex cl_cc
where cl_cc.campaign_no = @new_campaign_no and
cl_cc.cinelight_id = @cinelight_id

select @cinelight_count = count(cl_cc.cinelight_id)
  from cinelight_campaign_complex cl_cc
 where cl_cc.campaign_no = @campaign_no

if @cinelight_exists = 0 or @cinelight_exists is null
begin
	raiserror ('The destination campaign does not have this cinelight.  Please add it before continuing.', 16, 1)
	select @return_code = -1
    rollback transaction
	return -1
end

select @return_code = 1

select @ptran_desc_out = 'Transfered to Campaign No: ' + str(@new_campaign_no, 7)

select @ptran_desc_in = 'Transfered from Campaign No: ' + str(@campaign_no, 7)

 declare camp_prints_csr cursor static for 
  select branch_code,
			ptran_type_code,
			ptran_status_code,
			branch_qty,
			cinema_qty
    from cinelight_print_transaction
	where campaign_no = @campaign_no and 
			print_id = @print_id and
			cinelight_id = @cinelight_id
order by cinelight_id

open camp_prints_csr
fetch camp_prints_csr into @branch_code, @ptran_type, @ptran_status, @branch_qty, @cinema_qty 
while(@@fetch_status = 0)
begin

	execute @error = p_get_sequence_number 'cinelight_print_transaction',5,@ptran_id OUTPUT
	if (@error !=0)
	begin
		goto error
	end
	
	insert into cinelight_print_transaction
	(
	ptran_id,
	campaign_no,
	print_id,
	branch_code,
	ptran_type_code,
	ptran_status_code,	
	cinelight_id,
	ptran_date,
	branch_qty,
	cinema_qty,
	ptran_desc
	) values 
	(
	@ptran_id,
	@campaign_no,
	@print_id,
	@branch_code,
	@ptran_type,
	@ptran_status,
	@cinelight_id,
	@ptran_date,
	@branch_qty * -1,
	@cinema_qty * -1,
	@ptran_desc_out
	)	
	
	select @error = @@error
	if (@error !=0)
	begin
		goto error
	end

	execute @error = p_get_sequence_number 'cinelight_print_transaction',5,@ptran_id OUTPUT
	if (@error !=0)
	begin
		goto error
	end
	
	insert into cinelight_print_transaction
	(
	ptran_id,
	campaign_no,
	print_id,
	branch_code,
	ptran_type_code,
	ptran_status_code,	
	cinelight_id,
	ptran_date,
	branch_qty,
	cinema_qty,
	ptran_desc
	) values 
	(
	@ptran_id,
	@new_campaign_no,
	@print_id,
	@branch_code,
	@ptran_type,
	@ptran_status,
	@cinelight_id,
	@ptran_date,
	@branch_qty,
	@cinema_qty,
	@ptran_desc_in
	)	
	
	select @error = @@error
	if (@error !=0)
	begin
		goto error
	end

	fetch camp_prints_csr into @branch_code, @ptran_type, @ptran_status, @branch_qty, @cinema_qty 
end	

close camp_prints_csr
deallocate camp_prints_csr

commit transaction
return @return_code

error:

	raiserror ( 'p_transfer_cl_complex_prints : Error %1', 16, 1, @error)
	rollback transaction
	select @return_code = -1
	return @return_code
GO
