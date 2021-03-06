/****** Object:  StoredProcedure [dbo].[p_op_bonus_allocations_assignment]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_bonus_allocations_assignment]
GO
/****** Object:  StoredProcedure [dbo].[p_op_bonus_allocations_assignment]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_op_bonus_allocations_assignment] 	@new_bonus_percent_minimum              smallint,
                                                     	@new_bonus_percent_maximum              smallint,
                                                     	@sequential_allocations_flag            char(1),
                                                     	@allocation_count_remaining             int				OUTPUT,
                                                     	@allocation_value_remaining             numeric(18,2)	OUTPUT,
                                                     	@rows                                   int				OUTPUT
                                                     
as

/*==============================================================*
 * DESC:- This proc is called from its parent proc              *
 *        named p_campaign_bonus_allocations. It applies the    *
 *        the temporary table values for allocations.           *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1   05-Mar-2008 DH  Initial Build                           *
 *  1   01-Dec-2010 MR  Adding Goodwill Bonus                   *
 *                                                              *
 *==============================================================*/

set nocount on

declare @outpost_panel_id 		int, 
		@charge_rate 		money, 
		@spot_id 			int, 
		@billing_date 		datetime,
		@error				int

if (@allocation_count_remaining > 0)
begin
	/* user wants to allocation bonuses by a designated number of spots */

	set rowcount @allocation_count_remaining

	update 	#tmp_target_spots 
	set 	bonus_allocations_count = bonus_allocations_count + 1, 
			new_bonus_percent = ( convert(numeric(6,2), bonus_allocations_count + 2 ) / convert(numeric(6,2), spot_count) ) * 100, 
			new_bonus_allocations = new_bonus_allocations + 1 
	where	new_bonus_percent > @new_bonus_percent_minimum 
	and 	new_bonus_percent <= @new_bonus_percent_maximum 
	and 	sequential_bonuses = @sequential_allocations_flag

	select 	@error = @@error,
			@rows = @@rowcount

	select @allocation_count_remaining = @allocation_count_remaining - @rows

	set rowcount 0


	RETURN 0
end

if (@allocation_value_remaining > 0)
begin
	/* user wants to allocation bonuses by a designated dollar value */
	select @rows = 0

	declare 	allocations_bonus_cursor cursor static forward_only for
	select 		outpost_panel_id,billing_date 
	from 		#tmp_target_spots 
	where 		new_bonus_percent > @new_bonus_percent_minimum 
	and 		new_bonus_percent <= @new_bonus_percent_maximum 
	and 		sequential_bonuses = @sequential_allocations_flag 
	order by 	new_bonus_percent, 
				spot_count desc, 
				charge_rate_total

	open allocations_bonus_cursor 
	fetch allocations_bonus_cursor into @outpost_panel_id, @billing_date
	while @@fetch_status = 0
	begin
		select 		TOP 1 @charge_rate = cs.charge_rate,
					@spot_id = spot_id 
		from 		outpost_spot cs, 
					#tmp_target_spots tts,
					outpost_panel cl
		where 		cs.outpost_panel_id = cl.outpost_panel_id	
		and			cs.campaign_no = tts.campaign_no 
		and 		cl.outpost_panel_id = @outpost_panel_id 
		and 		cs.billing_date = tts.billing_date 
		and 		cs.spot_type = 'S' 
		and 		cs.spot_status in ('A','P') 
		and 		cs.charge_rate > 0 
		and 		cs.charge_rate <= @allocation_value_remaining 
		order by 	cs.charge_rate

		if (@@rowcount > 0)
		begin
			if ( @charge_rate <= @allocation_value_remaining )
			begin
				update 		#tmp_target_spots 
				set 		bonus_allocations_count = bonus_allocations_count + 1, 
							new_bonus_percent = ( convert(numeric(6,2), 
							bonus_allocations_count + 2 ) / convert(numeric(6,2), spot_count) ) * 100, new_bonus_allocations = new_bonus_allocations + 1
				where 		outpost_panel_id = @outpost_panel_id

				select @rows = @rows + 1
				select @allocation_value_remaining = @allocation_value_remaining - @charge_rate

				/* add the new allcoations to our temp allocations table */
				insert #tmp_allocations values(@outpost_panel_id, @spot_id, @billing_date, 1, @charge_rate)
			end
		end

		fetch allocations_bonus_cursor into @outpost_panel_id, @billing_date
	end
	close allocations_bonus_cursor 
	deallocate allocations_bonus_cursor 

	RETURN 0
end

set rowcount 0
select @rows = 0

RETURN 0
GO
