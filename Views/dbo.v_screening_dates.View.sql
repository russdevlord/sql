USE [production]
GO
/****** Object:  View [dbo].[v_screening_dates]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_screening_dates] with SCHEMABINDING
as
select screening_date
from dbo.film_screening_dates
GO
