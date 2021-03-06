/****** Object:  StoredProcedure [dbo].[p_statrev_create_campaign_avgs]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_create_campaign_avgs]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_create_campaign_avgs]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_statrev_create_campaign_avgs]		@campaign_no		int

as

declare		@error								int,
					@revision_group				int,
					@revenue					numeric(23,15),
					@revenue_total				numeric(23,15),
					@no_spots					numeric(23,15),
					@rows						int,
					@accounting_period			datetime,
					@previous_period			datetime,
					@revenue_check				numeric(38,30),
					@revenue_diff				numeric(38,30),
					@rate						numeric(38,30),
					@last_period				datetime,
					@period_cut_off				datetime,
					@first_period				datetime,
					@campaign_status			char(1)

set nocount on


select 		@campaign_status = campaign_status
from 		film_campaign
where 		campaign_no = @campaign_no

if @campaign_status = 'F' or @campaign_status = 'X'
	return 0


begin transaction

delete	statrev_spot_rates
from	film_campaign
where	statrev_spot_rates.campaign_no = film_campaign.campaign_no
and		statrev_spot_rates.campaign_no  = @campaign_no
and		business_unit_id = 2
and		revenue_group = 2

select 		@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error deleting orphan business unit stat rev rates', 16, 1)
	return -1
end	

delete	statrev_spot_rates
from	film_campaign
where	statrev_spot_rates.campaign_no = film_campaign.campaign_no
and		statrev_spot_rates.campaign_no  = @campaign_no
and		business_unit_id = 3
and		revenue_group = 1

select 		@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error deleting orphan business unit stat rev rates', 16, 1)
	return -1
end	

delete	statrev_spot_rates
where	campaign_no = @campaign_no
and		revenue_group in (50, 53, 100, 101, 150, 160)
and		spot_id not in (select spot_id from outpost_spot where campaign_no = @campaign_no)

select 		@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error deleting orphan spots stat rev rates', 16, 1)
	return -1
end	

delete	statrev_spot_rates
where	campaign_no = @campaign_no
and		revenue_group in (1, 2, 3, 8, 9, 10, 11)
and		spot_id not in (select spot_id from campaign_spot where campaign_no = @campaign_no)
and		spot_id not in (select spot_id from inclusion_spot where  campaign_no = @campaign_no)

select 		@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error deleting orphan spots stat rev rates', 16, 1)
	return -1
end	

delete	statrev_spot_rates
where	campaign_no = @campaign_no
and		revenue_group in (4)
and		spot_id not in (select spot_id from cinelight_spot where campaign_no = @campaign_no)

select 		@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error deleting orphan spots stat rev rates', 16, 1)
	return -1
end	

delete	statrev_spot_rates
where	campaign_no = @campaign_no
and		revenue_group in (5, 51)
and		spot_id not in (select spot_id from inclusion_spot where campaign_no = @campaign_no)

select 		@error = @@error
if @error <> 0 
begin
	rollback transaction
	raiserror ('Error deleting orphan spots stat rev rates', 16, 1)
	return -1
end	

delete	statrev_spot_rates
where	campaign_no = @campaign_no
and		revenue_group in (50, 53, 100, 101, 150, 160)
and		spot_id  in (select spot_id from outpost_spot where campaign_no = @campaign_no and spot_type in ('F', 'T', 'K', 'G', 'A'))

select 		@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error deleting orphan spots stat rev rates', 16, 1)
	return -1
end	

delete		statrev_spot_rates
where		campaign_no = @campaign_no
and			revenue_group in (1, 2, 3, 8, 9, 10, 11)
and			spot_id  in (select spot_id from campaign_spot where campaign_no = @campaign_no and spot_type  in ('F', 'T', 'K', 'G', 'A'))

select 		@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error deleting orphan spots stat rev rates', 16, 1)
	return -1
end	

delete		statrev_spot_rates
where		campaign_no = @campaign_no
and			revenue_group in (4)
and			spot_id  in (select spot_id from cinelight_spot where campaign_no = @campaign_no and spot_type in ('F', 'T', 'K', 'G', 'A'))

select 		@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error deleting orphan spots stat rev rates', 16, 1)
	return -1
end	

delete		statrev_spot_rates
where		campaign_no = @campaign_no
and			revenue_group in (5, 51)
and			spot_id in (select spot_id from inclusion_spot where campaign_no = @campaign_no and spot_type  in ('F', 'T', 'K', 'G', 'A'))

select 		@error = @@error
if @error <> 0 
begin
	rollback transaction
	raiserror ('Error deleting orphan spots stat rev rates', 16, 1)
	return -1
end	

/*
 * Delete rates orphaned by a media product change on 
 */
  
delete		statrev_spot_rates
where		campaign_no = @campaign_no
and			revenue_group = 50
and			spot_id not in (			select			spot_id 
												from				outpost_spot, 
																	outpost_player_xref, 
																	outpost_player 
												where			outpost_player.player_name = outpost_player_xref.player_name 
												and				outpost_spot.outpost_panel_id = outpost_player_xref.outpost_panel_id 
												and				campaign_no = @campaign_no and media_product_id = 9)

select 		@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error deleting orphan spots stat rev rates', 16, 1)
	return -1
end	


/*
 * Delete rates orphaned by a media product change on 
 */
  
delete	statrev_spot_rates
where	campaign_no = @campaign_no
and			revenue_group = 53
and			spot_id not in (	select		spot_id 
												from			outpost_spot, 
																	outpost_player_xref, 
																	outpost_player 
												where		outpost_player.player_name = outpost_player_xref.player_name 
												and				outpost_spot.outpost_panel_id = outpost_player_xref.outpost_panel_id 
												and				campaign_no = @campaign_no and media_product_id = 11)

select 		@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error deleting orphan spots stat rev rates', 16, 1)
	return -1
end	

/*
 * Delete rates orphaned by a media product change on Tower TV spots
 */
  
delete	statrev_spot_rates
where	campaign_no = @campaign_no
and			revenue_group = 150
and			spot_id not in (	select		spot_id 
												from			outpost_spot, 
																	outpost_player_xref, 
																	outpost_player 
												where		outpost_player.player_name = outpost_player_xref.player_name 
												and				outpost_spot.outpost_panel_id = outpost_player_xref.outpost_panel_id 
												and				campaign_no = @campaign_no and media_product_id = 16)

select 		@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error deleting orphan spots stat rev rates', 16, 1)
	return -1
end	


/*
 * Delete rates orphaned by a media product change on Pump Extra spots
 */
  
delete	statrev_spot_rates
where	campaign_no = @campaign_no
and			revenue_group = 160
and			spot_id not in (	select		spot_id 
												from			outpost_spot, 
																	outpost_player_xref, 
																	outpost_player 
												where		outpost_player.player_name = outpost_player_xref.player_name 
												and				outpost_spot.outpost_panel_id = outpost_player_xref.outpost_panel_id 
												and				campaign_no = @campaign_no and media_product_id = 17)

select 		@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error deleting orphan spots stat rev rates', 16, 1)
	return -1
end	
/*
 * Check that min and max periods are in for campaign
 */

select 		@accounting_period = end_date
from		statrev_campaign_periods
where 	campaign_no = @campaign_no
and			end_date = '01-jan-1900'

select 		@rows = @@rowcount,
				@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error getting perious period', 16, 1)
	return -1
end	

if @rows = 0
	insert into statrev_campaign_periods (campaign_no, end_date) values (@campaign_no, '01-jan-1900')

select 		@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error getting perious period', 16, 1)
	return -1
end	

select 			@accounting_period = end_date
from			statrev_campaign_periods
where 		campaign_no = @campaign_no
and				end_date = '31-dec-3000'

select 		@rows = @@rowcount,
				@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error getting perious period', 16, 1)
	return -1
end	

if @rows = 0
	insert into statrev_campaign_periods (campaign_no, end_date) values (@campaign_no, '31-dec-3000')

select 		@error = @@error

if @error <> 0 
begin
	rollback transaction
	raiserror ('Error getting perious period', 16, 1)
	return -1
end	

/* 
 * Determine Processing Periods to only process most recent period
 */
 
select			@rows = count(*) 
from			statrev_campaign_periods
where 		campaign_no = @campaign_no

if @rows <= 2
begin
    select		@last_period = '31-dec-3000',
					@period_cut_off = '01-jan-1900',
					@first_period = '01-jan-1900'
end
else if @rows > 2
begin
    select		@last_period = '31-dec-3000',
					@first_period = '01-jan-1900'
            
    select		@period_cut_off = max(end_date)
    from		statrev_campaign_periods
    where		campaign_no = @campaign_no
    and			end_date < '31-dec-3000'    

    select @error = @@error        

    if @error <> 0 
    begin
        rollback transaction
        raiserror ('Error getting perious period', 16, 1)
        return -1
    end	
end

/*
 * Delete Relevant Onscreen - Agency Spot Rates
 */
 
delete 		statrev_spot_rates
where 		campaign_no = @campaign_no
and			revenue_group = 1
and			spot_id in (    select			spot_id
										from			campaign_spot,
														film_campaign
										where 		film_campaign.campaign_no = @campaign_no
										and			film_campaign.campaign_no = campaign_spot.campaign_no
										and			(screening_date between @period_cut_off and @last_period
										or				(screening_date is null 
										and			billing_date between @period_cut_off and @last_period))
										and			business_unit_id = 2
										and			spot_status <> 'P'
										and			spot_type not in ('M', 'V', 'R'))

select 	@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error re-setting campaign avg rates', 16, 1)
	return -1
end

/*
 * Onscreen - Agency - Paid
 */

select 			@revenue = convert(numeric(23,15), isnull(sum(avg_rate),0)) 
from			statrev_spot_rates
where 			statrev_spot_rates.campaign_no = @campaign_no
and				revenue_group = 1
and				spot_id not in (select spot_id from inclusion_spot where  campaign_no = @campaign_no)

select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - agency', 16, 1)
    return -1
end

select 			@revenue_total = convert(numeric(23,15), isnull(sum(charge_rate),0) + isnull(sum(makegood_rate),0))
from			campaign_spot,
				film_campaign
