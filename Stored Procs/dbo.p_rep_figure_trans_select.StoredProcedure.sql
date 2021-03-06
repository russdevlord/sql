/****** Object:  StoredProcedure [dbo].[p_rep_figure_trans_select]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rep_figure_trans_select]
GO
/****** Object:  StoredProcedure [dbo].[p_rep_figure_trans_select]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_rep_figure_trans_select] @mode						integer,
                                      @rep_id					integer,
                                      @sales_period			datetime,
									  @commission_basis		char(1)
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

create table #figures
(
	figure_id						integer			null,
	campaign_no						char(7)			null,
	branch_code						char(2)			null,
	rep_id							integer			null,
	business_group					integer			null,
	team_id							integer			null,
	origin_period					datetime			null,
	creation_period				datetime			null,
	release_period					datetime			null,
	figure_type						char(1)			null,
	figure_status					char(1)			null,
	figure_category				integer			null,
	gross_amount					money				null,
	nett_amount						money				null,
	comm_amount						money				null,
	release_value					money				null,
	re_coupe_value					money				null,
	branch_hold						char(1)			null,
	ho_hold							char(1)			null,
	figure_hold						char(1)			null,
	figure_reason					varchar(50)		null,
	figure_official				char(1)			null,
	name_on_slide					varchar(50)		null,
	slide_figure_type_desc		varchar(30)		null,
	entry_level						money				null,
	commission_percentage		money				null,
	payroll_tran_id				integer			null,
	pt_action_flag					char(1)			null,
	pt_release_period				datetime			null,
	pt_release_period_status	char(1)			null,
	payroll_figure_calc			char(1)			null,
	area_id							integer			null,
	region_id						integer			null,
	commission_basis				char(1)			null,
	commission_type				char(1)			null,
	artwork_approved				datetime			null,
	total_commission_paid		money				null,
	billing_commission			char(1)			null
)

/*
 * Initialise Temporary Table
 */

insert into #figures
	( figure_id,   
     campaign_no,   
     branch_code,
     rep_id,   
     business_group,   
     team_id,   
     origin_period,   
     creation_period,   
     release_period,   
     figure_type,   
     figure_status,   
     figure_category,   
     gross_amount,   
     nett_amount,   
     comm_amount,   
     release_value,   
     re_coupe_value,   
     branch_hold,   
     ho_hold,   
     figure_hold,   
     figure_reason,   
     figure_official,   
     name_on_slide,   
     slide_figure_type_desc,
     entry_level,
     commission_percentage,
	  area_id,
	  region_id,
	  commission_basis,
	  commission_type,
	  artwork_approved,
	  payroll_figure_calc,
	  total_commission_paid,
	  billing_commission)
  select slide_figures.figure_id,   
         slide_figures.campaign_no,   
         slide_figures.branch_code,   
         slide_figures.rep_id,   
         slide_figures.business_group,   
         slide_figures.team_id,   
         slide_figures.origin_period,   
         slide_figures.creation_period,   
         slide_figures.release_period,   
         slide_figures.figure_type,   
         slide_figures.figure_status,   
         slide_figures.figure_category,   
         slide_figures.gross_amount,   
         slide_figures.nett_amount,   
         slide_figures.comm_amount,   
         slide_figures.release_value,   
         slide_figures.re_coupe_value,   
         slide_figures.branch_hold,   
         slide_figures.ho_hold,   
         slide_figures.figure_hold,   
         slide_figures.figure_reason,   
         slide_figures.figure_official,   
         slide_campaign.name_on_slide,   
         slide_figure_type.slide_figure_type_desc,
         0,
         0,
			slide_figures.area_id,
			slide_figures.region_id,
			'',
			'',
			slide_campaign.artwork_approved,
			slide_figures.payroll_options,
			0,
			slide_campaign.billing_commission
    from slide_figures,   
         slide_campaign,   
         slide_figure_type
   where slide_figures.campaign_no = slide_campaign.campaign_no and
         slide_figures.figure_type = slide_figure_type.slide_figure_type and
         slide_figures.rep_id = @rep_id and
         ( ( slide_figures.origin_period = @sales_period and @mode = 1 ) or
           ( slide_figures.release_period = @sales_period and @mode = 2 and
             slide_figures.figure_status <> 'P' ) ) and
         slide_campaign.campaign_release = 'Y'

