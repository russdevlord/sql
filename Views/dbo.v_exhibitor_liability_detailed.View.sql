/****** Object:  View [dbo].[v_exhibitor_liability_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_exhibitor_liability_detailed]
GO
/****** Object:  View [dbo].[v_exhibitor_liability_detailed]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view [dbo].[v_exhibitor_liability_detailed]
as
select exhibitor_name, complex_name, liability_type_desc, release_period, original_liability, cancelled, complex.state_code, business_unit_desc, film_campaign.campaign_no, film_campaign.product_desc, sum(cinema_amount) as cin_amt 
from spot_liability,complex, liability_type, exhibitor, campaign_spot, film_campaign, business_unit
where  complex.complex_id = spot_liability.complex_id and release_period > '1-jul-2009' and complex.exhibitor_id = exhibitor.exhibitor_id 
and spot_liability.liability_type = liability_type.liability_type_id
and campaign_spot.campaign_no = film_campaign.campaign_no
and campaign_spot.spot_id = spot_liability.spot_id
and film_campaign.business_unit_id = business_unit.business_unit_id
group by exhibitor_name, complex_name, liability_type_desc, release_period, original_liability, cancelled, complex.state_code, business_unit_desc, film_campaign.campaign_no, film_campaign.product_desc
union all
select exhibitor_name, complex_name, liability_type_desc, release_period, original_liability, cancelled, complex.state_code, business_unit_desc, film_campaign.campaign_no, film_campaign.product_desc, sum(cinema_amount) as cin_amt 
from cinelight_spot_liability,complex, liability_type, exhibitor, cinelight_spot, film_campaign, business_unit
where  complex.complex_id = cinelight_spot_liability.complex_id and release_period > '1-jul-2009' and complex.exhibitor_id = exhibitor.exhibitor_id 
and cinelight_spot_liability.liability_type = liability_type.liability_type_id
and cinelight_spot.campaign_no = film_campaign.campaign_no
and cinelight_spot.spot_id = cinelight_spot_liability.spot_id
and film_campaign.business_unit_id = business_unit.business_unit_id
group by exhibitor_name, complex_name, liability_type_desc, release_period, original_liability, cancelled, complex.state_code, business_unit_desc, film_campaign.campaign_no, film_campaign.product_desc
GO
