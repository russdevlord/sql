/****** Object:  StoredProcedure [dbo].[p_film_statement]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_statement]
GO
/****** Object:  StoredProcedure [dbo].[p_film_statement]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[p_film_statement]		@campaign_no			int,
										@accounting_period		datetime

as

declare		@error			int,
			@tran_id		int,
			@trantype_id	int,
			@exists			int,
			@tran_cat_code	char(1)


create table #statement (
	campaign_no				int				null,   
	balance_current			money			null,   
	balance_30				money			null,   
	balance_60				money			null,   
	balance_90				money			null,   
	balance_120				money			null,   
	accounting_period		datetime		null,   
	balance_forward			money			null,   
	balance_outstanding		money			null,   
	balance_credit			money			null,   
	statement_name			varchar(50)		null,   
	address_1				varchar(50)		null,   
	address_2				varchar(50)		null,   
	town_suburb				varchar(30)		null,   
	state_code				char(3)			null,   
	postcode				char(5)			null,   
	product_desc			varchar(100)	null,   
	nett_amount				money			null,   
	gst_amount				money			null,   
	gross_amount			money			null,   
	tran_desc				varchar(255)	null,   
	tran_notes				varchar(255)	null,  
	tran_id					int				null,   
	tran_date				datetime		null,   
	country_code			char(1)			null,   
	agency_deal				char(1)			null,   
	statement_id			int				null,   
	address_address_1		varchar(50)		null,   
	address_address_2		varchar(50)		null,   
	address_address_3		varchar(50)		null,   
	address_address_4		varchar(50)		null,   
	address_address_5		varchar(50)		null,   
	statement_message		varchar(255)	null,   
	tran_category			char(1)			null,
	business_unit_id		int 			null 
)

insert 		into #statement
SELECT	sa.campaign_no,   
		sa.balance_current,   
		sa.balance_30,   
		sa.balance_60,   
		sa.balance_90,   
		sa.balance_120,   
		sa.accounting_period,   
		sa.balance_forward,   
		sa.balance_outstanding,   
		sa.balance_credit,   
		sa.statement_name,   
		sa.address_1,   
		sa.address_2,   
		sa.town_suburb,   
		sa.state_code,   
		sa.postcode,   
		film_campaign.product_desc,   
		campaign_transaction.nett_amount,   
		campaign_transaction.gst_amount,   
		campaign_transaction.gross_amount,   
		campaign_transaction.tran_desc,   
		campaign_transaction.tran_notes,  
		campaign_transaction.tran_id,   
		campaign_transaction.tran_date,   
		branch.country_code,   
		film_campaign.agency_deal,   
		sa.statement_id,   
		branch_address.address_1,   
		branch_address.address_2,   
		branch_address.address_3,   
		branch_address.address_4,   
		branch_address.address_5,   
		sa.statement_message,   
		campaign_transaction.tran_category,
		film_campaign.business_unit_id  
FROM	statement AS sa LEFT OUTER JOIN
		campaign_transaction ON sa.statement_id = campaign_transaction.statement_id INNER JOIN
		film_campaign ON sa.campaign_no = film_campaign.campaign_no INNER JOIN
		branch ON film_campaign.branch_code = branch.branch_code INNER JOIN
		branch_address ON branch.branch_code = branch_address.branch_code
WHERE	(campaign_transaction.show_on_statement = 'Y') 
AND		(sa.campaign_no = @campaign_no) 
AND		(sa.accounting_period = @accounting_period) 
AND		(branch_address.address_category = 'FRM')

declare		statement_csr cursor static for
select		distinct tran_id
from		#statement
order by 	tran_id
for			read only

open statement_csr
fetch statement_csr into @tran_id
while(@@fetch_status=0)
begin

	select 	@exists = 0

	select 	@trantype_id = tran_type,
			@tran_cat_code = tran_category_code
	from 	campaign_transaction,
			transaction_type
	where 	tran_id = @tran_id
	and		campaign_transaction.tran_type = transaction_type.trantype_id

	
	if @tran_cat_code = 'B'
	begin
		select 	@exists = count(allocation_id)
		from	transaction_allocation,
				campaign_transaction
		where	to_tran_id = @tran_id
		and		from_tran_id = campaign_transaction.tran_id
		and		campaign_transaction.tran_type = 33 -- Group M discount
	end
	else if @tran_cat_code = 'Z'
	begin
		select 	@exists = count(ta1.allocation_id)
		from	transaction_allocation ta1,
				campaign_transaction ct1,
				transaction_allocation ta2,
				campaign_transaction ct2
		where	ta1.from_tran_id = @tran_id
		and		ta1.to_tran_id = ct1.tran_id
		and		ta2.to_tran_id = ct1.tran_id
		and		ta2.from_tran_id = ct2.tran_id
		and		ct2.tran_type = 33 -- Group M discount
	end
	
	if @exists > 0
	begin
		update 	#statement 
		set		nett_amount = nett_amount * 0.98,
				gst_amount = gst_amount * 0.98,
				gross_amount = gross_amount * 0.98
		where	tran_id = @tran_id
	end

	fetch statement_csr into @tran_id
end

select  campaign_no,   
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
		statement_id,   
		address_address_1,   
		address_address_2,   
		address_address_3,   
		address_address_4,   
		address_address_5,   
		statement_message,   
		tran_category,
		business_unit_id  
from	#statement

return 0
GO
