/****** Object:  View [dbo].[v_data_translate_complex_unique]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_data_translate_complex_unique]
GO
/****** Object:  View [dbo].[v_data_translate_complex_unique]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_data_translate_complex_unique]
as
select distinct data_provider_id, complex_id from data_translate_complex
GO
