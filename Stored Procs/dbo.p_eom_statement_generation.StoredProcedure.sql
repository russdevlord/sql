/****** Object:  StoredProcedure [dbo].[p_eom_statement_generation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_statement_generation]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_statement_generation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_eom_statement_generation] @campaign_no 			int,
                                       @accounting_period	datetime
as

/*
 * Declare Variables
 */

declare @error						integer,
        @rowcount					integer,
        @errorode						integer,
        @balance_forward		money,
        @balance_outstanding	money,
        @balance_current		money,
        @balance_credit			money,
        @balance_30				money,
        @balance_60				money,
        @balance_90				money,
        @balance_120				money,
        @statement_id			integer,
	     @statement_name			varchar(50),
        @address_1				varchar(50),
        @address_2				varchar(50),
        @town_suburb				varchar(30),
        @state						varchar(3),
        @postcode					varchar(5),
        @agency_deal				char(1),
        @billing_agency			integer,
        @client_id				integer,
        @tran_count				integer,
        @branch_code				char(2),
        @branch_message			varchar(255)

/*
 * Get Transaction Count
 */

select @tran_count = count(tran_id)
  from campaign_transaction
 where campaign_no = @campaign_no

select @error = @@error
if(@error !=0)
begin
  	raiserror ('Error: Failed to Create Statements for Campaign %1!',11,1, @campaign_no)
	return -1
end

/*
 * Get Balance Forward
 */


  select @balance_forward = balance_outstanding
    from statement
   where campaign_no = @campaign_no
  and   entry_date in (select max(entry_date) from statement where campaign_no = @campaign_no)

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0)
begin
  	raiserror ('Error: Failed to Create Statements for Campaign %1!',11,1, @campaign_no)
	return -1
end

if(@rowcount = 0)
	select @balance_forward = 0

/*
 * Get Billing Details and Aged Balances
 */

select @agency_deal = agency_deal,
       @billing_agency = billing_agency,
       @client_id = client_id,
       @branch_code = branch_code,
       @balance_outstanding = balance_outstanding,
       @balance_current = balance_current,
       @balance_30 = balance_30,
       @balance_60 = balance_60,
       @balance_90 = balance_90,
       @balance_120 = balance_120,
       @balance_credit = balance_credit
  from film_campaign
 where campaign_no = @campaign_no

select @error = @@error
if(@error !=0)
begin
  	raiserror ('Error: Failed to Create Statements for Campaign %1!',11,1, @campaign_no)
	return @error
end

/*
 * Get Statement Address Information
 */

if(@agency_deal = 'Y')
	select @statement_name = agency_name,
          @address_1 = address_1,
          @address_2 = address_2,
          @town_suburb = town_suburb,
          @state = state_code,
          @postcode = postcode
     from agency
    where agency_id = @billing_agency
else
	select @statement_name = client_name,
          @address_1 = address_1,
          @address_2 = address_2,
          @town_suburb = town_suburb,
          @state = state_code,
          @postcode = postcode
     from client
    where client_id = @client_id

select @error = @@error
if(@error !=0)
begin
  	raiserror ('Error: Failed to Create Statements for Campaign %1!',11,1, @campaign_no)
	return @error
end

/*
 * Get Branch Message
 */

select @branch_message = convert(varchar(255), branch_message_text)
  from branch_message
 where branch_code = @branch_code and
       message_category_code = 'F'

/*
 * If this is the first statement and the balance is zero then
 */

if(@tran_count = 0 and @balance_outstanding = 0)
	return 0

/*
 * Begin Transaction
 */

begin transaction

/*
 * Get Statement Id
 */

execute @errorode = p_get_sequence_number 'statement', 5, @statement_id OUTPUT
if (@errorode !=0)
begin
	rollback transaction
  	raiserror ('Error: Failed to Create Statements for Campaign %1!',11,1, @campaign_no)
	return -1
end

/*
 * Create Statement
 */
			
insert into statement (
		 statement_id,
	    campaign_no,
	    accounting_period,
       balance_forward,
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
       statement_message,
	    entry_date ) values (
       @statement_id,
       @campaign_no,
       @accounting_period,
       @balance_forward,
       @balance_outstanding,
       @balance_current,
       @balance_30,
       @balance_60,
       @balance_90,
       @balance_120,
       @balance_credit,
	    @statement_name,
       @address_1,
       @address_2,
       @town_suburb,
       @state,
       @postcode,
       @branch_message,
       getdate() )

select @error = @@error
if (@error !=0)
begin
	rollback transaction
  	raiserror ('Error: Failed to Create Statements for Campaign %1!',11,1, @campaign_no)
	return -1
end	

/*
 * Update Campaign Transactions
 */

update campaign_transaction
   set statement_id = @statement_id
 where campaign_no = @campaign_no and
       statement_id is null

select @error = @@error
if (@error !=0)
begin
	rollback transaction
  	raiserror ('Error: Failed to Create Statements for Campaign %1!',11,1, @campaign_no)
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
