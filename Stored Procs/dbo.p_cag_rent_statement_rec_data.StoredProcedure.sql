/****** Object:  StoredProcedure [dbo].[p_cag_rent_statement_rec_data]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_rent_statement_rec_data]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_rent_statement_rec_data]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* ALL YEAR TO DATE AMOUNTS calculated from 01-01-2004 */   

create PROC [dbo].[p_cag_rent_statement_rec_data]  @cinema_agreement_id  int,
                                             @revenue_source char(1),
                                             @complex_id    int,
                                             @period_from datetime, 
                                             @period_to datetime, 
                                             @liability_category_id tinyint, 
                                             @amount money output  as                              



declare @error     				int,
        @err_msg                varchar(150)

select @error = 0 

if @period_from is null and @period_to is null
   begin
      select @error = 500050
      select @err_msg = 'p_cag_rent_statement_rec_data: PERIOD from-to is not specified'
      GOTO PROC_END
   end

if @period_from is null
    select @period_from = @period_to

if @period_to is null
    select @period_to = @period_from

SELECT @amount = sum(cinema_agreement_revenue.cinema_amount)
 FROM cinema_agreement_revenue,
      liability_type, liability_category
WHERE cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id and
      liability_type.liability_category_id = liability_category.liability_category_id and  
      cinema_agreement_revenue.cancelled = 'N' and
      liability_category.liability_category_id = @liability_category_id and
      cinema_agreement_revenue.origin_period >= @period_from and
      cinema_agreement_revenue.origin_period <= @period_to and
      cinema_agreement_revenue.origin_period >= '2004-01-01' and
      ( cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id ) And  
      ( cinema_agreement_revenue.revenue_source = @revenue_source or @revenue_source = '' ) and
      ( cinema_agreement_revenue.complex_id = @complex_id or @complex_id = 0 )

if @@error != 0
   begin
      select @error = 500050
      select @err_msg = 'p_cag_rent_statement_rec_data: SELECT error'
      GOTO PROC_END
   end

PROC_END:
if @error >= 50000
    begin
       raiserror (@err_msg, 16, 1)        
       return -1
    end
        
return 0
GO
