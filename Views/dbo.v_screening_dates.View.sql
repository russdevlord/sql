/****** Object:  View [dbo].[v_screening_dates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_screening_dates]
GO
/****** Object:  View [dbo].[v_screening_dates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_screening_dates] with SCHEMABINDING
as
select screening_date
from dbo.film_screening_dates
GO
