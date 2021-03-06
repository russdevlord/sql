/****** Object:  StoredProcedure [dbo].[p_cag_rent_statement_policy]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_rent_statement_policy]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_rent_statement_policy]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
* SP p_cag_rent_statement_policy retrieves data for Cinema Agreement Policies page of a Cinema Rent Statement
* For NEW active policies it lists previouse policies as well to show the history of changes
*
* @retrieve_mode - 0 retrieve policies that were used in generating entitlements + active policies,
*                  1 retrieve 'new' and 'modified' policies for the statement acc period + previouse to the 'modified' policies to show the history
*/

create PROC [dbo].[p_cag_rent_statement_policy]  @cinema_agreement_id  int, @statement_no int, @retrieve_mode int as                              

declare @error     				int,
        @err_msg                varchar(150),
        @agreement_desc         varchar(50),
        @policy_id               int,
        @complex_id              int,
        @revenue_source          char(1),
        @rent_mode               char(1),
        @policy_status_code      char(1),
        @policy_created_period   datetime,
        @policy_start_date       datetime,
        @policy_end_date         datetime,
        @percentage_entitlement  decimal(6,4),
        @fixed_amount            money,
        @new_policy              char(1),
        @modified_policy         char(1),
        @cur_new_active_policy_open int,
        @previous_policy        int,
        @statement_acc_period   datetime,
        @complex_name            varchar(50),
        @agreement_split_percentage numeric(6,4),
        @entitlement_adjustment   money


select @statement_acc_period = accounting_period 
from cinema_agreement_statement
where cinema_agreement_statement.cinema_agreement_id = @cinema_agreement_id and
      cinema_agreement_statement.statement_no = @statement_no
        

CREATE TABLE #result_set
(   cinema_agreement_id int null,
    agreement_desc      varchar(50) null,
    policy_id   int null,
    complex_id          int null,
    revenue_source      char(1) null,
    rent_mode           char(1) null,
    policy_status_code  char(1) null,
    policy_created_period   datetime null,
    policy_start_date   datetime null,
    policy_end_date     datetime null,
    percentage_entitlement decimal(6,4) null,
    fixed_amount    money null,
    new_policy  char(1) null,
    modified_policy char(1) null,
    complex_name    varchar(50) null,
    agreement_split_percentage  decimal(6,4) null,
    entitlement_adjustment  money null
 )

select @statement_acc_period = accounting_period 
from cinema_agreement_statement
where cinema_agreement_statement.cinema_agreement_id = @cinema_agreement_id and
      cinema_agreement_statement.statement_no = @statement_no

select @error = 0 

select @agreement_desc = agreement_desc from cinema_agreement 
where cinema_agreement_id = @cinema_agreement_id

/*
* Selects policies that were used in generating entitlements for the statement +
* all Active as at today policies 
*/           
if @retrieve_mode = 0
    declare cur_new_active_policy cursor static for                               
  SELECT distinct
   	    cinema_agreement_policy.complex_id,
    	cinema_agreement_policy.revenue_source,
    	cinema_agreement_policy.policy_id,
	    cinema_agreement_policy.rent_mode,
    	cinema_agreement_policy.policy_status_code,
	    cinema_agreement_policy.policy_created_period,
    	cinema_agreement_policy.rent_inclusion_start,
    	cinema_agreement_policy.rent_inclusion_end,
    	cinema_agreement_policy.fixed_amount,
    	cinema_agreement_policy.percentage_entitlement,
    	cinema_agreement_policy.previous_policy,
        complex.complex_name,
        cinema_agreement_policy.agreement_split_percentage,
        cinema_agreement_policy.entitlement_adjustment
    FROM cinema_agreement_entitlement,   
         cinema_agreement_revenue,   
         cinema_agreement_transaction,
         cinema_Agreement_policy,
         complex
   WHERE ( cinema_agreement_entitlement.cag_entitlement_id = cinema_agreement_revenue.cag_entitlement_id ) and  
         ( cinema_agreement_transaction.tran_id = cinema_agreement_entitlement.tran_id ) and  
         ( ( cinema_agreement_transaction.cinema_agreement_id = @cinema_agreement_id ) AND  
         ( cinema_agreement_transaction.statement_no = @statement_no ) )  and
         (  cinema_agreement_revenue.cinema_Agreement_id =  cinema_Agreement_policy.cinema_Agreement_id and
          cinema_agreement_revenue.policy_id =  cinema_Agreement_policy.policy_id and
          cinema_agreement_revenue.revenue_source =  cinema_Agreement_policy.revenue_source  and
          cinema_agreement_revenue.complex_id =  cinema_Agreement_policy.complex_id ) and
          cinema_Agreement_policy.complex_id = complex.complex_id
