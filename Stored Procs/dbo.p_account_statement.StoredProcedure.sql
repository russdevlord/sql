/****** Object:  StoredProcedure [dbo].[p_account_statement]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_account_statement]
GO
/****** Object:  StoredProcedure [dbo].[p_account_statement]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create proc [dbo].[p_account_statement]		@account_id						int,
											@accounting_period				datetime,
											@company_id						int,
											@campaign_no					int,
											@invoice_id						int
as

declare		@pay_company_id						int,
			@pay_account_id						int,
			@pay_campaign_no					int,
			@pay_campaign_status				varchar(1),
			@pay_invoice_date					datetime,
			@pay_gross_amount					money,
			@pay_outstanding					money,
			@pay_inv_view_invoice_id			int,
			@pay_inv_view_tran_date				datetime,
			@pay_inv_view_outstanding_amount	money,
			@pay_inv_view_allocated_current		money,
			@pay_inv_view_adjusted_current		money,
			@pay_inv_view_allocated_prior		money,
			@pay_inv_view_outstanding_current	money,
			@pay_inv_view_outstanding_30		money,
			@pay_inv_view_outstanding_60		money,
			@pay_inv_view_outstanding_90		money,
			@pay_inv_view_outstanding_120		money

set nocount on


create table #invoice_campaign
(
	company_id						int					not null,
	account_id						int					not null,
	invoice_id						int					null,
	campaign_no						int					null,
	invoice_total					money				null,
	tran_date						datetime			null,
	outstanding_amount				money				null default 0.00,
	outstanding_current				money				null default 0.00,
	outstanding_30					money				null default 0.00,
	outstanding_60					money				null default 0.00,
	outstanding_90					money				null default 0.00,
	outstanding_120					money				null default 0.00,
	adjusted_current				money				null default 0.00,
	allocated_current				money				null default 0.00,
	allocated_prior					money				null default 0.00,
	allocated_total					as					allocated_current + allocated_prior,
	campaign_status					varchar(1)			null,
	group_id						int					null,
	detail_desc						varchar(max)		null
)

insert	into #invoice_campaign ( 
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
		allocated_prior,
		group_id,
		detail_desc
		)
select			tran_view.company_id,
				tran_view.account_id,
				tran_view.campaign_no,
				tran_view.campaign_status,
				isnull(tran_view.invoice_id, -100),
				/*sum( case when tran_view.group_id = 1 and tran_view.detail_id = 2 then tran_view.gross_amount else null end) as invoice_total,
				max( case when tran_view.group_id = 1 and tran_view.detail_id = 2 then tran_view.invoice_date else null end) as tran_date ,*/
				sum(tran_view.gross_amount) as invoice_total,
				tran_view.invoice_date as tran_date ,
				sum( case when tran_view.group_id in ( 1,3,4 ) then  tran_view.gross_amount else 0 end) as outstanding_amount,		
				case when sum( case when tran_view.group_id in ( 1 ) and datediff( mm, tran_view.invoice_date, @accounting_period) = 0 then tran_view.gross_amount else 0 end) = 0 then 0 else
					sum( case when tran_view.group_id in ( 1 ) and datediff( mm, tran_view.invoice_date, @accounting_period) = 0 then tran_view.gross_amount else 0 end) + 
					sum( case when tran_view.group_id in ( 3, 4 ) and datediff( mm, tran_view.invoice_date, @accounting_period) = 0 then tran_view.gross_amount else 0 end) end as outstanding_current,
				case when sum( case when tran_view.group_id in ( 1 ) and datediff( mm, tran_view.invoice_date, @accounting_period) = 1 then tran_view.gross_amount else 0 end) = 0 then 0 else
					sum( case when tran_view.group_id in ( 1 ) and datediff( mm, tran_view.invoice_date, @accounting_period) = 1 then tran_view.gross_amount else 0 end) +
					sum( case when tran_view.group_id in ( 3, 4 ) and datediff( mm, tran_view.invoice_date, @accounting_period) between 0 and 1 then tran_view.gross_amount else 0 end) end as outstanding_30,
				case when sum( case when tran_view.group_id in ( 1 ) and datediff( mm, tran_view.invoice_date, @accounting_period) = 2 then tran_view.gross_amount else 0 end) = 0 then 0 else
					sum( case when tran_view.group_id in ( 1 ) and datediff( mm, tran_view.invoice_date, @accounting_period) = 2 then tran_view.gross_amount else 0 end) + 
					sum( case when tran_view.group_id in ( 3, 4 ) and datediff( mm, tran_view.invoice_date, @accounting_period) between 0 and 2 then tran_view.gross_amount else 0 end) end as outstanding_60,
				case when sum( case when tran_view.group_id in ( 1 ) and datediff( mm, tran_view.invoice_date, @accounting_period) = 3 then tran_view.gross_amount else 0 end) = 0 then 0 else
					sum( case when tran_view.group_id in ( 1 ) and datediff( mm, tran_view.invoice_date, @accounting_period) = 3 then tran_view.gross_amount else 0 end) + 
					sum( case when tran_view.group_id in ( 3, 4 ) and datediff( mm, tran_view.invoice_date, @accounting_period) between 0 and 3 then tran_view.gross_amount else 0 end) end as outstanding_90,
				case when sum( case when tran_view.group_id in ( 1 ) and datediff( mm, tran_view.invoice_date, @accounting_period) >= 4 then tran_view.gross_amount else 0 end) = 0 then 0 else
					sum( case when tran_view.group_id in ( 1 ) and datediff( mm, tran_view.invoice_date, @accounting_period) >= 4 then tran_view.gross_amount else 0 end) + 
					sum( case when tran_view.group_id in ( 3, 4 ) and datediff( mm, tran_view.invoice_date, @accounting_period) >= 0 then tran_view.gross_amount else 0 end) end as outstanding_120,
				sum( case when tran_view.group_id in ( 3, 4) and tran_view.tran_category <> 'C' then (case when tran_view.invoice_date = @accounting_period then tran_view.gross_amount else 0 end) else 0 end) as adjusted_current,
				sum( case when tran_view.group_id in ( 3) and tran_view.tran_category = 'C' then (case when tran_view.invoice_date = dateadd(dd,1,@accounting_period) then tran_view.gross_amount else 0 end) else 0 end) as allocated_current,
				sum( case when tran_view.group_id in ( 3, 4) then (case when tran_view.invoice_date < dateadd(dd,1,@accounting_period) then tran_view.gross_amount else 0 end) else 0 end) allocated_prior,
				tran_view.group_id,
				tran_view.detail_desc
