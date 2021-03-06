/****** Object:  StoredProcedure [dbo].[p_cag_rent_statement_b_c_dtls]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_rent_statement_b_c_dtls]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_rent_statement_b_c_dtls]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure retrieves billing or/and collection details related to @cinema_agreement_id:@statement_no */

create PROC [dbo].[p_cag_rent_statement_b_c_dtls]  @cinema_agreement_id  int,
                                      @statement_no     int, 
                                      @arg_billing_group    char(1),
                                      @arg_collect_group    char(1),
                                      @mode             int as                              


declare @error     				int,
        @err_msg                varchar(150),
        @revenue_source         char(1),
        @cur_revenue_source_open        tinyint,
        @cur_liability_category_open    tinyint,
        @complex_id                     int,
        @complex_name                   char(50),
        @amount                         money,
        @liability_category_id          tinyint,
        @cnt                            tinyint,
        @ret                            int,
        @billing_group                  char(1),
        @collect_group                  char(1),
        @statement_period               datetime,
        @agreement_desc                 varchar(50),
        @rent_mode                      char(1),
        @liability_type_id              tinyint,
        @percentage_entitlement         dec(6,4)
        




       
CREATE TABLE #result_set
(   cinema_agreement_id         int null,
    complex_id                  int null,
    complex_name                varchar(50) null, 
    revenue_source              char(1) null,
    liability_category_id       tinyint null,
    amount                      money    null,
    statement_period            datetime null,
    agreement_desc              varchar(50) null,
    liability_type_id           tinyint null,
    percentage_entitlement      dec(6,4) null)

select @error = 0 

select @statement_period = accounting_period from cinema_agreement_statement 
where cinema_Agreement_id = @cinema_Agreement_id and statement_no = @statement_no

select @agreement_desc= agreement_desc from cinema_agreement
where cinema_Agreement_id = @cinema_Agreement_id 


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
        select @err_msg = 'p_cag_rent_statement_b_c_dtls: OPEN revenue CURSOR error'
        GOTO PROC_END
    end
select @cur_revenue_source_open = 1


fetch cur_revenue_source into @revenue_source, @complex_id, @complex_name
while(@@fetch_status = 0 ) 
    begin
        if  @revenue_source <> 'P' 
            begin

				declare cur_liability_category cursor static for                               
			    SELECT DISTINCT liability_type.liability_category_id, liability_type_id, billing_group, collect_group
			    FROM liability_category, liability_type
			    WHERE  liability_category.liability_category_id = liability_type.liability_category_id and
			           billing_group = @arg_billing_group and collect_group = @arg_collect_group
 
                open cur_liability_category
                if @@error != 0
                    begin
                        select @error = 500050
                        select @err_msg = 'p_cag_rent_statement_b_c_dtls: OPEN category CURSOR error'
                        GOTO PROC_END
                    end
                select @cur_liability_category_open = 1
            
                fetch cur_liability_category into @liability_category_id, @liability_type_id, @billing_group, @collect_group
                while (@@fetch_status = 0)
                    begin 
                            
                                SELECT @amount = IsNull(sum(cinema_agreement_revenue.cinema_amount), 0),
                                       @percentage_entitlement = cinema_agreement_revenue.percentage_entitlement
                                FROM   cinema_agreement_revenue,
                                       liability_type, liability_category
                                WHERE  cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id and
                                       cinema_agreement_revenue.cancelled = 'N' and
                                       liability_category.liability_category_id = liability_type.liability_category_id and
                                       liability_type.liability_type_id = @liability_type_id and  
                                       cinema_agreement_revenue.accounting_period = @statement_period and
                                      ( cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id ) And  
                                      ( cinema_agreement_revenue.revenue_source = @revenue_source  ) and
                                      ( cinema_agreement_revenue.complex_id = @complex_id or @mode = 0 )
                                 group by  cinema_agreement_revenue.percentage_entitlement   

                            if @amount <> 0 
                                INSERT INTO #result_set ( cinema_agreement_id, complex_id, complex_name, revenue_source,
                                                          liability_category_id, amount, statement_period, agreement_desc, 
                                                          liability_type_id, percentage_entitlement)
                                VALUES ( @cinema_agreement_id, @complex_id, @complex_name, @revenue_source,
                                         @liability_category_id, @amount, @statement_period, @agreement_desc, 
                                         @liability_type_id, @percentage_entitlement)                                                          
                                         
                                 if @@error != 0
                                    begin
                                        select @error = 500050
                                        select @err_msg = 'p_cag_rent_statement_b_c_dtls: INSERT INTO #result_set error'
                                        GOTO PROC_END
                                    end
                                               
                            fetch cur_liability_category into @liability_category_id, @liability_type_id, @billing_group, @collect_group
                 end
                                             
            
            
        if @cur_liability_category_open = 1
            begin
               deallocate cur_liability_category
               select @cur_liability_category_open = 0
            end
            
    end 
    
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
