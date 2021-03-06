/****** Object:  StoredProcedure [dbo].[p_slide_campaign_reverse_live]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_campaign_reverse_live]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_campaign_reverse_live]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_slide_campaign_reverse_live]  @campaign_no 	char(7)

as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare @error          			integer,
        @rowcount						integer,
		  @status 						char(1),
		  @campaign_min_len			integer,
		  @num_spots					integer,
		  @stat_count					integer

/*
 * Check campaign can be reversed.
 */

--Check campaign status
select @status = campaign_status ,
       @campaign_min_len = min_campaign_period
  from slide_campaign
 where campaign_no = @campaign_no

if (@status != 'L')
begin
   raiserror ('Campaign not Live', 16, 1)
	return -1
end

--Check number of spots
select @num_spots = count(spot_id)
  from slide_campaign_spot
 where slide_campaign_spot.campaign_no = @campaign_no

if (@num_spots != @campaign_min_len)
begin
	raiserror ('Incorect Number of Spots', 16, 1)
	return -1
end

--Check spot billing status
select @stat_count = count(spot_id) 
  from slide_campaign_spot
 where slide_campaign_spot.campaign_no = @campaign_no and
       slide_campaign_spot.billing_status = 'L'

if (@num_spots != @stat_count)
begin
	raiserror ('All spots must have a LIVE billing status', 16, 1)
   return -1
end

--Check spot status
select @stat_count = count(spot_id) 
  from slide_campaign_spot
 where slide_campaign_spot.campaign_no = @campaign_no and
     ( slide_campaign_spot.spot_status = 'L' or
       slide_campaign_spot.spot_status = 'A' )

if (@num_spots != @stat_count)
begin
	raiserror ('All spots must have a LIVE or SCREENED screening status', 16, 1)
   return -1
end

--Check screening status
select @stat_count = count(campaign_screening_id)
  from slide_campaign_screening,
       slide_campaign_spot 
 where slide_campaign_spot.campaign_no = @campaign_no and
		 slide_campaign_screening.spot_id = slide_campaign_spot.spot_id and
       slide_campaign_screening.screening_status <> 'A' and
       slide_campaign_screening.screening_status <> 'S'

if (@stat_count != 0)
begin
	raiserror ('All screenings must be ACTIVE or ON SCREEN', 16, 1)
   return -1
end

/*
 * Begin Transaction
 * All conditions met so continue
 */

begin transaction

/*
 * Reverse Screenings settings
 */

update slide_campaign_screening
	set slide_campaign_screening.screening_status = 'U',
       slide_campaign_screening.screening_date = Null
  from slide_campaign_spot
 where slide_campaign_spot.campaign_no = @campaign_no and
		 slide_campaign_screening.spot_id = slide_campaign_spot.spot_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
   return -1
end

/*
 * Reverse Spot settings
 */

update slide_campaign_spot
	set slide_campaign_spot.billing_status = 'U',
	    slide_campaign_spot.spot_status = 'U',
       slide_campaign_spot.screening_date = Null
 where slide_campaign_spot.campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
   return -1
end

/*
 *	 Reverse Changes to Slide distribution
 */

update slide_distribution 
   set actual_alloc = 0
 where campaign_no = @campaign_no and
       distribution_type = 'S'

select @error = @@error
if (@error !=0)
begin
	rollback transaction
   return -1
end

update slide_distribution 
   set actual_alloc = 0,
       accrued_alloc = 0
 where campaign_no = @campaign_no and
       distribution_type = 'P'

select @error = @@error
if (@error !=0)
begin
	rollback transaction
   return -1
end

update slide_distribution 
   set actual_alloc = 0
 where campaign_no = @campaign_no and
       distribution_type = 'R'

select @error = @@error
if (@error !=0)
begin
	rollback transaction
   return -1
end

/*
 *	 Delete rent distribution records.
 */

delete rent_distribution 
 where rent_distribution.campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
   return -1
end

/*
 * Update campaign record
 */

update slide_campaign
   set slide_campaign.campaign_status = 'U',
		 slide_campaign.start_date = Null
 where slide_campaign.campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
   return -1
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
