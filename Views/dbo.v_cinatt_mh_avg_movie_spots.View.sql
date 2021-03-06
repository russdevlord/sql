/****** Object:  View [dbo].[v_cinatt_mh_avg_movie_spots]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_mh_avg_movie_spots]
GO
/****** Object:  View [dbo].[v_cinatt_mh_avg_movie_spots]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_mh_avg_movie_spots]
AS
select  spot.campaign_no 'campaign_no',
        spot.screening_date 'screening_date',
        spot.complex_id 'complex_id',
        crc.regional_indicator 'regional_indicator',
        mh.movie_id 'movie_id',
        count(distinct spot.spot_id) 'spot_count'
 from   v_spots_allocated_att spot,
        certificate_item ci,
        certificate_group cg,
        movie_history mh,
        complex,
        complex_region_class crc
where   spot.spot_id = ci.spot_reference
and     ci.certificate_group = cg.certificate_group_id
and     cg.certificate_group_id = mh.certificate_group
and     spot.complex_id = complex.complex_id
and     complex.complex_region_class = crc.complex_region_class
and     complex.complex_id = mh.complex_id
and     complex.complex_id = cg.complex_id
and NOT EXISTS (select  1
                from    cinema_attendance
                where   cinema_attendance.screening_date = spot.screening_date
                and     cinema_attendance.complex_id = spot.complex_id
                and     cinema_attendance.movie_id = mh.movie_id)
and EXISTS (select  1
                from    cinema_attendance
                where   cinema_attendance.screening_date = spot.screening_date
                and     cinema_attendance.movie_id = mh.movie_id)
group by  spot.campaign_no,
          spot.screening_date,
          spot.complex_id,
          crc.regional_indicator,
          mh.movie_id
GO
