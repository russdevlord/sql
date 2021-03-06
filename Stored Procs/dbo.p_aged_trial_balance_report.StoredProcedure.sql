/****** Object:  StoredProcedure [dbo].[p_aged_trial_balance_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_aged_trial_balance_report]
GO
/****** Object:  StoredProcedure [dbo].[p_aged_trial_balance_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create proc [dbo].[p_aged_trial_balance_report]			@accounting_period			datetime,
														@country_code				char(1)

as

declare			@error					int,
				@account_id				int,
				@company_id				int,
				@campaign_no			int,
				@invoice_id				int		
				
create table #statement_to_run
(
	account_id				int,
	company_id				int,
	campaign_no				int,
	invoice_id				int
)

create table #statement_results
(
	invoice_id				int,
	campaign_no				int,
	invoice_total			money,
	tran_date				datetime,
	allocation_to_date		datetime,
	line_type				varchar(max),
	statement_name			varchar(max),
	address_1				varchar(max),
	address_2				varchar(max),
	town_suburb				varchar(max),
	state_code				varchar(max),
	postcode				varchar(max),
	product_desc			varchar(max),
	ba_address_1			varchar(max),
	ba_address_2			varchar(max),
	ba_address_3			varchar(max),
	ba_address_4			varchar(max),
	ba_address_5			varchar(max),
	company_id				int,
	company_desc			varchar(max),
	division_desc			varchar(max),
	abn						varchar(max),
	bsb						varchar(max),
	bank_account			varchar(max),
	account_id				int,
	country_code			char(1),
	agency_deal				char(1),
	account_type			char(1),
	accounting_period		datetime,
	group_id				int,
	detail_desc				varchar(max),
	reversal				char(1)
)

insert into		#statement_to_run
select			tran_view.account_id,
				tran_view.company_id,
				tran_view.campaign_no,
				null
FROM			v_company_account_campaign_combined_trans_all tran_view
left join		account AS acc on tran_view.account_id = acc.account_id
left outer join agency ON acc.agency_id = agency.agency_id 
left outer join client ON acc.client_id = client.client_id
WHERE			( tran_view.entry_date <= dateadd(dd,1,@accounting_period)  OR tran_view.entry_date IS NULL)
and				((( tran_view.group_id = 1 AND tran_view.detail_id = 2 )  -- Billing Total
OR				( tran_view.group_id = 3 AND tran_view.detail_id = 2)		-- Payment Allocation 
OR				( tran_view.group_id = 4 ) ))						-- Reversal Allocation
and				tran_view.company_id not in (3,4,6)
and				campaign_status <> 'X'
and				campaign_status <> 'Z'
and				isnull(tran_view.account_id, -100) <> -100
and				tran_view.country_code = @country_code
GROUP BY		tran_view.account_id,
				tran_view.company_id,
				tran_view.campaign_no
order by		tran_view.account_id,
				tran_view.company_id,
				tran_view.campaign_no		
				
insert into		#statement_results
select			isnull(tran_view.invoice_id, -100) as invoice_id,
				tran_view.campaign_no,
				sum(tran_view.gross_amount) as invoice_total,
				tran_view.invoice_date as tran_date,
				allocation_to_date,
				line_type,
				ac.account_name as statement_name,
				ac.address_1,
				ac.address_2,
				ac.town_suburb,
				ac.state_code,
				ac.postcode,
				case when tran_view.campaign_no is null then 'no transactions' else fc.product_desc end as product_desc,
				cp.address_1 as ba_address_1,
				cp.address_2 as ba_address_2,
				cp.address_3 as ba_address_3,
				cp.address_4 as ba_address_4,
				cp.address_5 as ba_address_5,
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
				accounting_period = @accounting_period,
				tran_view.group_id,
				tran_view.detail_desc,
				tran_view.reversal
from			#statement_to_run
inner join		v_company_account_campaign_combined_trans_all tran_view
on				#statement_to_run.account_id = tran_view.account_id
and				#statement_to_run.campaign_no = tran_view.campaign_no
and				#statement_to_run.company_id = tran_view.company_id
inner join		film_campaign fc on #statement_to_run.campaign_no = fc.campaign_no
inner join		account ac on #statement_to_run.account_id = ac.account_id
inner join		company cp on #statement_to_run.company_id = cp.company_id
where			isnull(tran_view.account_id, -100) <> -100
and				( tran_view.invoice_date <= dateadd(dd,1,@accounting_period)  or tran_view.invoice_date is null)
and				((( tran_view.group_id = 1 and tran_view.detail_id = 2 )  -- billing total
or				( tran_view.group_id = 3 and tran_view.detail_id = 2)		-- Payment Allocation 
or				( tran_view.group_id = 4 ) ))						-- reversal allocation
group by		tran_view.invoice_id,
				tran_view.campaign_no,
				line_type,
				tran_view.invoice_date,
				allocation_to_date,
				ac.account_name,
				ac.address_1,
				ac.address_2,
				ac.town_suburb,
				ac.state_code,
				ac.postcode,
				fc.product_desc,
				cp.address_1,
				cp.address_2,
				cp.address_3,
				cp.address_4,
				cp.address_5,
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
				tran_view.group_id,
				tran_view.detail_desc,
				tran_view.reversal

select			accounting_period,
				business_unit.business_unit_desc,
				branch.branch_name,   
				#statement_results.campaign_no,   
				film_campaign.product_desc,   
				client.client_name,   
				#statement_results.statement_name,   
				film_campaign.commission,   
				#statement_results.address_1,   
				#statement_results.address_2,   
				#statement_results.town_suburb,   
				#statement_results.state_code,   
				#statement_results.postcode,  
				invoice_id,
				invoice_total,   
				line_type,
				tran_date,
				allocation_to_date,
				country.country_name,
				first_name + ' ' + last_name as rep_name,
				campaign_status_desc,
				reversal
from			#statement_results
inner join 		film_campaign on #statement_results.campaign_no = film_campaign.campaign_no
inner join		business_unit on film_campaign.business_unit_id = business_unit.business_unit_id
inner join 		client on film_campaign.client_id = client.client_id
inner join 		branch on film_campaign.branch_code = branch.branch_code
inner join		country on  branch.country_code = country.country_code
inner join		sales_rep on film_campaign.rep_id = sales_rep.rep_id
inner join		campaign_status on film_campaign.campaign_status = campaign_status.campaign_status_code

return 0
GO
