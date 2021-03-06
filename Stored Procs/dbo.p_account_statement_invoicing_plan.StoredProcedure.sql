/****** Object:  StoredProcedure [dbo].[p_account_statement_invoicing_plan]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_account_statement_invoicing_plan]
GO
/****** Object:  StoredProcedure [dbo].[p_account_statement_invoicing_plan]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[p_account_statement_invoicing_plan]		@account_id						INT,
															@accounting_period			DATETIME,
															@company_id						INT,
															@campaign_no					INT,
															@invoice_id						INT
AS

CREATE TABLE #invoice_campaign
(
	company_id						INT					NOT NULL,
	account_id						INT					NOT NULL,
	invoice_id						INT					NULL,
	campaign_no						INT					NULL,
	invoice_total					MONEY				NULL,
	tran_date						DATETIME			NULL,
	outstanding_amount				MONEY				NULL DEFAULT 0.00,
	outstanding_current				MONEY				NULL DEFAULT 0.00,
	outstanding_30					MONEY				NULL DEFAULT 0.00,
	outstanding_60					MONEY				NULL DEFAULT 0.00,
	outstanding_90					MONEY				NULL DEFAULT 0.00,
	outstanding_120					MONEY				NULL DEFAULT 0.00,
	adjusted_current				MONEY				NULL DEFAULT 0.00,
	allocated_current				MONEY				NULL DEFAULT 0.00,
	allocated_prior					MONEY				NULL DEFAULT 0.00,
	allocated_total					AS allocated_current + allocated_prior,
	campaign_status					VARCHAR(1)			NULL
)

INSERT	INTO #invoice_campaign ( 
		company_id, 
		account_id,
		campaign_no, 
		campaign_status,
		invoice_id, 
		invoice_total, 
		tran_date,
		outstanding_amount,
		outstanding_current,
		outstanding_30,
		outstanding_60,
		outstanding_90,
		outstanding_120,
		adjusted_current,
		allocated_current,
		allocated_prior
		)
SELECT			V1.company_id,
				V1.account_id,
				V1.campaign_no,
				V1.campaign_status,
				V1.invoice_id,
				SUM( CASE When V1.group_id = 1 AND V1.detail_id = 2 Then V1.gross_amount Else NULL End) as invoice_total,
				MAX( CASE When V1.group_id = 1 AND V1.detail_id = 2 Then V1.tran_date Else NULL End) as tran_date ,
				SUM( CASE When V1.group_id IN ( 1,3,4 ) Then  V1.gross_amount Else 0 End) as outstanding_amount,		
				CASE When SUM( CASE When V1.group_id IN ( 1 ) AND DATEDIFF( MM, V1.entry_date, @accounting_period) = 0 Then V1.gross_amount Else 0 End) = 0 Then 0 Else
					SUM( CASE When V1.group_id IN ( 1 ) AND DATEDIFF( MM, V1.entry_date, @accounting_period) = 0 Then V1.gross_amount Else 0 End) + 
					SUM( CASE When V1.group_id IN ( 3, 4 ) AND DATEDIFF( MM, V1.entry_date, @accounting_period) = 0 Then V1.gross_amount Else 0 End) End as outstanding_current,
				CASE When SUM( CASE When V1.group_id IN ( 1 ) AND DATEDIFF( MM, V1.entry_date, @accounting_period) = 1 Then V1.gross_amount Else 0 End) = 0 Then 0 Else
					SUM( CASE When V1.group_id IN ( 1 ) AND DATEDIFF( MM, V1.entry_date, @accounting_period) = 1 Then V1.gross_amount Else 0 End) +
					SUM( CASE When V1.group_id IN ( 3, 4 ) AND DATEDIFF( MM, V1.entry_date, @accounting_period) BETWEEN 0 AND 1 Then V1.gross_amount Else 0 End) End as outstanding_30,
				CASE When SUM( CASE When V1.group_id IN ( 1 ) AND DATEDIFF( MM, V1.entry_date, @accounting_period) = 2 Then V1.gross_amount Else 0 End) = 0 Then 0 Else
					SUM( CASE When V1.group_id IN ( 1 ) AND DATEDIFF( MM, V1.entry_date, @accounting_period) = 2 Then V1.gross_amount Else 0 End) + 
					SUM( CASE When V1.group_id IN ( 3, 4 ) AND DATEDIFF( MM, V1.entry_date, @accounting_period) BETWEEN 0 AND 2 Then V1.gross_amount Else 0 End) End as outstanding_60,
				CASE When SUM( CASE When V1.group_id IN ( 1 ) AND DATEDIFF( MM, V1.entry_date, @accounting_period) = 3 Then V1.gross_amount Else 0 End) = 0 Then 0 Else
					SUM( CASE When V1.group_id IN ( 1 ) AND DATEDIFF( MM, V1.entry_date, @accounting_period) = 3 Then V1.gross_amount Else 0 End) + 
					SUM( CASE When V1.group_id IN ( 3, 4 ) AND DATEDIFF( MM, V1.entry_date, @accounting_period) BETWEEN 0 AND 3 Then V1.gross_amount Else 0 End) End as outstanding_90,
				CASE When SUM( CASE When V1.group_id IN ( 1 ) AND DATEDIFF( MM, V1.entry_date, @accounting_period) >= 4 Then V1.gross_amount Else 0 End) = 0 Then 0 Else
					SUM( CASE When V1.group_id IN ( 1 ) AND DATEDIFF( MM, V1.entry_date, @accounting_period) >= 4 Then V1.gross_amount Else 0 End) + 
					SUM( CASE When V1.group_id IN ( 3, 4 ) AND DATEDIFF( MM, V1.entry_date, @accounting_period) >= 0 Then V1.gross_amount Else 0 End) End as outstanding_120,
				SUM( CASE When V1.group_id IN ( 3, 4) AND V1.tran_category <> 'C' Then (CASE When V1.entry_date = @accounting_period Then V1.gross_amount Else 0 End) Else 0 End) as adjusted_current,
				SUM( CASE When V1.group_id IN ( 3) AND V1.tran_category = 'C' Then (CASE When V1.entry_date = dateadd(dd,1,@accounting_period) Then V1.gross_amount Else 0 End) Else 0 End) as allocated_current,
				SUM( CASE When V1.group_id IN ( 3, 4) Then (CASE When V1.entry_date < dateadd(dd,1,@accounting_period) Then V1.gross_amount Else 0 End) Else 0 End) allocated_prior
FROM			v_company_invoicing_plan_transactions V1
WHERE			((V1.invoice_id = @invoice_id or @invoice_id = 0 ) or V1.invoice_id IS NULL )
and				(V1.account_id = @account_id or @account_id = 0 )
AND				( V1.campaign_no = @campaign_no or @campaign_no = 0)
AND				( V1.company_id = @company_id OR @company_id = 0 )
AND				( V1.entry_date <= dateadd(dd,1,@accounting_period)  OR V1.entry_date IS NULL)
AND				((( V1.group_id = 1 AND V1.detail_id = 2 )  -- Billing Total
OR				( V1.group_id = 3 AND V1.detail_id = 1)		-- Payment Allocation 
OR				( V1.group_id = 4 ) ))						-- Reversal Allocation
GROUP BY		V1.company_id,	
				V1.account_id,
				V1.campaign_no, 
				V1.campaign_status, 
				V1.invoice_id

-- Delete fully paid Closed, Expired, Archieved CAMPAIGN with no current period payments
DELETE	FROM #invoice_campaign
WHERE	campaign_no IN (	SELECT campaign_no
							FROM #invoice_campaign
							WHERE	campaign_status IN ( 'X', 'Z')
							GROUP BY campaign_no)
/*AND		campaign_no NOT IN (	SELECT campaign_no
							FROM #invoice_campaign
							WHERE allocated_current <> 0 )*/
