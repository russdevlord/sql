/****** Object:  StoredProcedure [dbo].[p_account_statement_breakdown]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_account_statement_breakdown]
GO
/****** Object:  StoredProcedure [dbo].[p_account_statement_breakdown]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[p_account_statement_breakdown] @account_id integer, @accounting_period datetime

as

set nocount on 

declare @error     					integer,
        @rowcount       			integer,
        @invoice_date			    datetime,
        @campaign_no				integer,
        @product_desc				varchar(100),
        @tran_id					integer,
        @spot_tran_id				integer,
        @spot_tran_desc				varchar(100),
        @tran_desc1					varchar(100),
        @tran_desc2					varchar(100),
        @tran_desc3					varchar(100),
        @tran_date					datetime,
        @spot_id 					integer,
        @desc_loop					tinyint,
        @account_name               varchar(50),
        @invoice_id                 int,
		@company_id					int


create table #bill_trans (
    invoice_date			datetime			null,
    campaign_no				integer				null,
    product_desc			varchar(100)		null,
    tran_id					integer				null,
    tran_desc1				varchar(100)		null,
    tran_desc2				varchar(100)		null,
    tran_desc3				varchar(100)		null,
    tran_date				datetime			null,
    account_name			varchar(50)         null,
    invoice_id				int                 null,
	account_id				int                 null,
    accounting_period       datetime            null,
	company_id				int					null
)

-- Loop Billing Transactions
declare 	bill_csr cursor static for
select	inv.invoice_date,
		fc.campaign_no,
		fc.product_desc,
		ct.tran_id,
		ct.tran_date,
		a.account_name,
		inv.invoice_id,
		@accounting_period,
		company_id  = (case fc.branch_code When 'Z' Then 2 Else ( case fc.business_unit_id When 6 Then 3 Else 1 End) End)
from 	invoice inv,
		film_campaign fc,
		campaign_transaction ct,
		account a,
		transaction_type tt,
		accounting_period ap
where	ct.campaign_no = fc.campaign_no 
and		inv.invoice_id = ct.invoice_id 
and		tt.tran_category_code = 'B' 
and		ct.tran_type = tt.trantype_id
and		ct.show_on_statement = 'Y'
and		ct.nett_amount >= 0 
and		ct.account_id = a.account_id
and		ct.tran_date >= ap.benchmark_start
and		ct.tran_date <= ap.benchmark_end
and		ap.benchmark_end = @accounting_period
and		inv.account_id = @account_id  
and		inv.account_id = a.account_id 
order by	ct.tran_id
for read only

open bill_csr
fetch bill_csr into @invoice_date, @campaign_no, @product_desc, @tran_id, @tran_date, @account_name, @invoice_id, @accounting_period, @company_id
while(@@fetch_status = 0)
begin

	select @spot_id = null

	--Get Spot Id
	select	@spot_id = max(spot_id)
	from	campaign_spot
    where	tran_id = @tran_id

	--Build Transaction Information
	if(@spot_id is not null)
	begin
		select	@desc_loop = 0

		declare spot_csr cursor static for
		 select ct.tran_id,
		        ct.tran_desc
		   from film_spot_xref fsx,
		        campaign_transaction ct
		  where fsx.spot_id = @spot_id and
		        fsx.tran_id = ct.tran_id
		
		--Loop Spot Transactions
		open spot_csr
		fetch spot_csr into @spot_tran_id, @spot_tran_desc
		while(@@fetch_status = 0)
		begin
			
			select @desc_loop = @desc_loop + 1

			if(@desc_loop = 1)
			begin
				select @tran_desc1 = @spot_tran_desc + ' - Ref: ' + convert(varchar(10),@spot_tran_id)
			end

			if(@desc_loop = 2)
			begin
				select @tran_desc2 = @spot_tran_desc + ' - Ref: ' + convert(varchar(10),@spot_tran_id)
			end

			if(@desc_loop = 3)
			begin
				select @tran_desc3 = @spot_tran_desc + ' - Ref: ' + convert(varchar(10),@spot_tran_id)
			end

			fetch spot_csr into @spot_tran_id, @spot_tran_desc
			
		end
		close spot_csr
		deallocate spot_csr

		insert into #bill_trans (
			invoice_date,
			campaign_no,
			product_desc,
			tran_id,
			tran_desc1,
			tran_desc2,
			tran_desc3,
			tran_date,
			account_name,
			invoice_id,
			account_id,
			accounting_period,
			company_id ) 
		values (
			@invoice_date,
			@campaign_no,
			@product_desc,
			@tran_id,
			@tran_desc1,
			@tran_desc2,
			@tran_desc3,
			@tran_date,
			@account_name,
			@invoice_id,
			@account_id,
			@accounting_period,
			@company_id )

	end
	fetch bill_csr into @invoice_date, @campaign_no, @product_desc, @tran_id, @tran_date, @account_name, @invoice_id, @accounting_period, @company_id

end
close bill_csr
deallocate bill_csr

--Return Dataset
select	invoice_date,
			campaign_no,
			product_desc,
			tran_id,
			tran_desc1,
			tran_desc2,
			tran_desc3,
			tran_date,
			account_name,
			invoice_id,
			account_id,
			accounting_period,
			company_id
from	#bill_trans
order by tran_id

return 0

GRANT EXECUTE ON dbo.p_account_statement_breakdown to public
GO
