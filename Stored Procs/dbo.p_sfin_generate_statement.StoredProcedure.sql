/****** Object:  StoredProcedure [dbo].[p_sfin_generate_statement]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_generate_statement]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_generate_statement]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_generate_statement] @campaign_no			char(7),
                                      @screening_date		datetime,
												  @tran_date			datetime,
												  @cancel_type			char(1),
                                      @statement_id		integer OUTPUT
as

/*
 * Declare Variables
 */

declare @error        				integer,
        @rowcount     				integer,
        @errorode							integer,
		  @statement_no				integer,
		  @agency_id					integer,
		  @client_id					integer,
		  @line_no						integer,
		  @pay_count					integer,
		  @tran_type					integer,
		  @tran_id						integer,
		  @tran_csr_open				integer,
		  @min_camp_period			integer,
		  @prev_min_camp_period		integer,
		  @show_new_expiry			tinyint,
		  @statement_date				datetime,
		  @due_date						datetime,
		  @pay_date						datetime,
		  @start_date					datetime,
        @end_date						datetime,
		  @start_date_str				varchar(11),
		  @end_date_str				varchar(11),
		  @pay_date_str				varchar(11),
		  @name							varchar(50),
		  @addr1							varchar(50),
		  @addr2							varchar(50),
		  @statement_msg				varchar(255),
		  @line_desc					varchar(255),
		  @cancel_statement			char(1),
		  @agency_deal					char(1),
		  @cancel_code					char(1),
		  @state_code					char(3),
		  @postcode						char(5),
		  @town_suburb					char(30),
        @child_campaign				char(7),
		  @balance_forward			money,
		  @balance_30					money,
		  @balance_60					money,
		  @balance_90					money,
		  @balance_120					money,
		  @balance_outstanding    	money,
		  @prev_balance_120			money,
        @expirey_date				datetime,
        @campaign_start_date		datetime
		


/*
 *	Setup local values
 */

select @show_new_expiry = 0

if @screening_date is null
	select @cancel_statement = 'Y'
else
	select @cancel_statement = 'N'

/*
 * Begin Transaction
 */

begin transaction

/*
 *	Get Statement No
 */

select @statement_no = statement_no + 1,
		 @balance_forward = balance_outstanding,
		 @prev_min_camp_period = min_campaign_period,
		 @prev_balance_120 = balance_120
  from slide_statement
 where campaign_no = @campaign_no and
		 statement_no = ( select max(statement_no) 
                          from slide_statement
                         where campaign_no = @campaign_no )

if @statement_no is null
begin
	select @statement_no = 1
	select @balance_forward = 0
end

/*
 *	Get Statement Date and Due Date
 * -------------------------------
 * Statement Date is 28 Days prior to the Screening Date we are running the Billing Run For
 * Due Date is the 1 Day prior to the Screening Date
 *
 */

if(@cancel_statement = 'N')
begin
	select @statement_date = dateadd(dd,-28,@screening_date)
	select @due_date = dateadd(dd,-1,@screening_date)
end
else
begin
	select @statement_date = @tran_date
	select @due_date = @tran_date
end

/*
 *	Get correct Address Information
 */

select @agency_deal = agency_deal,
		 @agency_id = agency_id,
		 @client_id = client_id,
		 @campaign_start_date = start_date,
		 @expirey_date = dateadd(dd, ((min_campaign_period + bonus_period) * 7) - 1, start_date)
  from slide_campaign
 where campaign_no = @campaign_no

if(@expirey_date < @campaign_start_date)
begin
	select @expirey_date = @campaign_start_date
end

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
 * Set up statement message
 * ------------------------
 * Check campaign cancellation codes for special messages, and
 * if the enddate of any arrangement is null or is greater than or equal to	
 * billing run date (screening date - 28) then payment arrangments apply. 
 *
 */

if(@cancel_statement = 'Y')
begin

    /*
    * Cancellation
    */
	if @cancel_type = 'C' 
		select @statement_msg = 'CANCELLATION INVOICE' + char(13) + '8 weeks notice applied (Clause 13 of contract)'
	else if @cancel_type = 'S' /*Supercede*/
	begin

		/*
       * Select Child Campaign No
       */

		select @child_campaign = child_campaign
        from slide_family
       where parent_campaign = @campaign_no and
             relationship_type = 'S'

		if @child_campaign is null
			select @statement_msg = 'Supercede cancellation invoice - New billings to commence on new campaign.'
		else
			select @statement_msg = 'Supercede cancellation invoice - New billings to commence on campaign ' + @child_campaign + '.'

	end

