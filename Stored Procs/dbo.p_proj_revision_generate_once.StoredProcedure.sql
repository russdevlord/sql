/****** Object:  StoredProcedure [dbo].[p_proj_revision_generate_once]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_proj_revision_generate_once]
GO
/****** Object:  StoredProcedure [dbo].[p_proj_revision_generate_once]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * dbo.p_proj_revision_generate_once
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

CREATE PROC [dbo].[p_proj_revision_generate_once]	
with recompile
as

/*
 * Declare Variables
 */

declare     @error_num           int,
				@campaign_no			int,
				@retcode 				int
	
	if ((select 1 where exists (select * from campaign_revision )) = 1 )
		begin
			print 'this procedure should only be run once'
			return -1
		end

	/*
	 * Declare Cursors
	 */
	 
	declare campaign_cursor cursor static for
	select campaign_no 
	from film_campaign 
	where end_date >=  '1-jun-2004'
    and campaign_status != 'P'
	for read only    

    
    open campaign_cursor
    fetch campaign_cursor into @campaign_no
    while(@@fetch_status=0)
    begin

		EXECUTE @retcode = p_proj_revision_generate  @campaign_no  , 0  , 1 

	   fetch campaign_cursor into @campaign_no

	 end 

		/* set the delta date to pretend it happened when the campaign was originally confirmed */
		update revision_transaction set delta_date = confirmation_date
		from campaign_revision where campaign_revision.revision_id = revision_transaction.revision_id;


return 0
GO
