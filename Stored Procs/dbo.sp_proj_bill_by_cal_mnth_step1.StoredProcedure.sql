/****** Object:  StoredProcedure [dbo].[sp_proj_bill_by_cal_mnth_step1]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[sp_proj_bill_by_cal_mnth_step1]
GO
/****** Object:  StoredProcedure [dbo].[sp_proj_bill_by_cal_mnth_step1]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[sp_proj_bill_by_cal_mnth_step1] as
    begin
     begin transaction
       declare @billing_date    datetime, 
               @acc_period         datetime,
               @next_acc_period    datetime,
               @branch_code     char(1),
               @calendar_month_start    datetime,
               @calendar_month_end      datetime,
               @acc_prd_week_days       tinyint,
               @cal_prd_week_days       tinyint,
               @billing_week_end        datetime,
               @temp                    datetime,
               @il_temp                 int,
               @billing_amount          money,
               @acc_period_total        numeric(30,18),
               @finyear_end             datetime,
               @acc_period_days         int,
               @msg                     varchar(150),
               @business_unit_id        int, 
               @media_product_id        int,
               @agency_deal             char(1)
               
        delete from AAA_prd_cal_by_bill_week where billing_date >= '20-jun-2004'
        delete from AAA_prd_acc_by_bill_week where billing_date >= '20-jun-2004'
                             
        declare cur_spot_bill_week cursor for 
            select screening_date
            from film_screening_dates
            where screening_date >= '20-jun-2004'
            --and screening_date >= '2000-12-28'
        
          
       open cur_spot_bill_week
       fetch cur_spot_bill_week into @billing_date
       
       /* BILLING DATEs LOOP */
       while (@@fetch_status = 0)
       begin

        /* strange SELECT but does the job and retrieves all possible combinations of branch - media_product - business_unit*/
        declare cur_branc_business_media cursor for 
            select distinct branch_code, business_unit_id, media_product_id, 'Y'
            from branch, media_product, business_unit 
            where ( media_product_desc like '%Film%' or  media_product_desc like '%DMG%' ) and campaign_format in ('S', 'D')
            union select distinct branch_code, business_unit_id,  media_product_id, 'N'
            from branch, media_product, business_unit 
            where ( media_product_desc like '%Film%' or  media_product_desc like '%DMG%' ) and campaign_format in ('S', 'D')
            order by branch_code, business_unit_id, media_product_id        

           open cur_branc_business_media
           fetch cur_branc_business_media into @branch_code, @business_unit_id, @media_product_id, @agency_deal
          /* BRANCH, BUSINESS_UNIT, MEDIA_PRODUCT, AGENCY_DEAL LOOP*/
           while (@@fetch_status = 0)
             begin
--                select @msg = '(:Step1 bill_date ' + convert(varchar, @billing_date, 105) + ', branch ' + @branch_code + ', bus_unit ' + convert(varchar, @business_unit_id) + ', media ' + convert(varchar, @media_product_id)
--                PRINT @msg

                /* billing amount for week */
                exec p_projected_bill_calc_week @billing_date, @branch_code,  @business_unit_id, @media_product_id, @agency_deal, @billing_amount OUTPUT       
            
--                select @msg = '(::: Step 1 billing_amount ' + convert(varchar, @billing_amount) 
--                PRINT @msg
            
                /* CURRENT ACCOUNT. PRD */
                /*SP finds acc period(s) the week belongs to*/
                exec p_get_bill_date_acc_prd @billing_date, @acc_period OUTPUT, @acc_prd_week_days OUTPUT,
                                         @next_acc_period OUTPUT, @il_temp OUTPUT

--                select @msg = '(::: Step 1 p_get_bill_date_acc_prd ' + convert(varchar, @billing_date, 105) 
--                PRINT @msg
                 
                insert into AAA_prd_acc_by_bill_week
                  ( billing_date, acc_period, branch_code, business_unit_id, media_product_id, agency_deal,
                    billing_amount, acc_prd_week_days)
                 values
                  ( @billing_date, @acc_period, @branch_code, @business_unit_id, @media_product_id, @agency_deal,
                    @billing_amount * (convert(numeric, @acc_prd_week_days)/ 7 ), @acc_prd_week_days)
                
--                  select @msg = '(::: Step 1 insert 1 ' 
--                    PRINT @msg
                
-- 				if @billing_date = '19-aug-2004' 
-- 					BEGIN
-- 						DECLARE @TT VARCHAR(255)
-- 						SELECT @TT = '1 period:' + convert(varchar,@acc_period ) + ' ' + convert(varchar, @acc_prd_week_days) + '   ' + convert(varchar,@billing_amount * (convert(numeric, @acc_prd_week_days)/ 7 ) ) + 
-- 									'    2 period:' + convert(varchar,@next_acc_period ) + ' ' + convert(varchar, @il_temp)+ '  ' + convert(varchar,@billing_amount * (1 - convert(numeric, @acc_prd_week_days) / 7 ) ) 
-- 											
-- 						Print @tt
-- 					END

               if @il_temp <> 0 
                begin