where 			film_campaign.campaign_no = @campaign_no
and				film_campaign.campaign_no = campaign_spot.campaign_no
and				business_unit_id = 2
and				spot_status <> 'P'
and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G')


select 			@error = @@error,
					@rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - agency', 16, 1)
    return -1
end

select 			@no_spots = convert(numeric(23,15),count(spot_id))
from				campaign_spot,
					film_campaign
where 			film_campaign.campaign_no = @campaign_no
and				film_campaign.campaign_no = campaign_spot.campaign_no
and				(screening_date between @period_cut_off and @last_period
or					(screening_date is null 
and				billing_date between @period_cut_off and @last_period))
and				business_unit_id = 2
and				spot_status <> 'P'
and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G')


select			@error = @@error,
					@rows = @@rowcount

if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - agency', 16, 1)
    return -1
end


if @no_spots <> 0.0
begin
    select @rate = convert(numeric(38,30), (convert(numeric(23,15) , @revenue_total) - convert(numeric(23,15) , @revenue)) / convert(numeric(23,15) , @no_spots))
end
else
begin
    select @rate = 0.0
end

if @rate is not null and @rate <> 0.0
begin
    insert			into statrev_spot_rates 
    select			@campaign_no,
						1,
						spot_id,
						@rate
    from			campaign_spot,
						film_campaign
    where 		film_campaign.campaign_no = @campaign_no
    and				film_campaign.campaign_no = campaign_spot.campaign_no
    and				(screening_date between @period_cut_off and @last_period
    or					(screening_date is null 
    and				billing_date between @period_cut_off and @last_period))
    and				business_unit_id = 2
    and				spot_status <> 'P'
    and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G')

    select 	@error = @@error
    if @error <> 0
    begin
        rollback transaction
        raiserror ('Error updating onscreen - agency', 16, 1)
        return -1
    end

    select 			@revenue_check = sum(avg_rate)
    from			statrev_spot_rates
    where 		revenue_group = 1
    and				spot_id in (select 			spot_id
											from			campaign_spot,
																film_campaign
											where 		film_campaign.campaign_no = @campaign_no
											and				film_campaign.campaign_no = campaign_spot.campaign_no
											and				(screening_date between @period_cut_off and @last_period
											or					(screening_date is null 
											and				billing_date between @period_cut_off and @last_period))
											and				business_unit_id = 2
											and				spot_status <> 'P'
											and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G'))

    select  @revenue_diff = convert(numeric(38,30) , @revenue_total) - convert(numeric(38,30) , @revenue) - convert(numeric(38,30),isnull(@revenue_check,0))
    if @revenue_diff <> 0.000000000000000
    begin
        update			statrev_spot_rates
        set 					avg_rate = avg_rate + @revenue_diff
        where 			revenue_group = 1
        and					spot_id in (select			min(spot_id)
													from			campaign_spot,
																		film_campaign
													where 		film_campaign.campaign_no = @campaign_no
													and				film_campaign.campaign_no = campaign_spot.campaign_no
													and				(screening_date between @period_cut_off and @last_period
													or					(screening_date is null 
													and				billing_date between @period_cut_off and @last_period))
													and				business_unit_id = 2
													and				spot_status <> 'P'
													and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G'))
    end	
end

/*
 * Delete Relevant Onscreen - Direct Spot Rates
 */
 
delete 		statrev_spot_rates
where 			campaign_no = @campaign_no
and				revenue_group = 2
and				spot_id in (    select 			spot_id
											from			campaign_spot,
																film_campaign
											where 		film_campaign.campaign_no = @campaign_no
											and				film_campaign.campaign_no = campaign_spot.campaign_no
											and				(screening_date between @period_cut_off and @last_period
											or					(screening_date is null 
											and				billing_date between @period_cut_off and @last_period))
											and				business_unit_id = 3
											and				spot_status <> 'P'
											and				spot_type not in ('M', 'V', 'R'))

select 	@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error re-setting campaign avg rates', 16, 1)
	return -1
end

/*
 * Onscreen - direct - Paid
 */

select 			@revenue = convert(numeric(23,15), isnull(sum(avg_rate),0)) 
from			statrev_spot_rates
where 			statrev_spot_rates.campaign_no = @campaign_no
and				revenue_group = 2
and				spot_id not in (select spot_id from inclusion_spot where  campaign_no = @campaign_no)

select 			@error = @@error,
					@rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - direct', 16, 1)
    return -1
end

select 			@revenue_total = convert(numeric(23,15), isnull(sum(charge_rate),0) + isnull(sum(makegood_rate),0))
from			campaign_spot,
					film_campaign
where 			film_campaign.campaign_no = @campaign_no
and				film_campaign.campaign_no = campaign_spot.campaign_no
and				business_unit_id = 3
and				spot_status <> 'P'
and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G')


select			@error = @@error,
					@rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - direct', 16, 1)
    return -1
end

select 			@no_spots = convert(numeric(23,15),count(spot_id))
from			campaign_spot,
					film_campaign
where 		film_campaign.campaign_no = @campaign_no
and				film_campaign.campaign_no = campaign_spot.campaign_no
and				(screening_date between @period_cut_off and @last_period
or					(screening_date is null 
and				billing_date between @period_cut_off and @last_period))
and				business_unit_id = 3
and				spot_status <> 'P'
and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G')

select 	@error = @@error,
        @rows = @@rowcount

if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - direct', 16, 1)
    return -1
end


if @no_spots <> 0.0
begin
    select @rate = convert(numeric(38,30), (convert(numeric(23,15) , @revenue_total) - convert(numeric(23,15) , @revenue)) / convert(numeric(23,15) , @no_spots))
end
else
begin
    select @rate = 0.0
end

if @rate is not null and @rate <> 0.0
begin
    insert 				into statrev_spot_rates 
    select 				@campaign_no,
							2,
							spot_id,
							@rate
    from				campaign_spot,
							film_campaign
    where 			film_campaign.campaign_no = @campaign_no
    and					film_campaign.campaign_no = campaign_spot.campaign_no
    and					(screening_date between @period_cut_off and @last_period
    or						(screening_date is null 
    and					billing_date between @period_cut_off and @last_period))
    and					business_unit_id = 3
    and					spot_status <> 'P'
	and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G')

    select 	@error = @@error
    if @error <> 0
    begin
        rollback transaction
        raiserror ('Error updating onscreen - direct', 16, 1)
        return -1
    end

    select 	@revenue_check = sum(avg_rate)
    from   	statrev_spot_rates
    where 	revenue_group = 2
    and     spot_id in (select 			spot_id
									from			campaign_spot,
														film_campaign
									where 		film_campaign.campaign_no = @campaign_no
									and				film_campaign.campaign_no = campaign_spot.campaign_no
									and				(screening_date between @period_cut_off and @last_period
									or					(screening_date is null 
									and				billing_date between @period_cut_off and @last_period))
									and				business_unit_id = 3
									and				spot_status <> 'P'
									and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G'))

    select  @revenue_diff = convert(numeric(38,30) , @revenue_total) - convert(numeric(38,30) , @revenue) - convert(numeric(38,30),isnull(@revenue_check,0))
    if @revenue_diff <> 0.000000000000000
    begin
        update		statrev_spot_rates
        set 				avg_rate = avg_rate + @revenue_diff
        where 		revenue_group = 2
        and				spot_id in (select 			min(spot_id)
												from			campaign_spot,
																	film_campaign
												where 		film_campaign.campaign_no = @campaign_no
												and				film_campaign.campaign_no = campaign_spot.campaign_no
												and				(screening_date between @period_cut_off and @last_period
												or					(screening_date is null 
												and				billing_date between @period_cut_off and @last_period))
												and				business_unit_id = 3
												and				spot_status <> 'P'
												and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G'))
    end	
end

/*
 * Delete Relevant Onscreen - showcase Spot Rates
 */
 
delete 		statrev_spot_rates
where 			campaign_no = @campaign_no
and				revenue_group = 3
and				spot_id in (    select			spot_id
											from			campaign_spot,
																film_campaign
											where			film_campaign.campaign_no = @campaign_no
											and				film_campaign.campaign_no = campaign_spot.campaign_no
											and				(screening_date between @period_cut_off and @last_period
											or					(screening_date is null 
											and				billing_date between @period_cut_off and @last_period))
											and				business_unit_id = 5
											and				spot_status <> 'P'
											and				spot_type not in ('M', 'V', 'R'))

select 	@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error re-setting campaign avg rates', 16, 1)
	return -1
end

/*
 * Onscreen - showcase - Paid
 */

select 			@revenue = convert(numeric(23,15), isnull(sum(avg_rate),0)) 
from				statrev_spot_rates
where 			statrev_spot_rates.campaign_no = @campaign_no
and				revenue_group = 3
and				spot_id not in (select spot_id from inclusion_spot where  campaign_no = @campaign_no)

select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - showcase', 16, 1)
    return -1
end

select 			@revenue_total = convert(numeric(23,15), isnull(sum(charge_rate),0) + isnull(sum(makegood_rate),0))
from			campaign_spot,
					film_campaign
where 			film_campaign.campaign_no = @campaign_no
and				film_campaign.campaign_no = campaign_spot.campaign_no
and				business_unit_id = 5
and				spot_status <> 'P'
and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G')


select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - showcase', 16, 1)
    return -1
end

select 				@no_spots = convert(numeric(23,15),count(spot_id))
from				campaign_spot,
						film_campaign
where 				film_campaign.campaign_no = @campaign_no
and					film_campaign.campaign_no = campaign_spot.campaign_no
and					(screening_date between @period_cut_off and @last_period
or						(screening_date is null 
and					billing_date between @period_cut_off and @last_period))
and					business_unit_id = 5
and					spot_status <> 'P'
and					spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G')


select 	@error = @@error,
        @rows = @@rowcount

if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - showcase', 16, 1)
    return -1
end


if @no_spots <> 0.0
begin
    select @rate = convert(numeric(38,30), (convert(numeric(23,15) , @revenue_total) - convert(numeric(23,15) , @revenue)) / convert(numeric(23,15) , @no_spots))
end
else
begin
    select @rate = 0.0
end

if @rate is not null and @rate <> 0.0
begin
    insert 				into statrev_spot_rates 
    select 				@campaign_no,
							3,
							spot_id,
							@rate
    from				campaign_spot,
							film_campaign
    where 				film_campaign.campaign_no = @campaign_no
    and					film_campaign.campaign_no = campaign_spot.campaign_no
    and					(screening_date between @period_cut_off and @last_period
    or						(screening_date is null 
    and					billing_date between @period_cut_off and @last_period))
    and					business_unit_id = 5
    and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G')

	
    select 	@error = @@error
    if @error <> 0
    begin
        rollback transaction
        raiserror ('Error updating onscreen - showcase', 16, 1)
        return -1
    end

    select 				@revenue_check = sum(avg_rate)
    from   				statrev_spot_rates
    where 			revenue_group = 3
    and					spot_id in (select				spot_id
												from				campaign_spot,
																		film_campaign
												where 			film_campaign.campaign_no = @campaign_no
												and					film_campaign.campaign_no = campaign_spot.campaign_no
												and					(screening_date between @period_cut_off and @last_period
												or						(screening_date is null 
												and					billing_date between @period_cut_off and @last_period))
												and					business_unit_id = 5
												and					spot_status <> 'P'
												and					spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G'))

    select  @revenue_diff = convert(numeric(38,30) , @revenue_total) - convert(numeric(38,30) , @revenue) - convert(numeric(38,30),isnull(@revenue_check,0))
    if @revenue_diff <> 0.000000000000000
    begin
        update			statrev_spot_rates
        set					avg_rate = avg_rate + @revenue_diff
        where 			revenue_group = 3
        and					spot_id in (select				min(spot_id)
													from				campaign_spot,
																			film_campaign
													where 				film_campaign.campaign_no = @campaign_no
													and					film_campaign.campaign_no = campaign_spot.campaign_no
													and					(screening_date between @period_cut_off and @last_period
													or						(screening_date is null 
													and					billing_date between @period_cut_off and @last_period))
													and					business_unit_id = 5
													and					spot_status <> 'P'
													and					spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G')
)
    end	
end

/*
 * Delete Relevant Onscreen - CINEads Spot Rates
 */
 
delete 		statrev_spot_rates
where 		campaign_no = @campaign_no
and				revenue_group = 8
and				spot_id in (    select			spot_id
											from			campaign_spot,
																film_campaign
											where			film_campaign.campaign_no = @campaign_no
											and				film_campaign.campaign_no = campaign_spot.campaign_no
											and				(screening_date between @period_cut_off and @last_period
											or					(screening_date is null 
											and				billing_date between @period_cut_off and @last_period))
											and				business_unit_id = 9
											and				spot_status <> 'P'
											and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G'))

select 	@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error re-setting campaign avg rates', 16, 1)
	return -1
end

/*
 * Onscreen - Cineads - Paid
 */

select 		@revenue = convert(numeric(23,15), isnull(sum(avg_rate),0)) 
from			statrev_spot_rates
where 		statrev_spot_rates.campaign_no = @campaign_no
and				revenue_group = 8
and				spot_id not in (select spot_id from inclusion_spot where  campaign_no = @campaign_no)

select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - agency', 16, 1)
    return -1
end

select 			@revenue_total = convert(numeric(23,15), isnull(sum(charge_rate),0) + isnull(sum(makegood_rate),0))
from			campaign_spot,
					film_campaign
where 			film_campaign.campaign_no = @campaign_no
and				film_campaign.campaign_no = campaign_spot.campaign_no
and				business_unit_id = 9
and				spot_status <> 'P'
and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G')


select 			@error = @@error,
					@rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - agency', 16, 1)
    return -1
end

select 			@no_spots = convert(numeric(23,15),count(spot_id))
from			campaign_spot,
					film_campaign
where 		film_campaign.campaign_no = @campaign_no
and				film_campaign.campaign_no = campaign_spot.campaign_no
and				(screening_date between @period_cut_off and @last_period
or					(screening_date is null 
and				billing_date between @period_cut_off and @last_period))
and				business_unit_id = 9
and				spot_status <> 'P'
and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G')


select			@error = @@error,
					@rows = @@rowcount

if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - agency', 16, 1)
    return -1
end


if @no_spots <> 0.0
begin
    select @rate = convert(numeric(38,30), (convert(numeric(23,15) , @revenue_total) - convert(numeric(23,15) , @revenue)) / convert(numeric(23,15) , @no_spots))
end
else
begin
    select @rate = 0.0
end

if @rate is not null and @rate <> 0.0
begin
    insert			into statrev_spot_rates 
    select			@campaign_no,
						8,
						spot_id,
						@rate
    from			campaign_spot,
						film_campaign
    where 		film_campaign.campaign_no = @campaign_no
    and				film_campaign.campaign_no = campaign_spot.campaign_no
    and				(screening_date between @period_cut_off and @last_period
    or					(screening_date is null 
    and				billing_date between @period_cut_off and @last_period))
    and				business_unit_id = 9
    and				spot_status <> 'P'
    and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G')

	
    select 	@error = @@error
    if @error <> 0
    begin
        rollback transaction
        raiserror ('Error updating onscreen - agency', 16, 1)
        return -1
    end

    select 			@revenue_check = sum(avg_rate)
    from			statrev_spot_rates
    where 		revenue_group = 8
    and				spot_id in (select 			spot_id
											from			campaign_spot,
																film_campaign
											where 		film_campaign.campaign_no = @campaign_no
											and				film_campaign.campaign_no = campaign_spot.campaign_no
											and				(screening_date between @period_cut_off and @last_period
											or					(screening_date is null 
											and				billing_date between @period_cut_off and @last_period))
											and				business_unit_id = 9
											and				spot_status <> 'P'
											and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G'))

    select  @revenue_diff = convert(numeric(38,30) , @revenue_total) - convert(numeric(38,30) , @revenue) - convert(numeric(38,30),isnull(@revenue_check,0))
    if @revenue_diff <> 0.000000000000000
    begin
        update			statrev_spot_rates
        set 					avg_rate = avg_rate + @revenue_diff
        where 			revenue_group = 8
        and					spot_id in (select			min(spot_id)
													from			campaign_spot,
																		film_campaign
													where 		film_campaign.campaign_no = @campaign_no
													and				film_campaign.campaign_no = campaign_spot.campaign_no
													and				(screening_date between @period_cut_off and @last_period
													or					(screening_date is null 
													and				billing_date between @period_cut_off and @last_period))
													and				business_unit_id = 9
													and				spot_status <> 'P'
													and				spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G'))
    end	
end

/*
 * Delete Relevant Onscreen - Cinelight Spot Rates
 */
 
delete 			statrev_spot_rates
where 			campaign_no = @campaign_no
and					revenue_group = 4
and					spot_id in (select 				spot_id
											from				cinelight_spot,
																	film_campaign
											where 				film_campaign.campaign_no = @campaign_no
											and					film_campaign.campaign_no = cinelight_spot.campaign_no
											and					(screening_date between @period_cut_off and @last_period
											or						(screening_date is null 
											and					billing_date between @period_cut_off and @last_period))
											and					spot_status <> 'P'
											and					spot_type not in ('M', 'V', 'R', 'W', 'F', 'A', 'K', 'T', 'G'))

select 	@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error re-setting campaign avg rates', 16, 1)
	return -1
end

/*
 * Cinelight- Paid
 */

select 			@revenue = convert(numeric(23,15), isnull(sum(avg_rate),0)) 
from			statrev_spot_rates
where 		statrev_spot_rates.campaign_no = @campaign_no
and				revenue_group = 4

select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - cinelight', 16, 1)
    return -1
end

select 			@revenue_total = convert(numeric(23,15), isnull(sum(charge_rate),0) + isnull(sum(makegood_rate),0))
from			cinelight_spot,
					film_campaign
where 		film_campaign.campaign_no = @campaign_no
and				film_campaign.campaign_no = cinelight_spot.campaign_no
and				spot_status <> 'P'
and				spot_type <> 'M'
and				spot_type <> 'V'


select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - showcase', 16, 1)
    return -1
end

select 				@no_spots = convert(numeric(23,15),count(spot_id))
from				cinelight_spot,
						film_campaign
where 			film_campaign.campaign_no = @campaign_no
and					film_campaign.campaign_no = cinelight_spot.campaign_no
and					(screening_date between @period_cut_off and @last_period
or						(screening_date is null 
and					billing_date between @period_cut_off and @last_period))
and					spot_status <> 'P'
and					spot_type <> 'M'
and					spot_type <> 'V'
and					spot_type <> 'R' 
and 				spot_type <> 'W'
and					spot_type <> 'F' 

select 	@error = @@error,
        @rows = @@rowcount

if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - showcase', 16, 1)
    return -1
end


if @no_spots <> 0.0
begin
    select @rate = convert(numeric(38,30), (convert(numeric(23,15) , @revenue_total) - convert(numeric(23,15) , @revenue)) / convert(numeric(23,15) , @no_spots))
end
else
begin
    select @rate = 0.0
end

if @rate is not null and @rate <> 0.0
begin
    insert				into statrev_spot_rates 
    select 				@campaign_no,
							4,
            spot_id,
            @rate
    from	cinelight_spot,
            film_campaign
    where 	film_campaign.campaign_no = @campaign_no
    and		film_campaign.campaign_no = cinelight_spot.campaign_no
    and		(screening_date between @period_cut_off and @last_period
    or		(screening_date is null 
    and		billing_date between @period_cut_off and @last_period))
    and		spot_status <> 'P'
    and		spot_type <> 'M'
    and		spot_type <> 'V'
    and		spot_type <> 'R' 
    and 	spot_type <> 'W'

    select 	@error = @@error
    if @error <> 0
    begin
        rollback transaction
        raiserror ('Error updating onscreen - showcase', 16, 1)
        return -1
    end

    select 	@revenue_check = sum(avg_rate)
    from   	statrev_spot_rates
    where 	revenue_group = 4
    and     spot_id in (select 	spot_id
                        from	cinelight_spot,
                                film_campaign
                        where 	film_campaign.campaign_no = @campaign_no
                        and		film_campaign.campaign_no = cinelight_spot.campaign_no
                        and		(screening_date between @period_cut_off and @last_period
                        or		(screening_date is null 
                        and		billing_date between @period_cut_off and @last_period))
                        and		spot_status <> 'P'
                        and		spot_type <> 'M'
                        and		spot_type <> 'V'
                        and		spot_type <> 'R' 
                        and 	spot_type <> 'W')

    select  @revenue_diff = convert(numeric(38,30) , @revenue_total) - convert(numeric(38,30) , @revenue) - convert(numeric(38,30),isnull(@revenue_check,0))
    if @revenue_diff <> 0.000000000000000
    begin
        update	statrev_spot_rates
        set 	avg_rate = avg_rate + @revenue_diff
        where 	revenue_group = 4
        and     spot_id in (select 	min(spot_id)
                            from	cinelight_spot,
                                    film_campaign
                            where 	film_campaign.campaign_no = @campaign_no
                            and		film_campaign.campaign_no = cinelight_spot.campaign_no
                            and		(screening_date between @period_cut_off and @last_period
                            or		(screening_date is null 
                            and		billing_date between @period_cut_off and @last_period))
                            and		spot_status <> 'P'
                            and		spot_type <> 'M'
                            and		spot_type <> 'V'
                            and		spot_type <> 'R' 
                            and 	spot_type <> 'W')
    end	
end

/*
 * Delete Relevant Onscreen - cinemarketing Spot Rates
 */
 
delete 	statrev_spot_rates
where 	campaign_no = @campaign_no
and     revenue_group = 5
and     spot_id in (    select 	spot_id
                        from	inclusion_spot,
                                film_campaign
                        where 	film_campaign.campaign_no = @campaign_no
                        and		film_campaign.campaign_no = inclusion_spot.campaign_no
                        and		(screening_date between @period_cut_off and @last_period
                        or		(screening_date is null 
                        and		billing_date between @period_cut_off and @last_period))
                        and		spot_status <> 'P'
                        and		spot_type <> 'M'
                        and		spot_type <> 'V'
                        and		spot_type <> 'R'
                        and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 5))

select 	@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error re-setting campaign avg rates', 16, 1)
	return -1
end

/*
 * Onscreen - cinemarketing - Paid
 */

select 	@revenue = convert(numeric(23,15), isnull(sum(avg_rate),0)) 
from	statrev_spot_rates
where 	statrev_spot_rates.campaign_no = @campaign_no
and		revenue_group = 5

select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - cinemarketing', 16, 1)
    return -1
end

select 	@revenue_total = convert(numeric(23,15), isnull(sum(charge_rate),0) + isnull(sum(makegood_rate),0))
from	inclusion_spot,
        film_campaign
where 	film_campaign.campaign_no = @campaign_no
and		film_campaign.campaign_no = inclusion_spot.campaign_no
and		spot_status <> 'P'
and		spot_type <> 'M'
and		spot_type <> 'V'
and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 5)


select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - cinemarketing', 16, 1)
    return -1
end

select 	@no_spots = convert(numeric(23,15),count(spot_id))
from	inclusion_spot,
        film_campaign
where 	film_campaign.campaign_no = @campaign_no
and		film_campaign.campaign_no = inclusion_spot.campaign_no
and		(screening_date between @period_cut_off and @last_period
or		(screening_date is null 
and		billing_date between @period_cut_off and @last_period))
and		spot_status <> 'P'
and		spot_type <> 'M'
and		spot_type <> 'V'
and		spot_type <> 'R' 
and 	spot_type <> 'W'
and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 5)

select 	@error = @@error,
        @rows = @@rowcount

if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - cinemarketing', 16, 1)
    return -1
end


if @no_spots <> 0.0
begin
    select @rate = convert(numeric(38,30), (convert(numeric(23,15) , @revenue_total) - convert(numeric(23,15) , @revenue)) / convert(numeric(23,15) , @no_spots))
end
else
begin
    select @rate = 0.0
end

if @rate is not null and @rate <> 0.0
begin
    insert 	into statrev_spot_rates 
    select 	@campaign_no,
            5,
            spot_id,
            @rate
    from	inclusion_spot,
            film_campaign
    where 	film_campaign.campaign_no = @campaign_no
    and		film_campaign.campaign_no = inclusion_spot.campaign_no
    and		(screening_date between @period_cut_off and @last_period
    or		(screening_date is null 
    and		billing_date between @period_cut_off and @last_period))
    and		spot_status <> 'P'
    and		spot_type <> 'M'
    and		spot_type <> 'V'
    and		spot_type <> 'R' 
    and 	spot_type <> 'W'
    and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 5)

    select 	@error = @@error
    if @error <> 0
    begin
        rollback transaction
        raiserror ('Error updating onscreen - cinemarketing', 16, 1)
        return -1
    end

    select 	@revenue_check = sum(avg_rate)
    from   	statrev_spot_rates
    where 	revenue_group = 5
    and     spot_id in (select 	spot_id
                        from	inclusion_spot,
                                film_campaign
                        where 	film_campaign.campaign_no = @campaign_no
                        and		film_campaign.campaign_no = inclusion_spot.campaign_no
                        and		(screening_date between @period_cut_off and @last_period
                        or		(screening_date is null 
                        and		billing_date between @period_cut_off and @last_period))
                        and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 5)
                        and		spot_status <> 'P'
                        and		spot_type <> 'M'
                        and		spot_type <> 'V'
                        and		spot_type <> 'R' 
                        and 	spot_type <> 'W')

    select  @revenue_diff = convert(numeric(38,30) , @revenue_total) - convert(numeric(38,30) , @revenue) - convert(numeric(38,30),isnull(@revenue_check,0))
    if @revenue_diff <> 0.000000000000000
    begin
        update	statrev_spot_rates
        set 	avg_rate = avg_rate + @revenue_diff
        where 	revenue_group = 5
        and     spot_id in (select 	min(spot_id)
                            from	inclusion_spot,
                                    film_campaign
                            where 	film_campaign.campaign_no = @campaign_no
                            and		film_campaign.campaign_no = inclusion_spot.campaign_no
                            and		(screening_date between @period_cut_off and @last_period
                            or		(screening_date is null 
                            and		billing_date between @period_cut_off and @last_period))
                            and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 5)
                            and		spot_status <> 'P'
                            and		spot_type <> 'M'
                            and		spot_type <> 'V'
                            and		spot_type <> 'R' 
                            and 	spot_type <> 'W')
    end	
end

/*
 * Delete Relevant Onscreen - Audience Based Spot Rates
 */
 
delete 		statrev_spot_rates
from		film_campaign
where		statrev_spot_rates.campaign_no = @campaign_no
and			statrev_spot_rates.campaign_no = film_campaign.campaign_no
and			revenue_group = case film_campaign.business_unit_id when 2 then 1 when 3 then 2 when 5 then 3 else 0 end
and			spot_id in (   select 	spot_id
									from	inclusion_spot,
											film_campaign
									where 	film_campaign.campaign_no = @campaign_no
									and		film_campaign.campaign_no = inclusion_spot.campaign_no
									and		(screening_date between @period_cut_off and @last_period
									or		(screening_date is null 
									and		billing_date between @period_cut_off and @last_period))
									and		spot_status <> 'P'
									and		spot_type in ('F', 'K', 'A', 'T')
									and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type in (24, 29, 30, 31, 32)))

select 	@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error re-setting campaign avg rates', 16, 1)
	return -1
end

/*
 * Onscreen - audience inclusions
 */

select 	@revenue = convert(numeric(23,15), isnull(sum(avg_rate),0)) 
from		statrev_spot_rates,
			film_campaign
where 	statrev_spot_rates.campaign_no = @campaign_no
and		statrev_spot_rates.campaign_no = film_campaign.campaign_no
and		revenue_group = case film_campaign.business_unit_id when 2 then 1 when 3 then 2 when 5 then 3 else 0 end
and			spot_id in (   select 	spot_id
									from	inclusion_spot,
											film_campaign
									where 	film_campaign.campaign_no = @campaign_no
									and		film_campaign.campaign_no = inclusion_spot.campaign_no
									and		spot_status <> 'P'
									and		spot_type in ('F', 'K', 'A', 'T')
									and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type in (24, 29, 30, 31, 32)))


