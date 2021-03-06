/****** Object:  StoredProcedure [dbo].[p_account_invoice]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_account_invoice]
GO
/****** Object:  StoredProcedure [dbo].[p_account_invoice]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[p_account_invoice]			@invoice_id			int,
												@inclusion_id		int

as

set nocount on

declare		@errorode					int,
			@tran_id					int,
			@new_invoice_id				int,
			@business_unit_id			int,
			@campaign_no				int,
			@tran_desc					VARCHAR(255),
			@invoice_date				datetime,
			@production_count			int

--Create invoice if no invoice_id was passed
if(@invoice_id is null)
begin
	begin transaction

	exec @errorode = p_ffin_create_invoice			@inclusion_id,
													@tran_id				OUTPUT,
													@new_invoice_id			OUTPUT
																						
	if @errorode <> 0
	begin
		raiserror ('Error: Failed to create new invoice for this inclusion', 16, 1)
		rollback transaction
		return -1
	end																						
	
	commit transaction
	select @invoice_id = @new_invoice_id
end

CREATE TABLE #invoice_campaign(
		invoice_id						INT						NULL,
		company_id						INT						NULL,
		campaign_no						INT						NULL,
		balance_current					MONEY					NULL				DEFAULT 0.00,
		balance_30						MONEY					NULL				DEFAULT 0.00,
		balance_60						MONEY					NULL				DEFAULT 0.00,
		balance_90						MONEY					NULL				DEFAULT 0.00,
		balance_120						MONEY					NULL				DEFAULT 0.00,
		accounting_period				DATETIME				NULL,
		balance_forward					MONEY					NULL				DEFAULT 0.00,
		balance_outstanding				MONEY					NULL				DEFAULT 0.00,
		balance_credit					MONEY					NULL				DEFAULT 0.00,
		statement_name					VARCHAR(50)				NULL,
		address_1						VARCHAR(50)				NULL,
		address_2						VARCHAR(50)				NULL,
		town_suburb						VARCHAR(30)				NULL,
		state_code						VARCHAR(3)				NULL,
		postcode						VARCHAR(5)				NULL,
		product_desc					VARCHAR(100)			NULL,
		nett_amount						MONEY					NULL				DEFAULT 0.00,
		gst_amount						MONEY					NULL				DEFAULT 0.00,
		gross_amount					MONEY					NULL				DEFAULT 0.00,
		tran_desc						VARCHAR(255)			NULL,
		tran_notes						VARCHAR(255)			NULL,
		tran_id							INT						NULL,
		tran_date						DATETIME				NULL,
		country_code					VARCHAR(2)				NULL,
		agency_deal						VARCHAR(1)				NULL,
		address_address_1				VARCHAR(50)				NULL,
		address_address_2				VARCHAR(50)				NULL,
		address_address_3				VARCHAR(50)				NULL,
		address_address_4				VARCHAR(50)				NULL,
		address_address_5				VARCHAR(50)				NULL,
		statement_message				VARCHAR(255)			NULL,
		tran_category					VARCHAR(1)				NULL,
		business_unit_id				INT						NULL,
		rec_type						VARCHAR(1)				NULL,
		from_tran_id					INT						NULL,
		company_desc					VARCHAR(100)			NULL,
		division_desc					VARCHAR(100)			NULL,
		abn								VARCHAR(20)				NULL,
		bsb								VARCHAR(10)				NULL,
		bank_account					VARCHAR(30)				NULL,
		media_bundle_type				char(1)					NULL
		)

select		@campaign_no = campaign_no
from		campaign_transaction
where		invoice_id = @invoice_id

select		@invoice_date = invoice_date
from		invoice
where		invoice_id = @invoice_id

declare			business_unit_csr cursor for
select			distinct business_unit_id
from			film_campaign
inner join		campaign_transaction on film_campaign.campaign_no = campaign_transaction.campaign_no
where			campaign_transaction.invoice_id = @invoice_id
for				read only

open business_unit_csr
fetch business_unit_csr into @business_unit_id
while(@@fetch_status = 0)
begin
	select			@production_count = count(*)
	FROM 			invoice inv
	inner join		campaign_transaction ct on inv.invoice_id = ct.invoice_id
	inner join		film_campaign fc on ct.campaign_no = fc.campaign_no
	inner join		account ac on inv.account_id = ac.account_id
	inner join		company cp on inv.company_id = cp.company_id
	inner join		transaction_type tt on ct.tran_type = tt.trantype_id
	inner join		branch br on fc.branch_code = br.branch_code
	WHERE			inv.invoice_id = @invoice_id
	and				fc.business_unit_id = @business_unit_id
	and				ct.show_on_statement = 'Y'
	and				tt.tran_category_code in ('B', 'C', 'Z', 'M')
	and				tt.trantype_id in (22,25,32,45,80,82,150,154,158,159,160,161)

	print @business_unit_id

	if @business_unit_id = 2 or @business_unit_id = 3 or @business_unit_id = 5 or @business_unit_id = 9
	begin
		INSERT INTO #invoice_campaign(
						invoice_id,
						company_id,
						campaign_no,
						balance_current,
						balance_30,
						balance_60,
						balance_90,
						balance_120,
						accounting_period,
						balance_forward,
						balance_outstanding,
						balance_credit,
						statement_name,
						address_1,
						address_2,
						town_suburb,
						state_code,
						postcode,
						product_desc,
						nett_amount,
						gst_amount,
						gross_amount,
						tran_desc,
						tran_notes,
						tran_id,
						tran_date,
						country_code,
						agency_deal,
						address_address_1,
						address_address_2,
						address_address_3,
						address_address_4,
						address_address_5,
						statement_message,
						tran_category,
						business_unit_id,
						rec_type,
						from_tran_id,
						company_desc,
						division_desc,
						abn,
						bsb,
						bank_account,
						media_bundle_type)
		SELECT			inv.invoice_id,
						inv.company_id,
						ct.campaign_no,   
						convert(numeric(9,4),null) AS balance_current,   
						convert(numeric(9,4),null) AS balance_30,   
						convert(numeric(9,4),null) AS balance_60,   
						convert(numeric(9,4),null) AS balance_90,   
						convert(numeric(9,4),null) AS balance_120,   
						inv.invoice_date,   
						convert(numeric(9,4),null) AS balance_forward,   
						convert(numeric(9,4),null) AS balance_outstanding,   
						convert(numeric(9,4),null) AS balance_credit,   
						ac.account_name,   
						ac.address_1,   
						ac.address_2,   
						ac.town_suburb,   
						ac.state_code,   
						ac.postcode,   
						fc.product_desc,   
						sum(ct.nett_amount) as nett_amount,   
						sum(ct.gst_amount),   
						sum(ct.gross_amount),   
						case 
							when tt.tran_category_code in ('B', 'C') then 'Scheduled Media Screenings'
							when tt.tran_category_code in ('Z') then 'A/Comm on Scheduled Media Screenings'
							when tt.tran_category_code in ('M') and tt.trantype_id != 31 and fc.branch_code <> 'Z' then 'Production and Services'
							when tt.tran_category_code in ('M') and tt.trantype_id = 31 and fc.branch_code <> 'Z' then 'A/Comm on Production and Services'
							when tt.tran_category_code in ('M') and tt.trantype_id != 31 and fc.branch_code = 'Z' and @production_count > 0 then 'Production and Services'
							when tt.tran_category_code in ('M') and tt.trantype_id = 31 and fc.branch_code = 'Z' and @production_count > 0 then 'A/Comm on Production and Services'
							when tt.tran_category_code in ('M') and tt.trantype_id != 31 and fc.branch_code = 'Z' and @production_count = 0 then 'Services'
							when tt.tran_category_code in ('M') and tt.trantype_id = 31 and fc.branch_code = 'Z' and @production_count > 0 then 'A/Comm on Services'
							else 'Transaction Logic Error'
						end,   
						'',  
						max(ct.tran_id) as tran_id,   
						inv.invoice_date ,   
						br.country_code,   
						fc.agency_deal,   
						cp.address_1 AS address_address_1,   
						cp.address_2 AS address_address_2,   
						cp.address_3 AS address_address_3,   
						cp.address_4 AS address_address_4,   
						cp.address_5 AS address_address_5,   
						convert(varchar(255),null) AS statement_message,   
						ct.tran_category,
						fc.business_unit_id,
						convert(char(1),'I') AS rec_type,
						convert(int,null) AS from_tran_id,
						cp.company_desc,
						cp.division_desc,
						cp.abn,
						cp.bsb,
						cp.bank_account,
						'O' 
		FROM 			invoice inv
		inner join		campaign_transaction ct on inv.invoice_id = ct.invoice_id
		inner join		film_campaign fc on ct.campaign_no = fc.campaign_no
		inner join		account ac on inv.account_id = ac.account_id
		inner join		company cp on inv.company_id = cp.company_id
		inner join		transaction_type tt on ct.tran_type = tt.trantype_id
		inner join		branch br on fc.branch_code = br.branch_code
		WHERE			inv.invoice_id = @invoice_id
		and				fc.business_unit_id = @business_unit_id
		and				ct.show_on_statement = 'Y'
		and				tt.tran_category_code in ('B', 'C', 'Z', 'M')
		group by		inv.invoice_id,
						inv.company_id,
						ct.campaign_no,   
						inv.invoice_date,   
						ac.account_name,   
						ac.address_1,   
						ac.address_2,   
						ac.town_suburb,   
						ac.state_code,   
						ac.postcode,   
						fc.product_desc,   
						case 
							when tt.tran_category_code in ('B', 'C') then 'Scheduled Media Screenings'
							when tt.tran_category_code in ('Z') then 'A/Comm on Scheduled Media Screenings'
							when tt.tran_category_code in ('M') and tt.trantype_id != 31 and fc.branch_code <> 'Z' then 'Production and Services'
							when tt.tran_category_code in ('M') and tt.trantype_id = 31 and fc.branch_code <> 'Z' then 'A/Comm on Production and Services'
							when tt.tran_category_code in ('M') and tt.trantype_id != 31 and fc.branch_code = 'Z' and @production_count > 0 then 'Production and Services'
							when tt.tran_category_code in ('M') and tt.trantype_id = 31 and fc.branch_code = 'Z' and @production_count > 0 then 'A/Comm on Production and Services'
							when tt.tran_category_code in ('M') and tt.trantype_id != 31 and fc.branch_code = 'Z' and @production_count = 0 then 'Services'
							when tt.tran_category_code in ('M') and tt.trantype_id = 31 and fc.branch_code = 'Z' and @production_count > 0 then 'A/Comm on Services'
							else 'Transaction Logic Error'
						end,   
						br.country_code,   
						fc.agency_deal,   
						cp.address_1 ,   
						cp.address_2 ,   
						cp.address_3 ,   
						cp.address_4 ,   
						cp.address_5 ,   
						ct.tran_category,
						fc.business_unit_id,
						cp.company_desc,
						cp.division_desc,
						cp.abn,
						cp.bsb,
						cp.bank_account
		order by		ct.campaign_no, 
						inv.invoice_date
	end 
	else if @business_unit_id = 11 and @invoice_date >= '30-dec-2020'
	begin
		INSERT INTO #invoice_campaign(
						invoice_id,
						company_id,
						campaign_no,
						balance_current,
						balance_30,
						balance_60,
						balance_90,
						balance_120,
						accounting_period,
						balance_forward,
						balance_outstanding,
						balance_credit,
						statement_name,
						address_1,
						address_2,
						town_suburb,
						state_code,
						postcode,
						product_desc,
						nett_amount,
						gst_amount,
						gross_amount,
						tran_desc,
						tran_notes,
						tran_id,
						tran_date,
						country_code,
						agency_deal,
						address_address_1,
						address_address_2,
						address_address_3,
						address_address_4,
						address_address_5,
						statement_message,
						tran_category,
						business_unit_id,
						rec_type,
						from_tran_id,
						company_desc,
						division_desc,
						abn,
						bsb,
						bank_account,
						media_bundle_type)
		SELECT			inv.invoice_id,
						inv.company_id,
						ct.campaign_no,   
						convert(numeric(9,4),null) AS balance_current,   
						convert(numeric(9,4),null) AS balance_30,   
						convert(numeric(9,4),null) AS balance_60,   
						convert(numeric(9,4),null) AS balance_90,   
						convert(numeric(9,4),null) AS balance_120,   
						inv.invoice_date,   
						convert(numeric(9,4),null) AS balance_forward,   
						convert(numeric(9,4),null) AS balance_outstanding,   
						convert(numeric(9,4),null) AS balance_credit,   
						ac.account_name,   
						ac.address_1,   
						ac.address_2,   
						ac.town_suburb,   
						ac.state_code,   
						ac.postcode,   
						fc.product_desc,   
						sum(ct.nett_amount) as nett_amount,   
						sum(ct.gst_amount),   
						sum(ct.gross_amount),   
						case 
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'F' and default_format = 'T' then 'FANDOM Billings'
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'L' and default_format = 'T' then 'The Latch Billings'
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'U' and default_format = 'T' then 'Thrillist Billings'
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'V' and default_format = 'T' then 'Popsugar Billings'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'F' and default_format = 'T' then 'A/Comm on FANDOM Billings'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'L' and default_format = 'T' then 'A/Comm on The Latch Billings'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'U' and default_format = 'T' then 'A/Comm on Thrillist Billings'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'V' and default_format = 'T' then 'A/Comm on Popsugar Billingss'
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'F' and default_format = 'S' then 'FANDOM Production and Services'
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'L' and default_format = 'S' then 'The Latch Production and Services'
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'U' and default_format = 'S' then 'Thrillist Production and Services'
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'V' and default_format = 'S' then 'Popsugar Production and Services'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'F' and default_format = 'S' then 'A/Comm on FANDOM Production and Services'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'L' and default_format = 'S' then 'A/Comm on The Latch Production and Services'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'U' and default_format = 'S' then 'A/Comm on Thrillist Production and Services'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'V' and default_format = 'S' then 'A/Comm on Popsugar Production and Services'
							else 'Transaction Logic Error'
						end,
						'',  
						max(ct.tran_id) as tran_id,   
						inv.invoice_date ,   
						br.country_code,   
						fc.agency_deal,   
						cp.address_1 AS address_address_1,   
						cp.address_2 AS address_address_2,   
						cp.address_3 AS address_address_3,   
						cp.address_4 AS address_address_4,   
						cp.address_5 AS address_address_5,   
						convert(varchar(255),null) AS statement_message,   
						ct.tran_category,
						fc.business_unit_id,
						convert(char(1),'I') AS rec_type,
						convert(int,null) AS from_tran_id,
						cp.company_desc,
						cp.division_desc,
						cp.abn,
						cp.bsb,
						cp.bank_account,
						'O' 
		FROM 			invoice inv
		inner join		campaign_transaction ct on inv.invoice_id = ct.invoice_id
		inner join		film_campaign fc on ct.campaign_no = fc.campaign_no
		inner join		account ac on inv.account_id = ac.account_id
		inner join		company cp on inv.company_id = cp.company_id
		inner join		transaction_type tt on ct.tran_type = tt.trantype_id
		inner join		branch br on fc.branch_code = br.branch_code
		inner join		inclusion_tran_xref itx on ct.tran_id = itx.tran_id
		inner join		inclusion inc on itx.inclusion_id = inc.inclusion_id
		inner join		inclusion_type inc_type on inc.inclusion_type = inc_type.inclusion_type
		WHERE			inv.invoice_id = @invoice_id
		and				fc.business_unit_id = @business_unit_id
		and				ct.show_on_statement = 'Y'
		and				tt.tran_category_code in ('B', 'C', 'Z', 'M')
		group by		inv.invoice_id,
						inv.company_id,
						ct.campaign_no,   
						inv.invoice_date,   
						ac.account_name,   
						ac.address_1,   
						ac.address_2,   
						ac.town_suburb,   
						ac.state_code,   
						ac.postcode,   
						fc.product_desc,   
						case 
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'F' and default_format = 'T' then 'FANDOM Billings'
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'L' and default_format = 'T' then 'The Latch Billings'
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'U' and default_format = 'T' then 'Thrillist Billings'
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'V' and default_format = 'T' then 'Popsugar Billings'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'F' and default_format = 'T' then 'A/Comm on FANDOM Billings'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'L' and default_format = 'T' then 'A/Comm on The Latch Billings'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'U' and default_format = 'T' then 'A/Comm on Thrillist Billings'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'V' and default_format = 'T' then 'A/Comm on Popsugar Billingss'
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'F' and default_format = 'S' then 'FANDOM Production and Services'
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'L' and default_format = 'S' then 'The Latch Production and Services'
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'U' and default_format = 'S' then 'Thrillist Production and Services'
							when tt.tran_category_code in ('B', 'C') and inclusion_type_group = 'V' and default_format = 'S' then 'Popsugar Production and Services'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'F' and default_format = 'S' then 'A/Comm on FANDOM Production and Services'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'L' and default_format = 'S' then 'A/Comm on The Latch Production and Services'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'U' and default_format = 'S' then 'A/Comm on Thrillist Production and Services'
							when tt.tran_category_code in ('Z') and inclusion_type_group = 'V' and default_format = 'S' then 'A/Comm on Popsugar Production and Services'
							else 'Transaction Logic Error'
						end,   						
						br.country_code,   
						fc.agency_deal,   
						cp.address_1 ,   
						cp.address_2 ,   
						cp.address_3 ,   
						cp.address_4 ,   
						cp.address_5 ,   
						ct.tran_category,
						fc.business_unit_id,
						cp.company_desc,
						cp.division_desc,
						cp.abn,
						cp.bsb,
						cp.bank_account
		order by		ct.campaign_no, 
						inv.invoice_date
	end
	else
	begin
		INSERT INTO #invoice_campaign(
						invoice_id,
						company_id,
						campaign_no,
						balance_current,
						balance_30,
						balance_60,
						balance_90,
						balance_120,
						accounting_period,
						balance_forward,
						balance_outstanding,
						balance_credit,
						statement_name,
						address_1,
						address_2,
						town_suburb,
						state_code,
						postcode,
						product_desc,
						nett_amount,
						gst_amount,
						gross_amount,
						tran_desc,
						tran_notes,
						tran_id,
						tran_date,
						country_code,
						agency_deal,
						address_address_1,
						address_address_2,
						address_address_3,
						address_address_4,
						address_address_5,
						statement_message,
						tran_category,
						business_unit_id,
						rec_type,
						from_tran_id,
						company_desc,
						division_desc,
						abn,
						bsb,
						bank_account,
						media_bundle_type)
		SELECT			inv.invoice_id,
						inv.company_id,
						ct.campaign_no,   
						convert(numeric(9,4),null) AS balance_current,   
						convert(numeric(9,4),null) AS balance_30,   
						convert(numeric(9,4),null) AS balance_60,   
						convert(numeric(9,4),null) AS balance_90,   
						convert(numeric(9,4),null) AS balance_120,   
						inv.invoice_date,   
						convert(numeric(9,4),null) AS balance_forward,   
						convert(numeric(9,4),null) AS balance_outstanding,   
						convert(numeric(9,4),null) AS balance_credit,   
						ac.account_name,   
						ac.address_1,   
						ac.address_2,   
						ac.town_suburb,   
						ac.state_code,   
						ac.postcode,   
						fc.product_desc,   
						ct.nett_amount,   
						ct.gst_amount,   
						ct.gross_amount,   
						ct.tran_desc,   
						ct.tran_notes,  
						ct.tran_id,   
						ct.tran_date,   
						br.country_code,   
						fc.agency_deal,   
						cp.address_1 AS address_address_1,   
						cp.address_2 AS address_address_2,   
						cp.address_3 AS address_address_3,   
						cp.address_4 AS address_address_4,   
						cp.address_5 AS address_address_5,   
						convert(varchar(255),null) AS statement_message,   
						ct.tran_category,
						fc.business_unit_id,
						convert(char(1),'I') AS rec_type,
						convert(int,null) AS from_tran_id,
						cp.company_desc,
						cp.division_desc,
						cp.abn,
						cp.bsb,
						cp.bank_account,
						case cp.company_id
							when 1 then tt.media_bundle_type
							when 2 then tt.media_bundle_type
							else 'O'
						end 
		FROM 			invoice inv,
						campaign_transaction ct,   
						film_campaign fc,   
						account ac,   
						company cp,
						transaction_type tt,
						branch br
		WHERE			inv.invoice_id = @invoice_id
		and				ct.invoice_id = inv.invoice_id
		and				fc.campaign_no = ct.campaign_no
		and				ac.account_id = inv.account_id
		and				inv.company_id = cp.company_id
		and				fc.branch_code = br.branch_code
		and				ct.show_on_statement = 'Y'
		and				ct.tran_type = tt.trantype_id
		and				fc.business_unit_id = @business_unit_id
		order by		ct.campaign_no, ct.tran_date
	end
		fetch business_unit_csr into @business_unit_id
end

-- In case no outstanding or paid invoices i.e. nothing to display insert a dummy row 
IF (SELECT COUNT(*) FROM #invoice_campaign) = 0
BEGIN
	INSERT	INTO #invoice_campaign (
					invoice_id,
					company_id,
					campaign_no,
					accounting_period,
					statement_name,
					address_1,
					address_2,
					town_suburb,
					state_code,
					postcode,
					product_desc,
					country_code,
					agency_deal,
					address_address_1,
					address_address_2,
					address_address_3,
					address_address_4,
					address_address_5,
					statement_message,
					business_unit_id,
					rec_type,
					company_desc,
					division_desc,
					abn,
					bsb,
					bank_account,
					media_bundle_type)
	SELECT			inv.invoice_id,
					inv.company_id,
					0,
					inv.invoice_date,   
					ac.account_name,   
					ac.address_1,   
					ac.address_2,   
					ac.town_suburb,   
					ac.state_code,   
					ac.postcode,   
					'', --fc.product_desc,   
					ac.country_code,   
					'', --fc.agency_deal,   
					cp.address_1 AS address_address_1,   
					cp.address_2 AS address_address_2,   
					cp.address_3 AS address_address_3,   
					cp.address_4 AS address_address_4,   
					cp.address_5 AS address_address_5,   
					'No Transactions' AS statement_message,   
					NULL, --fc.business_unit_id,
					convert(char(1),'I') AS rec_type,
					cp.company_desc,
					cp.division_desc,
					cp.abn,
					cp.bsb,
					cp.bank_account,
					'O'
	FROM 			invoice inv,
					account ac,   
					company cp
	WHERE		    inv.invoice_id = @invoice_id
	and				ac.account_id = inv.account_id
	and				inv.company_id = cp.company_id

END


SELECT			#invoice_campaign.invoice_id,
				company_id,
				#invoice_campaign.campaign_no,
				balance_current,
				balance_30,
				balance_60,
				balance_90,
				balance_120,
				case accounting_period when '1-jul-2015' then '30-jun-2015' else accounting_period end,
				balance_forward,
				balance_outstanding,
				balance_credit,
				statement_name,
				address_1,
				address_2,
				town_suburb,
				state_code,
				postcode,
				product_desc,
				nett_amount,
				gst_amount,
				gross_amount,
				tran_desc,
				tran_notes,
				tran_id,
				tran_date,
				country_code,
				agency_deal,
				address_address_1,
				address_address_2,
				address_address_3,
				address_address_4,
				address_address_5,
				statement_message,
				tran_category,
				business_unit_id,
				rec_type,
				from_tran_id,
				company_desc,
				division_desc,
				abn,
				bsb,
				bank_account,
				media_bundle_type,
				invoice_comments.comments,
				film_campaign_standalone_invoice.invoice_payment_type_code
FROM			#invoice_campaign 
left outer join invoice_comments on #invoice_campaign.invoice_id = invoice_comments.invoice_id 
left outer join film_campaign_standalone_invoice on #invoice_campaign.campaign_no = film_campaign_standalone_invoice.campaign_no 
ORDER BY		tran_date

DROP TABLE #invoice_campaign

return 0
GO
