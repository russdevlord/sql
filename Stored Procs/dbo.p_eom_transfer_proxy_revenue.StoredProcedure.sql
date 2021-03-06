/****** Object:  StoredProcedure [dbo].[p_eom_transfer_proxy_revenue]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_transfer_proxy_revenue]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_transfer_proxy_revenue]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_eom_transfer_proxy_revenue]		@accounting_period			datetime

as

declare		@error						int,
			@errorode						int,
			@inclusion_id				int,
			@film_plan_id				int,
			@media_product_id			int,
			@link_id					int,
			@proxy_rate_amount			money,
			@proxy_charge_rate_amount	money,
			@dest_spot_count			int,
			@dest_spot_rate				money,
			@dest_spot_charge_rate		money,
			@reversal_tran_id			int,
			@campaign_no				int,
			@tran_id					int,	 
			@tran_type					int,
			@tran_desc					varchar(255),
			@tran_notes					varchar(255),
			@nett_amount				money,
			@gross_amount				money,
			@gst_rate					numeric(6,4),
			@new_tran_id				int,
			@spot_id            		int,
			@complex_id         		int,
		    @liability_type     		tinyint,
		    @allocation_id      		int,
		    @creation_period    		datetime,
		    @origin_period      		datetime,
		    @release_period     		datetime,
		    @spot_amount        		money,
		    @cinema_amount      		money,
		    @cinema_rent        		money,
		    @cancelled          		tinyint,
		    @original_liability			tinyint,
			@liability_id				int,
			@spot_liablity_id			int,
			@liability_gen_tran_id		int,
			@transfer_amount			money,
			@full_proxy_amount			money,
			@last_spot					int,
			@from_tran					int,
			@to_tran					int,
			@alloc_amount				money,
			@spot_liability_id			int,
			@tran_amount				money,
			@account_id					int
			

/*
 * Begin transaction
 */

begin transaction

/*
 * Loop over all proxy inlcusions that have spots with 
 * proxy release periods equal to @accounting_period
 */

declare 	proxy_csr cursor static forward_only for
select 		distinct inclusion_id,
			sum(rate),
			sum(charge_rate),
			campaign_no
from		inclusion_spot
where 		proxy_transfer_period <= @accounting_period
and			charge_rate > 0
group by	inclusion_id,
			campaign_no
order by 	inclusion_id
for 		read only