select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - cinemarketing', 16, 1)
    return -1
end

select 	@revenue_total = convert(numeric(23,15), isnull(sum(charge_rate),0) + isnull(sum(makegood_rate),0))
from	inclusion_spot,
        film_campaign
where 	film_campaign.campaign_no = @campaign_no
and		film_campaign.campaign_no = inclusion_spot.campaign_no
and		spot_status <> 'P'
and		spot_type <> 'M'
and		spot_type in ('F', 'K', 'A', 'T')
and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type in (24, 29, 30, 31, 32))


select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - cinemarketing', 16, 1)
    return -1
end

select 	@no_spots = convert(numeric(23,15),count(spot_id))
from	inclusion_spot,
        film_campaign
where 	film_campaign.campaign_no = @campaign_no
and		film_campaign.campaign_no = inclusion_spot.campaign_no
and		(screening_date between @period_cut_off and @last_period
or		(screening_date is null 
and		billing_date between @period_cut_off and @last_period))
and		spot_status <> 'P'
and		spot_type in ('F', 'K', 'A', 'T')
and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type in (24, 29, 30, 31, 32))

select 	@error = @@error,
        @rows = @@rowcount

if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - cinemarketing', 16, 1)
    return -1
end


if @no_spots <> 0.0
begin
    select @rate = convert(numeric(38,30), (convert(numeric(23,15) , @revenue_total) - convert(numeric(23,15) , @revenue)) / convert(numeric(23,15) , @no_spots))
