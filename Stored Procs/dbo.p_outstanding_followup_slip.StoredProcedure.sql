/****** Object:  StoredProcedure [dbo].[p_outstanding_followup_slip]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_outstanding_followup_slip]
GO
/****** Object:  StoredProcedure [dbo].[p_outstanding_followup_slip]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_outstanding_followup_slip] @campaign_no	char(7),
													 @title			varchar(30)
as
set nocount on 
/*
 * Decalre Variables
 */

declare	@action_date		datetime,
			@agency_deal		char(1),
			@client_id			integer,
			@agency_id			integer,
         @spot_count			integer,
			@desc1				varchar(255),
			@desc2				varchar(255),
			@desc3				varchar(255),
			@desc4				varchar(255),
			@prev_action_user integer,
			@prev_action_date	datetime,
			@client_name		varchar(50),
			@addr_1				varchar(50),
			@addr_2				varchar(50),
			@suburb				varchar(50),
			@postcode			char(5),
			@state				char(3),
			@cl_phone			char(20),
			@fax					char(20),
         @service_rep		varchar(60),
         @contract_rep		varchar(60)


--Get weeks billed.
select @spot_count = count(scs.spot_id) 
  from slide_campaign_spot scs
 where scs.billing_status = 'B' and 
		 scs.campaign_no = @campaign_no

select @agency_deal = agency_deal,
       @client_id = client_id,
       @agency_id = agency_id
  from slide_campaign
 where campaign_no = @campaign_no

-- Update address info.
if @agency_deal = 'N'
begin
	select @client_name 	= client.client_name,
			 @addr_1			= client.address_1,
			 @addr_2			= client.address_2,
			 @suburb			= client.town_suburb,
			 @postcode	 	= client.postcode,
			 @state		 	= client.state_code,
			 @cl_phone	 	= client.phone,
			 @fax		 		= client.fax
	  from client
	 where client.client_id = @client_id
end
else
begin
	select @client_name = ag.agency_name,
			 @addr_1		  = ag.address_1,
			 @addr_2		  = ag.address_2,
			 @suburb		  = ag.town_suburb,
			 @postcode	  = ag.postcode,
			 @state		  = ag.state_code,
			 @cl_phone	  = ag.phone,
			 @fax			  = ag.fax
	  from agency ag
	 where ag.agency_id = @agency_id
end
		
--Update Previous Followup details 
--Dont need to consider the case where action_Date is not null, as we are only selecting
--entries that have not been actioned.
--Reset vars 1st
select	@prev_action_date = service_diary.action_date,
			@prev_action_user = service_diary.action_user,
			@desc1 = isnull(service_diary.action_comm1,''),
			@desc2 = isnull(service_diary.action_comm2,''),
			@desc3 = isnull(service_diary.action_comm3,''),
			@desc4 = isnull(service_diary.action_comm4,'')
 FROM service_diary
WHERE (service_diary.action_flag = 'Y') AND  
		(service_diary.campaign_no = @campaign_no) and
		(service_diary.action_date = (select max(sd.action_date)
												 from service_diary sd
												 where sd.campaign_no = @campaign_no and sd.action_flag = 'Y') ) AND  
		(service_diary.entry_no =    (select max(sd.entry_no)
												  from service_diary sd
												 where sd.campaign_no = @campaign_no and sd.action_flag = 'Y') ) 


select @service_rep = sr.last_name + ', ' + sr.first_name
  from sales_rep sr,
       slide_campaign sc
 where sr.rep_id = sc.service_rep and
       sc.campaign_no = @campaign_no

select @contract_rep = sr.last_name + ', ' + sr.first_name
  from sales_rep sr,
       slide_campaign sc
 where sr.rep_id = sc.contract_rep and
       sc.campaign_no = @campaign_no
 
/*
 * Return Dataset
 */

select b.branch_code,   
 		 sc.campaign_no,   
 		 sc.name_on_slide,   
		 sc.signatory,   
		 sc.phone,   
		 sc.campaign_status,   
		 sc.credit_controller,   
		 sc.start_date,   
   	 sc.min_campaign_period,   
   	 sc.bonus_period,
		 sc.balance_current,   
       sc.balance_credit,
		 sc.balance_30,   
	 	 sc.balance_60,   
		 sc.balance_90,   
		 sc.balance_120,   
		 (sc.gross_contract_value / sc.orig_campaign_period),
		 @spot_count,
		 @service_rep,   
		 @contract_rep,   
		 b.service_message,
		 sc.agency_deal,
	 	 @client_name,
		 @addr_1,
		 @addr_2,
		 @suburb,
		 @postcode,
		 @state,
		 @cl_phone,
		 @fax,
  		 @prev_action_date,
		 @prev_action_user,
		 @desc1,
		 @desc2,
		 @desc3,
		 @desc4,
   		    @title,
		 sc.campaign_notes,
		 sc.contact
  from slide_campaign sc,
		 branch b
 where b.branch_code = sc.branch_code and
       sc.campaign_no = @campaign_no

/*
 * Return
 */

return 0
GO
