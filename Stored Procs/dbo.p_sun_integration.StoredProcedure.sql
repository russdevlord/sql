USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_sun_integration]    Script Date: 11/03/2021 2:30:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[p_sun_integration] @accounting_period datetime, @country_code varchar(1)
AS 

EXEC p_sun_integration_1_sales_invoice_revenue @accounting_period, @country_code

EXEC p_sun_integration_2_sales_invoice_agency @accounting_period, @country_code

EXEC p_sun_integration_3_theatre_rent_accrual @accounting_period, @country_code

EXEC p_sun_integration_4_theatre_rent_liability @accounting_period, @country_code

EXEC p_sun_integration_5_receipts_agency @accounting_period, @country_code

EXEC p_sun_integration_6_production_income @accounting_period, @country_code

GRANT EXECUTE ON dbo.p_sun_integration to public
GO
