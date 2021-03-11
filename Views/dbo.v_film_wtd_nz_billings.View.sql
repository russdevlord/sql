USE [production]
GO
/****** Object:  View [dbo].[v_film_wtd_nz_billings]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  VIEW [dbo].[v_film_wtd_nz_billings]
AS

  select fc.business_unit_id 'business_unit_id',
         cpx.complex_id 'complex_id',
         cpx.complex_name 'complex_name',
         fsd.billing_period 'accounting_period',
         convert(money,sum(((cs.charge_rate * cs.cinema_weighting)/cs.spot_weighting) * (1 - fc.commission))) 'film_wtd_nett_billings'
    from campaign_spot cs,
         film_campaign fc,
         branch br,
         film_screening_dates fsd,
         complex cpx
   where cs.billing_date = fsd.screening_date
     and cs.campaign_no = fc.campaign_no
     and fc.branch_code = br.branch_code
     and br.country_code = 'Z'
     and cs.tran_id is not null
     and cs.spot_weighting <> 0
     and cs.complex_id = cpx.complex_id
group by fc.business_unit_id,
         cpx.complex_id,
         cpx.complex_name,
         fsd.billing_period
GO