UNION SELECT
    	cinema_agreement_policy.complex_id,
    	cinema_agreement_policy.revenue_source,
    	cinema_agreement_policy.policy_id,
	    cinema_agreement_policy.rent_mode,
    	cinema_agreement_policy.policy_status_code,
	    cinema_agreement_policy.policy_created_period,
    	cinema_agreement_policy.rent_inclusion_start,
    	cinema_agreement_policy.rent_inclusion_end,
    	cinema_agreement_policy.fixed_amount,
    	cinema_agreement_policy.percentage_entitlement,
    	cinema_agreement_policy.previous_policy,
        complex.complex_name,
        cinema_agreement_policy.agreement_split_percentage,
        cinema_agreement_policy.entitlement_adjustment
     FROM cinema_agreement_policy, complex
     WHERE 	complex.complex_id = cinema_agreement_policy.complex_id and
            cinema_agreement_policy.cinema_agreement_id = @cinema_agreement_id and            
            policy_status_code = 'A' 
            
/*
* Selects policies that were changed and created during statement accounting period
*/           
if @retrieve_mode = 1
    declare cur_new_active_policy cursor static for                               
    SELECT
    	cinema_agreement_policy.complex_id,
    	cinema_agreement_policy.revenue_source,
    	cinema_agreement_policy.policy_id,
	    cinema_agreement_policy.rent_mode,
    	cinema_agreement_policy.policy_status_code,
	    cinema_agreement_policy.policy_created_period,
    	cinema_agreement_policy.rent_inclusion_start,
    	cinema_agreement_policy.rent_inclusion_end,
    	cinema_agreement_policy.fixed_amount,
    	cinema_agreement_policy.percentage_entitlement,
    	cinema_agreement_policy.previous_policy,
        complex.complex_name,
        cinema_agreement_policy.agreement_split_percentage,
        cinema_agreement_policy.entitlement_adjustment
     FROM cinema_agreement_policy, cinema_agreement_statement, complex
     WHERE 	complex.complex_id = cinema_agreement_policy.complex_id and 
            cinema_agreement_statement.cinema_agreement_id = cinema_agreement_policy.cinema_agreement_id and
            cinema_agreement_statement.accounting_period = cinema_agreement_policy.policy_created_period and
            cinema_agreement_statement.cinema_agreement_id = @cinema_agreement_id and
            cinema_agreement_statement.statement_no = @statement_no 


open cur_new_active_policy
if @@error != 0
    begin
        select @error = 500050
        select @err_msg = 'p_cag_rent_statement_policy: OPEN CURSOR error'
        GOTO PROC_END
    end
select @cur_new_active_policy_open = 1

fetch cur_new_active_policy 
into @complex_id, @revenue_source, @policy_id, @rent_mode, @policy_status_code,
	 @policy_created_period, @policy_start_date, @policy_end_date,
	 @fixed_amount,	@percentage_entitlement, @previous_policy, @complex_name,
     @agreement_split_percentage, @entitlement_adjustment  

