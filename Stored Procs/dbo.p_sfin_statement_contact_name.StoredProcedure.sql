/****** Object:  StoredProcedure [dbo].[p_sfin_statement_contact_name]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_statement_contact_name]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_statement_contact_name]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sfin_statement_contact_name] @campaign_no  char(7)
as
set nocount on 
declare 	@ls_cut_off_period  char,
		@li_credit_state	integer,
		@ld_current_balance	money,
		@ld_balance_30		money,
		@ld_balance_60		money,
		@ld_balance_90	money,
		@ld_balance_120	money,
		@li_cut_off	integer

  SELECT @ls_cut_off_period = slide_campaign.credit_cut_off,
         @ld_current_balance= slide_campaign.balance_current,
         @ld_balance_30 = slide_campaign.balance_30,
         @ld_balance_60 = slide_campaign.balance_60,
         @ld_balance_90 = slide_campaign.balance_90,
         @ld_balance_120 = slide_campaign.balance_120
    FROM slide_campaign
   WHERE slide_campaign.campaign_no = @campaign_no



	if (@ld_balance_120 <> 0)
		SELECT @li_credit_state = 4
	else if ( @ld_balance_90 <> 0 )
		SELECT @li_credit_state = 3
	else if ( @ld_balance_60 <> 0 )
		SELECT @li_credit_state = 2
	else if (@ld_balance_30 <> 0 )
		SELECT @li_credit_state = 1
	else
		SELECT @li_credit_state = 0

select @li_cut_off = convert(integer, @ls_cut_off_period )
if ( @li_cut_off <= @li_credit_state )
  SELECT employee.employee_name 'contact_name',
         branch.phone  'contact_phone'
    FROM branch,
         employee,
         slide_campaign
   WHERE ( branch.branch_code = employee.branch_code ) and
         ( slide_campaign.credit_manager = employee.employee_id ) and
         ( ( slide_campaign.campaign_no = @campaign_no ) )
else
  SELECT employee.employee_name 'contact_name',
         branch.phone  'contact_phone'
    FROM branch,
         employee,
         slide_campaign
   WHERE ( branch.branch_code = employee.branch_code ) and
         ( slide_campaign.credit_controller = employee.employee_id ) and
         (  slide_campaign.campaign_no = @campaign_no )

   Return 0
GO