--					print 'here'
                    insert into AAA_prd_acc_by_bill_week
                  ( billing_date, acc_period, branch_code, business_unit_id, media_product_id, agency_deal,
                        billing_amount, acc_prd_week_days)
                    values
                  ( @billing_date, @next_acc_period, @branch_code, @business_unit_id, @media_product_id, @agency_deal,
                       @billing_amount * (1 - convert(numeric, @acc_prd_week_days) / 7 ), @il_temp)
                 end                    
                    
            
                /* CALENDAR MONTHS */   
                select @billing_week_end = dateadd(day, 6, @billing_date)
                if datepart(month, @billing_date)  = datepart(month, @billing_week_end) 
                    begin
                        exec p_calendar_month_end @billing_week_end, @calendar_month_end OUTPUT
                        
                        select @finyear_end = max(finyear_end)
                        from accounting_period
                        where benchmark_end <= @calendar_month_end
                    
                        insert into AAA_prd_cal_by_bill_week
                        ( billing_date, calendar_period, branch_code, business_unit_id, media_product_id, agency_deal, cal_prd_week_days, finyear_end  )
                        values      
                        ( @billing_date, @calendar_month_end, @branch_code, @business_unit_id, @media_product_id, @agency_deal, 7, @finyear_end  )
                    
                     end 
                 else
                    begin
                        exec p_calendar_month_end @billing_date, @calendar_month_end OUTPUT
                        select @cal_prd_week_days = datediff(day, @billing_date, @calendar_month_end) + 1
                    
                        select @finyear_end = max(finyear_end)
                        from accounting_period
                        where benchmark_end <= @calendar_month_end
                    
                        insert into AAA_prd_cal_by_bill_week
                        ( billing_date, calendar_period, branch_code, business_unit_id, media_product_id, agency_deal, cal_prd_week_days, finyear_end  )
                        values      
                        ( @billing_date, @calendar_month_end, @branch_code, @business_unit_id, @media_product_id, @agency_deal, @cal_prd_week_days, @finyear_end  )
                    
                        select @cal_prd_week_days = datediff(day, @calendar_month_end, @billing_week_end)
                        exec p_calendar_month_end @billing_week_end, @calendar_month_end OUTPUT
                    
                        select @finyear_end = max(finyear_end)
                        from accounting_period
                        where benchmark_end <= @calendar_month_end
                    
                        insert into AAA_prd_cal_by_bill_week
                        ( billing_date, calendar_period, branch_code, business_unit_id, media_product_id, agency_deal, cal_prd_week_days, finyear_end  )
                        values      
                        ( @billing_date, @calendar_month_end, @branch_code, @business_unit_id, @media_product_id, @agency_deal, @cal_prd_week_days, @finyear_end  )
                    end
                    
                   fetch cur_branc_business_media into @branch_code, @business_unit_id, @media_product_id, @agency_deal
                 end    
               
                  close cur_branc_business_media 
				 deallocate cur_branc_business_media              
                  
                  fetch cur_spot_bill_week into @billing_date
              end
          
     close cur_spot_bill_week
		deallocate cur_spot_bill_week
     
     
     
     
     /* Populate Percentage of the period total */
     declare cur_percentage cursor for 
        select acc_period, billing_date, branch_code, business_unit_id, media_product_id, agency_deal, billing_amount
        from AAA_prd_acc_by_bill_week 
        for update of percetage_from_period_total
     
     open cur_percentage
     fetch cur_percentage into @acc_period, @billing_date, @branch_code, @business_unit_id, @media_product_id, @agency_deal, @billing_amount
     select @temp = @acc_period
     
     update  AAA_prd_acc_by_bill_week
     set percetage_from_period_total = 0
     
     while(@@fetch_status = 0)
        begin
            --if @temp <> @acc_period
                select @acc_period_total = isnull(sum(billing_amount), 0),
                       @acc_period_days  = sum(acc_prd_week_days)
                from   AAA_prd_acc_by_bill_week
                where  acc_period = @acc_period
                and    branch_code = @branch_code
                and    business_unit_id = @business_unit_id
                and    media_product_id = @media_product_id
                and    agency_deal = @agency_deal

            if @acc_period_total  <> 0
				begin
-- 				select @msg = 'Before update:' + convert(varchar, convert(numeric(30,18), @billing_amount) / @acc_period_total )
-- 				print @msg

                UPDATE AAA_prd_acc_by_bill_week
                SET percetage_from_period_total =  convert(numeric(30,18), billing_amount) / convert(numeric(30,18), @acc_period_total )
                WHERE CURRENT OF cur_percentage
				end
             else
                UPDATE AAA_prd_acc_by_bill_week
                SET percetage_from_period_total =  convert(numeric, acc_prd_week_days ) / convert(numeric, @acc_period_days)
                WHERE CURRENT OF cur_percentage

             fetch cur_percentage into @acc_period, @billing_date, @branch_code, @business_unit_id, @media_product_id, @agency_deal, @billing_amount
        end
       
       close cur_percentage 
	   deallocate cur_percentage

    commit transaction       
 end
GO
