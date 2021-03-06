/****** Object:  StoredProcedure [dbo].[p_eom_statrev_clean]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_statrev_clean]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_statrev_clean]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_eom_statrev_clean]	@accounting_period		datetime

as

declare		@error					int,
			@campaign_no			int,
			@deferred				money,
			@revision_no			int,
			@revision_id			int,
			@rowcount				int

set nocount on

if not (datepart(mm, @accounting_period) = 6 or datepart(mm, @accounting_period) = 12)
begin
	print 'Not Jun or Dec'
	return 0
end
else
	print @accounting_period


/*
 * Begin Transaction
 */

begin transaction


declare 	campaign_csr cursor forward_only for
select 		film_campaign.campaign_no
from		film_campaign,
			film_campaign_event
where		film_campaign.campaign_no = film_campaign_event.campaign_no
and			event_type = 'X'
and			event_date <= @accounting_period
group by	film_campaign.campaign_no
order by	film_campaign.campaign_no

open campaign_csr
fetch campaign_csr into @campaign_no
while(@@fetch_Status = 0)
begin


	select 	@deferred = 0

	select	@deferred = isnull(sum(cost),0)
	from	statrev_cinema_deferred_transaction,
			statrev_campaign_revision
	where	statrev_cinema_deferred_transaction.revision_id = statrev_campaign_revision.revision_id
	and		statrev_campaign_revision.campaign_no = @campaign_no
	and		transaction_type in (26,27,28,29,48,109,110,111,34,35,36,37,50,115,116,117,38,39,40,41,51,118,119,120)

	if @deferred <> 0
	begin

		print 	@campaign_no

		SELECT 	@revision_no = isnull ( max ( revision_no ) + 1  , 1 )
		FROM 	statrev_campaign_revision
		WHERE 	statrev_campaign_revision.campaign_no = @campaign_no

		insert into statrev_campaign_revision  
		( 
		campaign_no,   
		revision_type,   
		revision_category,   
		revision_no,
		confirmed_by,
		confirmation_date,
		comment)
		values
		(
		@campaign_no,
		4,
		1,
		@revision_no,
		1,
		@accounting_period,
		'EOM Campaign Close - Remove Outstanding Unallocated, Cancelled and On Hold Spots'
		)
	
		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error:  Failed to insert statrev_campaign_revision', 16, 1)
			return -1
		end		

		select 	@revision_id = revision_id
		from 	statrev_campaign_revision
		where	campaign_no = @campaign_no
		and		revision_no = @revision_no

		select 	@error =  @@error,
				@rowcount = @@rowcount

		if @error <> 0 or @rowcount <> 1
		begin
			rollback transaction
			raiserror ('Error:  Failed to get revision_id from statrev_campaign_revision', 16, 1)
			return -1
		end		

		insert 		into statrev_cinema_normal_transaction
		select		@revision_id, transaction_type, dateadd(dd, -6, @accounting_period), @accounting_period, @accounting_period, sum(cost),  sum(units), avg(avg_rate)
		from		statrev_cinema_deferred_transaction,
					statrev_campaign_revision
		where		statrev_cinema_deferred_transaction.revision_id = statrev_campaign_revision.revision_id
		and			statrev_campaign_revision.campaign_no = @campaign_no
		and			transaction_type in (26,27,28,29,48,109,110,111,34,35,36,37,50,115,116,117,38,39,40,41,51,118,119,120)
		group by 	transaction_type
 
		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error:  Failed to insert campaign_revision', 16, 1)
			return -1
		end		

		insert 		into statrev_cinema_deferred_transaction
		select		@revision_id, transaction_type, @accounting_period, -1 * sum(cost), -1 * sum(units), avg(avg_rate)
		from		statrev_cinema_deferred_transaction,
					statrev_campaign_revision
		where		statrev_cinema_deferred_transaction.revision_id = statrev_campaign_revision.revision_id
		and			statrev_campaign_revision.campaign_no = @campaign_no
		and			transaction_type in (26,27,28,29,48,109,110,111,34,35,36,37,50,115,116,117,38,39,40,41,51,118,119,120)
		group by 	transaction_type

		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error:  Failed to insert campaign_revision', 16, 1)
			return -1
		end		
	end

	select 	@deferred = 0

	select	@deferred = isnull(sum(cost),0)
	from	statrev_outpost_deferred_transaction,
			statrev_campaign_revision
	where	statrev_outpost_deferred_transaction.revision_id = statrev_campaign_revision.revision_id
	and		statrev_campaign_revision.campaign_no = @campaign_no
	and		transaction_type in (26,27,28,29,48,109,110,111,34,35,36,37,50,115,116,117,38,39,40,41,51,118,119,120)

	if @deferred <> 0
	begin

		print 	@campaign_no

		SELECT 	@revision_no = isnull ( max ( revision_no ) + 1  , 1 )
		FROM 	statrev_campaign_revision
		WHERE 	statrev_campaign_revision.campaign_no = @campaign_no

		insert into statrev_campaign_revision  
		( 
		campaign_no,   
		revision_type,   
		revision_category,   
		revision_no,
		confirmed_by,
		confirmation_date,
		comment)
		values
		(
		@campaign_no,
		4,
		1,
		@revision_no,
		1,
		@accounting_period,
		'EOM Campaign Close - Remove Outstanding Unallocated, Cancelled and On Hold Spots'
		)
	
		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error:  Failed to insert campaign_revision', 16, 1)
			return -1
		end		

		select 	@revision_id = revision_id
		from 	statrev_campaign_revision
		where	campaign_no = @campaign_no
		and		revision_no = @revision_no

		select 	@error =  @@error,
				@rowcount = @@rowcount

		if @error <> 0 or @rowcount <> 1
		begin
			rollback transaction
			raiserror ('Error:  Failed to get revision_id from statrev_campaign_revision', 16, 1)
			return -1
		end		

		insert 		into statrev_outpost_normal_transaction
		select		@revision_id, transaction_type, dateadd(dd, -6, @accounting_period), @accounting_period, @accounting_period, sum(cost),  sum(units), avg(avg_rate)
		from		statrev_outpost_deferred_transaction,
					statrev_campaign_revision
		where		statrev_outpost_deferred_transaction.revision_id = statrev_campaign_revision.revision_id
		and			statrev_campaign_revision.campaign_no = @campaign_no
		and			transaction_type in (26,27,28,29,48,109,110,111,34,35,36,37,50,115,116,117,38,39,40,41,51,118,119,120)
		group by 	transaction_type
 
		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error:  Failed to insert campaign_revision', 16, 1)
			return -1
		end		

		insert 		into statrev_outpost_deferred_transaction
		select		@revision_id, transaction_type, @accounting_period, -1 * sum(cost), -1 * sum(units), avg(avg_rate)
		from		statrev_outpost_deferred_transaction,
					statrev_campaign_revision
		where		statrev_outpost_deferred_transaction.revision_id = statrev_campaign_revision.revision_id
		and			statrev_campaign_revision.campaign_no = @campaign_no
		and			transaction_type in (26,27,28,29,48,109,110,111,34,35,36,37,50,115,116,117,38,39,40,41,51,118,119,120)
		group by 	transaction_type

		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error:  Failed to insert campaign_revision', 16, 1)
			return -1
		end		
	end
	
	fetch campaign_csr into @campaign_no
end

commit transaction
return 0
GO
