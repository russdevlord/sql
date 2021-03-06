/****** Object:  StoredProcedure [dbo].[p_cag_rent_statement_rec]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_rent_statement_rec]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_rent_statement_rec]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_cag_rent_statement_rec]  @cinema_agreement_id  int,
                                      @statement_no int, 
                                      @mode int as                              

/*
* SP p_cag_rent_statement_rec retrieves data for Billing Summary page of a Cinema Rent Statement
*
*   mode: 0 - details by complex - revenue source
*         1 - details by revenue source only
*/


declare @error     				int,
        @err_msg                varchar(150),
        @revenue_source         char(1),
        @cur_revenue_source_open        tinyint,
        @cur_liability_category_open     tinyint,
        @complex_id                     int,
        @complex_name                   char(50),
        @amount_prior                 money,
        @amount_5_month_prior         money,
        @amount_4_month_prior         money,
        @amount_3_month_prior         money,
        @amount_2_month_prior         money,
        @amount_1_month_prior         money,
        @amount_this_month            money,
        @period_1_month_prior         datetime,
        @period_2_month_prior         datetime,
        @period_3_month_prior         datetime,
        @period_4_month_prior         datetime,
        @period_5_month_prior         datetime,
        @period_prior                  datetime,
        @billing_group              char(1),
        @collect_group              char(1),
        @liability_group            char(1),
        @liability_category_id      tinyint,
        @cnt                        tinyint,
        @ret                        int,
        @statement_period           datetime,
        @agreement_desc             varchar(50),
        @report_max_period          datetime,
        @currency_code              varchar(3),
		@abn_no						varchar(20)
        



    

CREATE TABLE #result_set
(   cinema_agreement_id int null,
    complex_id  int null,
    complex_name            varchar(50) null, 
    revenue_source              char(1) null,
    liability_group             char(1) null,
    liability_category_id      tinyint null,
    period_prior                datetime    null,
    amount_prior                  money    null,
    period_5_month_prior         datetime null,
    amount_5_month_prior         money    null,
    period_4_month_prior         datetime null,
    amount_4_month_prior         money    null,
    period_3_month_prior         datetime null,
    amount_3_month_prior         money    null,
    period_2_month_prior         datetime null,
    amount_2_month_prior         money    null,
    period_1_month_prior         datetime null,
    amount_1_month_prior         money    null,
    statement_period             datetime null,
    amount_current_period        money    null,
    agreement_desc               varchar(50) null,
    real_statement_period             datetime null,
	abn_no						varchar(20)    )

select @error = 0 

select @statement_period = accounting_period from cinema_agreement_statement 
where cinema_Agreement_id = @cinema_Agreement_id and statement_no = @statement_no

select @agreement_desc= agreement_desc, @abn_no = abn_no from cinema_agreement
where cinema_Agreement_id = @cinema_Agreement_id 

select @currency_code = currency_code from cinema_agreement where cinema_Agreement_id = @cinema_Agreement_id

if @currency_code = 'NZD'
    select @report_max_period = '2004-12-24'
else
    begin
        if @statement_period >= '2004-6-30'
            select @report_max_period = @statement_period
        else
            select @report_max_period = '2004-6-30'
     end 

exec p_get_prior_accounting_period  @report_max_period, 1, @period_1_month_prior output
--exec p_get_prior_accounting_period  @statement_period, 1, @period_1_month_prior output
/* Historical total commence on 1-Jan-2004. This report shows 6 month history, */
/* use July-2004 period as a start period. It should be changed after we have full 6 month data history */
/*exec p_get_prior_accounting_period  '2004-06-30', 1, @period_1_month_prior output*/
exec p_get_prior_accounting_period  @period_1_month_prior, 1, @period_2_month_prior output
exec p_get_prior_accounting_period  @period_2_month_prior, 1, @period_3_month_prior output
exec p_get_prior_accounting_period  @period_3_month_prior, 1, @period_4_month_prior output
exec p_get_prior_accounting_period  @period_4_month_prior, 1, @period_5_month_prior output
exec p_get_prior_accounting_period  @period_5_month_prior, 1, @period_prior output

if @mode = 0 
     declare cur_revenue_source cursor static for                               
     SELECT DISTINCT	cinema_agreement_policy.revenue_source, 0, ''
      FROM cinema_agreement_policy
      WHERE  policy_status_code in ('A', 'I') and 
             cinema_agreement_id = @cinema_agreement_id
         
if @mode = 1 
     declare cur_revenue_source cursor static for                               
     SELECT DISTINCT cinema_agreement_policy.revenue_source, complex.complex_id, complex_name
      FROM cinema_agreement_policy, complex
      WHERE  cinema_agreement_policy.complex_id = complex.complex_id and
             policy_status_code in ('A', 'I') and 
             cinema_agreement_id = @cinema_agreement_id

open cur_revenue_source
if @@error != 0
    begin
        select @error = 500050
        select @err_msg = 'p_cag_rent_statement_rec: OPEN revenue CURSOR error'
        GOTO PROC_END
    end
select @cur_revenue_source_open = 1


