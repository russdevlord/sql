/****** Object:  StoredProcedure [dbo].[p_cag_analysis_recon]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_analysis_recon]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_analysis_recon]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_analysis_recon]  @cinema_agreement_id  int,
                                  @accounting_period    datetime, 
                                  @mode int as                              

/* Proc name:   p_cag_analysis_recon
 * Author:      Victoria Tyshchenko 
 * Date:        17/02/2004
 * Description: Cinema Agreement Analysis Window, Reconciliation tab
 *   mode: 0 - details by <complex - revenue source>
 *         1 - details by <revenue source>
 *
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date:   May 24 2004 12:43:34  $ 
 * $Author:   vtyshchenko  $ 
 * $Revision:   1.2  $
 * $Workfile:   cag_analysis_recon.sql  $
 *
*/ 

declare @proc_name varchar(30)
select  @proc_name = 'p_cag_analysis_recon'
/*exec    p_audit_proc @proc_name,'start' */

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
        @agreement_desc             varchar(50)
        




        

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
    agreement_desc               varchar(50)   )

select @error = 0 

select @agreement_desc= agreement_desc from cinema_agreement
where cinema_Agreement_id = @cinema_Agreement_id 

exec p_get_prior_accounting_period  @accounting_period, 1, @period_1_month_prior output
exec p_get_prior_accounting_period  @period_1_month_prior, 1, @period_2_month_prior output
exec p_get_prior_accounting_period  @period_2_month_prior, 1, @period_3_month_prior output
exec p_get_prior_accounting_period  @period_3_month_prior, 1, @period_4_month_prior output
exec p_get_prior_accounting_period  @period_4_month_prior, 1, @period_5_month_prior output
exec p_get_prior_accounting_period  @period_5_month_prior, 1, @period_prior output

if @mode = 0 
     declare cur_revenue_source cursor static for                               
     SELECT DISTINCT	cinema_agreement_revenue.revenue_source, 0, ''
      FROM cinema_agreement_revenue
      WHERE  cinema_agreement_id = @cinema_agreement_id
         
if @mode = 1 
     declare cur_revenue_source cursor static for                               
     SELECT DISTINCT cinema_agreement_revenue.revenue_source, complex.complex_id, complex_name
      FROM cinema_agreement_revenue, complex
      WHERE  cinema_agreement_revenue.complex_id = complex.complex_id and             
             cinema_agreement_id = @cinema_agreement_id

open cur_revenue_source
select @error = @@error
  if @error != 0
      goto rollbackerror
select @cur_revenue_source_open = 1


fetch cur_revenue_source into @revenue_source, @complex_id, @complex_name
while(@@fetch_status = 0 ) 
    begin
        if  @revenue_source <> 'P' /* Exclude Fixed Revenue from Billing vs Collections Rec data */
            begin

				declare cur_liability_category cursor static for                               
				SELECT DISTINCT liability_category.liability_category_id, billing_group, collect_group
				FROM liability_category, liability_category_rent_xref lcrx
				WHERE  lcrx.rent_mode in ('B','C','I','S')
				and		lcrx.liability_category_id = liability_category.liability_category_id

                open cur_liability_category
                select @error = @@error
                if @error != 0
                    goto rollbackerror
                select @cur_liability_category_open = 1
            
                fetch cur_liability_category into @liability_category_id, @billing_group, @collect_group
                while (@@fetch_status = 0)
                    begin 
                        if @liability_category_id <> 5 /* Exclude 'Production' from  Billing vs Collections Rec data */
                            begin
                                if @billing_group = 'Y'
                                    select @liability_group = 'B'                                            
                                if @collect_group = 'Y'
                                    select @liability_group = 'C'
                            
                                exec p_cag_rent_statement_rec_data  @cinema_agreement_id, @revenue_source ,@complex_id, @accounting_period, @accounting_period, @liability_category_id, @amount_this_month output
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
                                                          statement_period, amount_current_period, agreement_desc)
                                            VALUES        (@cinema_agreement_id, @complex_id, @complex_name, @revenue_source, @liability_group,
                                                          @liability_category_id, @period_prior, isnull(@amount_prior, 0), @period_5_month_prior, isnull(@amount_5_month_prior,0),
                                                          @period_4_month_prior, isnull(@amount_4_month_prior,0), @period_3_month_prior, isnull(@amount_3_month_prior,0),
                                                          @period_2_month_prior, isnull(@amount_2_month_prior, 0), @period_1_month_prior, isnull(@amount_1_month_prior,0),
                                                          @accounting_period, isnull(@amount_this_month, 0), @agreement_desc)      
                                          
                              select @error = @@error
                              if @error != 0
                                   goto rollbackerror 
                            end /* END for Exclude 'Production' from  Billing vs Collections Rec data */
                                               
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

deallocate cur_revenue_source 
/*exec p_audit_proc @proc_name,'end'*/
return 

rollbackerror:
error:
deallocate cur_revenue_source 
deallocate cur_liability_category

if @error >= 50000 
    begin
        select @err_msg = @proc_name + ': ' + @err_msg
        raiserror (@err_msg, 16, 1)
    end
--else
--       raiserror ( @error, 16, 1)

return
GO