from			v_company_account_campaign_combined_transactions tran_view
where			(( tran_view.invoice_id = @invoice_id or @invoice_id = 0 ) or tran_view.invoice_id is null )
and				( tran_view.account_id = @account_id or @account_id = 0 )
and				isnull(tran_view.account_id, -100) <> -100
and				( tran_view.campaign_no = @campaign_no or @campaign_no = 0)
and				( tran_view.company_id = @company_id or @company_id = 0 )
and				( tran_view.invoice_date <= dateadd(dd,1,@accounting_period)  or tran_view.invoice_date is null)
and				((( tran_view.group_id = 1 and tran_view.detail_id = 2 )  -- billing total
or				( tran_view.group_id = 3 and tran_view.detail_id = 2)		-- Payment Allocation 
or				( tran_view.group_id = 4 ) ))						-- reversal allocation
group by		tran_view.company_id,	
				tran_view.account_id,
				tran_view.campaign_no, 
				tran_view.campaign_status, 
				tran_view.invoice_id,
				tran_view.invoice_date,
				tran_view.group_id,
				tran_view.detail_desc
				
-- delete fully paid closed, expired, archieved campaign with no current period payments
delete	from #invoice_campaign
where	campaign_no in (	select campaign_no
							from #invoice_campaign
							where	campaign_status in ( 'X', 'Z')
							group by campaign_no)
and		campaign_no not in (	select campaign_no
							from #invoice_campaign
							where tran_date >= @accounting_period )

-- delete fully paid invoices with no current period payments
/*delete	from #invoice_campaign
where	( outstanding_amount = 0  and allocated_current = 0 )*/

-- in case no outstanding or paid invoices i.e. nothing to display insert a dummy row 
if (select count(*) from #invoice_campaign) = 0
	begin
		insert  #invoice_campaign (invoice_id, company_id, account_id, group_id)
		values(-100, @company_id, @account_id, 1 )
	end
	
-- result set
select 	temp.invoice_id,
		temp.campaign_no,
		temp.invoice_total,
		temp.tran_date,
		temp.outstanding_amount as outstanding_amount,
		null as balance_current,
		null as balance_prior,
		temp.adjusted_current as adjusted_current,
		temp.allocated_current as allocated_current,
		temp.allocated_prior as allocated_prior,
		temp.allocated_total as allocated_total,
		null as reversal_current,
		null as reversal_prior,
		null as reversal_total,
		temp.outstanding_current as outstanding_current,
		temp.outstanding_30 as outstanding_30,
		temp.outstanding_60 as outstanding_60,
		temp.outstanding_90 as outstanding_90,
		temp.outstanding_120 as outstanding_120,
		ac.account_name as statement_name,
		ac.address_1,
		ac.address_2,
		ac.town_suburb,
		ac.state_code,
		ac.postcode,
		case when temp.campaign_no is null then 'no transactions' else fc.product_desc end as product_desc,
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
		temp.group_id,
		temp.detail_desc
from	#invoice_campaign as temp 
		left outer join film_campaign as fc on temp.campaign_no = fc.campaign_no,
		account ac,
		company cp
where	temp.account_id = ac.account_id and
		temp.company_id = cp.company_id 
order by cp.company_id, 
		temp.campaign_no, 
		temp.tran_date asc
		
return 0
GO
