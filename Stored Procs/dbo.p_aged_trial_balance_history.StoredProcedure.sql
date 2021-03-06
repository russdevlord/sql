/****** Object:  StoredProcedure [dbo].[p_aged_trial_balance_history]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_aged_trial_balance_history]
GO
/****** Object:  StoredProcedure [dbo].[p_aged_trial_balance_history]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_aged_trial_balance_history]  @accounting_period	datetime,
                                          @country_code			char(1),
                                          @branch_code			char(2),
                                          @credit_controller	integer,
                                          @contract_rep			integer,
                                          @group_by				char(1),
                                          @sort_by					char(1),
                                          @user_id					char(30)
as

declare		@country_code_tmp				char(1),
				@branch_code_tmp				char(2),
				@credit_controller_tmp		integer,
				@contract_rep_tmp				integer

select @country_code_tmp = country.country_code
  from country
 where country.country_code = @country_code

select @branch_code_tmp = branch.branch_code
  from branch
 where branch.branch_code = @branch_code

select @credit_controller_tmp = employee.employee_id
  from employee
 where employee.employee_id = @credit_controller

select @contract_rep_tmp = sales_rep.rep_id
  from sales_rep
 where sales_rep.rep_id = @contract_rep

select @country_code = @country_code_tmp,
       @branch_code = @branch_code_tmp,
       @credit_controller = @credit_controller_tmp,
       @contract_rep = @contract_rep_tmp

/*
 * Return Dataset
 */

select sac.campaign_no,
       sac.name_on_slide,
       sac.campaign_type,
       sac.campaign_status,
       sac.credit_status,
       sac.statement_name,
       sac.address_1,
       sac.address_2,
       sac.town_suburb,
       sac.postcode,
       sac.state_code,
       sc.signatory,
       sac.balance_30,
       sac.balance_60,
       sac.balance_90,
       sac.balance_120,
       sac.balance_current,
       sac.balance_credit,
       employee.employee_name as credit_controller,
       sc.sort_key, 
       branch.branch_name,
       (sales_rep.last_name + ', ' + sales_rep.first_name) as contract_rep,
       @group_by as group_by,
       @sort_by as sort_by
  from slide_accounting_statement sac,
     	 slide_campaign sc,
     	 sales_rep,
	  	 branch,
	  	 branch_access,
       employee
 where sac.campaign_no = sc.campaign_no and
	 	 sales_rep.rep_id = sc.contract_rep and
       sc.branch_code = branch.branch_code and
       branch.branch_code = branch_access.branch_code and
	 	 employee.employee_id = sc.credit_controller and
		 sac.accounting_period = @accounting_period and
		 branch_access.user_id = @user_id and
		 ( branch.country_code = @country_code or @country_code is null ) and
		 ( branch.branch_code = @branch_code or @branch_code is null ) and
		 ( employee.employee_id = @credit_controller or @credit_controller is null ) and
		 ( sales_rep.rep_id = @contract_rep or @contract_rep is null )

return 0
GO
