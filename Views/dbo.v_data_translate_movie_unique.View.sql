USE [production]
GO
/****** Object:  View [dbo].[v_data_translate_movie_unique]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_data_translate_movie_unique]
as
select distinct data_provider_id, movie_id from data_translate_movie
GO
