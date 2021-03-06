/****** Object:  StoredProcedure [dbo].[p_account_statement_period]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_account_statement_period]
GO
/****** Object:  StoredProcedure [dbo].[p_account_statement_period]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[p_account_statement_period]		@accounting_period		datetime
as

set nocount on


CREATE TABLE #statement_listing
(
	account_id					INT						NOT NULL,
	outstanding_amount			MONEY					NULL DEFAULT 0.00,
	company_id					INT						NOT NULL,
	account_name				varchar(100)			null,
	town_suburb					varchar(100)			null,
	country_code				char(1)					null,
	contact						varchar(100)			null,
	email						varchar(100)			null,
	campaign_no					int						null,
	campaign_status				char(1)					null,
	tran_date					datetime				null
)

insert into		#statement_listing
SELECT			account_id = tran_view.account_id,
				SUM( case When tran_view.group_id IN ( 1,3,4 ) Then  tran_view.gross_amount Else 0 End) as outstanding_amount,		
				tran_view.company_id,
				acc.account_name,
				acc.town_suburb,
				acc.country_code,
				ISNULL(agency.agency_name, ISNULL( client.contact, acc.contact)) AS contact,
				ISNULL(agency.email, ISNULL( client.email, acc.email)) AS email	,
				tran_view.campaign_no,
				tran_view.campaign_status,
				MAX( case When tran_view.group_id = 1 AND tran_view.detail_id = 2 Then tran_view.tran_date Else NULL End) as tran_date
FROM			v_company_account_campaign_combined_transactions tran_view
left join		account AS acc on tran_view.account_id = acc.account_id
left outer join agency ON acc.agency_id = agency.agency_id 
left outer join client ON acc.client_id = client.client_id
WHERE			( tran_view.entry_date <= dateadd(dd,1,@accounting_period)  OR tran_view.entry_date IS NULL)
and				((( tran_view.group_id = 1 AND tran_view.detail_id = 2 )  -- Billing Total
OR				( tran_view.group_id = 3 AND tran_view.detail_id = 2)		-- Payment Allocation 
OR				( tran_view.group_id = 4 ) ))						-- Reversal Allocation
and				tran_view.company_id not in (3,4,6)
and				isnull(tran_view.account_id, -100) <> -100
GROUP BY		tran_view.account_id,
				tran_view.company_id,
				acc.account_name,
				acc.town_suburb,
				acc.country_code,
				agency.agency_name,
				client.contact, 
				acc.contact,
				agency.email,
				client.email, 
				acc.email,
				tran_view.campaign_no,
				tran_view.campaign_status
order by		tran_view.account_id,
				tran_view.company_id,
				tran_view.campaign_no						

DELETE			#statement_listing
WHERE			campaign_no IN (SELECT			campaign_no
								FROM			#statement_listing
								WHERE			campaign_status IN ( 'X', 'Z')
								GROUP BY		campaign_no)
AND				campaign_no NOT IN (SELECT			campaign_no
									FROM			#statement_listing
									WHERE			tran_date >= @accounting_period )

						
select			account_id,
				sum(outstanding_amount) as outstanding_amount,
				company_id,
				account_name,
				town_suburb,
				country_code,
				contact,
				email		 
from			#statement_listing						
group by		account_id,
				company_id,
				account_name,
				town_suburb,
				country_code,
				contact,
				email	

return 0
GO
