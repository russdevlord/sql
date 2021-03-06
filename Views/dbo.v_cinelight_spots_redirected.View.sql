/****** Object:  View [dbo].[v_cinelight_spots_redirected]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinelight_spots_redirected]
GO
/****** Object:  View [dbo].[v_cinelight_spots_redirected]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  VIEW [dbo].[v_cinelight_spots_redirected]
AS

select      spotb.billing_date,
            spotb.charge_rate,spotb.cinema_rate,
            spota.screening_date,
            spota.spot_id,
            spota.package_id,
            spota.campaign_no,
            cinelight.complex_id,
			spota.spot_type,
			spotb.spot_status,
            spotb.spot_type as orig_spot_type
from        cinelight_spot spota,
            cinelight_spot spotb,
			cinelight
where       dbo.f_cl_spot_redirect(spotb.spot_id) = spota.spot_id
and         spotb.spot_redirect is not null
and         spotb.spot_status <> 'P'
and 		spota.cinelight_id = cinelight.cinelight_id
union 
select      billing_date,
            charge_rate,cinema_rate,
            screening_date,
            spot_id,
            package_id,
            campaign_no,
            complex_id,
			spot_type,
			spot_status,
            spot_type
from        cinelight_spot,
			cinelight
where     cinelight_spot.cinelight_id = cinelight.cinelight_id
and			spot_redirect is null
and         spot_status <> 'P'
and         spot_type <> 'V'
and         spot_type <> 'M'
GO