end
else
begin
    select @rate = 0.0
end

if @rate is not null and @rate <> 0.0
begin
    insert 	into statrev_spot_rates 
    select 	@campaign_no,
            case film_campaign.business_unit_id when 2 then 1 when 3 then 2 when 5 then 3 else 0 end,
            spot_id,
            @rate
    from	inclusion_spot,
            film_campaign
    where 	film_campaign.campaign_no = @campaign_no
    and		film_campaign.campaign_no = inclusion_spot.campaign_no
    and		(screening_date between @period_cut_off and @last_period
    or		(screening_date is null 
    and		billing_date between @period_cut_off and @last_period))
    and		spot_status <> 'P'
    and		spot_type in ('F', 'K', 'A', 'T')
and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type in (24, 29, 30, 31, 32))

    select 	@error = @@error
    if @error <> 0
    begin
        rollback transaction
        raiserror ('Error updating onscreen - cinemarketing', 16, 1)
        return -1
    end

    select 	@revenue_check = sum(avg_rate)
    from   	statrev_spot_rates,
				film_campaign
    where 	statrev_spot_rates.campaign_no = @campaign_no
	and	statrev_spot_rates.campaign_no = film_campaign.campaign_no
	and revenue_group = case film_campaign.business_unit_id when 2 then 1 when 3 then 2 when 5 then 3 else 0 end

    and     spot_id in (select 	spot_id
                        from	inclusion_spot,
                                film_campaign
                        where 	film_campaign.campaign_no = @campaign_no
                        and		film_campaign.campaign_no = inclusion_spot.campaign_no
                        and		(screening_date between @period_cut_off and @last_period
                        or		(screening_date is null 
                        and		billing_date between @period_cut_off and @last_period))
                        and		spot_status <> 'P'
                        and		spot_type in ('F', 'K', 'A', 'T')
						and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type in (24, 29, 30, 31, 32)))

    select  @revenue_diff = convert(numeric(38,30) , @revenue_total) - convert(numeric(38,30) , @revenue) - convert(numeric(38,30),isnull(@revenue_check,0))
    if @revenue_diff <> 0.000000000000000
    begin
        update	statrev_spot_rates
        set 	avg_rate = avg_rate + @revenue_diff
		from	film_campaign
        where 	revenue_group = case film_campaign.business_unit_id when 2 then 1 when 3 then 2 when 5 then 3 else 0 end
		and statrev_spot_rates.campaign_no = film_campaign.campaign_no
        and     spot_id in (select 	min(spot_id)
                            from	inclusion_spot,
                                    film_campaign
                            where 	film_campaign.campaign_no = @campaign_no
                            and		film_campaign.campaign_no = inclusion_spot.campaign_no
                            and		(screening_date between @period_cut_off and @last_period
                            or		(screening_date is null 
                            and		billing_date between @period_cut_off and @last_period))
                            and		spot_status <> 'P'
							and		spot_type in ('F', 'K', 'A', 'T')
							and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type in (24, 29, 30, 31, 32)))
    end	
