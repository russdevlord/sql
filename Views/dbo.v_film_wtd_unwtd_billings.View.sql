/****** Object:  View [dbo].[v_film_wtd_unwtd_billings]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_film_wtd_unwtd_billings]
GO
/****** Object:  View [dbo].[v_film_wtd_unwtd_billings]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_film_wtd_unwtd_billings]
AS


  select cpx.complex_id 'complex_id',
         cpx.exhibitor_id 'exhibitor_id',
         ex.exhibitor_name 'exhibitor_name',
         cpx.complex_name 'complex_name',
         fsd.billing_period 'accounting_period',
         sum(cs.charge_rate - (cs.charge_rate * fc.commission) ) 'film_unwtd_nett_bill',
         convert(money,sum(((cs.charge_rate * cs.cinema_weighting)/cs.spot_weighting) * (1 - fc.commission))) 'film_wtd_nett_billings'
   from campaign_spot cs,
         film_screening_dates fsd,
         complex cpx,
         film_campaign fc,
         exhibitor ex
   where ex.exhibitor_id = cpx.exhibitor_id and
         cs.billing_date = fsd.screening_date and
         cs.complex_id = cpx.complex_id and
         cs.campaign_no = fc.campaign_no and
         cs.spot_weighting <> 0 and
        cs.spot_status <> 'P'     
group by cpx.exhibitor_id,
         cpx.complex_id,
         cpx.complex_name,
         fsd.billing_period,
		ex.exhibitor_name
GO
