/****** Object:  StoredProcedure [dbo].[sp_proj_bill_by_cal_mnth_step2]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[sp_proj_bill_by_cal_mnth_step2]
GO
/****** Object:  StoredProcedure [dbo].[sp_proj_bill_by_cal_mnth_step2]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create procedure [dbo].[sp_proj_bill_by_cal_mnth_step2] as
    begin
    begin transaction
       declare @billing_date       datetime, 
               @acc_period         datetime,
               @calendar_period    datetime,
               @billing_amount     money,
               @report_date        datetime,
               @branch_code        char(1),
               @finyear_end        datetime,
               @business_unit_id        int, 
               @media_product_id        int,
               @agency_deal             char(1),               
               @billings_month_01  money, @new_bill_month_01  money,
               @billings_month_02  money, @new_bill_month_02  money,
               @billings_month_03  money, @new_bill_month_03  money,
               @billings_month_04  money, @new_bill_month_04  money,
               @billings_month_05  money, @new_bill_month_05  money,
               @billings_month_06  money, @new_bill_month_06  money,
               @billings_month_07  money, @new_bill_month_07  money,
               @billings_month_08  money, @new_bill_month_08  money,
               @billings_month_09  money, @new_bill_month_09  money,
               @billings_month_10  money, @new_bill_month_10  money,
               @billings_month_11  money, @new_bill_month_11  money,
               @billings_month_12  money, @new_bill_month_12  money,
               @billings_future    money,
               @money_temp         numeric(30,18),
               @cal_prd_week_days  int,
               @cnt                int,
               @li_temp            int,
               @msg                varchar(150)
               
       delete from projected_billings_calendar
        where datediff(day, report_date, getdate()) = 0
                      
        declare cur_proj_bill cursor for 
        select  report_date, branch_code, business_unit_id, media_product_id, agency_deal, finyear_end,
                billings_month_01, billings_month_02, billings_month_03,
                billings_month_04, billings_month_05, billings_month_06,
                billings_month_07, billings_month_08, billings_month_09,
                billings_month_10, billings_month_11, billings_month_12, billings_future
        from projected_billings
        where datediff(day, report_date, getdate()) = 0 
--        and branch_code = 'N'
--        and media_product_id = 1 
--        and business_unit_id = 2 
--        and agency_deal = 'Y' 
--       and finyear_end = '30-jun-2005'
        
      
        open cur_proj_bill    
        fetch cur_proj_bill  into  @report_date, @branch_code, @business_unit_id, @media_product_id, @agency_deal, @finyear_end,
                @billings_month_01, @billings_month_02, @billings_month_03,
                @billings_month_04, @billings_month_05, @billings_month_06,
                @billings_month_07, @billings_month_08, @billings_month_09,
                @billings_month_10, @billings_month_11, @billings_month_12, @billings_future
       
        
        while(@@fetch_status = 0)        
            begin
            
                select @msg = '(::: Step 2 Proj Bill Calendar Month, report_date ' + convert(varchar, @report_date, 105) 
                PRINT @msg
            
                update AAA_prd_acc_by_bill_week
                       set billing_amount = 0
                      
                update AAA_prd_acc_by_bill_week
                       set billing_amount = @billings_month_01 * percetage_from_period_total
                from accounting_period
                where branch_code = @branch_code
                and accounting_period.benchmark_end = acc_period 
                and accounting_period.finyear_end = @finyear_end
                and business_unit_id = @business_unit_id
                and media_product_id = @media_product_id
                and agency_deal = @agency_deal
                and period_no = 7
                
                update AAA_prd_acc_by_bill_week
                       set billing_amount = @billings_month_02 * percetage_from_period_total
                from accounting_period
                where branch_code = @branch_code
                and accounting_period.benchmark_end = acc_period 
                and accounting_period.finyear_end = @finyear_end
                and business_unit_id = @business_unit_id
                and media_product_id = @media_product_id
                and agency_deal = @agency_deal
                and period_no = 8
                
                update AAA_prd_acc_by_bill_week
                       set billing_amount = @billings_month_03 * percetage_from_period_total
                from accounting_period
                where branch_code = @branch_code
                and accounting_period.benchmark_end = acc_period 
                and accounting_period.finyear_end = @finyear_end
                and business_unit_id = @business_unit_id
                and media_product_id = @media_product_id
                and agency_deal = @agency_deal
                and period_no = 9
                
                update AAA_prd_acc_by_bill_week
                       set billing_amount = @billings_month_04 * percetage_from_period_total
                from accounting_period
                where branch_code = @branch_code
                and accounting_period.benchmark_end = acc_period 
                and accounting_period.finyear_end = @finyear_end
                and business_unit_id = @business_unit_id
                and media_product_id = @media_product_id
                and agency_deal = @agency_deal
                and period_no = 10
                
                update AAA_prd_acc_by_bill_week
                       set billing_amount = @billings_month_05 * percetage_from_period_total
                from accounting_period
                where branch_code = @branch_code
                and accounting_period.benchmark_end = acc_period 
                and accounting_period.finyear_end = @finyear_end
                and business_unit_id = @business_unit_id
                and media_product_id = @media_product_id
                and agency_deal = @agency_deal
                and period_no = 11
                
                update AAA_prd_acc_by_bill_week
                       set billing_amount = @billings_month_06 * percetage_from_period_total
                from accounting_period
                where branch_code = @branch_code
                and accounting_period.benchmark_end = acc_period 
                and accounting_period.finyear_end = @finyear_end
                and business_unit_id = @business_unit_id
                and media_product_id = @media_product_id
                and agency_deal = @agency_deal
                and period_no = 12
                
                update AAA_prd_acc_by_bill_week
                       set billing_amount = @billings_month_07 * percetage_from_period_total
                from accounting_period
                where branch_code = @branch_code
                and accounting_period.benchmark_end = acc_period 
                and accounting_period.finyear_end = @finyear_end
                and business_unit_id = @business_unit_id
                and media_product_id = @media_product_id
                and agency_deal = @agency_deal
                and period_no = 1
                
                update AAA_prd_acc_by_bill_week
                       set billing_amount = @billings_month_08 * percetage_from_period_total
                from accounting_period
                where branch_code = @branch_code
                and accounting_period.benchmark_end = acc_period 
                and accounting_period.finyear_end = @finyear_end
                and business_unit_id = @business_unit_id
                and media_product_id = @media_product_id
                and agency_deal = @agency_deal
                and period_no = 2
                
                update AAA_prd_acc_by_bill_week
                       set billing_amount = @billings_month_09 * percetage_from_period_total
                from accounting_period
                where branch_code = @branch_code
                and accounting_period.benchmark_end = acc_period 
                and accounting_period.finyear_end = @finyear_end
                and business_unit_id = @business_unit_id
                and media_product_id = @media_product_id
                and agency_deal = @agency_deal
                and period_no = 3
                
                update AAA_prd_acc_by_bill_week
                       set billing_amount = @billings_month_10 * percetage_from_period_total
                from accounting_period
                where branch_code = @branch_code
                and accounting_period.benchmark_end = acc_period 
                and accounting_period.finyear_end = @finyear_end
                and business_unit_id = @business_unit_id
                and media_product_id = @media_product_id
                and agency_deal = @agency_deal
                and period_no = 4
                
                update AAA_prd_acc_by_bill_week
                       set billing_amount = @billings_month_11 * percetage_from_period_total
                from accounting_period
                where branch_code = @branch_code
                and accounting_period.benchmark_end = acc_period 
                and accounting_period.finyear_end = @finyear_end
                and business_unit_id = @business_unit_id
                and media_product_id = @media_product_id
                and agency_deal = @agency_deal
                and period_no = 5
                
                update AAA_prd_acc_by_bill_week
                       set billing_amount = @billings_month_12 * percetage_from_period_total
                from accounting_period
                where branch_code = @branch_code
                and accounting_period.benchmark_end = acc_period 
                and accounting_period.finyear_end = @finyear_end
                and business_unit_id = @business_unit_id
                and media_product_id = @media_product_id
                and agency_deal = @agency_deal
                and period_no = 6
                
                
		        declare cur_new_proj_bill cursor for 
		        select  billing_date, cal_prd_week_days, calendar_period
		        from AAA_prd_cal_by_bill_week
		        where finyear_end = @finyear_end
		        and branch_code = @branch_code
		        and business_unit_id = @business_unit_id
		        and media_product_id = @media_product_id
		        and agency_deal = @agency_deal

				open cur_new_proj_bill    
                fetch cur_new_proj_bill  into  @billing_date, @cal_prd_week_days, @calendar_period
        
                UPDATE AAA_prd_cal_by_bill_week
                SET billing_amount = 0
                        
                while(@@fetch_status = 0)        
                   begin
                    
                        select @money_temp =  convert(numeric(30,18), sum( billing_amount) )
                        from AAA_prd_acc_by_bill_week
                        where billing_date = @billing_date
                        and branch_code = @branch_code
                        and business_unit_id = @business_unit_id
                        and media_product_id = @media_product_id
                        and agency_deal = @agency_deal
                        group by billing_date, branch_code, business_unit_id, media_product_id, agency_deal
                        
                        --  30-Jun / 1-Jul
                        if  datepart(month, @billing_date) = 6 and datepart(month, dateadd(day, 6, @billing_date))= 7 
                            UPDATE AAA_prd_cal_by_bill_week
                            SET billing_amount = @money_temp 
                            WHERE CURRENT OF cur_new_proj_bill
                         else 
                            UPDATE AAA_prd_cal_by_bill_week
                            SET billing_amount = @money_temp * ( convert(numeric(30, 18 ), cal_prd_week_days ) / 7 )
                            WHERE CURRENT OF cur_new_proj_bill
                            
                        fetch cur_new_proj_bill  into  @billing_date, @cal_prd_week_days, @calendar_period
                    end
                    
                 close cur_new_proj_bill
				deallocate cur_new_proj_bill
   
                select @new_bill_month_01 = isnull(sum(billing_amount), 0)
                from AAA_prd_cal_by_bill_week
                where  datepart(month, calendar_period) = 7
                and finyear_end = @finyear_end
                                
                select @new_bill_month_02 = isnull(sum(billing_amount), 0)
                from AAA_prd_cal_by_bill_week
                where  datepart(month, calendar_period) = 8
                and finyear_end = @finyear_end
                
                select @new_bill_month_03 = isnull(sum(billing_amount), 0)
                from AAA_prd_cal_by_bill_week
                where  datepart(month, calendar_period) = 9
                and finyear_end = @finyear_end
                
                select @new_bill_month_04 = isnull(sum(billing_amount), 0)
                from AAA_prd_cal_by_bill_week
                where  datepart(month, calendar_period) = 10
                and finyear_end = @finyear_end
                
                select @new_bill_month_05 = isnull(sum(billing_amount), 0)
                from AAA_prd_cal_by_bill_week
                where  datepart(month, calendar_period) = 11
                and finyear_end = @finyear_end
                
                select @new_bill_month_06 = isnull(sum(billing_amount), 0)
                from AAA_prd_cal_by_bill_week
                where  datepart(month, calendar_period) = 12
                and finyear_end = @finyear_end
                
                select @new_bill_month_07 = isnull(sum(billing_amount), 0)
                from AAA_prd_cal_by_bill_week
                where  datepart(month, calendar_period) = 1
                and finyear_end = @finyear_end
                
                select @new_bill_month_08 = isnull(sum(billing_amount), 0)
                from AAA_prd_cal_by_bill_week
                where  datepart(month, calendar_period) = 2
                and finyear_end = @finyear_end
                
                select @new_bill_month_09 = isnull(sum(billing_amount), 0)
                from AAA_prd_cal_by_bill_week
                where  datepart(month, calendar_period) = 3
                and finyear_end = @finyear_end
                
                select @new_bill_month_10 = isnull(sum(billing_amount), 0)
                from AAA_prd_cal_by_bill_week
                where  datepart(month, calendar_period) = 4
                and finyear_end = @finyear_end
                
                select @new_bill_month_11 = isnull(sum(billing_amount), 0)
                from AAA_prd_cal_by_bill_week
                where  datepart(month, calendar_period) = 5
                and finyear_end = @finyear_end
                
                select @new_bill_month_12 = isnull(sum(billing_amount), 0)
                from AAA_prd_cal_by_bill_week
                where  datepart(month, calendar_period) = 6
                and finyear_end = @finyear_end
                
                
                insert into projected_billings_calendar 
                ( report_date,  business_unit_id, media_product_id, agency_deal, branch_code, finyear_end, 
                  billings_month_01,  billings_month_02, billings_month_03,
                  billings_month_04,  billings_month_05, billings_month_06,
                  billings_month_07,  billings_month_08, billings_month_09,
                  billings_month_10,  billings_month_11, billings_month_12, billings_future)
                  values ( @report_date, @business_unit_id, @media_product_id, @agency_deal, @branch_code, @finyear_end,
                        @new_bill_month_01, @new_bill_month_02, @new_bill_month_03,
                        @new_bill_month_04, @new_bill_month_05, @new_bill_month_06,
                        @new_bill_month_07, @new_bill_month_08, @new_bill_month_09,
                        @new_bill_month_10, @new_bill_month_11, @new_bill_month_12, @billings_future )
   
            fetch cur_proj_bill  into  @report_date, @branch_code, @business_unit_id, @media_product_id, @agency_deal, @finyear_end,
                @billings_month_01, @billings_month_02, @billings_month_03,
                @billings_month_04, @billings_month_05, @billings_month_06,
                @billings_month_07, @billings_month_08, @billings_month_09,
                @billings_month_10, @billings_month_11, @billings_month_12, @billings_future
                
        end
        
        close cur_proj_bill
		deallocate cur_proj_bill
        
        commit transaction
    end
GO
