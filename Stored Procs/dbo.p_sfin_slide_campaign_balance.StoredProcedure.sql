/****** Object:  StoredProcedure [dbo].[p_sfin_slide_campaign_balance]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_slide_campaign_balance]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_slide_campaign_balance]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sfin_slide_campaign_balance] @campaign_no	char(7)
as
set nocount on 

/*
 * Declare Variables
 */

declare @balance_curr				money,
        @balance_30					money,
        @balance_60					money,
        @balance_90					money,
        @balance_120					money,
        @balance_credit				money,
        @balance_outstanding		money

/*
 * Amount Owing Current
 */

select @balance_curr = IsNull(sum(sa.gross_amount),0)
  from slide_transaction st,
       slide_allocation sa
 where st.campaign_no = @campaign_no and
       st.gross_amount > 0 and
       st.age_code <= 0 and
       st.tran_id = sa.to_tran_id

/*
 * Amount Owing 30 Days
 */

select @balance_30 = IsNull(sum(sa.gross_amount),0)
  from slide_transaction st,
       slide_allocation sa
 where st.campaign_no = @campaign_no and
       st.gross_amount > 0 and
       st.age_code = 1 and
       st.tran_id = sa.to_tran_id

/*
 * Amount Owing 60 Days
 */

select @balance_60 = IsNull(sum(sa.gross_amount),0)
  from slide_transaction st,
       slide_allocation sa
 where st.campaign_no = @campaign_no and
       st.gross_amount > 0 and
       st.age_code = 2 and
       st.tran_id = sa.to_tran_id

/*
 * Amount Owing 90 Days
 */

select @balance_90 = IsNull(sum(sa.gross_amount),0)
  from slide_transaction st,
       slide_allocation sa
 where st.campaign_no = @campaign_no and
       st.gross_amount > 0 and
       st.age_code = 3 and
       st.tran_id = sa.to_tran_id

/*
 * Amount Owing 120 Days
 */

select @balance_120 = IsNull(sum(sa.gross_amount),0)
  from slide_transaction st,
       slide_allocation sa
 where st.campaign_no = @campaign_no and
       st.gross_amount > 0 and
       st.age_code = 4 and
       st.tran_id = sa.to_tran_id

/*
 * Amount in Credit
 */

select @balance_credit = 0 - IsNull(sum(sa.gross_amount),0)
  from slide_transaction st,
       slide_allocation sa
 where st.campaign_no = @campaign_no and
       st.gross_amount < 0 and
       st.tran_id = sa.from_tran_id

/*
 * Calculate Outstanding
 */

select @balance_outstanding = @balance_curr + 
                              @balance_30 + 
                              @balance_60	+ 
                              @balance_90 + 
                              @balance_120 + 
                              @balance_credit

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Slide Campaign
 */

update slide_campaign
   set balance_credit = @balance_credit,
       balance_current = @balance_curr,
       balance_30 = @balance_30,
       balance_60 = @balance_60,
       balance_90 = @balance_90,
       balance_120 = @balance_120,
       balance_outstanding = @balance_outstanding
 where campaign_no = @campaign_no

/*
 * Commit and Return
 */

commit transaction
return 0
GO
