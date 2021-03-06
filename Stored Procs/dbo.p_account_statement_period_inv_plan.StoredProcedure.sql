/****** Object:  StoredProcedure [dbo].[p_account_statement_period_inv_plan]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_account_statement_period_inv_plan]
GO
/****** Object:  StoredProcedure [dbo].[p_account_statement_period_inv_plan]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_account_statement_period_inv_plan]		@accounting_period		datetime
as

set nocount on


CREATE TABLE #statement_listing
(
	account_id							INT						NOT NULL,
	outstanding_amount			MONEY				NULL DEFAULT 0.00,
	company_id						INT						NOT NULL,
	account_name					varchar(100)		not null,
	town_suburb						varchar(100)		not null,
	country_code					char(1)				not null,
	contact								varchar(100)		not null,
	email									varchar(100)		not null
)


select			account_id = V1.account_id,
				SUM( CASE When V1.group_id IN ( 1,3,4 ) Then  V1.gross_amount Else 0 End) as outstanding_amount,		
				V1.company_id,
				acc.account_name,
				acc.town_suburb,
				acc.country_code,
				ISNULL(agency.agency_name, ISNULL( client.contact, acc.contact)) AS contact,
				ISNULL(agency.email, ISNULL( client.email, acc.email)) AS email	
FROM			v_company_invoicing_plan_transactions V1
left join		account AS acc on v1.account_id = acc.account_id
left outer join agency ON acc.agency_id = agency.agency_id 
left outer join	client ON acc.client_id = client.client_id
WHERE			( V1.entry_date <= dateadd(dd,1,@accounting_period)  OR V1.entry_date IS NULL)
and				((( V1.group_id = 1 AND V1.detail_id = 2 )  -- Billing Total
OR				( V1.group_id = 3 AND V1.detail_id = 1)		-- Payment Allocation 
OR				( V1.group_id = 4 ) ))						-- Reversal Allocation
and				V1.campaign_no in (select campaign_no from inclusion where inclusion_type = 28)
and				V1.company_id not in (3,4,6)
GROUP BY		V1.account_id,
				V1.company_id,
				acc.account_name,
				acc.town_suburb,
				acc.country_code,
				agency.agency_name,
				client.contact, 
				acc.contact,
				agency.email,
				client.email, 
				acc.email

return 0
GO
