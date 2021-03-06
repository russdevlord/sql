/****** Object:  View [dbo].[v_spots_allocated_att]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_spots_allocated_att]
GO
/****** Object:  View [dbo].[v_spots_allocated_att]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_spots_allocated_att]
AS
SELECT     spot_id, campaign_no, package_id, complex_id, screening_date, billing_date, spot_status, spot_type, tran_id, rate, charge_rate, makegood_rate, 
                      cinema_rate, spot_instruction, schedule_auto_create, billing_period, spot_weighting, cinema_weighting, certificate_score, dandc, onscreen, 
                      spot_redirect, [timestamp]
FROM         dbo.campaign_spot t
WHERE     (spot_status = 'X') AND (screening_date >= '3-jan-2002')
GO
