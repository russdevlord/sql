/****** Object:  StoredProcedure [dbo].[p_film_campaign_close_check]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_close_check]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_close_check]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO










CREATE PROC [dbo].[p_film_campaign_close_check] @campaign_no		integer,
												@display_error	char(1)
as

/*
 * Declare Variables
 */

declare @error						integer,
        @rowcount						integer,
        @errorode								integer,
        @makeup_deadline		    datetime,
        @last_screening			    datetime,
        @last_status					char(1),
        @hold_count				    integer,
        @tran_count				    integer,
        @campaign_status		    char(1),
        @cinelight_status		    char(1),
        @inclusion_status		    char(1),
		@outpost_status				char(1),
        @max_bill						datetime,
        @max_cinelight_bill			datetime,
        @max_inclusion_bill			datetime,
        @max_outpost_bill			datetime,
        @bill_status				char(1),
        @balance_outstanding	    money,
	    @dandc_count				integer,
		@spot_count				    integer,
		@dc_count					integer,
		@balance_credit				money,
		@balance_current			money,
		@balance_30					money,
		@balance_60					money,
		@balance_90					money,
		@balance_120				money
		

/*
 * Get Campaign Information
 */

select 	@campaign_status 		= campaign_status,
		@cinelight_status 		= cinelight_status,
		@inclusion_status 		= inclusion_status,
		@outpost_status 		= outpost_status,
		@balance_outstanding	= balance_outstanding,
		@balance_credit			= balance_credit,
		@balance_current		= balance_current,
		@balance_30				= balance_30,
		@balance_60				= balance_60,
		@balance_90				= balance_90,
		@balance_120			= balance_120
  from film_campaign
 where campaign_no = @campaign_no

select @spot_count = count(spot_id)
  from campaign_spot
 where campaign_no = @campaign_no
 
/*
 * Check Status
 */

if @campaign_status != 'F' or @cinelight_status != 'F' or @inclusion_status != 'F' or @outpost_status != 'F'
begin
	if(@display_error='Y')
	   raiserror (50027, 11, 1)
	return -1
end

if @campaign_no = 209197
begin
	if(@display_error='Y')
	   raiserror (50027, 11, 1)
	return -1
end

if @campaign_no = 209504
begin
	if(@display_error='Y')
	   raiserror (50027, 11, 1)
	return -1
end

if @campaign_no = 209674
begin
	if(@display_error='Y')
	   raiserror (50027, 11, 1)
	return -1
end

if @campaign_no = 305400
begin
	if(@display_error='Y')
	   raiserror (50027, 11, 1)
	return -1
end

if @campaign_no = 305716
begin
	if(@display_error='Y')
	   raiserror (50027, 11, 1)
	return -1
end

if @campaign_no = 401999
begin
	if(@display_error='Y')
	   raiserror (50027, 11, 1)
	return -1
end

if @campaign_no = 402023
begin
	if(@display_error='Y')
	   raiserror (50027, 11, 1)
	return -1
end

/*
 * Check Billing Periods are Closed
 */

if(@spot_count > 0)
begin

    select @max_bill = max(billing_period)
      from campaign_spot 
     where campaign_no = @campaign_no

	select @max_cinelight_bill = max(billing_period)
      from cinelight_spot 
     where campaign_no = @campaign_no

	if @max_cinelight_bill > @max_bill
		select @max_bill = @max_cinelight_bill

	select @max_outpost_bill = max(billing_period)
      from outpost_spot 
     where campaign_no = @campaign_no

	if @max_outpost_bill > @max_bill
		select @max_bill = @max_outpost_bill

	select 	@max_inclusion_bill = max(billing_period)
	from	inclusion_spot
	where	campaign_no = @campaign_no           

	if @max_inclusion_bill > @max_bill
		select @max_bill = @max_inclusion_bill

    select @bill_status = status
      from accounting_period
     where end_date = @max_bill

    if(@bill_status <> 'X')
    begin
	    if(@display_error='Y')
			raiserror ('Error: Could Not close campaign as there are end dates after the most recent closed accounting_period. Close denied.', 16, 1)
	    return -1
    end


end

/*
 * Check Campaign has nothing Left Owing
 */

if(@balance_outstanding != 0)
begin
	if(@display_error='Y')
		raiserror ('Error: Could Not close campaign as there are outstanding balances. Close denied.', 16, 1)
	return -1
end

if(@balance_credit != 0)
begin
	if(@display_error='Y')
		raiserror ('Error: Could Not close campaign as there are outstanding credit balances. Close denied.', 16, 1)
	return -1
end

if(@balance_30 != 0)
begin
	if(@display_error='Y')
		raiserror ('Error: Could Not close campaign as there are outstanding 30 day balances. Close denied.', 16, 1)
	return -1
end

if(@balance_60 != 0)
begin
	if(@display_error='Y')
		raiserror ('Error: Could Not close campaign as there are outstanding 60 day balances. Close denied.', 16, 1)
	return -1
end

if(@balance_90 != 0)
begin
	if(@display_error='Y')
		raiserror ('Error: Could Not close campaign as there are outstanding 90 day balances. Close denied.', 16, 1)
	return -1
end

if(@balance_120 != 0)
begin
	if(@display_error='Y')
		raiserror ('Error: Could Not close campaign as there are outstanding 120 day balances. Close denied.', 16, 1)
	return -1
end


/*
 * Check Campaign has no Pending Transactions
 */

select @tran_count = count(tran_id)
  from campaign_transaction
 where campaign_no = @campaign_no and
       statement_id is null

if(@tran_count > 0)
begin
	if(@display_error='Y')
		raiserror ('Error: there are transactions that have still not gone on statements', 16, 1)
	return -1
end

/*
 * Check Campaign Has no outstanding delete charge amounts
 */

select @spot_count = 0

select @dandc_count = count(cs.spot_id)
  from campaign_spot cs,
	   delete_charge_spots dcs,
	   delete_charge dc
 where cs.campaign_no = @campaign_no and
       cs.dandc = 'Y' and
       dcs.source_dest = 'S' and
       cs.spot_id = dcs.spot_id and
       dc.delete_charge_id = dcs.delete_charge_id and
       dc.source_campaign = @campaign_no and
       dc.confirmed = 'Y'

select @dandc_count = @dandc_count + count(cs.spot_id)
  from cinelight_spot cs,
	   delete_charge_cinelight_spots dcs,
	   delete_charge dc
 where cs.campaign_no = @campaign_no and
       cs.dandc = 'Y' and
       dcs.source_dest = 'S' and
       cs.spot_id = dcs.spot_id and
       dc.delete_charge_id = dcs.delete_charge_id and
       dc.source_campaign = @campaign_no and
       dc.confirmed = 'Y'


select @spot_count = count(cs.spot_id)
  from campaign_spot cs
 where cs.campaign_no = @campaign_no and
       cs.dandc = 'Y'

select @spot_count = @spot_count + count(cs.spot_id)
  from cinelight_spot cs
 where cs.campaign_no = @campaign_no and
       cs.dandc = 'Y'

select @dc_count = @spot_count - @dandc_count

if(@dc_count > 0)
begin
	if(@display_error='Y')
		raiserror ('Error: Could Not close campaign as there are outstanding D&&C spots. Close denied.', 16, 1)
	return -1
end

/*
 * Return Success
 */

return 0
GO
