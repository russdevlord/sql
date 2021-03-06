/****** Object:  StoredProcedure [dbo].[p_check_rep_payroll]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_check_rep_payroll]
GO
/****** Object:  StoredProcedure [dbo].[p_check_rep_payroll]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_check_rep_payroll] @rep_id					integer,
                                @sales_period			datetime
as

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
        @action_override		char(1),
		  @billing_paid			money,
		  @comm_amount				money

create table #rep_payroll
(
   rep_id				integer	null,
   sales_period		datetime	null,
   nett_business		money 	null,
	comm_amount			money		null,
   entry_level			money 	null,
   percentage			money 	null,
   calculated			money 	null,
   paid 					money 	null,
	billing_paid		money		null,
   variance				money 	null
)

/*
 * Check selected reps payroll for selected period
 */

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
--   raiserror @@error ''
   return -1
end

/*
 * Set the action flag on rep payroll if the variance is not zero
 */

select @action_override = action_override
  from payroll
 where payroll.rep_id = @rep_id and
       payroll.sales_period = @sales_period

if @variance <> 0 and @action_override <> 'Y'
begin
   update payroll
      set action_flag = 'Y'
    where payroll.rep_id = @rep_id and
          payroll.sales_period = @sales_period

   select @error = @@error,
          @rowcount = @@rowcount

   if (@error != 0)
   begin
	   raiserror ( 'Error', 16, 1) 
      return -1
   end

   insert into #rep_payroll
      ( rep_id, sales_period,
        nett_business, comm_amount, entry_level, percentage, calculated, paid, billing_paid, variance )
      values
      ( @rep_id,
        @sales_period,
        @nett_business,
		  @comm_amount,
        @entry_level,
        @percentage,
        @calculated,
        @paid,
		  @billing_paid,
        @variance )
end

/*
 * Declare cursor static for other periods to check selected reps payroll
 */

declare period_csr cursor static for
  select distinct pt.origin_period
    from payroll_transaction pt
   where pt.rep_id = @rep_id and
         pt.release_period = @sales_period and
         pt.release_period <> pt.origin_period
order by pt.origin_period
for read only

/*
 * Check selected reps payroll for other periods
 */

open period_csr
fetch period_csr into @sales_period
while (@@fetch_status = 0)
begin
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
--   	raiserror @@error
	   return -1
   end

   /*
    * Set the action flag on rep payroll if the variance is not zero
    */

   select @action_override = action_override
     from payroll
    where payroll.rep_id = @rep_id and
          payroll.sales_period = @sales_period

   if @variance <> 0 and @action_override <> 'Y'
   begin
      update payroll
         set action_flag = 'Y'
       where payroll.rep_id = @rep_id and
             payroll.sales_period = @sales_period

      select @error = @@error,
             @rowcount = @@rowcount

      if (@error != 0)
      begin
   	   raiserror ( 'Error', 16, 1) 
         return -1
      end

		insert into #rep_payroll
			( rep_id, sales_period,
			  nett_business, comm_amount, entry_level, percentage, calculated, paid, billing_paid, variance )
			values
			( @rep_id,
			  @sales_period,
			  @nett_business,
			  @comm_amount,
			  @entry_level,
			  @percentage,
			  @calculated,
			  @paid,
			  @billing_paid,
			  @variance )

   end

   fetch period_csr into @sales_period
end
close period_csr

/*
 * Return
 */

select rep_id,
       sales_period,
       nett_business,
		 comm_amount,
       entry_level,
       percentage,
       calculated,
       paid,
		 billing_paid,
       variance
  from #rep_payroll

return 0
GO
