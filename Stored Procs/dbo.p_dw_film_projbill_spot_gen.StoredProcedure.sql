/****** Object:  StoredProcedure [dbo].[p_dw_film_projbill_spot_gen]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_dw_film_projbill_spot_gen]
GO
/****** Object:  StoredProcedure [dbo].[p_dw_film_projbill_spot_gen]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_dw_film_projbill_spot_gen]
as

/*
 * Declare Variables
 */

declare @error        						int,
        @rowcount     						int,
        @errorode								int,
        @campaign_csr_open                  tinyint,
        @tran_id                            int,
        @campaign_no                        int,
        @accounting_period                  datetime
        
/*
 * Declare Campaign Cursor
 */
 
select  @accounting_period = min(finyear_end)
from    accounting_period
where   status = 'O' 

    declare campaign_csr cursor static for
     select distinct campaign_revision.campaign_no
       from revision_transaction,
            campaign_revision
      where revision_transaction.revision_id = campaign_revision.revision_id
      and   revision_transaction.revenue_period >= dateadd(yy, -1, @accounting_period)
   group by campaign_revision.campaign_no
   order by campaign_revision.campaign_no
        for read only
        
        
/*
 * Initialise Spot Cursor Open Indicator
 */
 
select @campaign_csr_open = 0

/*
 * Begin Transaction
 */

begin transaction

/*
 * Open Campaign Cursor
 */
 
open campaign_csr
select @campaign_csr_open = 1
fetch campaign_csr into @campaign_no
while(@@fetch_status = 0)
begin

    /*
     * Call Spot Liability Generation Procedure
     */

    execute @errorode = p_spot_liability_generation @campaign_no, 99, @tran_id, 1
    if(@errorode !=0)
    begin
        raiserror ('Error: Failed to complete Weightings Generation (Campaign No: %1!)', 16, 1, @campaign_no)
        rollback transaction
	    goto error
    end

    /*
     * Fetch Next
     */
     
    fetch campaign_csr into @campaign_no
    
end

/*
 * Deallocate Cursor
 */

deallocate campaign_csr
select @campaign_csr_open = 0

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

    if (@campaign_csr_open = 1)
    begin
        close campaign_csr
        deallocate campaign_csr
    end
    return -100
GO
