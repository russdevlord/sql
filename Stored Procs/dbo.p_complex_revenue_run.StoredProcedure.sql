/****** Object:  StoredProcedure [dbo].[p_complex_revenue_run]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_complex_revenue_run]
GO
/****** Object:  StoredProcedure [dbo].[p_complex_revenue_run]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_complex_revenue_run]
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
 * Begin Transaction
 */

begin transaction

/*
 * Call Complex Revenue Generation Procedure
 */

execute @errorode = p_complex_revenue_generation
if(@errorode !=0)
begin
    raiserror ('Error: Failed to complete Revenue Generation', 16, 1)
    rollback transaction
    goto error
end

/* execute procedures to populate Take out and Make Good values on Complex Projected Revenue Table */

execute @errorode = p_complex_revenue_takeout
if(@errorode !=0)
begin
    raiserror ('Error: Failed to complete Takeout Generation', 16, 1)
	rollback transaction
	goto error
end


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
