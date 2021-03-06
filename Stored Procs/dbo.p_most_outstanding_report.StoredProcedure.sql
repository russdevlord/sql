/****** Object:  StoredProcedure [dbo].[p_most_outstanding_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_most_outstanding_report]
GO
/****** Object:  StoredProcedure [dbo].[p_most_outstanding_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_most_outstanding_report]  @mode				integer,
					@branch_code   char(1)
as
set nocount on 
/*
 * Declare Variables
 */

declare  @today	  					datetime,
		   @campaign_no				char(7),
         @last_payment_date		datetime,
         @last_payment_amount		money

/*
 * Create Temporary Table
 */

create table #items 
(
 	campaign_no				char(7)			null,
	branch_code				char(1)			null,
	name_on_slide			varchar(50)		null,
	campaign_type			char(1)			null,
	campaign_status		char(1)			null,
	credit_status			char(1)			null,
	payment_arrangement 	char(1)			null,
	balance_30				money				null,
	balance_60				money				null,
	balance_90				money				null,
	balance_120				money				null,
	balance_current		money				null,
	balance_credit			money				null,			
	last_payment_date		datetime			null,
	last_payment_amnt		money				null,
	credit_controller		integer			null
)

/*
 * Setup current datetime
 */

select @today = getdate()

/*
 * Insert campaigns into tempory table.
 */

insert into #items (
       campaign_no,	  
       branch_code,
       name_on_slide,
       campaign_status,  
       campaign_type,
       credit_status,
       credit_controller,
       balance_current,
       balance_credit,
       balance_30,
       balance_60,
       balance_90,
       balance_120 )
select sc.campaign_no,   
		 sc.branch_code,
 		 sc.name_on_slide,   
		 sc.campaign_status,
		 sc.campaign_type,
		 sc.credit_status,
		 sc.credit_controller,   
		 sc.balance_current,   
       sc.balance_credit,
		 sc.balance_30,   
	 	 sc.balance_60,   
		 sc.balance_90,   
		 sc.balance_120
  from slide_campaign sc
 where ( @mode = 1 and
        sc.branch_code = @branch_code and
		 ( sc.balance_90 > 0 or 
		  sc.balance_120 > 0 ) ) or
		 (@mode = 2 and
		  sc.credit_status = 'D' and
        sc.branch_code = @branch_code )

 declare item_csr cursor static for
  select campaign_no
    from #items
order by campaign_no
     for read only
/*
 * Loop Entries
 */
open item_csr
fetch item_csr into @campaign_no
while(@@fetch_status = 0)
begin
	
	/*
    * Initialise Payment Amount and Date Variables
    */

	select @last_payment_date = NULL,
          @last_payment_amount = NULL

	/*
    * Set Payment Arrangement Flag
    */

	update #items
		set payment_arrangement = 'Y'
    where #items.campaign_no = @campaign_no and
          exists ( select ca.credit_arrangement_id
							from credit_arrangement ca
						  where ca.campaign_no = @campaign_no and 
								  ca.effective_from <= @today and
								  ca.effective_to >= @today)


	/*
	 * Set Last Payment Date
	 */
	
	select @last_payment_date = max(tran_date) 
		from slide_transaction st
	  where st.campaign_no = @campaign_no and	 
			  st.gross_amount < 0 and
			  st.tran_category = 'C'

	/*
	 * Set Last Payment Amount
	 */
	
	if @last_payment_date is not null
	begin
		select @last_payment_amount = st.gross_amount
		  from slide_transaction st 
		 where st.campaign_no = @campaign_no and	 
				 st.gross_amount < 0 and
				 st.tran_category = 'C' and
				 st.tran_id = (select max(tran_id) 
									  from slide_transaction
									 where campaign_no = @campaign_no and	 
											 gross_amount < 0 and
											 tran_category = 'C' and
											 tran_date = @last_payment_date)	
	end

	/*
    * Update Payment Details
    */

	update #items
		set last_payment_amnt = @last_payment_amount,
			 last_payment_date = @last_payment_date			
    where #items.campaign_no = @campaign_no

	/*
    * Fetch Next
    */

	fetch item_csr into @campaign_no

end
close item_csr
deallocate item_csr

/*
 * Return Dataset
 */

select campaign_no,
       branch_code,
       name_on_slide,
       campaign_type,
       campaign_status,
       credit_status,
       payment_arrangement,
       balance_30,
       balance_60,
       balance_90,
       balance_120,
       balance_current,
       balance_credit,
       last_payment_date,
       last_payment_amnt,
       credit_controller,
       @mode as report_type
  from #items

/*
 * Return
 */

return 0
GO
