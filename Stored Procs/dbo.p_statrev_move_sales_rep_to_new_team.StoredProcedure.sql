/****** Object:  StoredProcedure [dbo].[p_statrev_move_sales_rep_to_new_team]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_move_sales_rep_to_new_team]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_move_sales_rep_to_new_team]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_statrev_move_sales_rep_to_new_team]		@rep_id								int,
																																@revenue_period			datetime,
																																@old_team_id					int,
																																@new_team_id					int,
																																@change_date					datetime
as

declare			@error								int,
						@revision_id					int,
						@revision_no					int,
						@rep_count					int,
						@campaign_status		char(1),
						@campaign_no			int


/*
 * Begin Transaction
 */

begin transaction 

declare		campaign_csr cursor for
select		distinct campaign_no
from			statrev_campaign_revision
where		revision_id in (select revision_id from v_statrev_team where team_id = @old_team_id and revenue_period >= @revenue_period group by revision_id having sum(cost) <> 0 )
and				revision_id in (select revision_id from v_statrev_rep where rep_id = @rep_id and revenue_period >= @revenue_period group by revision_id having sum(cost) <> 0)
group by	campaign_no
order by	campaign_no

open campaign_csr
fetch campaign_csr into @campaign_no
while(@@fetch_status = 0)
begin

	select		@campaign_status = campaign_status
	from			film_campaign
	where		campaign_no = @campaign_no

	if @campaign_status <> 'P'
	begin

		/*
		 * Reverse all transaction on and after the date for old rep
		*/


		select @revision_no = max(revision_no) + 1
		from statrev_campaign_revision
		where campaign_no = @campaign_no

		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error 1', 16, 1)
			return -1
		end
			
		insert into statrev_campaign_revision
		(campaign_no, revision_type, revision_category, revision_no, confirmed_by, confirmation_date, comment)
		select @campaign_no, 1, 1, @revision_no, 0, @change_date, 'Moving Revenue To A New Team'

		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error 2', 16, 1)
			return -1
		end
			

		select @revision_id = revision_id
		from statrev_campaign_revision
		where campaign_no = @campaign_no
		and		revision_no = @revision_no

		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error 3', 16, 1)
			return -1
		end
			
		insert into statrev_cinema_normal_transaction
		(revision_id, transaction_type, screening_date, revenue_period, delta_date, cost, units, avg_rate)
		select @revision_id, transaction_type, screening_date, revenue_period, getdate(), ((sum(cost * revenue_percent) * -1)), sum(units), 0
		from	statrev_cinema_normal_transaction, statrev_revision_team_xref
		where	statrev_cinema_normal_transaction.revision_id in (select revision_id from statrev_campaign_revision where campaign_no = @campaign_no)
		and revenue_period >= @revenue_period
		and statrev_cinema_normal_transaction.revision_id = statrev_revision_team_xref.revision_id
		and statrev_revision_team_xref.team_id = @old_team_id
		group by transaction_type, screening_date, revenue_period

		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error 4', 16, 1)
			return -1
		end

		insert into statrev_outpost_normal_transaction
		(revision_id, transaction_type, screening_date, revenue_period, delta_date, cost, units, avg_rate)
		select @revision_id, transaction_type, screening_date, revenue_period, getdate(), ((sum(cost * revenue_percent) * -1)), sum(units),0
		from	statrev_outpost_normal_transaction, statrev_revision_team_xref
		where	statrev_outpost_normal_transaction.revision_id in (select revision_id from statrev_campaign_revision where campaign_no = @campaign_no)
		and revenue_period >= @revenue_period
		and statrev_outpost_normal_transaction.revision_id = statrev_revision_team_xref.revision_id
		and statrev_revision_team_xref.team_id = @old_team_id
		group by transaction_type, screening_date, revenue_period

		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error 5', 16, 1)
			return -1
		end

		insert into statrev_cinema_deferred_transaction
		(revision_id, transaction_type,   delta_date, cost, units, avg_rate)
		select @revision_id, transaction_type,   getdate(), ((sum(cost * revenue_percent) * -1)), sum(units), 0
		from	statrev_cinema_deferred_transaction, statrev_revision_team_xref
		where	statrev_cinema_deferred_transaction.revision_id in (select revision_id from statrev_campaign_revision where campaign_no = @campaign_no)
		and statrev_cinema_deferred_transaction.revision_id = statrev_revision_team_xref.revision_id
		and statrev_revision_team_xref.team_id = @old_team_id
		group by transaction_type

		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error 6', 16, 1)
			return -1
		end

		insert into statrev_outpost_deferred_transaction
		(revision_id, transaction_type, delta_date, cost, units, avg_rate)
		select @revision_id, transaction_type,  getdate(), ((sum(cost * revenue_percent) * -1)), sum(units), 0
		from	statrev_outpost_deferred_transaction, statrev_revision_team_xref
		where	statrev_outpost_deferred_transaction.revision_id in (select revision_id from statrev_campaign_revision where campaign_no = @campaign_no)
		and statrev_outpost_deferred_transaction.revision_id = statrev_revision_team_xref.revision_id
		and statrev_revision_team_xref.team_id = @old_team_id
		group by transaction_type

		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error 7', 16, 1)
			return -1
		end

		insert into 	statrev_revision_rep_xref values (@revision_id, @rep_id, 1.00)

		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error 8', 16, 1)
			return -1
		end

		insert into statrev_revision_team_xref 
		select @revision_id, team_id, max(revenue_percent)
		from statrev_revision_team_xref
		where revision_id in (select revision_id from statrev_campaign_revision where campaign_no = @campaign_no)
		group by team_id

		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error 8', 16, 1)
			return -1
		end

	end

	/*
	 * Make sure new rep is on the film campaign reps table as primary
	*/  

	select	@rep_count = count(*)
	from		film_campaign_reps, campaign_rep_teams
	where	campaign_no = @campaign_no
	and			rep_id = @rep_id
	and			film_campaign_reps.campaign_reps_id = campaign_rep_teams.campaign_reps_id
	and			campaign_rep_teams.team_id = @new_team_id
	
	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error 9', 16, 1)
		return -1
	end

	if @rep_count = 0
	begin
		update		campaign_rep_teams
		set				team_id = @new_team_id
		from			film_campaign_reps
		where		campaign_no = @campaign_no
		and				rep_id = @rep_id
		and				film_campaign_reps.campaign_reps_id = campaign_rep_teams.campaign_reps_id
		and				campaign_rep_teams.team_id = @old_team_id

		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error 10', 16, 1)
			return -1
		end
	end

	/*
	 * Call Revision Generate Proc
	 */

	if @campaign_status <> 'P'
	begin
		exec @error = p_statrev_revision_generate @campaign_no, 0, 1

		if @error <> 0
		begin
			raiserror ('Error 11', 16, 1)
			return -1
		end
	end
	
	fetch campaign_csr into @campaign_no
end

commit transaction

return 0
GO