AND		campaign_no NOT IN (	SELECT campaign_no
							FROM #invoice_campaign
							WHERE tran_date >= @accounting_period )

-- Delete fully paid invoices with no current period payments
DELETE	FROM #invoice_campaign
WHERE	( outstanding_amount = 0  AND allocated_current = 0 )

--delete campaign is no invoicing plan
delete from #invoice_campaign
where campaign_no not in (select campaign_no from inclusion where inclusion_type = 28)

-- In case no outstanding or paid invoices i.e. nothing to display insert a dummy row 
IF (SELECT COUNT(*) FROM #invoice_campaign) = 0
	BEGIN
		INSERT  #invoice_campaign (invoice_id, company_id, account_id)
		VALUES(-100, @company_id, @account_id )
	END
	
-- Result set
SELECT 	temp.invoice_id,
		temp.campaign_no,
		temp.invoice_total,
		temp.tran_date,
		temp.outstanding_amount as outstanding_amount,
		NULL as balance_current,
		NULL as balance_prior,
		temp.adjusted_current AS adjusted_current,
		temp.allocated_current AS allocated_current,
		temp.allocated_prior AS allocated_prior,
		temp.allocated_total AS allocated_total,
		NULL as reversal_current,
		NULL as reversal_prior,
		NULL as reversal_total,
		temp.outstanding_current AS outstanding_current,
		temp.outstanding_30 AS outstanding_30,
		temp.outstanding_60 AS outstanding_60,
		temp.outstanding_90 AS outstanding_90,
		temp.outstanding_120 AS outstanding_120,
		ac.account_name AS statement_name,
		ac.address_1,
		ac.address_2,
		ac.town_suburb,
		ac.state_code,
		ac.postcode,
		CASE When temp.campaign_no IS NULL Then 'No Transactions' Else fc.product_desc End AS product_desc,
		cp.address_1 AS ba_address_1,
		cp.address_2 AS ba_address_2,
		cp.address_3 AS ba_address_3,
		cp.address_4 AS ba_address_4,
		cp.address_5 AS ba_address_5,
		cp.company_id,
		cp.company_desc,
		cp.division_desc,
		cp.abn,
		cp.bsb,
		cp.bank_account,
		ac.account_id,
		ac.country_code,
		fc.agency_deal,
		ac.account_type,
		accounting_period = @accounting_period
FROM	#invoice_campaign AS temp 
		LEFT OUTER JOIN film_campaign AS fc ON temp.campaign_no = fc.campaign_no,
		account ac,
		company cp
WHERE	temp.account_id = ac.account_id and
		temp.company_id = cp.company_id 
ORDER BY cp.company_id, 
		temp.campaign_no, 
		temp.tran_date ASC

return 0
GO
