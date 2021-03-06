/****** Object:  StoredProcedure [dbo].[p_sfin_reset_campaign]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_reset_campaign]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_reset_campaign]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sfin_reset_campaign] @campaign_no	char(7)
as
set nocount on 
/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode							int

/*
 * Begin Transaction
 */

begin transaction

delete slide_allocation
 where from_tran_id in (select tran_id from slide_transaction where campaign_no = @campaign_no) or
		 to_tran_id in (select tran_id from slide_transaction where campaign_no = @campaign_no)

delete slide_spot_trans_xref 
 where billing_tran_id in (select tran_id from slide_transaction where campaign_no = @campaign_no)

delete slide_spot_pool
  from slide_campaign_spot scp,
 		 slide_spot_pool ssp
 where scp.spot_id = ssp.spot_id and
       scp.campaign_no = @campaign_no

delete slide_transaction 
 where campaign_no = @campaign_no

delete slide_campaign_screening
  from slide_campaign_spot scp,
       slide_campaign_screening scs
 where scp.campaign_no = @campaign_no and
       scs.spot_id = scp.spot_id and
       scp.spot_type <> 'S'

delete slide_campaign_spot
 where campaign_no = @campaign_no and
       spot_type <> 'S'

update slide_campaign_spot 
   set credit_value = 0,
       billing_status = 'L',
       spot_status = 'L'
 where campaign_no = @campaign_no

update slide_campaign
   set balance_30 = 0,
		 balance_60 = 0,
		 balance_90 = 0,
		 balance_120 = 0,
		 balance_credit = 0,
		 balance_current = 0,
		 min_campaign_period = orig_campaign_period
 where campaign_no = @campaign_no

update slide_distribution
   set accrued_alloc = 0
 where campaign_no = @campaign_no and
       distribution_type <> 'P'

update slide_distribution
   set actual_alloc = 0
 where campaign_no = @campaign_no and
       distribution_type = 'C'

update rent_distribution
   set billing_accrual = 0,
       screening_accrual = 0
 where campaign_no = @campaign_no

delete slide_statement_line
 where statement_id in (select statement_id from slide_statement where campaign_no = @campaign_no)

delete slide_statement
 where campaign_no = @campaign_no
/*
 * Commit and Return
 */

commit transaction
return 0
GO