end

/*
 * Delete Relevant Retail 
 */
 
delete 	statrev_spot_rates
where 	campaign_no = @campaign_no
and     revenue_group = 50
and     spot_id in (    select 	spot_id
                        from	outpost_spot,
                                outpost_panel,
                                outpost_player_xref,
                                outpost_player
                        where 	campaign_no = @campaign_no
                        and		(screening_date between @period_cut_off and @last_period
                        or		(screening_date is null 
                        and		billing_date between @period_cut_off and @last_period))
                        and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
                        and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
                        and 	outpost_player.player_name = outpost_player_xref.player_name 
                        and 	outpost_player.media_product_id = 9
                        and		spot_status <> 'P'
                        and		spot_type <> 'M'
                        and		spot_type <> 'V'
                        and		spot_type <> 'R')

select 	@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error re-setting campaign avg rates', 16, 1)
	return -1
end

/*
 * Retail
 */

select 	@revenue = convert(numeric(23,15), isnull(sum(avg_rate),0)) 
from	statrev_spot_rates
where 	statrev_spot_rates.campaign_no = @campaign_no
and		revenue_group = 50

select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - retail', 16, 1)
    return -1
end

select 	@revenue_total = convert(numeric(23,15), isnull(sum(charge_rate),0) + isnull(sum(makegood_rate),0))
 from	outpost_spot,
        outpost_panel,
        outpost_player_xref,
        outpost_player
where 	campaign_no = @campaign_no
and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
and 	outpost_player.player_name = outpost_player_xref.player_name 
and 	outpost_player.media_product_id = 9
and		spot_status <> 'P'
and		spot_type <> 'M'
and		spot_type <> 'V'


select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - retail', 16, 1)
    return -1
end

select 	@no_spots = convert(numeric(23,15),count(spot_id))
from	outpost_spot,
        outpost_panel,
        outpost_player_xref,
        outpost_player
where 	campaign_no = @campaign_no
and		(screening_date between @period_cut_off and @last_period
or		(screening_date is null 
and		billing_date between @period_cut_off and @last_period))
and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
and 	outpost_player.player_name = outpost_player_xref.player_name 
and 	outpost_player.media_product_id = 9
and		spot_status <> 'P'
and		spot_type <> 'M'
and		spot_type <> 'V'
and		spot_type <> 'R' 
and 	spot_type <> 'W'
                        
select 	@error = @@error,
        @rows = @@rowcount

if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - cinemarketing', 16, 1)
    return -1
end


if @no_spots <> 0.0
begin
    select @rate = convert(numeric(38,30), (convert(numeric(23,15) , @revenue_total) - convert(numeric(23,15) , @revenue)) / convert(numeric(23,15) , @no_spots))
end
else
begin
    select @rate = 0.0
end

if @rate is not null and @rate <> 0.0
begin
    insert 	into statrev_spot_rates 
    select 	@campaign_no,
            50,
            spot_id,
            @rate
    from	outpost_spot,
            outpost_panel,
            outpost_player_xref,
            outpost_player
    where 	campaign_no = @campaign_no
    and		(screening_date between @period_cut_off and @last_period
    or		(screening_date is null 
    and		billing_date between @period_cut_off and @last_period))
    and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
    and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
    and 	outpost_player.player_name = outpost_player_xref.player_name 
    and 	outpost_player.media_product_id = 9
    and		spot_status <> 'P'
    and		spot_type <> 'M'
    and		spot_type <> 'V'
    and		spot_type <> 'R' 
    and 	spot_type <> 'W'

    select 	@error = @@error
    if @error <> 0
    begin
        rollback transaction
        raiserror ('Error updating onscreen - cinemarketing', 16, 1)
        return -1
    end

    select 	@revenue_check = sum(avg_rate)
    from   	statrev_spot_rates
    where 	revenue_group = 50
    and     spot_id in (select 	spot_id
                        from	outpost_spot,
                                outpost_panel,
                                outpost_player_xref,
                                outpost_player
                        where 	campaign_no = @campaign_no
                        and		(screening_date between @period_cut_off and @last_period
                        or		(screening_date is null 
                        and		billing_date between @period_cut_off and @last_period))
                        and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
                        and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
                        and 	outpost_player.player_name = outpost_player_xref.player_name 
                        and 	outpost_player.media_product_id = 9
                        and		spot_status <> 'P'
                        and		spot_type <> 'M'
                        and		spot_type <> 'V'
                        and		spot_type <> 'R' 
                        and 	spot_type <> 'W')

    select  @revenue_diff = convert(numeric(38,30) , @revenue_total) - convert(numeric(38,30) , @revenue) - convert(numeric(38,30),isnull(@revenue_check,0))
    if @revenue_diff <> 0.000000000000000
    begin
        update	statrev_spot_rates
        set 	avg_rate = avg_rate + @revenue_diff
        where 	revenue_group = 50
        and     spot_id in (select 	min(spot_id)
                            from	outpost_spot,
                                    outpost_panel,
                                    outpost_player_xref,
                                    outpost_player
                            where 	campaign_no = @campaign_no
                            and		(screening_date between @period_cut_off and @last_period
                            or		(screening_date is null 
                            and		billing_date between @period_cut_off and @last_period))
                            and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
                            and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
                            and 	outpost_player.player_name = outpost_player_xref.player_name 
                            and 	outpost_player.media_product_id = 9
                            and		spot_status <> 'P'
                            and		spot_type <> 'M'
                            and		spot_type <> 'V'
                            and		spot_type <> 'R' 
                            and 	spot_type <> 'W')
    end	
end

/*
 * Delete Relevant Retail 
 */
 
delete 	statrev_spot_rates
where 	campaign_no = @campaign_no
and     revenue_group = 53
and     spot_id in (    select 	spot_id
                        from	outpost_spot,
                                outpost_panel,
                                outpost_player_xref,
                                outpost_player
                        where 	campaign_no = @campaign_no
                        and		(screening_date between @period_cut_off and @last_period
                        or		(screening_date is null 
                        and		billing_date between @period_cut_off and @last_period))
                        and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
                        and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
                        and 	outpost_player.player_name = outpost_player_xref.player_name 
                        and 	outpost_player.media_product_id = 11
                        and		spot_status <> 'P'
                        and		spot_type <> 'M'
                        and		spot_type <> 'V'
                        and		spot_type <> 'R')

select 	@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error re-setting campaign avg rates', 16, 1)
	return -1
end

/*
 * Retail
 */

select 	@revenue = convert(numeric(23,15), isnull(sum(avg_rate),0)) 
from	statrev_spot_rates
where 	statrev_spot_rates.campaign_no = @campaign_no
and		revenue_group = 53

select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - super wall', 16, 1)
    return -1
end

select 	@revenue_total = convert(numeric(23,15), isnull(sum(charge_rate),0) + isnull(sum(makegood_rate),0))
 from	outpost_spot,
        outpost_panel,
        outpost_player_xref,
        outpost_player
where 	campaign_no = @campaign_no
and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
and 	outpost_player.player_name = outpost_player_xref.player_name 
and 	outpost_player.media_product_id = 11
and		spot_status <> 'P'
and		spot_type <> 'M'
and		spot_type <> 'V'


select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - super wall', 16, 1)
    return -1
end

select 	@no_spots = convert(numeric(23,15),count(spot_id))
from	outpost_spot,
        outpost_panel,
        outpost_player_xref,
        outpost_player
where 	campaign_no = @campaign_no
and		(screening_date between @period_cut_off and @last_period
or		(screening_date is null 
and		billing_date between @period_cut_off and @last_period))
and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
and 	outpost_player.player_name = outpost_player_xref.player_name 
and 	outpost_player.media_product_id = 11
and		spot_status <> 'P'
and		spot_type <> 'M'
and		spot_type <> 'V'
and		spot_type <> 'R' 
and 	spot_type <> 'W'
                        
select 	@error = @@error,
        @rows = @@rowcount

if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - super wall', 16, 1)
    return -1
