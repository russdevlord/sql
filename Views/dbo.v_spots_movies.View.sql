/****** Object:  View [dbo].[v_spots_movies]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_spots_movies]
GO
/****** Object:  View [dbo].[v_spots_movies]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_spots_movies]
AS

select     long_name,
            spot_reference
from        v_certificate_item_distinct certificate_item,
            certificate_group,
            movie_history,
            movie
where       certificate_item.certificate_group = certificate_group.certificate_group_id
and         certificate_group.certificate_group_id = movie_history.certificate_group
and         movie_history.movie_id = movie.movie_id
group by    long_name,
            spot_reference
GO
