/****** Object:  StoredProcedure [dbo].[p_agreement_rent_pool_summary]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_agreement_rent_pool_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_agreement_rent_pool_summary]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_agreement_rent_pool_summary] @cinema_agreement_id		integer,
                                          @accounting_period        datetime

as

                             

 declare @error     						integer,
         @rowcount      		 		integer,
         @acct_period_start             datetime,
         @slide_collect_curr            money,
         @film_collect_curr             money,
         @slide_bill_curr               money,
         @film_bill_curr                money,
         @slide_margin_curr             money,
         @film_margin_curr              money,

         @slide_collect_ytd            money,
         @film_collect_ytd            money,
         @slide_bill_ytd               money,
         @film_bill_ytd                money,
         @slide_margin_ytd             money,
         @film_margin_ytd              money,

         @slide_collect_tot            money,
         @film_collect_tot             money,
         @slide_bill_tot               money,
         @film_bill_tot                money,
         @slide_margin_tot             money,
         @film_margin_tot             money


    SELECT  @acct_period_start = min(end_date)
    FROM    accounting_period
    WHERE   finyear_end = (select finyear_end from accounting_period where end_date = @accounting_period)

/*    IF @acct_period_start IS NULL THEN RETURN -1 */

    SELECT  @slide_collect_curr = sum(slide_total),
            @film_collect_curr  = sum(film_total),
            @slide_bill_curr    = sum(slide_billing_total),
            @film_bill_curr     = CASE when sum(isnull(nullif(film_billing_weighted, -1),0)) = 0 THEN sum(film_billing_total) else sum(film_billing_weighted) end,
            @slide_margin_curr  = sum(slide_margin_total),
            @film_margin_curr   = sum(film_margin_total)
    FROM    dbo.cinema_rent_pool
    WHERE   cinema_agreement_id = @cinema_agreement_id
    AND     accounting_period = @accounting_period

    SELECT  @slide_collect_ytd = sum(slide_total),
            @film_collect_ytd  = sum(film_total),
            @slide_bill_ytd    = sum(slide_billing_total),
            @film_bill_ytd     = CASE when sum(isnull(nullif(film_billing_weighted, -1),0)) = 0 THEN sum(film_billing_total) else sum(film_billing_weighted) end,
            @slide_margin_ytd  = sum(slide_margin_total),
            @film_margin_ytd   = sum(film_margin_total)
    FROM    dbo.cinema_rent_pool
    WHERE   cinema_agreement_id = @cinema_agreement_id
    AND     accounting_period <= @accounting_period
    AND     accounting_period >= @acct_period_start

    SELECT  @slide_collect_tot = sum(slide_total),
            @film_collect_tot  = sum(film_total),
            @slide_bill_tot    = sum(slide_billing_total),
            @film_bill_tot     = CASE when sum(isnull(nullif(film_billing_weighted, -1),0)) = 0 THEN sum(film_billing_total) else sum(film_billing_weighted) end,
            @slide_margin_tot  = sum(slide_margin_total),
            @film_margin_tot   = sum(film_margin_total)
    FROM    dbo.cinema_rent_pool
    WHERE   cinema_agreement_id = @cinema_agreement_id


    SELECT  @slide_collect_curr     'slide_collect_curr',
            @film_collect_curr      'film_collect_curr',
            @slide_bill_curr        'slide_bill_curr',
            @film_bill_curr         'film_bill_curr',
            @slide_margin_curr      'slide_margin_curr',
            @film_margin_curr       'film_margin_curr',
            @slide_collect_ytd      'slide_collect_ytd',
            @film_collect_ytd       'film_collect_ytd',
            @slide_bill_ytd         'slide_bill_ytd',
            @film_bill_ytd          'film_bill_ytd',
            @slide_margin_ytd       'slide_margin_ytd',
            @film_margin_ytd        'film_margin_ytd',
            @slide_collect_tot      'slide_collect_tot',
            @film_collect_tot       'film_collect_tot',
            @slide_bill_tot         'slide_bill_tot',
            @film_bill_tot          'film_bill_tot',
            @slide_margin_tot       'slide_margin_tot',
            @film_margin_tot        'film_margin_tot' 



return 0
GO