end


if @no_spots <> 0.0
begin
    select @rate = convert(numeric(38,30), (convert(numeric(23,15) , @revenue_total) - convert(numeric(23,15) , @revenue)) / convert(numeric(23,15) , @no_spots))
end
else
begin
    select @rate = 0.0
end

if @rate is not null and @rate <> 0.0
begin
    insert 	into statrev_spot_rates 
    select 	@campaign_no,
            53,
            spot_id,
            @rate
    from	outpost_spot,
            outpost_panel,
            outpost_player_xref,
            outpost_player
    where 	campaign_no = @campaign_no
    and		(screening_date between @period_cut_off and @last_period
    or		(screening_date is null 
    and		billing_date between @period_cut_off and @last_period))
    and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
    and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
    and 	outpost_player.player_name = outpost_player_xref.player_name 
    and 	outpost_player.media_product_id = 11
    and		spot_status <> 'P'
    and		spot_type <> 'M'
    and		spot_type <> 'V'
    and		spot_type <> 'R' 
    and 	spot_type <> 'W'

    select 	@error = @@error
    if @error <> 0
    begin
        rollback transaction
        raiserror ('Error updating onscreen - super wall', 16, 1)
        return -1
    end

    select 	@revenue_check = sum(avg_rate)
    from   	statrev_spot_rates
    where 	revenue_group = 53
    and     spot_id in (select 	spot_id
                        from	outpost_spot,
                                outpost_panel,
                                outpost_player_xref,
                                outpost_player
                        where 	campaign_no = @campaign_no
                        and		(screening_date between @period_cut_off and @last_period
                        or		(screening_date is null 
                        and		billing_date between @period_cut_off and @last_period))
                        and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
                        and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
                        and 	outpost_player.player_name = outpost_player_xref.player_name 
                        and 	outpost_player.media_product_id = 11
                        and		spot_status <> 'P'
                        and		spot_type <> 'M'
                        and		spot_type <> 'V'
                        and		spot_type <> 'R' 
                        and 	spot_type <> 'W')

    select  @revenue_diff = convert(numeric(38,30) , @revenue_total) - convert(numeric(38,30) , @revenue) - convert(numeric(38,30),isnull(@revenue_check,0))

	
	
    if @revenue_diff <> 0.000000000000000
    begin
		update	statrev_spot_rates
        set 	avg_rate = avg_rate + @revenue_diff
        where 	revenue_group = 53
        and     spot_id in (select 	min(spot_id)
                            from	outpost_spot,
                                    outpost_panel,
                                    outpost_player_xref,
                                    outpost_player
                            where 	campaign_no = @campaign_no
                            and		(screening_date between @period_cut_off and @last_period
                            or		(screening_date is null 
                            and		billing_date between @period_cut_off and @last_period))
                            and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
                            and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
                            and 	outpost_player.player_name = outpost_player_xref.player_name 
                            and 	outpost_player.media_product_id = 11
                            and		spot_status <> 'P'
                            and		spot_type <> 'M'
                            and		spot_type <> 'V'
                            and		spot_type <> 'R' 
                            and 	spot_type <> 'W')
    end	
end

/*
 * Delete Relevant  retail wall Spot Rates
 */
 
delete 	statrev_spot_rates
where 	campaign_no = @campaign_no
and     revenue_group = 51
and     spot_id in (    select 	spot_id
                        from	inclusion_spot,
                                film_campaign
                        where 	film_campaign.campaign_no = @campaign_no
                        and		film_campaign.campaign_no = inclusion_spot.campaign_no
                        and		(op_screening_date between @period_cut_off and @last_period
                        or		(op_screening_date is null 
                        and		op_billing_date between @period_cut_off and @last_period))
                        and		spot_status <> 'P'
                        and		spot_type <> 'M'
                        and		spot_type <> 'V'
                        and		spot_type <> 'R'
                        and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 18))

select 	@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error re-setting campaign avg rates', 16, 1)
	return -1
end

/*
 * Retail wall - Paid
 */

select 	@revenue = convert(numeric(23,15), isnull(sum(avg_rate),0)) 
from	statrev_spot_rates
where 	statrev_spot_rates.campaign_no = @campaign_no
and		revenue_group = 51

select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - retail wall', 16, 1)
    return -1
end

select 	@revenue_total = convert(numeric(23,15), isnull(sum(charge_rate),0) + isnull(sum(makegood_rate),0))
from	inclusion_spot,
        film_campaign
where 	film_campaign.campaign_no = @campaign_no
and		film_campaign.campaign_no = inclusion_spot.campaign_no
and		spot_status <> 'P'
and		spot_type <> 'M'
and		spot_type <> 'V'
and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 18)


select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - retail wall', 16, 1)
    return -1
end

select 	@no_spots = convert(numeric(23,15),count(spot_id))
from	inclusion_spot,
        film_campaign
where 	film_campaign.campaign_no = @campaign_no
and		film_campaign.campaign_no = inclusion_spot.campaign_no
and		(op_screening_date between @period_cut_off and @last_period
or		(op_screening_date is null 
and		op_billing_date between @period_cut_off and @last_period))
and		spot_status <> 'P'
and		spot_type <> 'M'
and		spot_type <> 'V'
and		spot_type <> 'R' 
and 	spot_type <> 'W'
and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 18)

select 	@error = @@error,
        @rows = @@rowcount

if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - retail wall', 16, 1)
    return -1
end


if @no_spots <> 0.0
begin
    select @rate = convert(numeric(38,30), (convert(numeric(23,15) , @revenue_total) - convert(numeric(23,15) , @revenue)) / convert(numeric(23,15) , @no_spots))
end
else
begin
    select @rate = 0.0
end

if @rate is not null and @rate <> 0.0
begin
    insert 	into statrev_spot_rates 
    select 	@campaign_no,
            51,
            spot_id,
            @rate
    from	inclusion_spot,
            film_campaign
    where 	film_campaign.campaign_no = @campaign_no
    and		film_campaign.campaign_no = inclusion_spot.campaign_no
    and		(op_screening_date between @period_cut_off and @last_period
    or		(op_screening_date is null 
    and		op_billing_date between @period_cut_off and @last_period))
    and		spot_status <> 'P'
    and		spot_type <> 'M'
    and		spot_type <> 'V'
    and		spot_type <> 'R' 
    and 	spot_type <> 'W'
    and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 18)

    select 	@error = @@error
    if @error <> 0
    begin
        rollback transaction
        raiserror ('Error updating onscreen - retail wall', 16, 1)
        return -1
    end

    select 	@revenue_check = sum(avg_rate)
    from   	statrev_spot_rates
    where 	revenue_group = 51
    and     spot_id in (select 	spot_id
                        from	inclusion_spot,
                                film_campaign
                        where 	film_campaign.campaign_no = @campaign_no
                        and		film_campaign.campaign_no = inclusion_spot.campaign_no
                        and		(op_screening_date between @period_cut_off and @last_period
                        or		(op_screening_date is null 
                        and		op_billing_date between @period_cut_off and @last_period))
                        and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 18)
                        and		spot_status <> 'P'
                        and		spot_type <> 'M'
                        and		spot_type <> 'V'
                        and		spot_type <> 'R' 
                        and 	spot_type <> 'W')

    select  @revenue_diff = convert(numeric(38,30) , @revenue_total) - convert(numeric(38,30) , @revenue) - convert(numeric(38,30),isnull(@revenue_check,0))
    if @revenue_diff <> 0.000000000000000
    begin
        update	statrev_spot_rates
        set 	avg_rate = avg_rate + @revenue_diff
        where 	revenue_group = 51
        and     spot_id in (select 	min(spot_id)
                            from	inclusion_spot,
                                    film_campaign
                            where 	film_campaign.campaign_no = @campaign_no
                            and		film_campaign.campaign_no = inclusion_spot.campaign_no
                            and		(op_screening_date between @period_cut_off and @last_period
                            or		(op_screening_date is null 
                            and		op_billing_date between @period_cut_off and @last_period))
                            and		inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 18)
                            and		spot_status <> 'P'
                            and		spot_type <> 'M'
                            and		spot_type <> 'V'
                            and		spot_type <> 'R' 
                            and 	spot_type <> 'W')
    end	
end


/*
 * Delete Relevant Petro - Normal Panel 
 */
 
delete 		statrev_spot_rates
where 		campaign_no = @campaign_no
and				revenue_group = 100
and				spot_id in (select			spot_id
										from			outpost_spot,
															outpost_panel,
															outpost_player_xref,
															outpost_player
										where 		campaign_no = @campaign_no
										and				(screening_date between @period_cut_off and @last_period
										or					(screening_date is null 
										and				billing_date between @period_cut_off and @last_period))
										and 			outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
										and 			outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
										and 			outpost_player.player_name = outpost_player_xref.player_name 
										and 			outpost_player.media_product_id = 12
										and				spot_status <> 'P'
										and				spot_type <> 'M'
										and				spot_type <> 'V'
										and				spot_type <> 'R')

select 	@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error re-setting campaign avg rates', 16, 1)
	return -1
end

/*
 * Petro
 */

select			@revenue = convert(numeric(23,15), isnull(sum(avg_rate),0)) 
from			statrev_spot_rates
where 		statrev_spot_rates.campaign_no = @campaign_no
and				revenue_group = 100

select 			@error = @@error,
					@rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - petro normal panel', 16, 1)
    return -1
end

select 			@revenue_total = convert(numeric(23,15), isnull(sum(charge_rate),0) + isnull(sum(makegood_rate),0))
 from			outpost_spot,
					outpost_panel,
					outpost_player_xref,
					outpost_player
where 		campaign_no = @campaign_no
and 			outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 			outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
and 			outpost_player.player_name = outpost_player_xref.player_name 
and 			outpost_player.media_product_id = 12
and				spot_status <> 'P'
and				spot_type <> 'M'
and				spot_type <> 'V'


select 			@error = @@error,
					@rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - petro', 16, 1)
    return -1
end

select 			@no_spots = convert(numeric(23,15),count(spot_id))
from			outpost_spot,
					outpost_panel,
					outpost_player_xref,
					outpost_player
