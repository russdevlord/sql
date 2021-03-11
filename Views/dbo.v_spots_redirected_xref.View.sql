USE [production]
GO
/****** Object:  View [dbo].[v_spots_redirected_xref]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  VIEW [dbo].[v_spots_redirected_xref]
AS

select      spotb.billing_date,
            spotb.charge_rate,
            spotb.cinema_rate,
            spota.screening_date,
            spota.spot_id,
            spota.package_id,
            spota.campaign_no,
            spota.complex_id,
			spota.spot_type,
			spotb.spot_status,
            spotb.spot_type as orig_spot_type,
			spota.spot_redirect as spot_redirect,
			spota.dandc as dandc
from        campaign_spot spota,
            campaign_spot spotb,
			campaign_spot_redirect_xref spotxref
where       spotb.spot_id = spotxref.original_spot_id
and			spotxref.redirect_spot_id = spota.spot_id
and         spotb.spot_redirect is not null
and         spotb.spot_status <> 'P'
union 
select      billing_date,
            charge_rate, cinema_rate,
            screening_date,
            spot_id,
            package_id,
            campaign_no,
            complex_id,
			spot_type,
			spot_status,
            spot_type,
			spot_redirect,
			dandc
from        campaign_spot
where       spot_redirect is null
and         spot_status <> 'P'
and         spot_type <> 'V'
and         spot_type <> 'M'
GO
