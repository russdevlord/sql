/****** Object:  StoredProcedure [dbo].[p_statrev_revision_generate_acp_change]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_revision_generate_acp_change]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_revision_generate_acp_change]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
 * dbo.p_statrev_revision_generate_acp_change
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

CREATE  PROC [dbo].[p_statrev_revision_generate_acp_change]	
with recompile
as

/*
 * Declare Variables
 */

declare     @error_num          int,
				@campaign_no		int,
				@retcode 			int

set nocount on

/*
 * Declare Cursors
 */
 
declare 	campaign_cursor cursor static for
select 		distinct campaign_no 
from			v_statrev 
where screening_date >= '25-Dec-2014'
for read only    

begin transaction

open campaign_cursor
fetch campaign_cursor into @campaign_no
while(@@fetch_status=0)
begin

	--print @campaign_no

	EXECUTE @retcode = p_statrev_revision_generate  @campaign_no  , 0  , 1 

	if @retcode <> 0 
	begin
		raiserror ('Error setting campaign average rates', 16, 1)
		rollback transaction
		return -1
	end

	fetch campaign_cursor into @campaign_no
end 

commit transaction
return 0
GO
