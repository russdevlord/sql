/****** Object:  View [dbo].[v_outpost_panel_detail]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_outpost_panel_detail]
GO
/****** Object:  View [dbo].[v_outpost_panel_detail]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create View  [dbo].[v_outpost_panel_detail] As
Select a.outpost_panel_id As Panel_ID, a.outpost_panel_desc As Panel_Name, b.outpost_venue_name As Venue_name, 
b.state_code As State, d.outpost_venue_status_desc AS Venue_status, a.installation_date, c.outpost_booking_group_desc As Panel_Type, e.outpost_panel_status_desc AS Panel_status
FROM outpost_panel a
JOIN outpost_venue b
on a.outpost_venue_id = b.outpost_venue_id
JOIN Outpost_booking_Group c
ON a.outpost_booking_group_id = c.outpost_booking_group_id
JOIN outpost_venue_status d
ON b.outpost_venue_status_code = d.outpost_venue_status_code
JOIN outpost_panel_status e
ON a.outpost_panel_status =  e.outpost_panel_status
GO
