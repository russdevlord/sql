/****** Object:  View [dbo].[v_film_billings_by_exhib_accperiod]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_film_billings_by_exhib_accperiod]
GO
/****** Object:  View [dbo].[v_film_billings_by_exhib_accperiod]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_film_billings_by_exhib_accperiod]
AS

    SELECT  country_code,
            exhibitor_id,
            exhibitor_name,
            finyear,
            accounting_period,
            sum(film_bill_raw_nett) as film_bill_raw_nett,
            sum(film_bill_wtd_nett) as film_bill_wtd_nett,
            sum(film_bill_raw_gross) as film_bill_raw_gross,
            sum(film_bill_wtd_gross) as film_bill_wtd_gross
     FROM   v_film_billings_by_complex_exhib_accperiod
GROUP BY    country_code,
            exhibitor_id,
            exhibitor_name,
            finyear,
            accounting_period
GO
