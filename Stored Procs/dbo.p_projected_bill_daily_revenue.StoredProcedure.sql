/****** Object:  StoredProcedure [dbo].[p_projected_bill_daily_revenue]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_projected_bill_daily_revenue]
GO
/****** Object:  StoredProcedure [dbo].[p_projected_bill_daily_revenue]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_projected_bill_daily_revenue]  @report_date	datetime,
                                            @accounting_period   datetime,
                                            @country_code	char(1),
                                            @product_type  tinyint
with recompile as

/*
 * Declare Valiables
 */

declare @error							integer,
        @sqlstatus					integer,
        @temp_month             tinyint,
        @month_num               tinyint,
        @month_loop             tinyint,
        @month_str              char(2),
        @branch_code					char(2),
        @prior_yr_report_date   datetime,
        @prior_yr_accounting_period datetime,
        @prev_bill                  money,
        @future_dummy_period        datetime,
        @current_manual_bill                money,
        @current_budget_bill                money,
        @ytd_manual_bill                money,
        @ytd_budget_bill                money,
        @nett_billings				money,
        @temp_billings              money,
        @current_mnth_billings      money,
        @current_ytd_billings       money,
        @prior_yr_mnth_billings          money,
        @prior_yr_ytd_billings          money,
        @period_csr_open			tinyint,
        @branch_csr_open			tinyint,
        @update_date_ftr            datetime,
        @sql_string                 varchar(255),
        @finyear                    datetime





select @temp_month = datepart(mm,@accounting_period)
if @temp_month = 1 select @month_num = 7
if @temp_month = 2 select @month_num = 8
if @temp_month = 3 select @month_num = 9
if @temp_month = 4 select @month_num = 10
if @temp_month = 5 select @month_num = 11
if @temp_month = 6 select @month_num = 12
if @temp_month = 7 select @month_num = 1
if @temp_month = 8 select @month_num = 2
if @temp_month = 9 select @month_num = 3
if @temp_month = 10 select @month_num = 4
if @temp_month = 11 select @month_num = 5
if @temp_month = 12 select @month_num = 6

create table #temp(month_num tinyint null, value money null)

create table #results(
            branch_code             char(2) null,
            current_mnth_billings   money null, 
            current_ytd_billings    money null, 
            prior_yr_mnth_billings  money null,
            prior_yr_ytd_billings   money null,
            current_manual_bill     money null,
            current_budget_bill     money null,
            ytd_manual_bill         money null,
            ytd_budget_bill         money null)

select  @finyear = finyear_end
from    accounting_period
where   end_date = @accounting_period

/* get report date for prior year - may be NULL if there is no data at all - handle in later selects */
select  @prior_yr_report_date = max(report_date)
from    projected_billings
where   report_date <= dateadd(yy,-1,@report_date)

if datediff(dd,@prior_yr_report_date, dateadd(yy,-1,@report_date)) > 4 /* more than a weekend */
    select @prior_yr_report_date = null

select  @prior_yr_accounting_period = max(end_date)
from    accounting_period
where   end_date <= dateadd(yy,-1,dateadd(dd,-1,dateadd(mm,1,convert(datetime,convert(char(4),datepart(yy,@accounting_period)) + '-' + convert(varchar(2),datepart(mm,@accounting_period)) + '-1'))))


select  @current_manual_bill = 0,
        @current_budget_bill = 0,
        @ytd_manual_bill = 0,
        @ytd_budget_bill = 0

/* get current monthly manual billings and budget figures */
select  @current_manual_bill = isnull(film_manual_billings_total,0),
        @current_budget_bill = isnull(film_billings_budget,0)
from    monthly_billings
where   billing_period = @accounting_period
and     country_code = @country_code

/* get YTD monthly manual billings and budget figures */
select  @ytd_manual_bill = sum(isnull(film_manual_billings_total,0)),
        @ytd_budget_bill = sum(isnull(film_billings_budget,0))
from    monthly_billings
where   billing_period in (select end_date from accounting_period where end_date <= @accounting_period and finyear_end = @finyear)
and     country_code = @country_code

 declare branch_csr cursor static for
  select branch_code
    from branch
   where country_code = @country_code
order by branch_code ASC
     for read only
/*
 * Loop Branches
 */

open branch_csr
select @branch_csr_open = 1
fetch branch_csr into @branch_code
while (@@fetch_status = 0)
begin
    delete #temp
    /* get current billing figures */
    select  @month_loop = 1
    while @month_loop <= @month_num
    begin
        if @month_loop < 10
            select @month_str = stuff(str(@month_loop,2),1,1,'0')
        else
            select @month_str = str(@month_loop,2)

        select @sql_string = 'insert into #temp select ' + str(@month_loop,2) + ', billings_month_' + @month_str + 
                ' from    projected_billings where report_date = '' + convert(varchar(20),@report_date) + 
                '' and     branch_code = '' + @branch_code +
                '' and     product_type = ' + str(@product_type,1) + 
                ' and     finyear_end = '' + convert(varchar(20),@finyear) + '''

        execute (@sql_string)
        select @month_loop = @month_loop + 1
    end /*while*/
    
    select  @current_ytd_billings = sum(value) from #temp
    select  @current_mnth_billings = value from #temp where month_num = @month_num

    /* get prior year billing figures */
    select  @prior_yr_ytd_billings = 0,
            @prior_yr_mnth_billings = 0
    if @prior_yr_report_date is not null
    begin
        delete #temp
        select  @month_loop = 1
        while @month_loop <= @month_num
        begin
            if @month_loop < 10
                select @month_str = stuff(str(@month_loop,2),1,1,'0')        
            else
                select @month_str = str(@month_loop,2)
        
            select @sql_string = 'insert into #temp select ' + str(@month_loop,2) + ', billings_month_' + @month_str + 
                    ' from    projected_billings where report_date = '' + convert(varchar(20),@prior_yr_report_date) + 
                    '' and     branch_code = '' + @branch_code +
                    '' and     product_type = ' + str(@product_type,1) + 
                    ' and     finyear_end = '' + convert(varchar(20),@finyear) + '''
        
            execute (@sql_string)
            select @month_loop = @month_loop + 1
        end /*while*/
    
        select  @prior_yr_ytd_billings = sum(value) from #temp
        select  @prior_yr_mnth_billings = value from #temp where month_num = @month_num
    end /*if*/

    /* select results for PB DW */
    insert into #results
    select  @branch_code,
            @current_mnth_billings, 
            @current_ytd_billings, 
            @prior_yr_mnth_billings,
            @prior_yr_ytd_billings,
            @current_manual_bill,
            @current_budget_bill,
            @ytd_manual_bill,
            @ytd_budget_bill

    fetch branch_csr into @branch_code

end /*while branch*/
close branch_csr
deallocate branch_csr

drop table #temp

select * from #results

return 0
GO
