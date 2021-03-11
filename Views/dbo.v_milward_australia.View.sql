USE [production]
GO
/****** Object:  View [dbo].[v_milward_australia]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_milward_australia] 
AS
    select fm.film_market_no,
       fm.film_market_desc,
       fc.campaign_no,
       fc.product_desc,
       c.client_name,
       spot.screening_date,
  	   count(spot.spot_id) as no_spots
  from campaign_spot spot,
       film_campaign fc,
       client c,
       complex cplx,
       film_market fm
 where spot.campaign_no = fc.campaign_no and
       fc.client_id = c.client_id and
       (fc.business_unit_id = 2 or
       fc.campaign_no = 203851 or 
       fc.campaign_no = 203947) and
       fc.branch_code <> 'Z' and
       spot.spot_status <> 'P' and
       spot.screening_date is not null and
       spot.complex_id = cplx.complex_id and
       cplx.film_market_no = fm.film_market_no and
       fm.film_market_no in (1,4,6,10,12) and
       spot.screening_date >= '1-jan-2005'
group by fm.film_market_no,
         fm.film_market_desc,
         fc.campaign_no,
         fc.product_desc,
         c.client_name,
         spot.screening_date
GO
