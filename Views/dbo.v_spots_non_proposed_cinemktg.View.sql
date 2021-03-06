/****** Object:  View [dbo].[v_spots_non_proposed_cinemktg]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_spots_non_proposed_cinemktg]
GO
/****** Object:  View [dbo].[v_spots_non_proposed_cinemktg]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_spots_non_proposed_cinemktg]
AS

SELECT
	t.spot_id,
	t.campaign_no,
	t.inclusion_id,
	t.complex_id,
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
	t.spot_redirect,
	t.timestamp
 FROM dbo.inclusion_spot t,
 inclusion inc
   WHERE spot_status != 'P'
   and inc.inclusion_id = t.inclusion_id
   and inc.inclusion_type = 5
GO
