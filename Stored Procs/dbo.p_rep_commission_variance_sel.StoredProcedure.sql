/****** Object:  StoredProcedure [dbo].[p_rep_commission_variance_sel]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rep_commission_variance_sel]
GO
/****** Object:  StoredProcedure [dbo].[p_rep_commission_variance_sel]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_rep_commission_variance_sel] @rep_id					integer,
                                        @sales_period			datetime
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare @errorode						integer,
        @error          		integer,
        @rowcount					integer,

        @nett_business			money,
        @entry_level				money,
        @percentage				money,
        @calculated				money,
        @paid						money,
        @variance					money,	
		  @comm_amount				money,
		  @billing_paid			money

execute @errorode = p_rep_commission_variance @rep_id,
                                           @sales_period,
                                           @nett_business OUTPUT,
														 @comm_amount OUTPUT,
                                           @entry_level OUTPUT,
                                           @percentage OUTPUT,
                                           @calculated OUTPUT,
                                           @paid OUTPUT,
														 @billing_paid OUTPUT,
                                           @variance OUTPUT
if (@errorode !=0)
begin
	rollback transaction
	raiserror ('p_rep_commission_variance_sel: error in p_rep_commission_variance', 16, 1)
	return -1
end

/*
 * Return
 */

select @rep_id as rep_id,
       @sales_period as sales_period,
       @nett_business as nett_business,
		 @comm_amount as comm_amount,
       @entry_level as entry_level,
       @percentage as percentage,
       @calculated as calculated,
       @paid as paid,
		 @billing_paid as billing_paid,
       @variance as variance

return 0
GO
