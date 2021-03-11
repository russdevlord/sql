USE [production]
GO
/****** Object:  View [dbo].[v_certificate_multiple_playlists]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_certificate_multiple_playlists] as
select movie_id, complex_id, screening_date, print_medium, three_d_type, premium_cinema, count(*) as no_playlists
from movie_history
group by movie_id, complex_id, screening_date, print_medium, three_d_type, premium_cinema
GO
