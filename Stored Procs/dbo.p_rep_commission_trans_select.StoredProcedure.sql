/****** Object:  StoredProcedure [dbo].[p_rep_commission_trans_select]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rep_commission_trans_select]
GO
/****** Object:  StoredProcedure [dbo].[p_rep_commission_trans_select]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_rep_commission_trans_select] @mode				integer,
					@rep_id				integer,
                               		@sales_period			datetime
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare @error          			integer,
        @rowcount						integer,
		  @total_commission_paid	money

/*
 * Create Temporary Tables
 */

create table #commission
(
	comm_tran_id					integer			null,
	tran_id							integer			null,
	origin_period					datetime			null,
	release_period					datetime			null,
	campaign_no						char(7)			null,
	rep_id							integer			null,
	comm_tran_desc					varchar(50)		null,
	nett_amount						money				null,
	pay_amount						money				null,
	comm_rate						numeric(6,4)	null,
	comm_amount						money				null,
	status							char(1)			null,
	entry_date						datetime			null,
	name_on_slide					varchar(50)		null,
	payroll_tran_id				integer			null,
	pt_action_flag					char(1)			null,
	pt_release_period				datetime			null,
	pt_release_period_status	char(1)			null,
	total_commission_paid		money				null,
	entry_level						money				null,   
	commission_percentage		numeric(6,4)	null,
	commission_type				char(1)			null,
	commission_basis				char(1)			null,
	branch_code						char(1)			null
)

/*
 * Initialise Temporary Table
 */

insert into #commission
	(  comm_tran_id,
		tran_id,
		origin_period,
		release_period,
		campaign_no,
		rep_id,
		comm_tran_desc,
		nett_amount,
		pay_amount,
		comm_rate,
		comm_amount,
		status,
		entry_date,
		name_on_slide,
		total_commission_paid,
		entry_level,   
		commission_percentage,
		commission_type,
		commission_basis,
		branch_code)
  select commission_transaction.comm_tran_id,
		commission_transaction.tran_id,
		commission_transaction.origin_period,
		commission_transaction.release_period,
		commission_transaction.campaign_no,
		commission_transaction.rep_id,
		commission_transaction.comm_tran_desc,
		commission_transaction.nett_amount,
		commission_transaction.pay_amount,
		commission_transaction.comm_rate,
		commission_transaction.comm_amount,
		commission_transaction.status,
		commission_transaction.entry_date,
		slide_campaign.name_on_slide,
		0.0,
		0.0,
		0.0,
		'',
		'',
		slide_campaign.branch_code
    from commission_transaction,   
         slide_campaign
   where commission_transaction.campaign_no = slide_campaign.campaign_no and
         commission_transaction.rep_id = @rep_id and
         ((@mode = 1 and
			commission_transaction.release_period = @sales_period) or
			(@mode = 2 and
			commission_transaction.release_period is null))
/*
 * Set Entry Level and Commission Perecntage
 */

update #commission
	set #commission.entry_level = payroll.entry_level,   
		 #commission.commission_percentage = payroll.commission_percentage,
		 #commission.commission_type = payroll.commission_type,
		 #commission.commission_basis = payroll.commission_basis
  from payroll
 where payroll.sales_period = @sales_period and
		 payroll.rep_id = @rep_id

/*
 * Set the linked payroll transaction, action_flag, release_date
 */

update #commission
   set payroll_tran_id = ( select pt.payroll_tran_id
                             from payroll_transaction pt
                            where pt.comm_tran_id = #commission.comm_tran_id ),
       pt_action_flag = ( select pt.action_flag
                            from payroll_transaction pt
                           where pt.comm_tran_id = #commission.comm_tran_id ),
       pt_release_period = ( select pt.release_period
                               from payroll_transaction pt
                              where pt.comm_tran_id = #commission.comm_tran_id )

/*
 * Set the linked payroll transaction release_date status
 */

update #commission
   set pt_release_period_status = sp.status
  from sales_period sp
 where sp.sales_period_end = @sales_period

select @total_commission_paid = sum(round((payroll_transaction.pay_qty * payroll_transaction.pay_amount),2))
     from payroll_transaction
    where payroll_transaction.paytran_type = 'L' and
          payroll_transaction.rep_id = @rep_id and
          payroll_transaction.release_period = @sales_period

update #commission
	set total_commission_paid = @total_commission_paid


/*
 * Return Dataset
 */

  select comm_tran_id,
			tran_id,
			origin_period,
			release_period,
			campaign_no,
			rep_id,
			comm_tran_desc,
			nett_amount,
			pay_amount,
			comm_rate,
			comm_amount,
			status,
			entry_date,
			name_on_slide,
			payroll_tran_id,
			pt_action_flag,
			pt_release_period,
			pt_release_period_status,
			total_commission_paid,
			entry_level, 
			commission_percentage,
			commission_type,
			commission_basis,
			branch_code
  from #commission
         
/*
 * Return
 */

return 0
GO
