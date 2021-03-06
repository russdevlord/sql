/****** Object:  StoredProcedure [dbo].[p_statrev_move_sales_rep]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_move_sales_rep]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_move_sales_rep]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_statrev_move_sales_rep]		@campaign_no			int,
													@revenue_period			datetime,
													@old_rep_id				int,
													@new_rep_id				int,
													@change_date			datetime
as

declare			@error							int,
				@revision_id					int,
				@revision_no					int,
				@rep_count						int,
				@campaign_status				char(1),
				@new_rep_revision_id			int,
				@business_unit_id				int

select			@campaign_status = campaign_status,
				@business_unit_id = business_unit_id
from			film_campaign
where			campaign_no = @campaign_no

/*
 * Begin Transaction
 */

begin transaction 

if @campaign_status <> 'P'
begin

	/*
	 * Reverse all transaction on and after the date for old rep
	*/


	select		@revision_no = max(revision_no) + 1
	from		statrev_campaign_revision
	where		campaign_no = @campaign_no

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 1', 16, 1)
		return -1
	end
		
	insert		into statrev_campaign_revision
				(campaign_no, revision_type, revision_category, revision_no, confirmed_by, confirmation_date, comment)
	select		@campaign_no, 1, 1, @revision_no, 0, @change_date, 'Moving Revenue To A New Account Manager'

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 2', 16, 1)
		return -1
	end
		

	select		@revision_id = revision_id
	from		statrev_campaign_revision
	where		campaign_no = @campaign_no
	and			revision_no = @revision_no

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 3', 16, 1)
		return -1
	end
		
	insert		into statrev_cinema_normal_transaction
				(revision_id, transaction_type, screening_date, revenue_period, delta_date, cost, units, avg_rate)
	select		@revision_id, transaction_type, screening_date, revenue_period, getdate(), ((sum(cost * revenue_percent) * -1)), sum(units), 0
	from		statrev_cinema_normal_transaction, statrev_revision_rep_xref
	where		statrev_cinema_normal_transaction.revision_id in (select revision_id from statrev_campaign_revision where campaign_no = @campaign_no)
	and			revenue_period >= @revenue_period
	and			statrev_cinema_normal_transaction.revision_id = statrev_revision_rep_xref.revision_id
	and			statrev_revision_rep_xref.rep_id = @old_rep_id
	group by	transaction_type, screening_date, revenue_period

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 4', 16, 1)
		return -1
	end

	insert		into statrev_outpost_normal_transaction
				(revision_id, transaction_type, screening_date, revenue_period, delta_date, cost, units, avg_rate)
	select		@revision_id, transaction_type, screening_date, revenue_period, getdate(), ((sum(cost * revenue_percent) * -1)), sum(units),0
	from		statrev_outpost_normal_transaction, statrev_revision_rep_xref
	where		statrev_outpost_normal_transaction.revision_id in (select revision_id from statrev_campaign_revision where campaign_no = @campaign_no)
	and			revenue_period >= @revenue_period
	and			statrev_outpost_normal_transaction.revision_id = statrev_revision_rep_xref.revision_id
	and			statrev_revision_rep_xref.rep_id = @old_rep_id
	group by	transaction_type, screening_date, revenue_period

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 5', 16, 1)
		return -1
	end

	insert		into statrev_cinema_deferred_transaction
				(revision_id, transaction_type,   delta_date, cost, units, avg_rate)
	select		@revision_id, transaction_type,   getdate(), ((sum(cost * revenue_percent) * -1)), sum(units), 0
	from		statrev_cinema_deferred_transaction, statrev_revision_rep_xref
	where		statrev_cinema_deferred_transaction.revision_id in (select revision_id from statrev_campaign_revision where campaign_no = @campaign_no)
	and			statrev_cinema_deferred_transaction.revision_id = statrev_revision_rep_xref.revision_id
	and			statrev_revision_rep_xref.rep_id = @old_rep_id
	group by	transaction_type

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 6', 16, 1)
		return -1
	end

	insert		into statrev_outpost_deferred_transaction
				(revision_id, transaction_type, delta_date, cost, units, avg_rate)
	select		@revision_id, transaction_type,  getdate(), ((sum(cost * revenue_percent) * -1)), sum(units), 0
	from		statrev_outpost_deferred_transaction, statrev_revision_rep_xref
	where		statrev_outpost_deferred_transaction.revision_id in (select revision_id from statrev_campaign_revision where campaign_no = @campaign_no)
	and			statrev_outpost_deferred_transaction.revision_id = statrev_revision_rep_xref.revision_id
	and			statrev_revision_rep_xref.rep_id = @old_rep_id
	group by	transaction_type

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 7', 16, 1)
		return -1
	end

	insert	into statrev_revision_rep_xref values (@revision_id, @old_rep_id, 1.00)

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 8', 16, 1)
		return -1
	end

