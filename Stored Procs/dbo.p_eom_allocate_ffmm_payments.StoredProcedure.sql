/****** Object:  StoredProcedure [dbo].[p_eom_allocate_ffmm_payments]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_allocate_ffmm_payments]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_allocate_ffmm_payments]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_eom_allocate_ffmm_payments]		@allocation_id				int,
																						@accounting_period		datetime

as

declare		@error									int,
				@from_tran_id					int,
				@to_tran_id						int,
				@amount								money,
				@spot_amount_used			money,	
				@cinema_amount_used		money,
				@spot_amount						money,	
				@cinema_amount					money,
				@inclusion_spot					int,
				@campaign_no						int,
				@spot_type							char(1),
				@rowcount							int,
				@liability_id							int,
				@spot_id								int,
				@complex_id						int
			
select		@to_tran_id	 = to_tran_id,
				@from_tran_id = from_tran_id,
				@amount = -1 * alloc_amount
from			transaction_allocation 
where 		allocation_id = @allocation_id

/*select		@inclusion_spot = campaign_no)
from			inclusion_spot
where		tran_id = @to_tran_id
*/

begin transaction

select		@spot_amount_used = isnull(spot_amount_used,0),
				@cinema_amount_used = isnull(cinema_amount_used,0)
from			inclusion_follow_film_allocation_xref
where 		allocation_id = @allocation_id

select		@error = @@error,
				@rowcount = @@rowcount

if (@error !=0)
begin
	rollback transaction
	raiserror ('Error: 1', 16, 1)
	return -1
end			

if @rowcount = 0
begin
	insert into inclusion_follow_film_allocation_xref values (@allocation_id, 0, 0) 

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		raiserror ('Error: ', 16, 1)
		return -1
	end	
	
	select		@spot_amount_used = 0,
					@cinema_amount_used = 0
end

if round(@amount,2) = round(@spot_amount_used,2) and round(@amount,2) = round(@cinema_amount_used,2)
begin
	update	transaction_allocation 
	set		process_period = @accounting_period	
    where   allocation_id = @allocation_id
	
	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		raiserror ('Error: Failed to insert billing liability', 16, 1)
		return -1
	end	
	
	commit transaction
	return 0
end

declare			spot_csr cursor forward_only for
select			spot_liability.spot_id,
					spot_liability.complex_id,
					sum(spot_amount),
					sum(cinema_amount)
from				campaign_spot
inner join		spot_liability on campaign_spot.spot_id = spot_liability.spot_id
inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
inner join		inclusion_spot	on inclusion_campaign_spot_xref.inclusion_id = inclusion_spot.spot_id 
											and campaign_spot.campaign_no = inclusion_spot.campaign_no 
											and campaign_spot.spot_type = inclusion_spot.spot_type
where			campaign_spot.spot_status = 'X'
and				inclusion_spot.tran_id = @to_tran_id
group by		spot_liability.spot_id,
					spot_liability.complex_id
order by		spot_liability.spot_id,
					spot_liability.complex_id
for				read only

open spot_csr
fetch spot_csr into @spot_id, @complex_id, @spot_amount, @cinema_amount
while(@@fetch_status = 0) and (((@amount - @spot_amount_used) > 0) or ( (@amount - @cinema_amount_used) > 0))
begin

	if @spot_amount > (@amount - @spot_amount_used)
		select @spot_amount = (@amount - @spot_amount_used)
		
	if @cinema_amount > (@amount - @cinema_amount_used)
		select @cinema_amount = (@amount - @cinema_amount_used)
		
	execute @error = p_get_sequence_number 'spot_liability', 5, @liability_id OUTPUT
	
	if(@error !=0)
	begin
		rollback transaction
		raiserror ('Error: Failed to get liability id', 16, 1)
		return -1
	end
		                
		/*
		 * Insert Liability Record
		 */
	
	insert into spot_liability (
			spot_liability_id,
			spot_id,
			complex_id,
			allocation_id, 
			liability_type,
			spot_amount,
			cinema_amount,
			cinema_rent,
			cancelled,
			original_liability,
			creation_period,
			origin_period,
			release_period 
			) values (
			@liability_id,
			@spot_id,
			@complex_id,
			@allocation_id,
			3,
			isnull(-1 * @spot_amount,0),
			isnull(-1 * @cinema_amount,0),
			isnull(@cinema_amount,0),
			0,
			0,
			@accounting_period,
			@accounting_period, 
			@accounting_period )

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		raiserror ('Error: Failed to insert billing liability', 16, 1)
		return -1
	end	

	select 		@spot_amount_used = @spot_amount_used + @spot_amount, 
				@cinema_amount_used = @cinema_amount_used + @cinema_amount

	fetch spot_csr into @spot_id, @complex_id, @spot_amount, @cinema_amount
end

update		inclusion_follow_film_allocation_xref
set			spot_amount_used = @spot_amount_used,
			cinema_amount_used = @cinema_amount_used
where 		allocation_id = @allocation_id


if round(@amount,2) = round(@spot_amount_used,2) and round(@amount,2) = round(@cinema_amount_used,2)
begin
	update	transaction_allocation 
	set		process_period = @accounting_period	
    where     allocation_id = @allocation_id
	
	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		raiserror ('Error: Failed to insert billing liability', 16, 1)
		return -1
	end	
end

commit transaction
return 0
GO
