/****** Object:  View [dbo].[v_film_screening_date_xref]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_film_screening_date_xref]
GO
/****** Object:  View [dbo].[v_film_screening_date_xref]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create View [dbo].[v_film_screening_date_xref] AS
SELECT *, DATENAME(QUARTER,Screening_Date) Quarter, DATENAME(YEAR,Screening_Date) Year 
FROM film_screening_date_xref
GO
