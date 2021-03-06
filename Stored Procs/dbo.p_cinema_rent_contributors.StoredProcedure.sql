/****** Object:  StoredProcedure [dbo].[p_cinema_rent_contributors]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinema_rent_contributors]
GO
/****** Object:  StoredProcedure [dbo].[p_cinema_rent_contributors]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cinema_rent_contributors]  @cinema_agreement_id		integer,
                                        @accounting_period          datetime
as

declare @error     			integer,
        @start_date         datetime,
        @end_date           datetime

select  @end_date = @accounting_period

select  @start_date = min(end_date)
from    accounting_period
where   finyear_end = (select finyear_end from accounting_period where end_date = @accounting_period)



select  cpx.complex_name                 'complex_name',
        @start_date                      'start_date',
        @end_date                        'end_date',
        sum(crx.slide_amount)            'slide_amount',
        sum(crx.film_amount)             'film_amount' ,
        sum(crx.slide_billing_amount)    'slide_billing_amount',
        sum(crx.film_billing_amount)     'film_billing_amount',
        sum(crx.agreement_amount)        'agreement_amount',
        sum(crx.payment_accrual)         'payment_accrual'
from    cinema_rent_xref crx, cinema_rent cr, complex cpx
where   crx.cinema_agreement_id = @cinema_agreement_id
and     cr.accounting_period >= @start_date
and     cr.accounting_period <= @end_date
and     crx.cinema_rent_id = cr.cinema_rent_id
and     cr.complex_id = cpx.complex_id
group by cpx.complex_name

return 0
GO
