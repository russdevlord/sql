USE [production]
GO
/****** Object:  View [dbo].[v_spots_with_attendance_figures]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_spots_with_attendance_figures]
AS

SELECT      spot.spot_id,
	        spot.campaign_no,
	        spot.package_id,
	        spot.complex_id,
	        spot.screening_date,
	        spot.billing_date,
	        spot.spot_status,
	        spot.spot_type,
	        spot.tran_id,
	        spot.rate,
	        spot.charge_rate,
	        spot.makegood_rate,
	        spot.cinema_rate,
	        spot.spot_instruction,
	        spot.schedule_auto_create,
	        spot.billing_period,
	        spot.spot_weighting,
	        spot.cinema_weighting,
	        spot.certificate_score,
	        spot.dandc,
	        spot.onscreen,
	        spot.spot_redirect,
            sum(cinatt.attendance_per_print) as 'attendance'
    FROM    campaign_spot spot,  
            campaign_package cpack,
            certificate_item ci,
            certificate_group cg,
            movie_history mh,
            complex cplx,
            v_cinatt_mh_total_attendance cinatt
    where   spot.complex_id = cplx.complex_id 
    and     spot.package_id = cpack.package_id 
    and     spot.spot_status ='X'
    and     spot.spot_id = ci.spot_reference
    and     ci.certificate_group = cg.certificate_group_id
    and     cg.certificate_group_id = mh.certificate_group
    and     spot.screening_date = cinatt.screening_date
    and     spot.complex_id = cinatt.complex_id
    and     mh.movie_id = cinatt.movie_id
    group by spot.spot_id,
	        spot.campaign_no,
	        spot.package_id,
	        spot.complex_id,
	        spot.screening_date,
	        spot.billing_date,
	        spot.spot_status,
	        spot.spot_type,
	        spot.tran_id,
	        spot.rate,
	        spot.charge_rate,
	        spot.makegood_rate,
	        spot.cinema_rate,
	        spot.spot_instruction,
	        spot.schedule_auto_create,
	        spot.billing_period,
	        spot.spot_weighting,
	        spot.cinema_weighting,
	        spot.certificate_score,
	        spot.dandc,
	        spot.onscreen,
	        spot.spot_redirect
GO