end


/*
 * Check for Payment Arrangements
 */

if(@statement_msg is null)
begin

	if exists ( select 1
					  from credit_arrangement
					 where campaign_no = @campaign_no and
						  ( effective_to is null or
							 effective_to >= @statement_date) )
	begin
		select @statement_msg = 'Please Note - Payment arrangement conditions apply.'
	end

end

/*
 * Default Statement Message from Branch
 */

if(@statement_msg is null)
begin

	select @statement_msg = invoice_message
     from branch, slide_campaign
    where slide_campaign.campaign_no = @campaign_no and
          branch.branch_code = slide_campaign.branch_code

end

/*
 * Get a Statement Id
 */

execute @errorode = p_get_sequence_number 'slide_statement',5,@statement_id OUTPUT
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

insert into slide_statement (
       statement_id,
       campaign_no,
       screening_date,
       statement_no,
       statement_date,
       due_date,
       balance_forward,
       balance_outstanding,
       balance_current,
       balance_30,
       balance_60,
       balance_90,
       balance_120,
       balance_credit,
       balance_overdue,
       campaign_start,
       campaign_end,
       min_campaign_period,
       bonus_period,
       statement_name,
       address_1,
       address_2,
       town_suburb,
       state_code,
       postcode,
       statement_message )
select @statement_id, 
       sc.campaign_no,
       @screening_date,
       @statement_no,
       @statement_date,
       @due_date,
       @balance_forward,
       sc.balance_outstanding,       
       sc.balance_current,
       sc.balance_30,
       sc.balance_60,
       sc.balance_90,
       sc.balance_120,
       sc.balance_credit,
       sc.balance_30 + sc.balance_60 + sc.balance_90 + sc.balance_120, 
       sc.start_date,
       @expirey_date,
       sc.min_campaign_period,
       sc.bonus_period,
       @name,
       @addr1,
       @addr2,	
       @town_suburb,
       @state_code,	
       @postcode,
       @statement_msg
  from slide_campaign sc
 where campaign_no = @campaign_no

/*
 *	Associate Transactions with statement and generate any relevant lines.
 */

select @line_no = 0

/*
 *	Check for Lines for the top of the statement , ie no payments, and 8 or 12 weeks overdue
 */

select @balance_outstanding = balance_outstanding,
       @balance_30 = balance_30,
       @balance_60 = balance_60,
	    @balance_90 = balance_90,
	    @balance_120 = balance_120,
		 @min_camp_period = min_campaign_period
  from slide_campaign
 where campaign_no = @campaign_no

if(@statement_no > 1)
begin

	select @pay_count = count(tran_id)
	  from slide_transaction
	 where tran_category = 'C' and /*Active Credit - Deposit or Payment */
			 statement_id is null and
			 campaign_no = @campaign_no
	
	if @pay_count = 0 and @balance_outstanding > 0 
	begin

		/*
       * Check for any payments at all for the campaign.
       */

		select @pay_date = tran_date
		  from slide_transaction 
		 where tran_category = 'C' and /*Active Credit - Deposit or Payment*/
				 campaign_no = @campaign_no and
				 reversal = 'N' and
				 tran_date = ( select max(tran_date)
									  from slide_transaction
									 where tran_category = 'C' and /*Active Credit - Deposit or Payment*/
											 reversal = 'N' and
											 campaign_no = @campaign_no )
	
		if(@pay_date is null)
		begin

			select @line_desc = 'Our records indicate no Payment has been received.'
			exec @errorode = p_sfin_add_statement_line @statement_id, @line_no, @line_desc, 'N'
			if (@errorode !=0)
			begin
				rollback transaction
				return -1
			end
			select @line_no = @line_no + 1

		end
		else
		begin

			exec p_sfin_format_date @pay_date, 1, @pay_date_str OUTPUT

			select @line_desc = 'Our records indicate no Payment has been received since ' + @pay_date_str + '.'
			exec @errorode = p_sfin_add_statement_line @statement_id, @line_no, @line_desc, 'N'
			if (@errorode !=0)
			begin
				rollback transaction
				return -1
			end
			select @line_no = @line_no + 1
 
		end

	end			 

end

/*
 * Overdue Balance Messages
 */

if @balance_120 > 0
	if @prev_balance_120 > 0
		if @expirey_date < @due_date
			select @line_desc = 'Your account is 16 weeks in arrears. Please rectify immediately.'
		else
			select @line_desc = 'Your account is 16 weeks in arrears. Please rectify immediately to avoid having your credit facility cancelled.'
	else
		select @line_desc = 'Your account is 16 weeks in arrears.'

