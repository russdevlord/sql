/****** Object:  View [dbo].[v_accpac_customer]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_accpac_customer]
GO
/****** Object:  View [dbo].[v_accpac_customer]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_accpac_customer] 
AS
  SELECT
    'C' 'customer_type',
    client_id 'vm_customer_id',
	'ZC' + left('00000000', 8 - len(convert(varchar(10),t.client_id))) + convert(varchar(10),t.client_id) 'accpac_customer_id'
 FROM dbo.client t
UNION
SELECT
    'A' 'customer_type',
    agency_id 'vm_customer_id',
	'ZA' + left('00000000', 8 - len(convert(varchar(10),t.agency_id))) + convert(varchar(10),t.agency_id)'accpac_customer_id'
 FROM dbo.agency t
GO