while(@@fetch_status = 0)
    begin
        
        if @statement_acc_period = @policy_created_period and @policy_id = 1 
            select @new_policy = 'Y'
        else
            select @new_policy = 'N'
            
        if @statement_acc_period = @policy_created_period and @policy_id > 1 
            select @modified_policy = 'Y'
        else
            select @modified_policy = 'N'
            
        Insert into #result_set    
            ( cinema_agreement_id,
              agreement_desc,
              policy_id,
              complex_id,
              revenue_source,
              rent_mode,
              policy_status_code,
              policy_created_period,
              policy_start_date,
              policy_end_date,
              percentage_entitlement,
              fixed_amount,
              new_policy,
              modified_policy,
              complex_name, agreement_split_percentage, entitlement_adjustment )
         values ( @cinema_agreement_id, @agreement_desc, @policy_id,
                  @complex_id, @revenue_source, @rent_mode, @policy_status_code,
                  @policy_created_period, @policy_start_date, @policy_end_date, @percentage_entitlement,
                  @fixed_amount, @new_policy, @modified_policy, @complex_name,
                  @agreement_split_percentage, @entitlement_adjustment  )

/*
* Retrieves previous version of a modified policy to show the history of a change
*/         
         if @retrieve_mode = 1
            begin
             if @policy_id > 1 and @previous_policy > 0
                begin     
                    SELECT
                    	@complex_id = cinema_agreement_policy.complex_id,
                    	@revenue_source = cinema_agreement_policy.revenue_source,
                    	@policy_id = cinema_agreement_policy.policy_id,
                    	@rent_mode = cinema_agreement_policy.rent_mode,
                    	@policy_status_code = cinema_agreement_policy.policy_status_code,
                    	@policy_created_period = cinema_agreement_policy.policy_created_period,
                    	@policy_start_date = cinema_agreement_policy.rent_inclusion_start,
                    	@policy_end_date = cinema_agreement_policy.rent_inclusion_end,
                    	@fixed_amount = cinema_agreement_policy.fixed_amount,
                    	@percentage_entitlement = cinema_agreement_policy.percentage_entitlement,
                    	@previous_policy = cinema_agreement_policy.previous_policy,
                        @complex_name = complex.complex_name
                 FROM   cinema_agreement_policy, complex
                 WHERE 	complex.complex_id = cinema_agreement_policy.complex_id and
                        cinema_agreement_policy.policy_id = @previous_policy and
                        complex.complex_id = @complex_id and revenue_source = @revenue_source

                    if @statement_acc_period = @policy_created_period 
                        select @modified_policy = 'Y'
                    else
                        select @modified_policy = 'N'
                        
                    if @statement_acc_period <> @policy_created_period                        
                     Insert into #result_set    
                            ( cinema_agreement_id,
                              agreement_desc,
                              policy_id,
                              complex_id,
                              revenue_source,
                              rent_mode,
                              policy_status_code,
                              policy_created_period,
                              policy_start_date,
                              policy_end_date,
                              percentage_entitlement,
                              fixed_amount,
                              new_policy, modified_policy, complex_name )
                     values ( @cinema_agreement_id, @agreement_desc, @policy_id,
                              @complex_id, @revenue_source, @rent_mode, @policy_status_code,
                              @policy_created_period, @policy_start_date, @policy_end_date, @percentage_entitlement,
                              @fixed_amount, 'N', @modified_policy, @complex_name )
                 end
              end  /* @retrieve_mode = 1 */
                  
    
        fetch cur_new_active_policy 
        into @complex_id, @revenue_source, @policy_id, @rent_mode, @policy_status_code,
        	 @policy_created_period, @policy_start_date, @policy_end_date,
        	 @fixed_amount,	@percentage_entitlement, @previous_policy, @complex_name,
             @agreement_split_percentage, @entitlement_adjustment  
    end
deallocate cur_new_active_policy
select distinct * from #result_set order by complex_id, revenue_source, policy_status_code, policy_id desc



PROC_END:
        
if @error >= 50000
    begin
       raiserror (@err_msg, 16, 1)        
       return -1
    end
        
return 0
GO
