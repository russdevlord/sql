/****** Object:  StoredProcedure [dbo].[p_sfin_eom_statement_gen]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_eom_statement_gen]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_eom_statement_gen]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_eom_statement_gen] @accounting_period		datetime
as

/*
 * Declare Variables
 */

declare @error        				integer,
        @rowcount     				integer,
        @errorode							integer,
		  @statement_id				integer,
		  @agency_id					integer,
		  @client_id					integer,
		  @name							varchar(50),
		  @addr1							varchar(50),
		  @addr2							varchar(50),
		  @agency_deal					char(1),
		  @state_code					char(3),
		  @postcode						char(5),
		  @campaign_no				char(7),
		  @town_suburb					varchar(30)

/*
 * Begin Transaction
 */

begin transaction

declare 	campaign_csr cursor static forward_only for
  select slide_campaign.campaign_no
    from slide_campaign,   
         branch,   
         branch_online  
   where slide_campaign.branch_code = branch.branch_code and  
         slide_campaign.branch_code = branch_online.branch_code and  
         slide_campaign.is_closed = 'N' and
       ( slide_campaign.is_official = 'Y' or
         slide_campaign.start_date is not null or
         slide_campaign.balance_outstanding <> 0 )
order by slide_campaign.campaign_no ASC   


open campaign_csr 
fetch campaign_csr into @campaign_no
while(@@fetch_status=0)
begin
	
	/*
	 *	Get correct address information
	 */
	
	select @agency_deal = agency_deal,
			 @agency_id = agency_id,
			 @client_id = client_id
	  from slide_campaign
	 where campaign_no = @campaign_no
	
	if(@agency_deal = 'Y')
	begin
	
		select @name 			= ag.agency_name,
				 @addr1		 	= ag.address_1,
				 @addr2		 	= ag.address_2,
				 @town_suburb 	= ag.town_suburb,
				 @postcode	 	= ag.postcode,
				 @state_code	= ag.state_code
		  from agency ag
		 where ag.agency_id = @agency_id
	
	end
	else
	begin
	
		select @name 			= client.client_name,
				 @addr1		 	= client.address_1,
				 @addr2		 	= client.address_2,
				 @town_suburb	= client.town_suburb,
				 @postcode	 	= client.postcode,
				 @state_code	= client.state_code
		  from client
		 where client.client_id = @client_id
	
	end
			
	
	
	/*
	 * Call Balance Update
	 */
	
	execute @errorode = p_sfin_slide_campaign_balance @campaign_no
	if (@errorode !=0)
	begin
		rollback transaction
		raiserror ('Error : Failed to create accounting statement for Slide Campaign %1!', 11, 1, @campaign_no)
		return -1
	end
	
	/*
	 * Get an accounting statement id
	 */
	                                        
	execute @errorode = p_get_sequence_number 'slide_accounting_statement',5,@statement_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		raiserror ('Error : Failed to create accounting statement for Slide Campaign %1!', 11, 1, @campaign_no)
		return -1
	end
	
	/*
	 * Create Record
	 */
	
	insert into slide_accounting_statement (
	       statement_id,
	       accounting_period,
	       campaign_no,
	       name_on_slide,
	       balance_outstanding,
	       balance_current,
	       balance_30,
	       balance_60,
	       balance_90,
	       balance_120,
	       balance_credit,
	       statement_name,
	       address_1,
	       address_2,
	       town_suburb,
	       state_code,
	       postcode,
	       campaign_status,
	       campaign_type,
	       credit_status )
	select @statement_id, 
	       @accounting_period,
	       @campaign_no,
	       sc.name_on_slide,
	       sc.balance_outstanding,
	       sc.balance_current,
	       sc.balance_30,
	       sc.balance_60,
	       sc.balance_90,
	       sc.balance_120,
	       sc.balance_credit,
	       @name,
	       @addr1,
	       @addr2,	
	       @town_suburb,
	       @state_code,	
	       @postcode,
	       sc.campaign_status,
	       sc.campaign_type,
	       sc.credit_status
	  from slide_campaign sc
	 where campaign_no = @campaign_no
	
	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		raiserror ('Error : Failed to create accounting statement for Slide Campaign %1!', 11, 1, @campaign_no)
		return -1
	end	

	fetch campaign_csr into @campaign_no
end

deallocate campaign_csr

/*
 * Commit and Return
 */

commit transaction
return 0
GO
