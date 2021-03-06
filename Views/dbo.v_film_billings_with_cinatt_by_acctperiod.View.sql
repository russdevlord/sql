/****** Object:  View [dbo].[v_film_billings_with_cinatt_by_acctperiod]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_film_billings_with_cinatt_by_acctperiod]
GO
/****** Object:  View [dbo].[v_film_billings_with_cinatt_by_acctperiod]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_film_billings_with_cinatt_by_acctperiod]
AS
SELECT
	t.country_code,
    crc.regional_indicator,
	t.complex_id,
	t.complex_name,
	t.exhibitor_id,
	t.exhibitor_name,
	t.finyear,
	t.accounting_period,
    t.film_bill_raw_nett, 
    t.film_bill_raw_gross,
    t.film_bill_wtd_nett,
    t.film_bill_wtd_gross,
    (select sum(isnull(matched_attendance,0)) from v_dw_fact_complex_cinatt_by_acctperiod
     where  accounting_period = t.accounting_period
     and    complex_id = t.complex_id) as matched_attendance,
    (select sum(isnull(raw_attendance,0)) from v_dw_fact_complex_cinatt_by_acctperiod
     where  accounting_period = t.accounting_period
     and    complex_id = t.complex_id) as raw_attendance,
    (select sum(isnull(attendance,0)) from v_cinatt_excluded_by_complex_by_accperiod
     where  accounting_period = t.accounting_period
     and    complex_id = t.complex_id) as excluded_attendance
 FROM   v_film_billings_by_complex_exhib_accperiod t,
        complex cpx,
        complex_region_class crc
where   t.complex_id = cpx.complex_id
and     cpx.complex_region_class = crc.complex_region_class
GO
