/****** Object:  StoredProcedure [dbo].[p_ffin_allocate_takeout_transaction]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_allocate_takeout_transaction]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_allocate_takeout_transaction]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc	[dbo].[p_ffin_allocate_takeout_transaction]		@campaign_no		int

as

declare		@error					int,
			@tran_id				int,
			@trantype_id			int,
			@takeout_id				int,
			@takeout_tran_date		datetime,
			@parent_tran_date		datetime,
			@tran_amount			money,
			@remain_alloc			money,
			@target_alloc			money,
			@takeout_remaining		money,
			@other_period			datetime,
			@exit_loop				int,
			@billing_period			datetime,
			@spot_id				int,
			@currency_code			char(3),
			@alloc_date				datetime

set nocount on

/* 
 * Begin Transaction
 */

begin transaction

select	@alloc_date = min(end_date)
from	accounting_period
where	status <> 'X'      
                     
/* 
 * Loop New/Outstanding Transaction
 */

declare			takeout_csr	cursor forward_only static for
select			ct.tran_id,
				ct.tran_type,
				ct.nett_amount,
				isnull(sum(ta.nett_amount),0),
				ct.entry_date, 
				ct.currency_code              
from			campaign_transaction ct
inner join 		transaction_type tt on ct.tran_type = tt.trantype_id
inner join 		transaction_allocation ta on ct.tran_id = ta.from_tran_id
inner join 		takeout_tran_xref ttx on tt.trantype_id = ttx.takeout_trantype_id
where			ct.campaign_no = @campaign_no
group by 		ct.tran_id,
				ct.tran_type,
				ct.nett_amount,
				ct.entry_date,
				ct.currency_code
having			isnull(sum(ta.nett_amount),0) <> 0
order by		ct.tran_id,
				ct.tran_type



open takeout_csr
fetch takeout_csr into @takeout_id, @trantype_id, @tran_amount, @remain_alloc, @takeout_tran_date, @currency_code
while(@@fetch_status=0)
begin

	select @takeout_remaining = @remain_alloc

	select @exit_loop = 0

	declare		alloc_to_csr cursor forward_only static for
	select		ct.tran_id,
				isnull(sum(ta.nett_amount),0)
	from		campaign_transaction ct,
				transaction_allocation ta,
				takeout_tran_xref ttx 
	where 		ct.campaign_no = @campaign_no
	and        	ct.tran_id = ta.to_tran_id 
	and			ct.tran_type = ttx.alloc_trantype_id
	and			ttx.takeout_trantype_id = @trantype_id
	and			ct.entry_date = @takeout_tran_date
	and			ct.currency_code = @currency_code
	group by 	ct.tran_id,
				ct.gross_amount,
				ct.tran_date
	having		isnull(sum(ta.nett_amount),0) > 0
	order by 	ct.tran_date

	open alloc_to_csr
	fetch alloc_to_csr into @tran_id, @target_alloc
	while (@@fetch_status = 0 and @exit_loop = 0)
	begin

		/*
		 * Calculate Tran Amount
		 */
		
		if(@target_alloc > @takeout_remaining)
			select @tran_amount = @takeout_remaining
		else
			select @tran_amount = @target_alloc
		
		if(@tran_amount = 0)
			select @exit_loop = 1
		else
		begin
		
			/*
			 * Call Allocation Function
			 */
			
			select @tran_amount = 0 - @tran_amount

			execute @error = p_ffin_allocate_transaction @takeout_id, @tran_id, @tran_amount, @alloc_date
			if (@error !=0)
			begin
				close alloc_to_csr
				deallocate alloc_to_csr
				close takeout_csr
				deallocate takeout_csr
				raiserror ('Error - failed to allocate takeout transaction', 16, 1)
				rollback transaction
				return -1			
			end
		
			/*
			 * Update Pay Amount Remaining
			 */
			
			select @takeout_remaining = @takeout_remaining + @tran_amount
		
		end
		
		if(@takeout_remaining = 0)
			select @exit_loop = 1
		

		fetch alloc_to_csr into @tran_id, @target_alloc
	end

	close alloc_to_csr
	deallocate alloc_to_csr

	if @takeout_remaining > 0 
	begin

		declare 	alloc_to_csr cursor forward_only static for
		select		ct.tran_id,
					isnull(sum(ta.nett_amount),0)
		from		campaign_transaction ct,
					transaction_allocation ta,
					takeout_tran_xref ttx 
		where 		ct.campaign_no = @campaign_no
		and        	ct.tran_id = ta.to_tran_id 
		and			ct.tran_type = ttx.alloc_trantype_id
		and			ttx.takeout_trantype_id = @trantype_id
		and			ct.entry_date <> @takeout_tran_date
		and			ct.currency_code = @currency_code
		group by 	ct.tran_id,
					ct.gross_amount,
					ct.tran_date
		having		isnull(sum(ta.nett_amount),0) > 0
		order by 	ct.tran_date
	
		open alloc_to_csr
		fetch alloc_to_csr into @tran_id, @target_alloc
		while (@@fetch_status = 0 and @exit_loop = 0)
		begin
	
			/*
			 * Calculate Tran Amount
			 */
			
			if(@target_alloc > @takeout_remaining)
				select @tran_amount = @takeout_remaining
			else
				select @tran_amount = @target_alloc
			
			if(@tran_amount = 0)
				select @exit_loop = 1
			else
			begin
			
				/*
				 * Call Allocation Function
				 */
				
				select @tran_amount = 0 - @tran_amount
	
				execute @error = p_ffin_allocate_transaction @takeout_id, @tran_id, @tran_amount, @alloc_date
				if (@error !=0)
				begin
					close alloc_to_csr
					deallocate alloc_to_csr
					close takeout_csr
					deallocate takeout_csr
					raiserror ('Error - failed to allocate takeout transaction', 16, 1)
					rollback transaction
					return -1			
				end
			
				/*
				 * Update Pay Amount Remaining
				 */
				
				select @takeout_remaining = @takeout_remaining + @tran_amount
			
			end
			
			if(@takeout_remaining = 0)
				select @exit_loop = 1
			
	
			fetch alloc_to_csr into @tran_id, @target_alloc
		end
	
		close alloc_to_csr
		deallocate alloc_to_csr
	
	end

	
	fetch takeout_csr into @takeout_id, @trantype_id, @tran_amount, @remain_alloc,  @takeout_tran_date, @currency_code
end

close takeout_csr
deallocate takeout_csr

/*
 * Loop All spots and ensure set to status X if fully allocated
 */

update 	inclusion_spot
set 	spot_status = 'X'
where	spot_id in (select 			spot_id 
					from			(select			ct.tran_id,
													spot.spot_id as  spot_id	
									from			campaign_transaction ct 
									inner join 		transaction_allocation ta on 	ct.tran_id = ta.from_tran_id
									inner join 		inclusion_spot_xref spot_xref on ct.tran_id = spot_xref.tran_id
									inner join 		inclusion_spot spot on spot_xref.spot_id = spot.spot_id
									inner join 		takeout_tran_xref ttx on ct.tran_type = ttx.takeout_trantype_id
									where			ct.campaign_no = @campaign_no
									and				spot_type not in ('F', 'A', 'K', 'T')
									group by		ct.tran_id,
													spot.spot_id	
									having			isnull(sum(ta.nett_amount),0) = 0) as temp_table)

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error Updating Spot Status', 16, 1)
	rollback transaction
	return -1
end

/*
 * Commit and return
 */

commit transaction
return 0
GO