where 		campaign_no = @campaign_no
and				(screening_date between @period_cut_off and @last_period
or					(screening_date is null 
and				billing_date between @period_cut_off and @last_period))
and 			outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 			outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
and 			outpost_player.player_name = outpost_player_xref.player_name 
and 			outpost_player.media_product_id = 12
and				spot_status <> 'P'
and				spot_type <> 'M'
and				spot_type <> 'V'
and				spot_type <> 'R' 
and 			spot_type <> 'W'
                        
select 	@error = @@error,
        @rows = @@rowcount

if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - petro', 16, 1)
    return -1
end


if @no_spots <> 0.0
begin
    select @rate = convert(numeric(38,30), (convert(numeric(23,15) , @revenue_total) - convert(numeric(23,15) , @revenue)) / convert(numeric(23,15) , @no_spots))
end
else
begin
    select @rate = 0.0
end

if @rate is not null and @rate <> 0.0
begin
    insert 				into statrev_spot_rates 
    select 				@campaign_no,
							100,
							spot_id,
							@rate
    from				outpost_spot,
							outpost_panel,
							outpost_player_xref,
							outpost_player
    where 			campaign_no = @campaign_no
    and					(screening_date between @period_cut_off and @last_period
    or						(screening_date is null 
    and					billing_date between @period_cut_off and @last_period))
    and 				outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
    and 				outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
    and 				outpost_player.player_name = outpost_player_xref.player_name 
    and 				outpost_player.media_product_id = 12
    and					spot_status <> 'P'
    and					spot_type <> 'M'
    and					spot_type <> 'V'
    and					spot_type <> 'R' 
    and 				spot_type <> 'W'

    select 	@error = @@error
    if @error <> 0
    begin
        rollback transaction
        raiserror ('Error updating onscreen - cinemarketing', 16, 1)
        return -1
    end

    select 				@revenue_check = sum(avg_rate)
    from   				statrev_spot_rates
    where 			revenue_group = 100
    and					spot_id in (select				spot_id
												from				outpost_spot,
																		outpost_panel,
																		outpost_player_xref,
																		outpost_player
												where 			campaign_no = @campaign_no
												and					(screening_date between @period_cut_off and @last_period
												or						(screening_date is null 
												and					billing_date between @period_cut_off and @last_period))
												and 				outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
												and 				outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
												and 				outpost_player.player_name = outpost_player_xref.player_name 
												and 				outpost_player.media_product_id = 12
												and					spot_status <> 'P'
												and					spot_type <> 'M'
												and					spot_type <> 'V'
												and					spot_type <> 'R' 
												and 				spot_type <> 'W')

    select  @revenue_diff = convert(numeric(38,30) , @revenue_total) - convert(numeric(38,30) , @revenue) - convert(numeric(38,30),isnull(@revenue_check,0))
    if @revenue_diff <> 0.000000000000000
    begin
        update			statrev_spot_rates
        set 					avg_rate = avg_rate + @revenue_diff
        where 			revenue_group = 100
        and					spot_id in (select 				min(spot_id)
													from				outpost_spot,
																			outpost_panel,
																			outpost_player_xref,
																			outpost_player
													where 			campaign_no = @campaign_no
													and					(screening_date between @period_cut_off and @last_period
													or						(screening_date is null 
													and					billing_date between @period_cut_off and @last_period))
													and 				outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
													and 				outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
													and 				outpost_player.player_name = outpost_player_xref.player_name 
													and 				outpost_player.media_product_id = 12
													and					spot_status <> 'P'
													and					spot_type <> 'M'
													and					spot_type <> 'V'
													and					spot_type <> 'R' 
													and 				spot_type <> 'W')
    end	
end


/*
 * Delete Relevant Petro - CStore Panels
 */
 
delete 		statrev_spot_rates
where 		campaign_no = @campaign_no
and				revenue_group = 101
and				spot_id in (select			spot_id
										from			outpost_spot,
															outpost_panel,
															outpost_player_xref,
															outpost_player
										where 		campaign_no = @campaign_no
										and				(screening_date between @period_cut_off and @last_period
										or					(screening_date is null 
										and				billing_date between @period_cut_off and @last_period))
										and 			outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
										and 			outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
										and 			outpost_player.player_name = outpost_player_xref.player_name 
										and 			outpost_player.media_product_id = 13
										and				spot_status <> 'P'
										and				spot_type <> 'M'
										and				spot_type <> 'V'
										and				spot_type <> 'R')

select 	@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error re-setting campaign avg rates', 16, 1)
	return -1
end

/*
 * Retail
 */

select			@revenue = convert(numeric(23,15), isnull(sum(avg_rate),0)) 
from			statrev_spot_rates
where 		statrev_spot_rates.campaign_no = @campaign_no
and				revenue_group = 101

select 			@error = @@error,
					@rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - petro normal panel', 16, 1)
    return -1
end

select 			@revenue_total = convert(numeric(23,15), isnull(sum(charge_rate),0) + isnull(sum(makegood_rate),0))
 from			outpost_spot,
					outpost_panel,
					outpost_player_xref,
					outpost_player
where 		campaign_no = @campaign_no
and 			outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 			outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
and 			outpost_player.player_name = outpost_player_xref.player_name 
and 			outpost_player.media_product_id = 13
and				spot_status <> 'P'
and				spot_type <> 'M'
and				spot_type <> 'V'


select 			@error = @@error,
					@rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - retail', 16, 1)
    return -1
end

select 			@no_spots = convert(numeric(23,15),count(spot_id))
from			outpost_spot,
					outpost_panel,
					outpost_player_xref,
					outpost_player
where 		campaign_no = @campaign_no
and				(screening_date between @period_cut_off and @last_period
or					(screening_date is null 
and				billing_date between @period_cut_off and @last_period))
and 			outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 			outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
and 			outpost_player.player_name = outpost_player_xref.player_name 
and 			outpost_player.media_product_id = 13
and				spot_status <> 'P'
and				spot_type <> 'M'
and				spot_type <> 'V'
and				spot_type <> 'R' 
and 			spot_type <> 'W'
                        
select 	@error = @@error,
        @rows = @@rowcount

if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - cinemarketing', 16, 1)
    return -1
end


if @no_spots <> 0.0
begin
    select @rate = convert(numeric(38,30), (convert(numeric(23,15) , @revenue_total) - convert(numeric(23,15) , @revenue)) / convert(numeric(23,15) , @no_spots))
end
else
begin
    select @rate = 0.0
end

if @rate is not null and @rate <> 0.0
begin
    insert 				into statrev_spot_rates 
    select 				@campaign_no,
							101,
							spot_id,
							@rate
    from				outpost_spot,
							outpost_panel,
							outpost_player_xref,
							outpost_player
    where 			campaign_no = @campaign_no
    and					(screening_date between @period_cut_off and @last_period
    or						(screening_date is null 
    and					billing_date between @period_cut_off and @last_period))
    and 				outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
    and 				outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
    and 				outpost_player.player_name = outpost_player_xref.player_name 
    and 				outpost_player.media_product_id = 13
    and					spot_status <> 'P'
    and					spot_type <> 'M'
    and					spot_type <> 'V'
    and					spot_type <> 'R' 
    and 				spot_type <> 'W'

    select 	@error = @@error
    if @error <> 0
    begin
        rollback transaction
        raiserror ('Error updating onscreen - cinemarketing', 16, 1)
        return -1
    end

    select 				@revenue_check = sum(avg_rate)
    from   				statrev_spot_rates
    where 			revenue_group = 101
    and					spot_id in (select				spot_id
												from				outpost_spot,
																		outpost_panel,
																		outpost_player_xref,
																		outpost_player
												where 			campaign_no = @campaign_no
												and					(screening_date between @period_cut_off and @last_period
												or						(screening_date is null 
												and					billing_date between @period_cut_off and @last_period))
												and 				outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
												and 				outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
												and 				outpost_player.player_name = outpost_player_xref.player_name 
												and 				outpost_player.media_product_id = 13
												and					spot_status <> 'P'
												and					spot_type <> 'M'
												and					spot_type <> 'V'
												and					spot_type <> 'R' 
												and 				spot_type <> 'W')

    select  @revenue_diff = convert(numeric(38,30) , @revenue_total) - convert(numeric(38,30) , @revenue) - convert(numeric(38,30),isnull(@revenue_check,0))
    if @revenue_diff <> 0.000000000000000
    begin
        update			statrev_spot_rates
        set 					avg_rate = avg_rate + @revenue_diff
        where 			revenue_group = 101
        and					spot_id in (select 				min(spot_id)
													from				outpost_spot,
																			outpost_panel,
																			outpost_player_xref,
																			outpost_player
													where 			campaign_no = @campaign_no
													and					(screening_date between @period_cut_off and @last_period
													or						(screening_date is null 
													and					billing_date between @period_cut_off and @last_period))
													and 				outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
													and 				outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
													and 				outpost_player.player_name = outpost_player_xref.player_name 
													and 				outpost_player.media_product_id = 13
													and					spot_status <> 'P'
													and					spot_type <> 'M'
													and					spot_type <> 'V'
													and					spot_type <> 'R' 
													and 				spot_type <> 'W')
    end	
end


/*
 * Delete Relevant Pump Extra 
 */
 
delete 	statrev_spot_rates
where 	campaign_no = @campaign_no
and     revenue_group = 150
and     spot_id in (    select 	spot_id
                        from	outpost_spot,
                                outpost_panel,
                                outpost_player_xref,
                                outpost_player
                        where 	campaign_no = @campaign_no
                        and		(screening_date between @period_cut_off and @last_period
                        or		(screening_date is null 
                        and		billing_date between @period_cut_off and @last_period))
                        and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
                        and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
                        and 	outpost_player.player_name = outpost_player_xref.player_name 
                        and 	outpost_player.media_product_id = 16
                        and		spot_status <> 'P'
                        and		spot_type <> 'M'
                        and		spot_type <> 'V'
                        and		spot_type <> 'R')

select 	@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error re-setting campaign avg rates', 16, 1)
	return -1
end


/*
 * Tower TV
 */

select 	@revenue = convert(numeric(23,15), isnull(sum(avg_rate),0)) 
from	statrev_spot_rates
where 	statrev_spot_rates.campaign_no = @campaign_no
and		revenue_group = 150

