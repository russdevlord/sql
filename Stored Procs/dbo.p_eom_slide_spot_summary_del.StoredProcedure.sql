/****** Object:  StoredProcedure [dbo].[p_eom_slide_spot_summary_del]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_slide_spot_summary_del]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_slide_spot_summary_del]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_eom_slide_spot_summary_del] @accounting_period		datetime
as

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @errorode						integer,
        @errno						integer

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Existing Summary Data
 */

delete slide_spot_summary
 where accounting_period = @accounting_period

select @errno = @@error
if	(@errno != 0)
	goto error

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	 rollback transaction
	 raiserror ('Error : Failed to delete slide spot summary records.', 16, 1)
	 return -1
GO
