/****** Object:  StoredProcedure [dbo].[p_eom_slide_nt_held_consol]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_slide_nt_held_consol]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_slide_nt_held_consol]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_eom_slide_nt_held_consol]   
as

declare	@cost_centre_code		char(2),
			@gl_code					char(4),
			@campaign_no		   char(7),
			@amount					money,
			@error					integer

/*
 * Create Temporary Table
 */


/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Non Trading entries where not in Held Accounts
 */

update non_trading
   set held_active = 'N'
  from non_trading nt,
		 cost_account ca
 where nt.held_active = 'Y' and
		 nt.gl_code = ca.gl_code and
		 ca.hold_account = 'N'

select @error = @@error
if @error != 0
begin
	rollback transaction
	raiserror ('Error : Failed to update held accounts on non trading.', 16, 1)
	return -1
end
	    
/*
 * Open Cursor
 */

     declare nt_csr cursor static for
  select nt.cost_centre_code,
			nt.gl_code,
         nt.campaign_no,
			sum(nt.amount)
    from non_trading nt,
         cost_account ca
   where nt.held_active = 'Y' and
			nt.gl_code = ca.gl_code and
         ca.hold_account = 'Y'
group by nt.cost_centre_code,
			nt.gl_code,
         nt.campaign_no
  having sum(nt.amount) = 0
      for read only

open nt_csr
fetch nt_csr into @cost_centre_code, @gl_code, @campaign_no, @amount
begin

	update non_trading
		set held_active = 'N'
	 where cost_centre_code = @cost_centre_code and
			 gl_code = @gl_code and
			 campaign_no =@campaign_no

	select @error = @@error
	if @error != 0
	begin
		rollback transaction
		raiserror ('Error : Failed to update held accounts on non trading.', 16, 1)
		return -1
	end

	/*
	 * Fetch Next 
	 */

	fetch nt_csr into @cost_centre_code, @gl_code, @campaign_no, @amount

end

close nt_csr
deallocate nt_csr

/*
 * Return
 */

commit transaction

return 0
GO
