/****** Object:  View [dbo].[v_dw_dim_campaign_movie_spots]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dw_dim_campaign_movie_spots]
GO
/****** Object:  View [dbo].[v_dw_dim_campaign_movie_spots]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_dw_dim_campaign_movie_spots]
AS
    select  spot.campaign_no as campaign_no,
            spot.screening_date as screening_date,
            spot.billing_date as billing_date,
            spot.spot_id as spot_id,
            spot.complex_id as complex_id,
            cplx.complex_name as complex_name,
            spot.package_id as package_id,
            mh.movie_id as movie_id,
            mv.long_name as movie_name
    from    campaign_spot spot,
            campaign_package cpack,
            certificate_item ci,
            certificate_group cg,
            movie_history mh,
            complex cplx,
            movie mv
    where   spot.complex_id = cplx.complex_id 
    and     spot.package_id = cpack.package_id 
    and     spot.spot_status ='X'
    and     spot.spot_id = ci.spot_reference
    and     ci.certificate_group = cg.certificate_group_id
    and     cg.certificate_group_id = mh.certificate_group
    and     mh.movie_id = mv.movie_id
GO
