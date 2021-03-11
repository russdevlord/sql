/****** Object:  View [dbo].[v_bi_Dates]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_bi_Dates]
GO
/****** Object:  View [dbo].[v_bi_Dates]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--DROP VIEW [dbo].[v_bi_Dates]
--GO
CREATE View [dbo].[v_bi_Dates] AS
Select distinct a.fin_year, a.fin_qtr,a.fin_half, a.fin_Month, a.client_id, a.client_name, a.agency_name
From fj_Table_test a
--RIGHT JOIN 
--fj_Table_test b
--ON a.fin_year = b.fin_year
GO
