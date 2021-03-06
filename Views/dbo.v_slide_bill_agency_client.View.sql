/****** Object:  View [dbo].[v_slide_bill_agency_client]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_slide_bill_agency_client]
GO
/****** Object:  View [dbo].[v_slide_bill_agency_client]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_slide_bill_agency_client]
AS
select  vc.campaign_no,
        vc.campaign_name,
        vc.branch_code,
        vc.client_name,
        vc.agency_name,
        vb.accounting_period,
        vb.billing_total
from    v_slide_agency_client vc, v_slide_billings_by_campaign vb
where   vc.campaign_no = vb.campaign_no
GO
