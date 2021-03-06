/****** Object:  StoredProcedure [dbo].[p_get_lead_trail_bill_dates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_get_lead_trail_bill_dates]
GO
/****** Object:  StoredProcedure [dbo].[p_get_lead_trail_bill_dates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * dbo.p_get_lead_trail_bill_dates
 * ---------------------------------------
 * Encapsulates functionality for getting leading and trailing billing dates  
 * derived from passed arguments: arg_billing_period_from and arg_billing_period_to
 *
 * <arg_billing_period_from and arg_billing_period_to> ARE END_DATEs of the accounting_period table
 * the arguments will be translated into the relative BENCHMARK_END dates to find leading/trailing billing dates
 * 
 * Author:      Victori Tyshchenko
 * Date:        08/03/2004
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date$ 
 * $Author$ 
 * $Revision$
 * $Workfile$
 *
*/ 

 

CREATE PROC [dbo].[p_get_lead_trail_bill_dates]  @arg_billing_period_from    datetime,
                                         @arg_billing_period_to      datetime,
                                         @leading_bill_date          datetime OUTPUT,
                                         @trailing_bill_date         datetime OUTPUT,
                                         @leading_bill_portion       tinyint  OUTPUT,
                                         @trailing_bill_portion      tinyint  OUTPUT
as

set nocount on 
/*
 * Declare Variables
 */

declare     @error_num               int,
            @row_count               int,
            @cut_off_date            datetime,
            @prev_bill_date          datetime

/* in case if benchmark end date  <> end of accounting period date */
select @arg_billing_period_from = benchmark_end
from accounting_period
where end_date = @arg_billing_period_from

select @arg_billing_period_to = benchmark_end
from accounting_period
where end_date = @arg_billing_period_to

/* use local cut_off date as this may be modified and original billing_period may be required */
select @cut_off_date = @arg_billing_period_to

/* Get prev billing date */
select @prev_bill_date = max(benchmark_end)
  from accounting_period
 where benchmark_end < @arg_billing_period_from
if @prev_bill_date is null return -1

/* Adjust cutoff dates for june/december period */
if datepart(mm,@cut_off_date) in (6,12) /* june, december */
begin
    select @cut_off_date = DATEADD(dd,-1,DATEADD(mm,1,DATEADD(day,-(DATEPART(dd,@cut_off_date) - 1), CONVERT(VARCHAR,@cut_off_date,101))))
end

if datepart(mm,@prev_bill_date) in (6,12) /* june, december */
begin
    select @prev_bill_date = DATEADD(dd,-1,DATEADD(mm,1,DATEADD(day,-(DATEPART(dd,@prev_bill_date) - 1), CONVERT(VARCHAR,@prev_bill_date,101))))
end
if @cut_off_date is null return -1
if @prev_bill_date is null return -1


/* Get leading billing date (FILM) */
select @leading_bill_date = max(billing_date)
  from campaign_spot
 where billing_date <= @prev_bill_date
if @leading_bill_date is null return -1

/* Get trailing billing date (FILM) */
select @trailing_bill_date = max(billing_date)
  from campaign_spot
 where billing_date <= @cut_off_date
if @trailing_bill_date is null return -1

/* get leading and trailing billing portions */
/* leading portion is 7 minus datediff inclusive, essentially 6 - sybase datediff */
select @leading_bill_portion = (6 - datediff(day, @leading_bill_date, @prev_bill_date))
if (@leading_bill_portion > 7) or (@leading_bill_portion < 1) select @leading_bill_portion = 0
/* trailing portion is datediff inclusive, which is sybase datediff + 1 */
select @trailing_bill_portion = (datediff(day, @trailing_bill_date, @cut_off_date) + 1)
if (@trailing_bill_portion > 7) or (@trailing_bill_portion < 1) select @trailing_bill_portion = 0

return 0
GO
