/****** Object:  View [dbo].[v_cinelight_spots_non_proposed]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinelight_spots_non_proposed]
GO
/****** Object:  View [dbo].[v_cinelight_spots_non_proposed]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinelight_spots_non_proposed]
AS

SELECT
	t.spot_id,
	t.campaign_no,
	t.package_id,
	t.cinelight_id,
	c.complex_id,
	t.screening_date,
	t.billing_date,
	t.spot_status,
	t.spot_type,
	t.tran_id,
	t.rate,
	t.charge_rate,
	t.makegood_rate,
	t.cinema_rate,
	t.billing_period,
	t.spot_weighting,
	t.cinema_weighting,
	t.dandc,
	t.timestamp
 FROM dbo.cinelight_spot t,
	  dbo.cinelight c
 WHERE c.cinelight_id = t.cinelight_id and
	spot_status != 'P'
GO
