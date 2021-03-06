/****** Object:  View [dbo].[v_certificate_multiple_playlists]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_certificate_multiple_playlists]
GO
/****** Object:  View [dbo].[v_certificate_multiple_playlists]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_certificate_multiple_playlists] as
select movie_id, complex_id, screening_date, print_medium, three_d_type, premium_cinema, count(*) as no_playlists
from movie_history
group by movie_id, complex_id, screening_date, print_medium, three_d_type, premium_cinema
GO