/*
 * Set Entry Level and Commission Perecntage
 */

update #figures
	set #figures.entry_level = payroll.entry_level,   
		 #figures.commission_percentage = payroll.commission_percentage,
		 #figures.commission_type = payroll.commission_type,
		 #figures.commission_basis = payroll.commission_basis
  from payroll
 where payroll.sales_period = @sales_period and
		 payroll.rep_id = @rep_id

/*
 * Set the linked payroll transaction, action_flag, release_date
 */

update #figures
   set payroll_tran_id = ( select pt.payroll_tran_id
                             from payroll_transaction pt
                            where pt.figure_id = #figures.figure_id ),
       pt_action_flag = ( select pt.action_flag
                            from payroll_transaction pt
                           where pt.figure_id = #figures.figure_id ),
       pt_release_period = ( select pt.release_period
                               from payroll_transaction pt
                              where pt.figure_id = #figures.figure_id )

/*
 * Set the linked payroll transaction release_date status
 */

update #figures
   set pt_release_period_status = sp.status
  from sales_period sp
 where sp.sales_period_end = @sales_period

select @total_commission_paid = sum(round((payroll_transaction.pay_qty * payroll_transaction.pay_amount),2))
     from payroll_transaction
    where payroll_transaction.paytran_type = 'C' and
          payroll_transaction.rep_id = @rep_id and
          payroll_transaction.release_period = @sales_period

update #figures
	set total_commission_paid = @total_commission_paid

/*
 * Set the payroll options for the system figures
 */

if @mode = 1 -- origin period
begin

	update #figures 
		set payroll_figure_calc = 'P' --primary
	 where payroll_figure_calc = 'Y' and --system
			 figure_status = 'R' and
			 origin_period = release_period and
			 (commission_type = 'F' or 
			 (commission_type = 'A' and
			 artwork_approved is not null))
	
	update #figures 
		set payroll_figure_calc = 'S' --secondary
	 where payroll_figure_calc = 'Y' and --system
			 (figure_status = 'P' or (
			 figure_status = 'R' and
			 origin_period <> release_period)) and
			 (commission_type = 'F' or 
			 (commission_type = 'A' and
			 artwork_approved is null))
end 
else if @mode = 2 --release period
begin
	update #figures 
		set payroll_figure_calc = 'P' --primary
	 where payroll_figure_calc = 'Y' and --system
			 figure_status = 'R' and
			 (commission_type = 'F' or 
			 (commission_type = 'A' and
			 artwork_approved is not null))
	
	update #figures 
		set payroll_figure_calc = 'S' --secondary
	 where payroll_figure_calc = 'Y' and --system
			 ((commission_type = 'F' and
			 figure_status = 'P' ) or 
			 (figure_status = 'R'  and
			 commission_type = 'A' and
			 artwork_approved is null))
end

/*
 * Return Dataset
 */

select figure_id,   
       campaign_no,   
       branch_code,
       rep_id,   
       business_group,   
       team_id,   
       origin_period,   
       creation_period,   
       release_period,   
       figure_type,   
       figure_status,   
       figure_category,   
       gross_amount,   
       nett_amount,   
       comm_amount,   
       release_value,   
       re_coupe_value,   
       branch_hold,   
       ho_hold,   
       figure_hold,   
       figure_reason,   
       figure_official,   
       name_on_slide,   
       slide_figure_type_desc,   
       entry_level,   
       commission_percentage,
       payroll_tran_id,
       pt_action_flag,
       pt_release_period,
       pt_release_period_status,
       payroll_figure_calc,
		 area_id,
		 region_id,
		 commission_basis,
		 commission_type,
		 artwork_approved,
		 total_commission_paid,
		 billing_commission
  from #figures
         
/*
 * Return
 */

return 0
GO