select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - retail', 16, 1)
    return -1
end

select 	@revenue_total = convert(numeric(23,15), isnull(sum(charge_rate),0) + isnull(sum(makegood_rate),0))
 from	outpost_spot,
        outpost_panel,
        outpost_player_xref,
        outpost_player
where 	campaign_no = @campaign_no
and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
and 	outpost_player.player_name = outpost_player_xref.player_name 
and 	outpost_player.media_product_id = 16
and		spot_status <> 'P'
and		spot_type <> 'M'
and		spot_type <> 'V'


select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - retail', 16, 1)
    return -1
end

select 	@no_spots = convert(numeric(23,15),count(spot_id))
from	outpost_spot,
        outpost_panel,
        outpost_player_xref,
        outpost_player
where 	campaign_no = @campaign_no
and		(screening_date between @period_cut_off and @last_period
or		(screening_date is null 
and		billing_date between @period_cut_off and @last_period))
and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
and 	outpost_player.player_name = outpost_player_xref.player_name 
and 	outpost_player.media_product_id = 16
and		spot_status <> 'P'
and		spot_type <> 'M'
and		spot_type <> 'V'
and		spot_type <> 'R' 
and 	spot_type <> 'W'
                        
select 	@error = @@error,
        @rows = @@rowcount

if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - cinemarketing', 16, 1)
    return -1
end


if @no_spots <> 0.0
begin
    select @rate = convert(numeric(38,30), (convert(numeric(23,15) , @revenue_total) - convert(numeric(23,15) , @revenue)) / convert(numeric(23,15) , @no_spots))
end
else
begin
    select @rate = 0.0
end

if @rate is not null and @rate <> 0.0
begin
    insert 	into statrev_spot_rates 
    select 	@campaign_no,
            150,
            spot_id,
            @rate
    from	outpost_spot,
            outpost_panel,
            outpost_player_xref,
            outpost_player
    where 	campaign_no = @campaign_no
    and		(screening_date between @period_cut_off and @last_period
    or		(screening_date is null 
    and		billing_date between @period_cut_off and @last_period))
    and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
    and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
    and 	outpost_player.player_name = outpost_player_xref.player_name 
    and 	outpost_player.media_product_id = 16
    and		spot_status <> 'P'
    and		spot_type <> 'M'
    and		spot_type <> 'V'
    and		spot_type <> 'R' 
    and 	spot_type <> 'W'

    select 	@error = @@error
    if @error <> 0
    begin
        rollback transaction
        raiserror ('Error updating onscreen - cinemarketing', 16, 1)
        return -1
    end

    select 	@revenue_check = sum(avg_rate)
    from   	statrev_spot_rates
    where 	revenue_group = 150
    and     spot_id in (select 	spot_id
                        from	outpost_spot,
                                outpost_panel,
                                outpost_player_xref,
                                outpost_player
                        where 	campaign_no = @campaign_no
                        and		(screening_date between @period_cut_off and @last_period
                        or		(screening_date is null 
                        and		billing_date between @period_cut_off and @last_period))
                        and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
                        and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
                        and 	outpost_player.player_name = outpost_player_xref.player_name 
                        and 	outpost_player.media_product_id = 16
                        and		spot_status <> 'P'
                        and		spot_type <> 'M'
                        and		spot_type <> 'V'
                        and		spot_type <> 'R' 
                        and 	spot_type <> 'W')

    select  @revenue_diff = convert(numeric(38,30) , @revenue_total) - convert(numeric(38,30) , @revenue) - convert(numeric(38,30),isnull(@revenue_check,0))
    if @revenue_diff <> 0.000000000000000
    begin
        update	statrev_spot_rates
        set 	avg_rate = avg_rate + @revenue_diff
        where 	revenue_group = 150
        and     spot_id in (select 	min(spot_id)
                            from	outpost_spot,
                                    outpost_panel,
                                    outpost_player_xref,
                                    outpost_player
                            where 	campaign_no = @campaign_no
                            and		(screening_date between @period_cut_off and @last_period
                            or		(screening_date is null 
                            and		billing_date between @period_cut_off and @last_period))
                            and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
                            and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
                            and 	outpost_player.player_name = outpost_player_xref.player_name 
                            and 	outpost_player.media_product_id = 16
                            and		spot_status <> 'P'
                            and		spot_type <> 'M'
                            and		spot_type <> 'V'
                            and		spot_type <> 'R' 
                            and 	spot_type <> 'W')
    end	
end

/*
 * Delete Relevant Pump Extra 
 */
 
delete 	statrev_spot_rates
where 	campaign_no = @campaign_no
and     revenue_group = 160
and     spot_id in (    select 	spot_id
                        from	outpost_spot,
                                outpost_panel,
                                outpost_player_xref,
                                outpost_player
                        where 	campaign_no = @campaign_no
                        and		(screening_date between @period_cut_off and @last_period
                        or		(screening_date is null 
                        and		billing_date between @period_cut_off and @last_period))
                        and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
                        and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
                        and 	outpost_player.player_name = outpost_player_xref.player_name 
                        and 	outpost_player.media_product_id = 17
                        and		spot_status <> 'P'
                        and		spot_type <> 'M'
                        and		spot_type <> 'V'
                        and		spot_type <> 'R')

select 	@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error re-setting campaign avg rates', 16, 1)
	return -1
end

/*
 * Pump Extra
 */

select 	@revenue = convert(numeric(23,15), isnull(sum(avg_rate),0)) 
from	statrev_spot_rates
where 	statrev_spot_rates.campaign_no = @campaign_no
and		revenue_group = 160

select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - retail', 16, 1)
    return -1
end

select 	@revenue_total = convert(numeric(23,15), isnull(sum(charge_rate),0) + isnull(sum(makegood_rate),0))
 from	outpost_spot,
        outpost_panel,
        outpost_player_xref,
        outpost_player
where 	campaign_no = @campaign_no
and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
and 	outpost_player.player_name = outpost_player_xref.player_name 
and 	outpost_player.media_product_id = 17
and		spot_status <> 'P'
and		spot_type <> 'M'
and		spot_type <> 'V'


select 	@error = @@error,
        @rows = @@rowcount
        
if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - retail', 16, 1)
    return -1
end

select 	@no_spots = convert(numeric(23,15),count(spot_id))
from	outpost_spot,
        outpost_panel,
        outpost_player_xref,
        outpost_player
where 	campaign_no = @campaign_no
and		(screening_date between @period_cut_off and @last_period
or		(screening_date is null 
and		billing_date between @period_cut_off and @last_period))
and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
and 	outpost_player.player_name = outpost_player_xref.player_name 
and 	outpost_player.media_product_id = 17
and		spot_status <> 'P'
and		spot_type <> 'M'
and		spot_type <> 'V'
and		spot_type <> 'R' 
and 	spot_type <> 'W'
                        
select 	@error = @@error,
        @rows = @@rowcount

if @error <> 0
begin
    rollback transaction
    print @campaign_no
    raiserror ('Error calculating onscreen - cinemarketing', 16, 1)
    return -1
end


if @no_spots <> 0.0
begin
    select @rate = convert(numeric(38,30), (convert(numeric(23,15) , @revenue_total) - convert(numeric(23,15) , @revenue)) / convert(numeric(23,15) , @no_spots))
end
else
begin
    select @rate = 0.0
end

if @rate is not null and @rate <> 0.0
begin
    insert 	into statrev_spot_rates 
    select 	@campaign_no,
            160,
            spot_id,
            @rate
    from	outpost_spot,
            outpost_panel,
            outpost_player_xref,
            outpost_player
    where 	campaign_no = @campaign_no
    and		(screening_date between @period_cut_off and @last_period
    or		(screening_date is null 
    and		billing_date between @period_cut_off and @last_period))
    and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
    and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
    and 	outpost_player.player_name = outpost_player_xref.player_name 
    and 	outpost_player.media_product_id = 17
    and		spot_status <> 'P'
    and		spot_type <> 'M'
    and		spot_type <> 'V'
    and		spot_type <> 'R' 
    and 	spot_type <> 'W'

    select 	@error = @@error
    if @error <> 0
    begin
        rollback transaction
        raiserror ('Error updating onscreen - cinemarketing', 16, 1)
        return -1
    end

    select 	@revenue_check = sum(avg_rate)
    from   	statrev_spot_rates
    where 	revenue_group = 160
    and     spot_id in (select 	spot_id
                        from	outpost_spot,
                                outpost_panel,
                                outpost_player_xref,
                                outpost_player
                        where 	campaign_no = @campaign_no
                        and		(screening_date between @period_cut_off and @last_period
                        or		(screening_date is null 
                        and		billing_date between @period_cut_off and @last_period))
                        and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
                        and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
                        and 	outpost_player.player_name = outpost_player_xref.player_name 
                        and 	outpost_player.media_product_id = 17
                        and		spot_status <> 'P'
                        and		spot_type <> 'M'
                        and		spot_type <> 'V'
                        and		spot_type <> 'R' 
                        and 	spot_type <> 'W')

    select  @revenue_diff = convert(numeric(38,30) , @revenue_total) - convert(numeric(38,30) , @revenue) - convert(numeric(38,30),isnull(@revenue_check,0))
    if @revenue_diff <> 0.000000000000000
    begin
        update	statrev_spot_rates
        set 	avg_rate = avg_rate + @revenue_diff
        where 	revenue_group = 160
        and     spot_id in (select 	min(spot_id)
                            from	outpost_spot,
                                    outpost_panel,
                                    outpost_player_xref,
                                    outpost_player
                            where 	campaign_no = @campaign_no
                            and		(screening_date between @period_cut_off and @last_period
                            or		(screening_date is null 
                            and		billing_date between @period_cut_off and @last_period))
                            and 	outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
                            and 	outpost_panel.outpost_panel_id = outpost_player_xref.outpost_panel_id  
                            and 	outpost_player.player_name = outpost_player_xref.player_name 
                            and 	outpost_player.media_product_id = 17
                            and		spot_status <> 'P'
                            and		spot_type <> 'M'
                            and		spot_type <> 'V'
                            and		spot_type <> 'R' 
                            and 	spot_type <> 'W')
    end	
end

commit transaction
return 0
GO
