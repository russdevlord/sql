/****** Object:  StoredProcedure [dbo].[p_aged_trial_balance]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_aged_trial_balance]
GO
/****** Object:  StoredProcedure [dbo].[p_aged_trial_balance]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_aged_trial_balance]  @campaign_no		char(7)
as

declare  @today	  			datetime,
			@agency_deal		char(1),
			@client_id			integer,
			@agency_id			integer,
			@spot_count			integer,
		   @phone				varchar(20),
			@client_name		varchar(50),
			@addr_1				varchar(50),
			@addr_2				varchar(50),
			@suburb				varchar(50),
			@postcode			char(5),
			@state				char(3),
			@cl_phone			char(20),
			@fax					char(20),
			@weeks_to_bill			integer,
			@payment_arrangement	char(1),
			@last_payment_date	datetime,
			@last_payment_amount	money

/*
 * Set up some local vars
 */

select @today = getdate()

select @agency_deal = agency_deal,
		 @client_id	= client_id,
		 @agency_id	= agency_id
  from slide_campaign
 where campaign_no = @campaign_no

/*
 * Set payment arrangement flag
 */

if exists ( select ca.credit_arrangement_id
				  from credit_arrangement ca
				 where ca.campaign_no = @campaign_no and 
						 ca.effective_from <= @today and
						 ca.effective_to >= @today)

	select @payment_arrangement = 'Y'
else
	select @payment_arrangement = 'N'

/*
 * Set last payment date
 */

select @last_payment_date = max(tran_date) 
   from slide_transaction st
  where st.campaign_no = @campaign_no and	 
	 	  st.gross_amount < 0 and
		  st.tran_category = 'C'

/*
 * Set last payment details
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
 * Weeks left to bill
 */

select @weeks_to_bill = count(scs.spot_id) 
  from slide_campaign_spot scs
 where (scs.billing_status = 'L' or scs.billing_status = 'U') and 
		 scs.campaign_no = @campaign_no

/*
 * Update address info.
 */

if @agency_deal = 'N'
begin
	select @client_name = client.client_name,
			 @addr_1		  = client.address_1,
			 @addr_2		  = client.address_2,
			 @suburb		  = client.town_suburb,
			 @postcode 	  = client.postcode,
			 @state		  = client.state_code,
			 @cl_phone 	  = client.phone,
			 @fax		 	  = client.fax
	  from client
	 where client.client_id = @client_id
end
else
begin
	select @client_name = ag.agency_name,
			 @addr_1		 = ag.address_1,
			 @addr_2		 = ag.address_2,
			 @suburb		 = ag.town_suburb,
			 @postcode	 = ag.postcode,
			 @state		 = ag.state_code,
			 @cl_phone	 = ag.phone,
			 @fax			 = ag.fax
	  from agency ag
	 where ag.agency_id = @agency_id
end

/*
 * Return Dataset
 */

select sc.campaign_no,
       sc.name_on_slide,
       sc.campaign_type,
       sc.campaign_status,
       sc.credit_status,
       sc.agency_deal,
       @client_name,
       @addr_1,
       @addr_2,
       @suburb,
       @postcode,
       @state,
       @cl_phone,
       @fax,
       @phone,
       sc.signatory,
      (rtrim(rep_a.last_name) + ', ' + rtrim(rep_a.first_name)),
       @weeks_to_bill,
       @payment_arrangement,
       sc.balance_30,
       sc.balance_60,
       sc.balance_90,
       sc.balance_120,
       sc.balance_current,
       sc.balance_credit,
       @last_payment_date,
       @last_payment_amount,
       employee.employee_name,
       sc.sort_key, 
       branch.branch_name,
      (rep_b.last_name + ', ' + rep_b.first_name)
  from slide_campaign sc,
     	 sales_rep rep_a,
     	 sales_rep rep_b,
	  	 branch,
       employee
 where sc.campaign_no = @campaign_no and
	 	 rep_a.rep_id = sc.service_rep and	
		 rep_b.rep_id = sc.contract_rep and
		 employee.employee_id = sc.credit_controller and
       branch.branch_code = sc.branch_code

return 0
GO
