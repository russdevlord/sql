/****** Object:  StoredProcedure [dbo].[p_check_reps_payroll]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_check_reps_payroll]
GO
/****** Object:  StoredProcedure [dbo].[p_check_reps_payroll]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_check_reps_payroll] @sales_period			datetime
as

/*
 * Declare Procedure Variables
 */

declare @errorode						integer,
        @error          		integer,
        @rowcount					integer,

        @rep_id					integer,

        @nett_business			money,
		  @comm_amount				money,
        @entry_level				money,
        @percentage				money,
        @calculated				money,
        @paid						money,
		  @billing_paid			money,
        @variance					money,

        @pt_origin_period		datetime,
        @action_override		char(1)

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
 * Declare cursor static for all reps to check selected period
 */

declare reps_csr cursor static for
  select payroll.rep_id
    from payroll
   where payroll.sales_period = @sales_period
order by payroll.rep_id
for read only

/*
 * Check all reps payroll for selected period
 */

open reps_csr
fetch reps_csr into @rep_id
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

   select @action_override = action_override
     from payroll
    where payroll.rep_id = @rep_id and
          payroll.sales_period = @sales_period

   -- Set the action flag on rep payroll if the variance is not zero
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

   fetch reps_csr into @rep_id
end
close reps_csr

/*
 * Declare cursor static for other periods to check selected reps payroll
 */

declare rep_period_csr cursor static for
  select distinct pt.rep_id, pt.origin_period
    from payroll_transaction pt
   where pt.release_period = @sales_period and
         pt.release_period <> pt.origin_period
order by pt.origin_period
for read only

/*
 * Check selected reps payroll for other periods
 */

open rep_period_csr
fetch rep_period_csr into @rep_id, @pt_origin_period
while (@@fetch_status = 0)
begin
   execute @errorode = p_rep_commission_variance @rep_id,
                                              @pt_origin_period,
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

   select @action_override = action_override
     from payroll
    where payroll.rep_id = @rep_id and
          payroll.sales_period = @sales_period

   -- Set the action flag on rep payroll if the variance is not zero
   if @variance <> 0 and @action_override <> 'Y'
   begin
      update payroll
         set action_flag = 'Y'
       where payroll.rep_id = @rep_id and
             payroll.sales_period = @pt_origin_period

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

   fetch rep_period_csr into @rep_id, @pt_origin_period
end
close rep_period_csr

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
