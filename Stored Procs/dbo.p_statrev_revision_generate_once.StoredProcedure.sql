/****** Object:  StoredProcedure [dbo].[p_statrev_revision_generate_once]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_revision_generate_once]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_revision_generate_once]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * dbo.p_statrev_revision_generate_once
 * ---------------------------------------
 * This procedure populates campaign_revision and revision_transaction_tables for all campaigns ending 
 * during or after this current financial year
 *
 * Args:    none
 *
 * Created/Modified
 * LM, 13/10/2005, Created.
 *
 * ReUsed/Modified
 * 
 */
CREATE PROCEDURE [dbo].[p_statrev_revision_generate_once]	
with recompile
as

/*
 * Declare Variables
 */

declare     @error_num           int,
				@campaign_no			int,
				@retcode 				int
	
/*
 * Declare Cursors
 */
 
declare campaign_cursor cursor static for
select campaign_no 
from film_campaign 
where campaign_status != 'P'
and business_unit_id = 6
order by campaign_no
for read only    

begin transaction
    
open campaign_cursor
fetch campaign_cursor into @campaign_no
while(@@fetch_status=0)
begin

	print	@campaign_no

	EXECUTE @retcode = p_strev_create_campaign_avgs	@campaign_no

	if @retcode <> 0 
	begin
		raiserror ('Error setting campaign average rates', 16, 1)
		rollback transaction
		return -1
	end

	EXECUTE @retcode = p_statrev_revision_generate  @campaign_no  , 0  , 1 

	if @retcode <> 0 
	begin
		raiserror ('Error setting campaign average rates', 16, 1)
		rollback transaction
		return -1
	end


   fetch campaign_cursor into @campaign_no

end 

/* set the delta date to pretend it happened when the campaign was originally confirmed */
update statrev_cinema_normal_transaction set delta_date = confirmation_date
from statrev_campaign_revision where statrev_campaign_revision.revision_id = statrev_cinema_normal_transaction.revision_id

select @retcode = @@error
if @retcode <> 0
begin
	print @campaign_no
	raiserror ('error', 16, 1)
	rollback transaction
	return -1
end

update statrev_cinema_deferred_transaction set delta_date = confirmation_date
from statrev_campaign_revision where statrev_campaign_revision.revision_id = statrev_cinema_deferred_transaction.revision_id

select @retcode = @@error
if @retcode <> 0
begin
	print @campaign_no
	raiserror ('error', 16, 1)
	rollback transaction
	return -1
end

update statrev_outpost_normal_transaction set delta_date = confirmation_date
from statrev_campaign_revision where statrev_campaign_revision.revision_id = statrev_outpost_normal_transaction.revision_id

select @retcode = @@error
if @retcode <> 0
begin
	print @campaign_no
	raiserror ('error', 16, 1)
	rollback transaction
	return -1
end

update statrev_outpost_deferred_transaction set delta_date = confirmation_date
from statrev_campaign_revision where statrev_campaign_revision.revision_id = statrev_outpost_deferred_transaction.revision_id

select @retcode = @@error
if @retcode <> 0
begin
	print @campaign_no
	raiserror ('error', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
