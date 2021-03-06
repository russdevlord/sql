/****** Object:  StoredProcedure [dbo].[p_film_campaign_expiry_check]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_expiry_check]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_expiry_check]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_film_campaign_expiry_check]	@campaign_no		integer,
													@display_error	char(1)
as

/*
 * Declare Variables
 */

declare @error						int,
        @rowcount					int,
        @makeup_deadline			datetime,
        @last_screening				datetime,
		@last_spot					datetime,
		@last_cinelight_spot		datetime,
		@last_inclusion_spot		datetime,
		@last_outpost_spot			datetime,
        @last_status				char(1),
        @count						int,
        @campaign_status			char(1),
        @cinelight_status			char(1),
        @inclusion_status			char(1),
        @outpost_status				char(1),
        @status						char(1),
		@under						int,
		@cinelight_count			int,
		@inclusion_count			int,
		@outpost_count				int


/*
 * Get Campaign Information
 */

select 	@campaign_status 	= campaign_status,
       	@cinelight_status 	= cinelight_status,
		@inclusion_status 	= inclusion_status,
		@outpost_status 	= outpost_status,
		@makeup_deadline 	= makeup_deadline		
  from 	film_campaign
 where 	campaign_no = @campaign_no

/*
 * Check Status
 */

if(@campaign_status != 'L') or @cinelight_status != 'L' or @inclusion_status != 'L' or @outpost_status <> 'L'
begin
	if(@display_error='Y')
	   raiserror ('Film Campaign Expiry: Campaign must be live before expiry is permitted. Expiry request denied.', 16, 1)
	return -1
end


select	@count = count(spot_id)
from	campaign_spot
where 	campaign_no = @campaign_no
and		screening_date is not null

select 	@cinelight_count = count(spot_id)
from	cinelight_spot
where 	campaign_no = @campaign_no
and		screening_date is not null

select 	@count = @count + @cinelight_count

select 	@outpost_count = count(spot_id)
from	outpost_spot
where 	campaign_no = @campaign_no
and		screening_date is not null

select 	@count = @count + @outpost_count

select 	@inclusion_count = count(spot_id)
from	inclusion_spot
where 	campaign_no = @campaign_no
and		screening_date is not null

select 	@count = @count + @inclusion_count

select 	@inclusion_count = count(billing_period)
from	inclusion_spot
where 	campaign_no = @campaign_no
and		screening_date is null
and		spot_status <> 'C' 
and		spot_status <> 'H'

select 	@count = @count + @inclusion_count

select	@last_spot = max(screening_date)
from	campaign_spot
where 	campaign_no = @campaign_no

select 	@last_cinelight_spot = max(screening_date)
from	cinelight_spot
where 	campaign_no = @campaign_no

if @last_cinelight_spot > @last_spot or @last_spot is null
	select @last_spot = @last_cinelight_spot

select 	@last_outpost_spot = max(screening_date)
from	outpost_spot
where 	campaign_no = @campaign_no

if @last_outpost_spot > @last_spot or @last_spot is null
	select @last_spot = @last_outpost_spot


select 	@last_inclusion_spot = max(screening_date)
from	inclusion_spot
where 	campaign_no = @campaign_no
and		screening_date is not null

if @last_inclusion_spot > @last_spot or @last_spot is null
	select @last_spot = @last_inclusion_spot

select 	@last_inclusion_spot = max(billing_period)
from	inclusion_spot
where 	campaign_no = @campaign_no
and		screening_date is null
and		spot_status <> 'C' 
and		spot_status <> 'H'

if @last_inclusion_spot > @last_spot or @last_spot is null
	select @last_spot = @last_inclusion_spot



select 	@under = count(spot_id)
from	campaign_spot
where 	campaign_no = @campaign_no
and		(spot_status = 'U'
or		spot_status = 'N')
and		spot_redirect is null


/*
 * Define Screening Date Cursor
 */

if @count > 0
begin
	if @under = 0
	 declare date_csr cursor static for
	  select screening_date,
	         screening_date_status
	    from film_screening_dates
	   where screening_date >= @last_spot
	order by screening_date asc
	     for read only
	else if @under > 0
	 declare date_csr cursor static for
	  select screening_date,
	         screening_date_status
	    from film_screening_dates
	   where screening_date >= @makeup_deadline
	order by screening_date asc
	     for read only
	
	/*
	 * Check Makeup Deadline has Passed and Screening Date is Closed
	 */
	
	open date_csr
	fetch date_csr into @last_screening, @last_status
	select @error = @@fetch_status
	
	if(@error != 0 or @last_status != 'X')
	begin
		if(@display_error = 'Y')
			raiserror (50026, 11, 1)
		return -1
	end
	
	close date_csr
	deallocate date_csr
end

/*
 * Check there are no Active Spots
 */

select @count = count(spot_id)
  from campaign_spot
 where campaign_no = @campaign_no and
       spot_status = 'A'

if(@count > 0)
begin
	if(@display_error = 'Y')
		raiserror ('Film Campaign Expiry: Campaign still has "Active" spots. Expiry request denied.', 16, 1)
	return -1
end

/*
 * Check there are no Active Spots
 */

select @count = count(spot_id)
  from cinelight_spot
 where campaign_no = @campaign_no and
       spot_status = 'A'

if(@count > 0)
begin
	if(@display_error = 'Y')
		raiserror ('Film Campaign Expiry: Campaign still has "Active" Cinelight spots. Expiry request denied.', 16, 1)
	return -1
end

/*
 * Check there are no Active Spots
 */

select @count = count(spot_id)
  from outpost_spot
 where campaign_no = @campaign_no and
       spot_status = 'A'