/*	insert		into statrev_revision_team_xref 
	select		@revision_id, sales_team_members.team_id, 1.00
	from		sales_team_members, sales_team
	where		sales_team_members.team_id = sales_team.team_id
	and			rep_id = @old_rep_id
	and			business_unit_id = @business_unit_id
	and			leader_id <> @old_rep_id
	group by	sales_team_members.team_id

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 8', 16, 1)
		return -1
	end*/

end

/*
 * Make sure new rep is on the film campaign reps table as primary
*/  

select		@rep_count = count(*)
from		film_campaign_Reps
where		campaign_no = @campaign_no
and			rep_id = @new_rep_id
and			control_idc = 'P'

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error 9', 16, 1)
	return -1
end

if @rep_count = 0
begin
	update		film_campaign_reps
	set			rep_id = @new_rep_id
	where		campaign_no = @campaign_no
	and			rep_id = @old_rep_id
	
	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 10', 16, 1)
		return -1
	end
end

/*
 * Update film campaign rep with the new rep id
 */
 
update	film_campaign
set		rep_id = @new_rep_id
where	campaign_no = @campaign_no

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error 10 a', 16, 1)
	return -1
end

if @campaign_status <> 'P'
begin

	/*
	 * Reverse all transaction on and after the date for old rep
	*/

	select @revision_no = @revision_no + 1

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 1', 16, 1)
		return -1
	end
		
	insert		into statrev_campaign_revision
				(campaign_no, revision_type, revision_category, revision_no, confirmed_by, confirmation_date, comment)
	select		@campaign_no, 1, 1, @revision_no, 0, @change_date, 'Moving Revenue To A New Account Manager'

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 2', 16, 1)
		return -1
	end
		

	select		@new_rep_revision_id = revision_id
	from		statrev_campaign_revision
	where		campaign_no = @campaign_no
	and			revision_no = @revision_no

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 3', 16, 1)
		return -1
	end
		
	insert		into statrev_cinema_normal_transaction
				(revision_id, transaction_type, screening_date, revenue_period, delta_date, cost, units, avg_rate)
	select		@new_rep_revision_id, transaction_type, screening_date, revenue_period, getdate(), ((sum(cost) * -1)), sum(units), 0
	from		statrev_cinema_normal_transaction
	where		statrev_cinema_normal_transaction.revision_id = @revision_id
	group by	transaction_type, screening_date, revenue_period

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 4', 16, 1)
		return -1
	end

	insert		into statrev_outpost_normal_transaction
				(revision_id, transaction_type, screening_date, revenue_period, delta_date, cost, units, avg_rate)
	select		@new_rep_revision_id, transaction_type, screening_date, revenue_period, getdate(), ((sum(cost) * -1)), sum(units),0
	from		statrev_outpost_normal_transaction
	where		statrev_outpost_normal_transaction.revision_id = @revision_id
	group by	transaction_type, screening_date, revenue_period

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 5', 16, 1)
		return -1
	end

	insert		into statrev_cinema_deferred_transaction
				(revision_id, transaction_type,   delta_date, cost, units, avg_rate)
	select		@new_rep_revision_id, transaction_type,   getdate(), ((sum(cost) * -1)), sum(units), 0
	from		statrev_cinema_deferred_transaction
	where		statrev_cinema_deferred_transaction.revision_id = @revision_id
	group by	transaction_type

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 6', 16, 1)
		return -1
	end

	insert		into statrev_outpost_deferred_transaction
				(revision_id, transaction_type, delta_date, cost, units, avg_rate)
	select		@new_rep_revision_id, transaction_type,  getdate(), ((sum(cost) * -1)), sum(units), 0
	from		statrev_outpost_deferred_transaction
	where		statrev_outpost_deferred_transaction.revision_id = @revision_id
	group by	transaction_type

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 7', 16, 1)
		return -1
	end

	insert		into statrev_revision_rep_xref values (@new_rep_revision_id, @new_rep_id, 1.00)

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 8', 16, 1)
		return -1
	end

	/*insert		into statrev_revision_team_xref 
	select		@new_rep_revision_id, sales_team_members.team_id, 1.0
	from		sales_team_members, sales_team
	where		rep_id = @new_rep_id
	and			business_unit_id = @business_unit_id
	and			sales_team_members.team_id = sales_team.team_id	
	group by	sales_team_members.team_id

	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 9', 16, 1)
		return -1
	end*/

end

commit transaction
return 0
GO
