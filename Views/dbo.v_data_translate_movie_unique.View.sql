/****** Object:  View [dbo].[v_data_translate_movie_unique]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_data_translate_movie_unique]
GO
/****** Object:  View [dbo].[v_data_translate_movie_unique]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_data_translate_movie_unique]
as
select distinct data_provider_id, movie_id from data_translate_movie
GO
