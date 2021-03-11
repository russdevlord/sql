USE [production]
GO
/****** Object:  View [dbo].[v_bi_Dates]    Script Date: 11/03/2021 2:30:32 PM ******/
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
