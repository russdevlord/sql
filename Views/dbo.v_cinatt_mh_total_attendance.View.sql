/****** Object:  View [dbo].[v_cinatt_mh_total_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_mh_total_attendance]
GO
/****** Object:  View [dbo].[v_cinatt_mh_total_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_mh_total_attendance]
AS

    -- actual matched attendance
    select  vs.campaign_no,
            'A' as country_code,
            vs.screening_date,
            vs.complex_id,
            vs.movie_id,
            vs.spot_count,
            vc.attendance_per_print,
            vs.spot_count * vc.attendance_per_print 'total_attendance',
            'A' as actual_estimate
     from  v_cinatt_mh_matched_spots vs,
           v_cinatt_mh_matched_attendance vc
    where vs.screening_date = vc.screening_date
    and   vs.complex_id = vc.complex_id
    and   vs.movie_id = vc.movie_id
UNION      
    -- avg movie attendance
    select  vs.campaign_no,
            'A' as country_code,
            vs.screening_date,
            vs.complex_id,
            vs.movie_id,
            vs.spot_count,
            vc.avg_movie_attendance,
            vs.spot_count * vc.avg_movie_attendance 'total_attendance',
            'M' as actual_estimate
     from  v_cinatt_mh_avg_movie_spots vs,
           v_cinatt_mh_avg_movie vc
    where vs.screening_date = vc.screening_date
    and   vs.regional_indicator = vc.regional_indicator
    and   vs.movie_id = vc.movie_id
UNION
    -- avg region attendance
    select  vs.campaign_no,
            'A' as country_code,
            vs.screening_date,
            vs.complex_id,
            vs.movie_id,
            vs.spot_count,
            vc.avg_region_attendance,
            vs.spot_count * vc.avg_region_attendance 'total_attendance',
            'R' as actual_estimate
     from  v_cinatt_mh_avg_region_spots vs,
           v_cinatt_mh_avg_region vc
    where vs.screening_date = vc.screening_date
    and   vs.regional_indicator = vc.regional_indicator
GO
