/****** Object:  StoredProcedure [dbo].[p_sfin_age_transactions]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_age_transactions]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_age_transactions]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sfin_age_transactions] @campaign_no	char(7)
as

/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode							int,
		  @max_age						smallint

select @max_age = 4

/*
 * Begin Transaction
 */

begin transaction

/*
 * Increase Slide Campaign Transactions Age
 */

update slide_transaction
   set tran_age = tran_age + 1
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Increased Slide Campaign Transaction Age Codes
 */

update slide_transaction
   set age_code = age_code + 1
 where age_code < @max_age and
       campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
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
