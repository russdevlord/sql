/****** Object:  StoredProcedure [dbo].[p_sun_integration]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sun_integration]
GO
/****** Object:  StoredProcedure [dbo].[p_sun_integration]    Script Date: 12/03/2021 10:03:50 AM ******/
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
