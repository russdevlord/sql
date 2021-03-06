/****** Object:  StoredProcedure [dbo].[sp_reachfrequency_population_addUpdate]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[sp_reachfrequency_population_addUpdate]
GO
/****** Object:  StoredProcedure [dbo].[sp_reachfrequency_population_addUpdate]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_reachfrequency_population_addUpdate]  
  @type int,  
  @country_code         char(1),                            
     @start_date        datetime,                    
     @end_date         datetime,                    
  @reporting_demographics_id          int,                    
  @film_market_no          int,                      
  @population         int,                    
  @loyalty_transaction         int,                    
  @frequency         numeric(6,2),                    
  @reach_threshold         numeric(30,6)                     
AS  
BEGIN  
 begin try  
  if @type = 1 --Insert new population data  
  begin  
   IF OBJECT_ID('tempdb..#SelectedScreeningDates') IS NOT NULL  
   DROP TABLE #SelectedScreeningDates  
  
   ;with cte1 as  
   (select screening_date from film_screening_dates where screening_date between @start_date and @end_date)   
   select * into #SelectedScreeningDates from cte1  
  
   ;with cte2 as  
   (  
    select @country_code as country_code,  
    @reporting_demographics_id as cinetam_reporting_demographics_id,  
    screening_date,  
    @film_market_no as film_market_no,  
    @population as populations,  
    0 as mm_adjustment, --while inserting we default it to 0   
    @loyalty_transaction as loyalty_transactions,  
    @frequency as frequency,  
    @reach_threshold as reach_threshold from #SelectedScreeningDates  
   )  
   insert into cinetam_reachfreq_population select * from cte2  
  end  
  else --update existing population data  
  begin     
   update cinetam_reachfreq_population
   SET [population] = @population,  
   loyalty_transactions = @loyalty_transaction,  
   frequency = @frequency,  
   reach_threshold = @reach_threshold  
      where country_code = @country_code   
   and cinetam_reporting_demographics_id = @reporting_demographics_id   
   and film_market_no = @film_market_no  
   and (screening_date between @start_date and @end_date)         
  end  
   END TRY  
 BEGIN CATCH     
  
  DECLARE @ErMessage NVARCHAR(2048),@ErSeverity INT,@ErState INT   
  SELECT @ErMessage = ERROR_MESSAGE(),@ErSeverity = ERROR_SEVERITY(),@ErState = ERROR_STATE()  
  RAISERROR (@ErMessage,@ErSeverity,@ErState )  
  
 END CATCH   
END
GO
