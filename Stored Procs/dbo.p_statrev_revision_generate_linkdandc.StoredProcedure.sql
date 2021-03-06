/****** Object:  StoredProcedure [dbo].[p_statrev_revision_generate_linkdandc]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_revision_generate_linkdandc]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_revision_generate_linkdandc]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
 * dbo.p_statrev_revision_generate_linkdandc
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

CREATE  PROC [dbo].[p_statrev_revision_generate_linkdandc]	@campaign_no            int
with recompile
as

/*
 * Declare Variables
 */

declare     @error_num              int,
			@source_campaign_no		int,
			@retcode 			    int


/*
 * Declare Cursors
 */
 
declare 	campaign_cursor cursor static for
select 		source_campaign 
from 		delete_charge 
where 		destination_campaign = @campaign_no
for read only    

begin transaction

open campaign_cursor
fetch campaign_cursor into @source_campaign_no
while(@@fetch_status=0)
begin

	EXECUTE @retcode = p_statrev_revision_generate  @source_campaign_no  , 0  , 1 

	if @retcode <> 0 
	begin
		raiserror ('Error setting creating statutory revenue for D and C Source Campaigns', 16, 1)
		rollback transaction
		return -1
	end

	fetch campaign_cursor into @campaign_no
end 

commit transaction
return 0
GO
