/****** Object:  StoredProcedure [dbo].[p_eom_film_spot_summary_del]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_film_spot_summary_del]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_film_spot_summary_del]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_eom_film_spot_summary_del] @accounting_period		datetime
as

/*
 * Declare Variables
 */

declare @error        			int,
        @rowcount     			int,
        @errorode					int,
        @errno					int,
		@temp					varchar(100)

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Existing Summary Data
 */

delete film_spot_summary
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
	 select @temp = convert(varchar, @accounting_period, 105 )
  	 raiserror ('Error: Failed to Delete Spot Summary Records for Accounting Period %1!',11,1, @temp)
	 return -1
GO
