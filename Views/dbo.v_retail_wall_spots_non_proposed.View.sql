/****** Object:  View [dbo].[v_retail_wall_spots_non_proposed]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_retail_wall_spots_non_proposed]
GO
/****** Object:  View [dbo].[v_retail_wall_spots_non_proposed]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_retail_wall_spots_non_proposed]
AS

SELECT
	t.spot_id,
	t.campaign_no,
	t.inclusion_id,
	t.complex_id,
	t.op_screening_date,
	t.op_billing_date,
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
 FROM dbo.inclusion_spot t 
 WHERE 	spot_status != 'P' 
 and  inclusion_id in (select inclusion_id from inclusion where inclusion_type = 18)
GO
