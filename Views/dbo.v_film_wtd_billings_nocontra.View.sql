/****** Object:  View [dbo].[v_film_wtd_billings_nocontra]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_film_wtd_billings_nocontra]
GO
/****** Object:  View [dbo].[v_film_wtd_billings_nocontra]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  VIEW [dbo].[v_film_wtd_billings_nocontra]
AS

  select fc.business_unit_id 'business_unit_id',
         cp.media_product_id 'media_product_id',
         cpx.complex_id 'complex_id',
         cpx.complex_name 'complex_name',
         fsd.billing_period 'accounting_period',
         convert(money,sum(((cs.charge_rate * cs.cinema_weighting)/cs.spot_weighting) * (1 - fc.commission))) 'film_wtd_nett_billings'
    from campaign_spot cs,
         film_campaign fc,
         branch br,
         film_screening_dates fsd,
         complex cpx,
         campaign_package cp
   where cs.billing_date = fsd.screening_date
     and cs.campaign_no = fc.campaign_no
     and fc.branch_code = br.branch_code
     and cp.package_id = cs.package_id
     and br.country_code = 'A'
     and cs.tran_id is not null
     and cs.spot_weighting <> 0
     and cs.complex_id = cpx.complex_id
     and cp.package_id = cs.package_id
     and cs.spot_type != 'C'
group by fc.business_unit_id,
         cp.media_product_id,
         cpx.complex_id,
         cpx.complex_name,
         fsd.billing_period
union
  select fc.business_unit_id 'business_unit_id',
         3 'media_product_id',
         cpx.complex_id 'complex_id',
         cpx.complex_name 'complex_name',
         fsd.billing_period 'accounting_period',
         convert(money,sum(((cs.charge_rate * cs.cinema_weighting)/cs.spot_weighting) * (1 - fc.commission))) 'film_wtd_nett_billings'
    from cinelight_spot cs,
         cinelight c,
         film_campaign fc,
         branch br,
         film_screening_dates fsd,
         complex cpx
   where cs.billing_date = fsd.screening_date
     and cs.campaign_no = fc.campaign_no
     and fc.branch_code = br.branch_code
     and br.country_code = 'A'
     and cs.tran_id is not null
     and cs.spot_weighting <> 0
     and cs.cinelight_id = c.cinelight_id
     and c.complex_id = cpx.complex_id
     and cs.spot_type != 'C'
group by fc.business_unit_id,
         cpx.complex_id,
         cpx.complex_name,
         fsd.billing_period
union
  select fc.business_unit_id 'business_unit_id',
         6 'media_product_id',
         cpx.complex_id 'complex_id',
         cpx.complex_name 'complex_name',
         fsd.billing_period 'accounting_period',
         convert(money,sum(((cs.charge_rate * cs.cinema_weighting)/cs.spot_weighting) * (1 - fc.commission))) 'film_wtd_nett_billings'
    from inclusion_spot cs,
         film_campaign fc,
         branch br,
         film_screening_dates fsd,
         complex cpx
   where cs.billing_date = fsd.screening_date
     and cs.campaign_no = fc.campaign_no
     and fc.branch_code = br.branch_code
     and br.country_code = 'A'
     and cs.tran_id is not null
     and cs.spot_weighting <> 0
     and cs.inclusion_id in (select inclusion_id from inclusion where inclusion_type = 5)
     and cs.complex_id = cpx.complex_id
     and cs.spot_type != 'C'
group by fc.business_unit_id,
         cpx.complex_id,
         cpx.complex_name,
         fsd.billing_period
GO
