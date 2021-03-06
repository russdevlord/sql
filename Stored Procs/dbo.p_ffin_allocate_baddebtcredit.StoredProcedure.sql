/****** Object:  StoredProcedure [dbo].[p_ffin_allocate_baddebtcredit]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_allocate_baddebtcredit]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_allocate_baddebtcredit]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

create proc  [dbo].[p_ffin_allocate_baddebtcredit]	@tran_id		int

as

declare		@error				int,
			@allocation_id		int,
			@session_id			int,
			@accounting_period	datetime

set nocount on

/*
 * Get Current Accounting Period
 */

select 	@accounting_period = min(end_date)
from	accounting_period
where 	status = 'O'

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: could not obtain current accounting_period', 16, 1)
	return -1
end

/*
 * Declare Cursor to find all allocations of passed transaction
 */

declare		allocation_csr cursor static forward_only for
select		allocation_id
from		transaction_allocation
where		process_period is null
and			from_tran_id = @tran_id
order by 	allocation_id
for			read only

/*
 * Begin Transaction
 */

begin transaction

/*
 * Open Cursor and begin processing.
 */

open allocation_csr
fetch allocation_csr into @allocation_id
while(@@fetch_status=0)
begin

	execute @error = p_get_sequence_number 'work_session',5,@session_id OUTPUT
	if (@error !=0)
	begin
		rollback transaction
		raiserror ('Error: Could not get session id for spot allocation', 16, 1)
		return -1
	end

	exec @error = p_eom_spot_allocation @allocation_id, @accounting_period, @session_id
	if (@error !=0)
	begin
		rollback transaction
		raiserror ('Error: Could not run spot allocation', 16, 1)
		return -1
	end

	fetch allocation_csr into @allocation_id
end

commit transaction
return 0
GO
