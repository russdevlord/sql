/****** Object:  View [dbo].[v_spots_non_proposed_cinelight]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_spots_non_proposed_cinelight]
GO
/****** Object:  View [dbo].[v_spots_non_proposed_cinelight]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_spots_non_proposed_cinelight]
AS

SELECT
	t.spot_id,
	t.campaign_no,
	t.package_id,
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
	t.spot_instruction,
	t.billing_period,
	t.spot_weighting,
	t.cinema_weighting,
	t.certificate_score,
	t.dandc,
	t.spot_redirect,
	t.timestamp
 FROM dbo.cinelight_spot t,
       dbo.cinelight c
  WHERE spot_status != 'P'
  and c.cinelight_id = t.cinelight_id
GO