else if @balance_90 > 0
	select @line_desc = 'Your account is 12 weeks in arrears. Please rectify immediately.'
else if @balance_60 > 0
	select @line_desc = 'Your account is 8 weeks in arrears.'
else if @balance_30 > 0
	select @line_desc = 'Your account is 4 weeks in arrears.'
else
	select @line_desc = null
 
if(@line_desc is not null)
begin

	exec @errorode = p_sfin_add_statement_line @statement_id, @line_no, @line_desc, 'N'
	if (@errorode !=0)
	begin
		rollback transaction
		return -1
	end
	select @line_no = @line_no + 1

end

/*
 * Check for a statement line to be added in case of a cancellation
 * this happens when a the min campaign period decreases between statements.
 * and cant appear on the 1st invoice.
 */

if(@statement_no > 1)
begin

	if(@min_camp_period < @prev_min_camp_period)
	begin
		select @show_new_expiry = 1
	end

end
	

/*
 * Declare Cursors
 */

 declare tran_csr cursor static for
  select tran_id,
		   tran_type
    from slide_transaction
   where statement_id is null and
 	      campaign_no = @campaign_no
order by tran_date,tran_id                
     for read only

/*
 *	Check for any comments that go after or before any transaction types.
 */

open tran_csr
select @tran_csr_open = 1
fetch tran_csr into @tran_id, @tran_type
while (@@fetch_status = 0)
begin

	/*
    * Move Suspension from being a transaction to being a campaign line instead
    */

	if @tran_type = 70 /*Suspension*/
	begin

		/*
       * Create a statement line for the suspension
       */

		select @line_desc = tran_desc
        from slide_transaction
       where tran_id = @tran_id
			
		exec @errorode = p_sfin_add_statement_line @statement_id, @line_no, @line_desc, 'N'
		if (@errorode !=0)
		begin
			rollback transaction
			goto error
		end

		select @line_no = @line_no + 1
	
		/*
       * Create a line for the new expirey date.	
       */

		select @show_new_expiry = 1

		/*
       * Delete the transaction so it wont appear on any statements or trans listings.
       */

		delete slide_allocation 
       where to_tran_id = @tran_id

		delete slide_transaction
       where tran_id = @tran_id

	end
	else
	begin

		/*
       * Assign a line_no to this trans.
       */

		update slide_transaction
			set statement_id = @statement_id,
				 statement_line_no = @line_no
		 where tran_id = @tran_id

		select @line_no = @line_no + 1
	end

	/*
	 *	Check this trans to see if we need a comment line to be added after the transaction.
	 */

	if (@tran_type = 69) or (@tran_type = 71) /*Billing Credit */
	begin
		select @show_new_expiry = 1
	end		

	fetch tran_csr into @tran_id, @tran_type

end
close tran_csr
deallocate tran_csr
select @tran_csr_open = 0

/*
 *	Create the new expiry line if required at the end of the statement
 */

if(@show_new_expiry = 1 or @cancel_statement = 'Y')
begin

	if(@cancel_statement = 'Y')
	begin

		if exists ( select 1  
                    from campaign_event
                   where campaign_no = @campaign_no and
                         event_type = 'C' and
                         event_outstanding = 'Y' )  
		begin

			update campaign_event
            set event_outstanding = 'N'
          where campaign_no = @campaign_no and
                event_type = 'C'

			select @line_desc = 'Your Slide Campaign has been Cancelled.'
			exec @errorode = p_sfin_add_statement_line @statement_id, @line_no, @line_desc, 'Y'

			if(@errorode !=0)
			begin
				rollback transaction
				goto error
			end

			select @line_no = @line_no + 1

		end
	end

	select @line_desc = 'PLEASE NOTE NEW EXPIRY DATE.'
	exec @errorode = p_sfin_add_statement_line @statement_id, @line_no, @line_desc, 'Y'
	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end
	select @line_no = @line_no + 1

end

/*
 * Check to ensure at least 1 transaction or line has been added, 
 * if not add a line that says no lines appear on this statement
 */

if not exists (select 1 from slide_statement_line where statement_id = @statement_id) AND
   not exists (select 1 from slide_transaction where statement_id = @statement_id)
begin

	select @line_desc = 'No Transactions exist for this Invoice Period.'
	exec @errorode = p_sfin_add_statement_line @statement_id, @line_no, @line_desc, 'N'

	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end

	select @line_no = @line_no + 1

end	

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	if (@tran_csr_open = 1)
   begin
		close tran_csr
		deallocate tran_csr
	end

	return -1
GO
