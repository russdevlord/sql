/****** Object:  StoredProcedure [dbo].[p_ffin_delete_allocation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_delete_allocation]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_delete_allocation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_ffin_delete_allocation] @allocation_id 	integer,
				    @campaign_no	integer
as

/*
 * Declare Variables
 */

declare @errorode				integer,
		  @error				integer,
		  @tran_count		integer,
        @statement_id	integer,
		  @tran_category	char(1),
		  @process_period	datetime,
		  @reversal			char(1)
		  
/*
 * Initialise Variables
 */

select @tran_count = count(allocation_id)
  from transaction_allocation
 where allocation_id = @allocation_id
   and process_period is not null

if(@tran_count > 0)
begin
	raiserror ('Transaction has already been processed - Delete Failed.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */
	
begin transaction

/*
 * Delete Transaction
 */

delete transaction_allocation
 where allocation_id = @allocation_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Refresh Campaign Balances
 */

execute @errorode = p_ffin_campaign_balances @campaign_no
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