open	proxy_csr
fetch 	proxy_csr into @inclusion_id, @proxy_rate_amount, @proxy_charge_rate_amount, @campaign_no
while(@@fetch_status = 0)
begin


	/*
	 * If proxy has a film Plan - then determine rate and update ghost spots etc
	 */
	
	select 	@film_plan_id = null

	select 	@film_plan_id = film_plan_id
	from	inclusion
	where 	inclusion_id = @inclusion_id
	
	if isnull(@film_plan_id, 0) <> 0
	begin

		/*
		 * Determine and apply Ghost Spot Rate
 		 */ 

		select 		@dest_spot_count = count(spot_id)
		from		campaign_spot 
		where 		spot_type = 'G'
		and			film_plan_id = @film_plan_id

		if @dest_spot_count > 0 
		begin

			select 		@dest_spot_rate = round(@proxy_rate_amount / @dest_spot_count, 0),
						@dest_spot_charge_rate = round(@proxy_charge_rate_amount / @dest_spot_count, 0)

			select 		@last_spot = max(spot_id)
			from		campaign_spot
			where 		spot_type = 'G'
			and			film_plan_id = @film_plan_id
			
			update		campaign_spot
			set 		rate = @dest_spot_rate,
						charge_rate = @dest_spot_charge_rate
			where 		spot_type = 'G'
			and			film_plan_id = @film_plan_id
			and			spot_id < @last_spot

			update		campaign_spot
			set 		rate = @dest_spot_rate + (@proxy_rate_amount - (@dest_spot_count * @dest_spot_rate)),
						charge_rate = @dest_spot_charge_rate + (@proxy_rate_amount - (@dest_spot_count * @dest_spot_rate))
			where 		spot_type = 'G'
			and			film_plan_id = @film_plan_id
			and			spot_id = @last_spot
	
			update		campaign_spot
			set 		spot_type = 'Y'
			where 		spot_type = 'G'
			and			film_plan_id = @film_plan_id
			
			/*
			 * Reverse and recreate transactions
			 */
	
			declare		transaction_csr cursor static forward_only for
			select 		tran_id, 
						tran_type,
						tran_desc,
						tran_notes,
						nett_amount,
						gst_rate,
						gross_amount,
						account_id
			from		campaign_transaction
			where		tran_id in (select 	tran_id 
									from 	inclusion_spot_xref 
									where 	spot_id in (select 	spot_id 
														from 	inclusion_spot 
														where 	inclusion_id = @inclusion_id
														and	 	proxy_transfer_period <= @accounting_period
														and		charge_rate > 0))
			group by 	tran_id, 
						tran_type,
						tran_desc,
						tran_notes,
						nett_amount,
						gst_rate,
						gross_amount,
						account_id
			order by 	tran_id
			for 		read only

			open transaction_csr 
			fetch transaction_csr into @tran_id, @tran_type, @tran_desc, @tran_notes, @nett_amount, @gst_rate, @gross_amount, @account_id
			while(@@fetch_status = 0)
			begin

				select @tran_desc = 'Proxy Reversal - ' + right(@tran_desc,239),
					@tran_amount =	-1 * @nett_amount 
	
				exec @errorode = p_ffin_create_transaction @tran_type,
														@campaign_no,
														@account_id,
														@accounting_period,
														@tran_desc,
														@tran_notes,
														@tran_amount,
														@gst_rate,
														'N',
														@reversal_tran_id OUTPUT

				if (@errorode !=0)
				begin
					rollback transaction
				    raiserror ('p_ffin_transaction_reversal: Failed to unallocate reversed transaction.', 16, 1)
				    return -1
				end

				insert into inclusion_spot_xref
				select 	spot_id,
						@reversal_tran_id
				from 	inclusion_spot
				where	inclusion_id = @inclusion_id
				and		proxy_transfer_period = @accounting_period
				and		charge_rate > 0

				select @error = @@error
				if (@error !=0)
				begin
					rollback transaction
				    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
				    return -1
				end

				/*
				 * Reverse any Allocations
				 */
				
				execute @errorode = p_ffin_transaction_unallocate @tran_id, 'Y', 0
				                                          
				if (@errorode !=0)
				begin
					rollback transaction
				    raiserror ('p_ffin_transaction_reversal: Failed to unallocate reversed transaction.', 16, 1)
				    return -1
				end
				
				if(@gross_amount > 0)
				begin
					select @from_tran = @reversal_tran_id
					select @to_tran = @tran_id
					if(@nett_amount = 0)
				   	    select @alloc_amount = @gross_amount * -1
					else
				   	    select @alloc_amount = @nett_amount * -1
				
				end
				else
				begin
					select @from_tran = @tran_id
					select @to_tran = @reversal_tran_id
					if(@nett_amount = 0)
				   	    select @alloc_amount = @gross_amount
					else
				   	    select @alloc_amount = @nett_amount
				end
				
				exec @errorode = p_ffin_allocate_transaction @from_tran, @to_tran, @alloc_amount
									    
				if(@errorode !=0)
				begin
					rollback transaction
				    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
				end
				
				select @tran_desc = 'Proxy Transfer - ' + right(@tran_desc,239)

				exec @errorode = p_ffin_create_transaction @tran_type,
														@campaign_no,
														@account_id,
														@accounting_period,
														@tran_desc,
														@tran_notes,
														@nett_amount,
														@gst_rate,
														'N',
														@new_tran_id OUTPUT

				if (@errorode !=0)
				begin
					rollback transaction
				    raiserror ('p_ffin_transaction_reversal: Failed to unallocate reversed transaction.', 16, 1)
				    return -1
				end

				if @tran_type = 84 or @tran_type = 86
				begin

					select 	@liability_gen_tran_id = @new_tran_id
			
					update 	campaign_spot 
					set 	tran_id = @new_tran_id
					where 	film_plan_id = @film_plan_id
					and		spot_type = 'G'

					select @error = @@error
					if (@error !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
					    return -1
					end
				end

				insert into film_spot_xref
				select 	spot_id,
						@new_tran_id
				from 	campaign_spot
				where	film_plan_id = @film_plan_id
				and		spot_type = 'G'

				select @error = @@error
				if (@error !=0)
				begin
					rollback transaction
				    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
				    return -1
				end
				

				execute @errorode = p_ffin_payment_allocation @campaign_no
				if (@errorode !=0)
				begin
					rollback transaction
				    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
				    return -1
				end
				
				/*
				 * Call Balance Update
				 */
				
				execute @errorode = p_ffin_campaign_balances @campaign_no
				if (@errorode !=0)
				begin
					rollback transaction
				    raiserror ('p_ffin_transaction_reversal: Failed to resync campaign balances.', 16, 1)
				    return -1
				end

				fetch transaction_csr into @tran_id, @tran_type, @tran_desc, @tran_notes, @nett_amount, @gst_rate, @gross_amount, @account_id
			end

			close transaction_csr
	
			/*
			 * Reverse and recreate liability
			 */
	
			declare		liability_csr cursor static forward_only for
			select  	spot_liability_id,
						inclusion_spot_liability.spot_id,
					    inclusion_spot_liability.complex_id,
					    liability_type,
					    allocation_id,
					    creation_period,
					    origin_period,
					    release_period,
					    spot_amount,
					    cinema_amount,
					    cinema_rent,
					    cancelled,
				    	original_liability
			from 		inclusion_spot_liability,
						inclusion_spot
			where 		proxy_transfer_period <= @accounting_period
			and			charge_rate > 0
			and			inclusion_spot_liability.spot_id = inclusion_spot.spot_id
			and			inclusion_spot.inclusion_id = @inclusion_id
			order by 	spot_liability_id

			open liability_csr
			fetch liability_csr into @spot_liability_id, @spot_id, @complex_id, @liability_type, @allocation_id, @creation_period, @origin_period, @release_period, @spot_amount, @cinema_amount, @cinema_rent, @cancelled, @original_liability
			while(@@fetch_status = 0)			
			begin
			    execute @errorode = p_get_sequence_number 'spot_liability',5,@liability_id OUTPUT
			    if (@errorode !=0)
			    begin
		            raiserror ('Error: Failed to get new spot liability id', 16, 1)
				    rollback transaction
		        	return -100
			    end

				insert into inclusion_spot_liability
				   (spot_liability_id,
					spot_id,
				    complex_id,
				    liability_type,
				    allocation_id,
				    creation_period,
				    origin_period,
				    release_period,
				    spot_amount,
				    cinema_amount,
				    cinema_rent,
				    cancelled,
			    	original_liability) values
				   (@liability_id,
					@spot_id,
				    @complex_id,
				    @liability_type,
				    @allocation_id,
				    @accounting_period,
				    @origin_period,
				    @release_period,
				    -1 * @spot_amount,
				    -1 * @cinema_amount,
				    -1 * @cinema_rent,
				    @cancelled,
			    	@original_liability)

				select @error = @@error
			    if (@errorode !=0)
			    begin
		            raiserror ('Error: Failed to insert spot liability', 16, 1)
				    rollback transaction
		        	return -100
			    end
			end
			
			close liability_csr			

			exec @errorode = p_spot_liability_generation @campaign_no, 1, @liability_gen_tran_id, 1

			
			/*
	 		 * Set rate on proxy spots to zero
			 */

			update 		inclusion_spot
			set			rate = 0,
						charge_rate = 0
			where		inclusion_id = @inclusion_id		
			and			proxy_transfer_period <= @accounting_period
			and			charge_rate > 0
		end
	end
	
	/*
	 * If Proxy has inclusion_proxy_xref rows determine amount for xref to transfer
	 * Check amounts already transfered and only transfer total amount less transfered amount
	 * up to the amount of the linked media
	 */

	declare 	link_csr cursor static forward_only for
	select 		media_product_id,
				link_id,
				transfer_amount,
				proxy_full_amount
	from		inclusion_proxy_xref
	where		inclusion_id = @inclusion_id
	group by	media_product_id,
				link_id,
				transfer_amount,
				proxy_full_amount
	order by	media_product_id,
				link_id
	for 		read only

	open link_csr
	fetch link_csr into @media_product_id, @link_id, @transfer_amount, @full_proxy_amount
	while(@@fetch_status=0)
	begin

		/*
		 * Determine the destination cinelight or cinemarketing package
		 */

		if @media_product_id = 3
		begin

			/* 
			 * Destination: Cinelight
			 */

			select 		@dest_spot_count = count(spot_id)
			from		cinelight_spot 
			where 		package_id = @link_id

			if @dest_spot_count > 0 
	
				select 		@dest_spot_rate = round((@proxy_rate_amount * @transfer_amount / @full_proxy_amount) / @dest_spot_count, 0),
							@dest_spot_charge_rate = round((@proxy_charge_rate_amount * @transfer_amount / @full_proxy_amount) / @dest_spot_count, 0)
			
				select 		@last_spot = max(spot_id)
				from		cinelight_spot
				where 		package_id = @link_id
				group by 	spot_id
				

				update		cinelight_spot
				set 		rate = rate + @dest_spot_rate,
							charge_rate = charge_rate + @dest_spot_charge_rate
				where 		package_id = @link_id
				and			spot_id < @last_spot
		
				update		cinelight_spot
				set 		rate = rate + @dest_spot_rate + (@proxy_rate_amount - (@dest_spot_count * @dest_spot_rate)),
							charge_rate = charge_rate + @dest_spot_charge_rate + (@proxy_rate_amount - (@dest_spot_count * @dest_spot_rate))
				where 		package_id = @link_id
				and			spot_id = @last_spot
		
				/*
				 * Reverse and recreate transactions
				 */
		
				declare 	transaction_csr cursor static forward_only for
				select 		tran_id, 
							tran_type,
							tran_desc,
							tran_notes,
							nett_amount,
							gst_rate,
							gross_amount,
							account_id
				from		campaign_transaction
				where		tran_id in (select 	tran_id 
										from 	inclusion_spot_xref 
										where 	spot_id in (select 	spot_id 
															from 	inclusion_spot 
															where 	inclusion_id = @inclusion_id
															and	 	proxy_transfer_period <= @accounting_period
															and		charge_rate > 0))
				group by 	tran_id, 
							tran_type,
							tran_desc,
							tran_notes,
							nett_amount,
							gst_rate,
							gross_amount,
							account_id
				order by 	tran_id
				for 		read only
	
				open transaction_csr 
				fetch transaction_csr into @tran_id, @tran_type, @tran_desc, @tran_notes, @nett_amount, @gst_rate, @gross_amount, @account_id
				while(@@fetch_status = 0)
				begin
	
					select @tran_desc = 'Proxy Reversal - ' + right(@tran_desc,239),
					@tran_amount =	-1 * @nett_amount 

					exec @errorode = p_ffin_create_transaction @tran_type,
															@campaign_no,
															@account_id,
															@accounting_period,
															@tran_desc,
															@tran_notes,
															@tran_amount,
															@gst_rate,
															'N',
															@reversal_tran_id OUTPUT
	
					if (@errorode !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to unallocate reversed transaction.', 16, 1)
					    return -1
					end
	
					insert into inclusion_spot_xref
					select 	spot_id,
							@reversal_tran_id
					from 	inclusion_spot
					where	inclusion_id = @inclusion_id
					and		proxy_transfer_period <= @accounting_period
					and		charge_rate > 0

					select @error = @@error
					if (@error !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
					    return -1
					end
	
					/*
					 * Reverse any Allocations
					 */
					
					execute @errorode = p_ffin_transaction_unallocate @tran_id, 'Y', 0
					                                          
					if (@errorode !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to unallocate reversed transaction.', 16, 1)
					    return -1
					end
					
					if(@gross_amount > 0)
					begin
						select @from_tran = @reversal_tran_id
						select @to_tran = @tran_id
						if(@nett_amount = 0)
					   	    select @alloc_amount = @gross_amount * -1
						else
					   	    select @alloc_amount = @nett_amount * -1
					
					end
					else
					begin
						select @from_tran = @tran_id
						select @to_tran = @reversal_tran_id
						if(@nett_amount = 0)
					   	    select @alloc_amount = @gross_amount
						else
					   	    select @alloc_amount = @nett_amount
					end
					
					exec @errorode = p_ffin_allocate_transaction @from_tran, @to_tran, @alloc_amount
										    
					if(@errorode !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
					end
					
					select @tran_desc =  'Proxy Transfer - ' + right(@tran_desc,239)

					exec @errorode = p_ffin_create_transaction @tran_type,
															@campaign_no,
															@account_id,
															@accounting_period,
															@tran_desc,
															@tran_notes,
															@nett_amount,
															@gst_rate,
															'N',
															@new_tran_id OUTPUT
	
					if (@errorode !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to unallocate reversed transaction.', 16, 1)
					    return -1
					end
	
					if @tran_type = 93
					begin
	
						select 	@liability_gen_tran_id = @new_tran_id
				
						update 	cinelight_spot 
						set 	tran_id = @new_tran_id
						where 	package_id = @link_id
	
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
						    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
						    return -1
						end
					end
	
					insert into cinelight_spot_xref
					select 	spot_id,
							@new_tran_id
					from 	campaign_spot
					where	package_id = @link_id
	
					select @error = @@error
					if (@error !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
					    return -1
					end
					
					execute @errorode = p_ffin_payment_allocation @campaign_no
					if (@errorode !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
					    return -1
					end
					
					/*
					 * Call Balance Update
					 */
					
					execute @errorode = p_ffin_campaign_balances @campaign_no
					if (@errorode !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to resync campaign balances.', 16, 1)
					    return -1
					end
	
					fetch transaction_csr into @tran_id, @tran_type, @tran_desc, @tran_notes, @nett_amount, @gst_rate, @gross_amount
				end
	
				close transaction_csr
		
				/*
				 * Reverse and recreate liability
				 */
		
				declare		liability_csr cursor static forward_only for
				select  	spot_liability_id,
							inclusion_spot_liability.spot_id,
						    inclusion_spot_liability.complex_id,
						    liability_type,
						    allocation_id,
						    creation_period,
						    origin_period,
						    release_period,
						    spot_amount,
						    cinema_amount,
						    cinema_rent,
						    cancelled,
					    	original_liability
				from 		inclusion_spot_liability,
							inclusion_spot
				where 		proxy_transfer_period <= @accounting_period
				and			charge_rate > 0
				and			inclusion_spot_liability.spot_id = inclusion_spot.spot_id
				and			inclusion_spot.inclusion_id = @inclusion_id
				order by 	spot_liability_id
	
				open liability_csr
				fetch liability_csr into @spot_liability_id, @spot_id, @complex_id, @liability_type, @allocation_id, @creation_period, @origin_period, @release_period, @spot_amount, @cinema_amount, @cinema_rent, @cancelled, @original_liability
				while(@@fetch_status = 0)			
				begin
				    execute @errorode = p_get_sequence_number 'spot_liability',5,@liability_id OUTPUT
				    if (@errorode !=0)
				    begin
			            raiserror ('Error: Failed to get new spot liability id', 16, 1)
					    rollback transaction
			        	return -100
				    end
	
					insert into inclusion_spot_liability
					   (spot_liability_id,
						spot_id,
					    complex_id,
					    liability_type,
					    allocation_id,
					    creation_period,
					    origin_period,
					    release_period,
					    spot_amount,
					    cinema_amount,
					    cinema_rent,
					    cancelled,
				    	original_liability) values
					   (@liability_id,
						@spot_id,
					    @complex_id,
					    @liability_type,
					    @allocation_id,
					    @accounting_period,
					    @origin_period,
					    @release_period,
					    -1 * @spot_amount,
					    -1 * @cinema_amount,
					    -1 * @cinema_rent,
					    @cancelled,
				    	@original_liability)
	
					select @error = @@error
				    if (@errorode !=0)
				    begin
			            raiserror ('Error: Failed to insert spot liability', 16, 1)
					    rollback transaction
			        	return -100
				    end
	
				end
				
				close liability_csr			
	
				exec @errorode = p_spot_liability_generation @campaign_no, 1, @liability_gen_tran_id, 2
	
				
				/*
		 		 * Set rate on proxy spots to zero
				 */
	
				update 		inclusion_spot
				set			rate = 0,
							charge_rate = 0
				where		inclusion_id = @inclusion_id
				and			proxy_transfer_period <= @accounting_period	
				and			charge_rate > 0

		end
		else if @media_product_id = 6
		begin

			/* 
			 * Destination: Cinemarketing
			 */

			select 		@dest_spot_count = count(spot_id)
			from		inclusion_spot
			where 		inclusion_id = @link_id

			if @dest_spot_count > 0 
	
				select 		@dest_spot_rate = round((@proxy_rate_amount * @transfer_amount / @full_proxy_amount) / @dest_spot_count, 0),
							@dest_spot_charge_rate = round((@proxy_charge_rate_amount * @transfer_amount / @full_proxy_amount) / @dest_spot_count, 0)
		
				select 		@last_spot = max(spot_id)
				from		inclusion_spot
				where 		inclusion_id = @link_id

				update		inclusion_spot
				set 		rate = @dest_spot_rate,
							charge_rate = @dest_spot_charge_rate
				where 		inclusion_id = @link_id
				and			spot_id < @last_spot
		
				update		inclusion_spot
				set 		rate = @dest_spot_rate + (@proxy_rate_amount - (@dest_spot_count * @dest_spot_rate)),
							charge_rate = @dest_spot_charge_rate + (@proxy_rate_amount - (@dest_spot_count * @dest_spot_rate))
				where 		inclusion_id = @link_id
				and			spot_id = @last_spot
		
				/*
				 * Reverse and recreate transactions
				 */
		
				declare 	transaction_csr cursor static forward_only for
				select 		tran_id, 
							tran_type,
							tran_desc,
							tran_notes,
							nett_amount,
							gst_rate,
							gross_amount,
							account_id
				from		campaign_transaction
				where		tran_id in (select 	tran_id 
										from 	inclusion_spot_xref 
										where 	spot_id in (select 	spot_id 
															from 	inclusion_spot 
															where 	inclusion_id = @inclusion_id
															and	 	proxy_transfer_period <= @accounting_period
															and		charge_rate > 0))
				group by 	tran_id, 
							tran_type,
							tran_desc,
							tran_notes,
							nett_amount,
							gst_rate,
							gross_amount,
							account_id
				order by 	tran_id
				for 		read only
	
				open transaction_csr 
				fetch transaction_csr into @tran_id, @tran_type, @tran_desc, @tran_notes, @nett_amount, @gst_rate, @gross_amount
				while(@@fetch_status = 0)
				begin
	
					select 	@tran_desc = 'Proxy Reversal - ' + right(@tran_desc,239),
					@tran_amount =	-1 * @nett_amount 

					exec @errorode = p_ffin_create_transaction @tran_type,
															@campaign_no,
															@account_id, 
															@accounting_period,
															@tran_desc,
															@tran_notes,
															@tran_amount,
															@gst_rate,
															'N',
															@reversal_tran_id OUTPUT
	
					if (@errorode !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to unallocate reversed transaction.', 16, 1)
					    return -1
					end
	
					insert into inclusion_spot_xref
					select 	spot_id,
							@reversal_tran_id
					from 	inclusion_spot
					where	inclusion_id = @inclusion_id
					and		proxy_transfer_period <= @accounting_period
					and		charge_rate > 0	

					select @error = @@error
					if (@error !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
					    return -1
					end
	
					/*
					 * Reverse any Allocations
					 */
					
					execute @errorode = p_ffin_transaction_unallocate @tran_id, 'Y', 0
					                                          
					if (@errorode !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to unallocate reversed transaction.', 16, 1)
					    return -1
					end
					
					if(@gross_amount > 0)
					begin
						select @from_tran = @reversal_tran_id
						select @to_tran = @tran_id
						if(@nett_amount = 0)
					   	    select @alloc_amount = @gross_amount * -1
						else
					   	    select @alloc_amount = @nett_amount * -1
					
					end
					else
					begin
						select @from_tran = @tran_id
						select @to_tran = @reversal_tran_id
						if(@nett_amount = 0)
					   	    select @alloc_amount = @gross_amount
						else
					   	    select @alloc_amount = @nett_amount
					end
					
					exec @errorode = p_ffin_allocate_transaction @from_tran, @to_tran, @alloc_amount
										    
					if(@errorode !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
					end
					
					select @tran_desc = 'Proxy Transfer - ' + right(@tran_desc,239)

					exec @errorode = p_ffin_create_transaction @tran_type,
															@campaign_no,
															@account_id,
															@accounting_period,
															@tran_desc,
															@tran_notes,
															@nett_amount,
															@gst_rate,
															'N',
															@new_tran_id OUTPUT
	
					if (@errorode !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to unallocate reversed transaction.', 16, 1)
					    return -1
					end
	
					if @tran_type = 84 or @tran_type = 86 /**/
					begin
	
						select 	@liability_gen_tran_id = @new_tran_id
				
						update 	inclusion_spot 
						set 	tran_id = @new_tran_id
						where 	@inclusion_id = @link_id
	
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
						    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
						    return -1
						end
					end
	
					insert into inclusion_spot_xref
					select 	spot_id,
							@new_tran_id
					from 	inclusion_spot
					where 	@inclusion_id = @link_id
	
					select @error = @@error
					if (@error !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
					    return -1
					end
					
	
					execute @errorode = p_ffin_payment_allocation @campaign_no
					if (@errorode !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to allocate reversal transaction.', 16, 1)
					    return -1
					end
					
					/*
					 * Call Balance Update
					 */
					
					execute @errorode = p_ffin_campaign_balances @campaign_no
					if (@errorode !=0)
					begin
						rollback transaction
					    raiserror ('p_ffin_transaction_reversal: Failed to resync campaign balances.', 16, 1)
					    return -1
					end
	
					fetch transaction_csr into @tran_id, @tran_type, @tran_desc, @tran_notes, @nett_amount, @gst_rate, @gross_amount, @account_id
				end
	
				close transaction_csr
		
				/*
				 * Reverse and recreate liability
				 */
		
				declare		liability_csr cursor static forward_only for
				select  	spot_liability_id,
							inclusion_spot_liability.spot_id,
						    inclusion_spot_liability.complex_id,
						    liability_type,
						    allocation_id,
						    creation_period,
						    origin_period,
						    release_period,
						    spot_amount,
						    cinema_amount,
						    cinema_rent,
						    cancelled,
					    	original_liability
				from 		inclusion_spot_liability,
							inclusion_spot
				where 		proxy_transfer_period <= @accounting_period
				and			charge_rate > 0
				and			inclusion_spot_liability.spot_id = inclusion_spot.spot_id
				and			inclusion_spot.inclusion_id = @inclusion_id
				order by 	spot_liability_id
	
				open liability_csr
				fetch liability_csr into @spot_liability_id, @spot_id, @complex_id, @liability_type, @allocation_id, @creation_period, @origin_period, @release_period, @spot_amount, @cinema_amount, @cinema_rent, @cancelled, @original_liability
				while(@@fetch_status = 0)			
				begin
				    execute @errorode = p_get_sequence_number 'spot_liability',5,@liability_id OUTPUT
				    if (@errorode !=0)
				    begin
			            raiserror ('Error: Failed to get new spot liability id', 16, 1)
					    rollback transaction
			        	return -100
				    end
	
					insert into inclusion_spot_liability
					   (spot_liability_id,
						spot_id,
					    complex_id,
					    liability_type,
					    allocation_id,
					    creation_period,
					    origin_period,
					    release_period,
					    spot_amount,
					    cinema_amount,
					    cinema_rent,
					    cancelled,
				    	original_liability) values
					   (@liability_id,
						@spot_id,
					    @complex_id,
					    @liability_type,
					    @allocation_id,
					    @accounting_period,
					    @origin_period,
					    @release_period,
					    -1 * @spot_amount,
					    -1 * @cinema_amount,
					    -1 * @cinema_rent,
					    @cancelled,
				    	@original_liability)
	
					select @error = @@error
				    if (@errorode !=0)
				    begin
			            raiserror ('Error: Failed to insert spot liability', 16, 1)
					    rollback transaction
			        	return -100
				    end
					
	
				end
				
				close liability_csr			
	
				exec @errorode = p_spot_liability_generation @campaign_no, 1, @liability_gen_tran_id, 3
	
				
				/*
		 		 * Set rate on proxy spots to zero
				 */
	
				update 		inclusion_spot
				set			rate = 0,
							charge_rate = 0
				where		inclusion_id = @inclusion_id	
				and			proxy_transfer_period <= @accounting_period	
				and			charge_rate > 0
			end

		fetch link_csr into @media_product_id, @link_id, @transfer_amount, @full_proxy_amount
	
	end

	close link_csr
	


	fetch proxy_csr into @inclusion_id, @proxy_rate_amount, @proxy_charge_rate_amount, @campaign_no
end

commit transaction
return 0
GO
