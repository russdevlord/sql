/****** Object:  StoredProcedure [dbo].[p_statement_listing]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statement_listing]
GO
/****** Object:  StoredProcedure [dbo].[p_statement_listing]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_statement_listing] @screening_date		datetime
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare 	@error          			integer,
			@rowcount					integer,
			@campaign_no				char(7),
			@name_on_slide				varchar(50),
			@run_date					datetime,
			@campaign_start			datetime,
			@campaign_end				datetime,
			@balance_forward			money,
			@balance_outstanding		money,
			@paid_amount				money,
			@adjust_amount				money,
			@billed_amount				money,
			@branch_name				varchar(50),
			@statementid				integer

/*
 * Create temp table 
 */

create table #temp
(
	billing_date			datetime		null,
	campaign_no				char(7) 		null,
	name_on_slide			varchar(50)	null,
	campaign_start			datetime		null,
	campaign_end			datetime		null,
	balance_forward		money			null,
	balance_outstanding	money			null,
	paid_amount				money			null,
	adjust_amount			money			null,
	billed_amount			money			null,
	branch_name				varchar(50) null
)

/*
 * Calculate Billing Date
 */

select @run_date = dateadd(dd, -28, @screening_date)

/*
 * Get statement list
 */

declare statement_csr cursor static for 
 select statement_id
   from slide_statement
  where screening_date = @screening_date
    for read only

/*
 * Loop Cursor
 */
open statement_csr
fetch statement_csr into @statementid
while (@@fetch_status = 0)
begin

	select @balance_forward = slide_statement.balance_forward,
          @balance_outstanding = slide_statement.balance_outstanding,
          @campaign_start = slide_statement.campaign_start,
          @campaign_end = slide_statement.campaign_end,
          @campaign_no = slide_campaign.campaign_no,
          @name_on_slide = slide_campaign.name_on_slide,
          @branch_name = branch.branch_name
     from slide_statement,
          slide_campaign,
          branch
    where slide_statement.statement_id = @statementid and
          slide_statement.campaign_no = slide_campaign.campaign_no and
          slide_campaign.branch_code = branch.branch_code

	/*
	 * Get Billed Amount
	 */

	select @billed_amount = sum(gross_amount)
     from slide_transaction
    where statement_id = @statementid and
          ( tran_category = 'B' or 
            tran_category = 'Z')

	/*
	 * Get Paid Amount
	 */

	select @paid_amount = sum(gross_amount)
     from slide_transaction
    where statement_id = @statementid and
          tran_category = 'C'
           

	/*
	 * Get Adjustment Amount
	 */

	select @adjust_amount = sum(gross_amount)
     from slide_transaction
    where statement_id = @statementid and
          tran_category <> 'C' and
          tran_category <> 'B' and
          tran_category <> 'Z' 

	/*
	 * Insert into temp table
	 */
	
	insert into #temp values (
          @run_date,
          @campaign_no,
          @name_on_slide,
          @campaign_start,
          @campaign_end,
          @balance_forward,
          @balance_outstanding,	
          @paid_amount,
          @adjust_amount,
          @billed_amount,
          @branch_name )

	fetch statement_csr into @statementid

end

deallocate statement_csr
/*
 * Return Dataset
 */

select * from #temp

/*
 * Return
 */

return 0
GO
