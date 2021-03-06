/****** Object:  StoredProcedure [dbo].[p_eom_film_print_death]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_film_print_death]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_film_print_death]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_eom_film_print_death] @accounting_period		datetime
as

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @errorode					integer,
        @errno					integer

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Prints
 */

update film_print
   set dead_period = @accounting_period
 where dead_period is null and
		 print_status = 'D'

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Delete Print Transactions on Dead Prints
 */

delete print_transactions
  from film_print
 where film_print.print_status = 'D' and
		 film_print.print_id = print_transactions.print_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Update Cinelight Prints
 */

update cinelight_print
   set dead_period = @accounting_period
 where dead_period is null and
		 print_status = 'D'

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Delete Cinelight Print Transactions on Dead Prints
 */

delete cinelight_print_transaction
  from cinelight_print
 where cinelight_print.print_status = 'D' and
		 cinelight_print.print_id = cinelight_print_transaction.print_id

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
