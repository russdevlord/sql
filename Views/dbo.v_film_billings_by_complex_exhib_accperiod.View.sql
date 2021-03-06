/****** Object:  View [dbo].[v_film_billings_by_complex_exhib_accperiod]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_film_billings_by_complex_exhib_accperiod]
GO
/****** Object:  View [dbo].[v_film_billings_by_complex_exhib_accperiod]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_film_billings_by_complex_exhib_accperiod]
AS
  select br.country_code 'country_code',
         cpx.complex_id 'complex_id',
         cpx.complex_name 'complex_name',
         ex.exhibitor_id 'exhibitor_id',
         ex.exhibitor_name 'exhibitor_name',
         x.finyear_end 'finyear', 
         x.benchmark_end 'accounting_period',
         sum((cs.charge_rate * (1 - fc.commission)) * (convert(numeric(6,4),x.no_days)/7.0)) 'film_bill_raw_nett',
         sum((cs.cinema_rate * (1 - fc.commission)) * (convert(numeric(6,4),x.no_days)/7.0)) 'film_bill_wtd_nett',
         sum(cs.charge_rate * (convert(numeric(6,4),x.no_days)/7.0)) 'film_bill_raw_gross',
         sum(cs.cinema_rate * (convert(numeric(6,4),x.no_days)/7.0)) 'film_bill_wtd_gross'
    from campaign_spot cs,
         complex cpx,
         branch br,
         film_campaign fc,
         exhibitor ex,
         film_screening_date_xref x
   where ex.exhibitor_id = cpx.exhibitor_id and
         cs.billing_date = x.screening_date and
         cs.complex_id = cpx.complex_id and
         br.branch_code = fc.branch_code and
         cs.campaign_no = fc.campaign_no and
         cs.spot_status <> 'P' and
         cs.spot_type not in ('M','D','V')
group by br.country_code,
         cpx.complex_id,
         cpx.complex_name,
         ex.exhibitor_id,
         ex.exhibitor_name,
         x.finyear_end,
         x.benchmark_end
GO