if(@count > 0)
begin
	if(@display_error = 'Y')
		raiserror ('Film Campaign Expiry: Campaign still has "Active" Retail spots. Expiry request denied.', 16, 1)
	return -1
end


/*
 * Check there are no Active Spots
 */

select @count = count(spot_id)
  from inclusion_spot
 where campaign_no = @campaign_no and
       spot_status = 'A' and
       screening_date is not null

if(@count > 0)
begin
	if(@display_error = 'Y')
		raiserror ('Film Campaign Expiry: Campaign still has "Active" Inclusion spots. Expiry request denied.', 16, 1)
	return -1
end

/*
 * Check there are no spots on hold
 */

select @count = count(spot_id)
  from campaign_spot
 where campaign_no = @campaign_no and
       spot_status = 'H'

if(@count > 0)
begin
	if(@display_error = 'Y')
		raiserror (50025, 11, 1)
	return -1
end

/*
 * Check there are no spots on hold
 */

select @count = count(spot_id)
  from cinelight_spot
 where campaign_no = @campaign_no and
       spot_status = 'H'

if(@count > 0)
begin
	if(@display_error = 'Y')
		raiserror ('Film Campaign Expiry: Campaign still has "On Hold" Cinelight spots. Expiry request denied.', 16, 1)
	return -1
end

/*
 * Check there are no spots on hold
 */

select @count = count(spot_id)
  from outpost_spot
 where campaign_no = @campaign_no and
       spot_status = 'H'

if(@count > 0)
begin
	if(@display_error = 'Y')
		raiserror ('Film Campaign Expiry: Campaign still has "On Hold" Retail spots. Expiry request denied.', 16, 1)
	return -1
end

/*
 * Check there are no spots on hold
 */

select @count = count(spot_id)
  from inclusion_spot
 where campaign_no = @campaign_no and
       spot_status = 'H'

if(@count > 0)
begin
	if(@display_error = 'Y')
		raiserror ('Film Campaign Expiry: Campaign still has "On Hold" Inclusion spots. Expiry request denied.', 16, 1)
	return -1
end

/*
 * Check that all Screening Dates are Closed
 */

select @last_screening = max(screening_date)
  from campaign_spot
 where campaign_no = @campaign_no and
       spot_status <> 'D' and
       spot_status <> 'P' and
       spot_type <> 'M' and
       spot_type <> 'V'

select @rowcount = @@rowcount

if(@rowcount > 0 and @last_screening is not null)
begin

	select @status = screening_date_status
     from film_screening_dates
    where screening_date = @last_screening

	if(@status <> 'X')
	begin
		if(@display_error = 'Y')
			raiserror (50042, 11, 1)
		return -1
	end

end

/*
 * Check that all Screening Dates are Closed
 */

select @last_screening = max(screening_date)
  from cinelight_spot
 where campaign_no = @campaign_no and
       spot_status <> 'D' and
       spot_status <> 'P' and
       spot_type <> 'M' and
       spot_type <> 'V'

select @rowcount = @@rowcount

if(@rowcount > 0 and @last_screening is not null)
begin

	select @status = screening_date_status
     from film_screening_dates
    where screening_date = @last_screening

	if(@status <> 'X')
	begin
		if(@display_error = 'Y')
			raiserror ('Film Campaign Expiry: Campaign still has Cinelight spots on open screening weeks. Expiry request denied.', 16, 1)
		return -1
	end

end

/*
 * Check that all Screening Dates are Closed
 */

select @last_screening = max(screening_date)
  from outpost_spot
 where campaign_no = @campaign_no and
       spot_status <> 'D' and
       spot_status <> 'P' and
       spot_type <> 'M' and
       spot_type <> 'V'

select @rowcount = @@rowcount

if(@rowcount > 0 and @last_screening is not null)
begin

	select @status = screening_date_status
     from outpost_screening_dates
    where screening_date = @last_screening

	if(@status <> 'X')
	begin
		if(@display_error = 'Y')
			raiserror ('Film Campaign Expiry: Campaign still has Retail spots on open screening weeks. Expiry request denied.', 16, 1)
		return -1
	end

end

/*
 * Check that all Screening Dates are Closed
 */

select @last_screening = max(screening_date)
  from inclusion_spot
 where campaign_no = @campaign_no and
       spot_status <> 'D' and
       spot_status <> 'P' and
       spot_type <> 'M' and
       spot_type <> 'V' and
	   screening_date is not null

select @rowcount = @@rowcount

if(@rowcount > 0 and @last_screening is not null)
begin

	select @status = screening_date_status
     from film_screening_dates
    where screening_date = @last_screening

	if(@status <> 'X')
	begin
		if(@display_error = 'Y')
			raiserror ('Film Campaign Expiry: Campaign still has Inclusion spots on open screening weeks. Expiry request denied.', 16, 1)
		return -1
	end

end

/*
 * Check that all Screening Dates are Closed
 */

select @last_screening = max(billing_period)
  from inclusion_spot
 where campaign_no = @campaign_no and
       spot_status <> 'D' and
       spot_status <> 'P' and
       spot_type <> 'M' and
       spot_type <> 'V' and
	   screening_date is null and
	   spot_status <> 'C' and
	   spot_status <> 'H'

select @rowcount = @@rowcount

if(@rowcount > 0 and @last_screening is not null)
begin

	select @status = status
     from accounting_period
    where end_date = @last_screening

	if(@status <> 'X')
	begin
		if(@display_error = 'Y')
			raiserror ('Film Campaign Expiry: Campaign still has Inclusion spots on open accounting_periods. Expiry request denied.', 16, 1)
		return -1
	end

end
/*
 * Return Success
 */

return 0
GO
