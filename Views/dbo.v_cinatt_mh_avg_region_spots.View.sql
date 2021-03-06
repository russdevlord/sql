/****** Object:  View [dbo].[v_cinatt_mh_avg_region_spots]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_mh_avg_region_spots]
GO
/****** Object:  View [dbo].[v_cinatt_mh_avg_region_spots]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_mh_avg_region_spots]
AS
select  spot.campaign_no 'campaign_no',
        spot.screening_date 'screening_date',
        spot.complex_id 'complex_id',
        crc.regional_indicator 'regional_indicator',
        mh.movie_id 'movie_id',
        count(distinct spot.spot_id) 'spot_count'
 from   campaign_spot spot,
        certificate_item ci,
        certificate_group cg,
        movie_history mh,
        complex,
        complex_region_class crc
where   spot.spot_status ='X'
and     spot.screening_date >= '3-jan-2002'
and     spot.spot_id = ci.spot_reference
and     ci.certificate_group = cg.certificate_group_id
and     cg.certificate_group_id = mh.certificate_group
and     spot.complex_id = complex.complex_id
and     complex.complex_region_class = crc.complex_region_class
and NOT EXISTS (select  1
                from    cinema_attendance
                where   cinema_attendance.screening_date = spot.screening_date
                and     cinema_attendance.complex_id = spot.complex_id
                and     cinema_attendance.movie_id = mh.movie_id)
and NOT EXISTS (select 1
                from    cinema_attendance
                where   cinema_attendance.screening_date = spot.screening_date
                and     cinema_attendance.movie_id = mh.movie_id
                and     cinema_attendance.complex_id in (   select  a.complex_id
                                                            from    movie_history a, 
                                                                    complex b, 
                                                                    complex_region_class c
                                                             where  a.movie_id = mh.movie_id 
                                                             and    a.screening_date = spot.screening_date 
                                                             and    a.complex_id = b.complex_id 
                                                             and    b.complex_region_class = c.complex_region_class
                                                             and    c.regional_indicator = crc.regional_indicator
                                                             and    b.branch_code != 'Z'))
group by  spot.campaign_no,
          spot.screening_date,
          spot.complex_id,
          crc.regional_indicator,
          mh.movie_id
UNION
select  spot.campaign_no 'campaign_no',
        spot.screening_date 'screening_date',
        spot.complex_id 'complex_id',
        crc.regional_indicator 'regional_indicator',
        0 'movie_id',
        count(distinct spot.spot_id) 'spot_count'
 from   campaign_spot spot,
        certificate_item ci,
        certificate_group cg,
        complex,
        complex_region_class crc
where   spot.spot_status ='X'
and     spot.screening_date >= '3-jan-2002'
and     spot.spot_id = ci.spot_reference
and     ci.certificate_group = cg.certificate_group_id
and     spot.complex_id = complex.complex_id
and     complex.complex_region_class = crc.complex_region_class
and not exists (select 1
                from    movie_history
                where   certificate_group = cg.certificate_group_id)
group by  spot.campaign_no,
          spot.screening_date,
          spot.complex_id,
          crc.regional_indicator
GO