fetch cur_revenue_source into @revenue_source, @complex_id, @complex_name
while(@@fetch_status = 0 ) 
    begin
        if  @revenue_source <> 'P' /* Exclude Fixed Revenue from Billing vs Collections Rec data */
            begin

				declare cur_liability_category cursor static for                               
				SELECT DISTINCT liability_category_id, billing_group, collect_group
				FROM liability_category
				WHERE  billing_group = 'Y' or collect_group = 'Y'
    
                open cur_liability_category
                if @@error != 0
                    begin
                        select @error = 500050
                        select @err_msg = 'p_cag_rent_statement_rec: OPEN category CURSOR error'
                        GOTO PROC_END
                    end
                select @cur_liability_category_open = 1
            
                fetch cur_liability_category into @liability_category_id, @billing_group, @collect_group
                while (@@fetch_status = 0)
                    begin 
                           if @billing_group = 'Y'
                                select @liability_group = 'B'                                            
                            if @collect_group = 'Y'
                                select @liability_group = 'C'
                            
                             --exec p_cag_rent_statement_rec_data  @cinema_agreement_id, @revenue_source ,@complex_id, @statement_period, @statement_period, @liability_category_id, @amount_this_month output
                             exec p_cag_rent_statement_rec_data  @cinema_agreement_id, @revenue_source ,@complex_id, @report_max_period, @report_max_period, @liability_category_id, @amount_this_month output
                             /*exec p_cag_rent_statement_rec_data  @cinema_agreement_id, @revenue_source ,@complex_id, '2004-06-25', '2004-06-25', @liability_category_id, @amount_this_month output*/
                             exec p_cag_rent_statement_rec_data  @cinema_agreement_id, @revenue_source ,@complex_id, @period_1_month_prior, @period_1_month_prior, @liability_category_id, @amount_1_month_prior output
                             exec p_cag_rent_statement_rec_data  @cinema_agreement_id, @revenue_source ,@complex_id, @period_2_month_prior, @period_2_month_prior, @liability_category_id, @amount_2_month_prior output                                                                   
                             exec p_cag_rent_statement_rec_data  @cinema_agreement_id, @revenue_source ,@complex_id, @period_3_month_prior, @period_3_month_prior, @liability_category_id, @amount_3_month_prior output
                             exec p_cag_rent_statement_rec_data  @cinema_agreement_id, @revenue_source ,@complex_id, @period_4_month_prior, @period_4_month_prior, @liability_category_id, @amount_4_month_prior output
                             exec p_cag_rent_statement_rec_data  @cinema_agreement_id, @revenue_source ,@complex_id, @period_5_month_prior, @period_5_month_prior, @liability_category_id, @amount_5_month_prior output
                             exec p_cag_rent_statement_rec_data  @cinema_agreement_id, @revenue_source ,@complex_id, '1999-01-01', @period_prior, @liability_category_id, @amount_prior output
                                                    
                             INSERT INTO #result_set (cinema_agreement_id, complex_id, complex_name, revenue_source, liability_group,
                                                      liability_category_id, period_prior, amount_prior, period_5_month_prior, amount_5_month_prior,
                                                      period_4_month_prior, amount_4_month_prior, period_3_month_prior, amount_3_month_prior,
                                                      period_2_month_prior, amount_2_month_prior, period_1_month_prior, amount_1_month_prior,
                                                      statement_period, amount_current_period, agreement_desc, real_statement_period, abn_no)
                             VALUES        (@cinema_agreement_id, @complex_id, @complex_name, @revenue_source, @liability_group,
                                                      @liability_category_id, @period_prior, isnull(@amount_prior, 0), @period_5_month_prior, isnull(@amount_5_month_prior,0),
                                                      @period_4_month_prior, isnull(@amount_4_month_prior,0), @period_3_month_prior, isnull(@amount_3_month_prior,0),
                                                      @period_2_month_prior, isnull(@amount_2_month_prior, 0), @period_1_month_prior, isnull(@amount_1_month_prior,0),
                                                      @report_max_period , isnull(@amount_this_month, 0), @agreement_desc, @statement_period, @abn_no)      
                                                      /*@statement_period, isnull(@amount_this_month, 0), @agreement_desc, @statement_period)*/
                                                      /*'2004-06-25', isnull(@amount_this_month, 0), @agreement_desc, @statement_period)     */
                                          
                              if @@error != 0
                                    begin
                                        select @error = 500050
                                        select @err_msg = 'p_cag_rent_statement_rec: INSERT INTO #result_set error'
                                        GOTO PROC_END
                                    end
                                               
                            fetch cur_liability_category into @liability_category_id, @billing_group, @collect_group
                 end
                                             
            
            
        if @cur_liability_category_open = 1
            begin
               deallocate cur_liability_category
               select @cur_liability_category_open = 0
            end
            
    end /* END  for Exclude Fixed Revenue from Billing vs Collections Rec data */
    
    fetch cur_revenue_source into @revenue_source, @complex_id, @complex_name
end    

select * from #result_set

PROC_END:
if @cur_revenue_source_open > 0 
    begin
        close cur_revenue_source 
        deallocate cur_revenue_source 
    end
if @cur_liability_category_open > 0
    begin
        close cur_liability_category
        deallocate cur_liability_category
    end

if @error >= 50000
    begin
       raiserror (@err_msg, 16, 1)        
       return -1
    end
        
return 0
GO
