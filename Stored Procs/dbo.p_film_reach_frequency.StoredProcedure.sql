/****** Object:  StoredProcedure [dbo].[p_film_reach_frequency]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_reach_frequency]
GO
/****** Object:  StoredProcedure [dbo].[p_film_reach_frequency]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_film_reach_frequency]		@campaign_no			int, 
						@mode				int,
						@message			varchar(255) OUTPUT

as

declare 	@error							int,
		@film_market_no					int,
		@attendance_analysis			char(1),
		@avg_spot_week					numeric(10,4),
		@no_screens						int,
		@no_weeks						int,
		@duration						int,
		@stored_avg_spot_week			numeric(10,4),
		@stored_no_screens				int,
		@stored_no_weeks				int,
		@stored_duration				int,
		@spot_count						int,
		@different						char(1),
		@records_exist					int



/*
 * Check that this campaign can have reach and frequncy data
 */

select      @attendance_analysis = attendance_analysis 
from        film_campaign
where       campaign_no = @campaign_no

if @attendance_analysis = 'N' 
begin
	raiserror ('This campaign cannot have Reach and Frequency Data generated.  Please see your manager.', 16, 1)
	return -1
end

/*
 * Check That There Are Spots
 */

select @spot_count = count(spot_id)
  from campaign_spot
 where campaign_no = @campaign_no

if @spot_count < 1 
begin
	raiserror ('This campaign must have spots generated before this process can be run.', 16, 1)
	return -1
end

/*
 * Set @different to 'N' - if 'Y' at the end will throw a message saying reach and frequency values are no longer valid.
 */

select @different = 'N'

/*
 * Determine if current reach and frequency records exist
 */

select @records_exist = count(campaign_no)
  from film_reach_frequency
 where campaign_no = @campaign_no

if @mode = 2 and @records_exist < 1
begin
	raiserror ('There are no records to compare with for this campaign.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Campaign Duration
 */

select      @duration = datediff(wk, start_date, dateadd(dd, 6, end_date))
from        film_campaign
where       campaign_no = @campaign_no

select      @stored_duration = duration
from        film_reach_frequency
where       campaign_no = @campaign_no

if @mode = 1
begin
	
	if @records_exist > 0
	begin

        update      film_reach_frequency
        set         duration = @duration,
                    reach = 0.0,
                    frequency = 0.0
        where       campaign_no = @campaign_no

		select @error = @@error
		if @error != 0
		begin
			rollback transaction
			raiserror ('Error Updating new Reach and Frequecy Records.', 16, 1)
			return -1
		end
		
	end
	else
	begin
		insert into film_reach_frequency
		(campaign_no,
		reach,
		frequency,
		duration) values
		(@campaign_no,
		0.0,
		0.0,
		@duration)
	

		select @error = @@error
		if @error != 0
		begin
			rollback transaction
			raiserror ('Error Inserting new Reach and Frequecy Records.', 16, 1)
			return -1
		end
	end
end
else if @mode = 2
begin

	if @duration != @stored_duration 
		select @different = 'Y'
end


/*
 * Film Market
 */

if @mode = 1 
begin
	delete reach_frequency_parms
	 where campaign_no = @campaign_no

	select @error = @@error
	if @error != 0
	begin
		rollback transaction
		raiserror ('Error Inserting new Reach and Frequecy Records.', 16, 1)
		return -1
	end
end

/*
 * Declare Cursors
 */

declare     campaign_market_csr cursor static for
select      distinct film_market_no
from        campaign_spot,
            complex
where       campaign_spot.complex_id = complex.complex_id
and         campaign_spot.campaign_no = @campaign_no
order by    film_market_no
for         read only

open campaign_market_csr
fetch campaign_market_csr into @film_market_no
while (@@fetch_status=0)
begin

	select @no_weeks = count(distinct screening_date)
     from campaign_spot,
			 complex
    where campaign_spot.complex_id = complex.complex_id 
      and campaign_spot.campaign_no = @campaign_no
      and complex.film_market_no = @film_market_no
      and spot_status != 'D'
      and spot_status != 'C'
      and spot_status != 'U'
      and spot_status != 'N'
      
	select @spot_count = count(spot_id)
     from campaign_spot,
			 complex
    where campaign_spot.complex_id = complex.complex_id 
      and campaign_spot.campaign_no = @campaign_no
      and complex.film_market_no = @film_market_no
      and spot_status != 'D'
      and spot_status != 'C'
      and spot_status != 'U'
      and spot_status != 'N'

	select @avg_spot_week = convert(numeric(10,4), convert(numeric(16,8), @spot_count) / convert(numeric(16,8),@no_weeks))

	if @mode = 1
	begin
			insert into reach_frequency_parms
					(campaign_no,
					 film_market_no,
					 no_screens,
					 avg_spot_week) values
					(@campaign_no,
					 @film_market_no,
					 @no_weeks,
					 @avg_spot_week)

			select @error = @@error
			if @error != 0
			begin
				rollback transaction
				raiserror ('Error Inserting new Reach and Frequecy Records.', 16, 1)
				return -1
			end

	end
	else if @mode = 2
	begin

	select @stored_avg_spot_week = avg_spot_week,
			 @stored_no_weeks = no_screens
     from reach_frequency_parms 
	 where campaign_no = @campaign_no
      and film_market_no = @film_market_no

		if @stored_avg_spot_week != @avg_spot_week or @stored_no_weeks != @no_weeks
			select @different = 'Y'

	end

	fetch campaign_market_csr into @film_market_no
end

close campaign_market_csr
deallocate campaign_market_csr

/*
 * Commit Transaction
 */

commit transaction


if @mode = 2 and @different = 'Y'
begin
	select @message = 'The details that the current Reach and Frequency figures are based on have changed.' + char(10) +  'You will need to Re-calculate these figures.'
	return -1
end

if @mode = 2 and @different = 'N'
begin
	select @message = 'The current Reach and Frequency figures are correct.'
	return 0
end

return 0
GO
