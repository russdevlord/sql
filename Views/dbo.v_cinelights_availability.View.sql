/****** Object:  View [dbo].[v_cinelights_availability]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinelights_availability]
GO
/****** Object:  View [dbo].[v_cinelights_availability]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinelights_availability]
AS


select  screening_week as screening_date,
        cinelight_id as cinelight_id,
        0 as available_bookings,
        cinelight_campaign_no as booked_cinelight_campaign_no
from    cinelight_billings
where   billing_status <> 'D'
and     billing_status <> 'P'



















GO
