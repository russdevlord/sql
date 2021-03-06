/****** Object:  StoredProcedure [dbo].[p_fin_year_sales_period_sel]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_fin_year_sales_period_sel]
GO
/****** Object:  StoredProcedure [dbo].[p_fin_year_sales_period_sel]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_fin_year_sales_period_sel]
as

/*
 * Declare Procedure Variables
 */

declare @error          		integer,
        @rowcount					integer,
        @finyear_end				datetime

/*
 * Create Temporary Tables
 */

create table #finyear
(
	finyear_end			datetime				null,
	finyear_start		datetime				null,
   finyear_desc		varchar(30)			null,
	sales_period_min	datetime				null,
	sales_period_max	datetime				null
)



/*
 * Initialise Temporary Table
 */

insert into #finyear
   ( finyear_end, finyear_start, finyear_desc )
  select distinct financial_year.finyear_end,   
         financial_year.finyear_start,   
         financial_year.finyear_desc  
    from sales_period,   
         financial_year  
   where sales_period.finyear_end = financial_year.finyear_end

/*
 * Declare Cursors
 */

declare finyear_csr cursor static for
 select finyear_end
   from #finyear
order by finyear_end
for read only

open finyear_csr
fetch finyear_csr into @finyear_end
while (@@fetch_status = 0)
begin
   update #finyear
      set sales_period_min = ( select min(sales_period.sales_period_end)
                                from sales_period
                               where sales_period.finyear_end = @finyear_end and
                                     sales_period.status = 'O' ),

          sales_period_max = ( select max(sales_period.sales_period_end)
                                from sales_period
                               where sales_period.finyear_end = @finyear_end and
                                     sales_period.status = 'O' )

    where #finyear.finyear_end = @finyear_end

   fetch finyear_csr into @finyear_end
end
close finyear_csr
deallocate finyear_csr

/*
 * Return
 */

select finyear_end,
       finyear_start,
       finyear_desc,
       sales_period_min,
       sales_period_max
  from #finyear
 where sales_period_min is not null and
       sales_period_max is not null

return 0
GO
