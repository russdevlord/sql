/****** Object:  StoredProcedure [dbo].[p_eom_film_campaign_arc]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_film_campaign_arc]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_film_campaign_arc]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_eom_film_campaign_arc] @campaign_no				int,
                                    @accounting_period		datetime
as

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @errorode					integer,
        @errno					integer,
        @print_id				integer,
        @event_id 				integer,
        @campaign_usage 		integer,
        @shell_usage 			integer

/*
 * Begin Transaction
 */

begin transaction

/*
 * Create Archive Event
 */

execute @errorode = p_get_sequence_number 'film_campaign_event', 5, @event_id OUTPUT
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

insert into film_campaign_event (
       campaign_event_id,
       campaign_no,
       event_type,
       event_date,
       event_outstanding,
       event_desc,
       entry_date ) values (
       @event_id,
       @campaign_no,
       'Y',
       @accounting_period,
       'N',
       'EOM - Archive Complete',
       @accounting_period )

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Summarise Spot Information
 */

execute @errorode = p_arc_film_campaign_spots @campaign_no
if (@errorode !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Remove Package Audience Profiles
 */

delete campaign_audience
  from campaign_package pack
 where pack.campaign_no = @campaign_no and
       pack.package_id = campaign_audience.package_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Remove Package Movie Categories
 */

delete campaign_category
  from campaign_package pack
 where pack.campaign_no = @campaign_no and
       pack.package_id = campaign_category.package_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Remove Package Movie Classifications
 */

delete campaign_classification
  from campaign_package pack
 where pack.campaign_no = @campaign_no and
       pack.package_id = campaign_classification.package_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Remove Package Movie Instructions
 */

delete movie_screening_instructions
  from campaign_package pack
 where pack.campaign_no = @campaign_no and
       pack.package_id = movie_screening_instructions.package_id

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Archive Spot Liability
 */

insert into archive..vault_spot_liability
			(
			spot_liability_id,
			spot_id,
			complex_id,
			liability_type,
			allocation_id,
			creation_period,
			origin_period,
			release_period,
			spot_amount,
			cinema_amount,
			cancelled,
			original_liability,
			cinema_rent
			)
			select spot_liability_id,
			spot_id,
			complex_id,
			liability_type,
			allocation_id,
			creation_period,
			origin_period,
			release_period,
			spot_amount,
			cinema_amount,
			cancelled,
			original_liability,
			cinema_rent
from		spot_liability
where 		spot_id in (select spot_id from campaign_spot where campaign_no = @campaign_no)		

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

delete spot_liability where spot_id in (select spot_id from campaign_spot where campaign_no = @campaign_no)		

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Archive Campaign Spots to archive database
 */

insert into archive..vault_campaign_spot
			(spot_id,
			campaign_no,
			package_id,
			complex_id,
			screening_date,
			billing_date,
			spot_status,
			spot_type,
			tran_id,
			rate,
			charge_rate,
			nett_rate,
			spot_instruction,
			schedule_auto_create,
			billing_period,
			spot_weighting,
			cinema_weighting,
			certificate_score)
			select spot_id,
			campaign_no,
			package_id,
			complex_id,
			screening_date,
			billing_date,
			spot_status,
			spot_type,
			tran_id,
			rate,
			charge_rate,
			cinema_rate,
			spot_instruction,
			schedule_auto_create,
			billing_period,
			spot_weighting,
			cinema_weighting,
			certificate_score
	 from campaign_spot
   where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	


/*
 * Remove Campaign Spots
 */

delete campaign_spot
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Remove Campaign Complex Info
 */

delete film_campaign_complex
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Remove cinelight complex Complex Info
 */

delete cinelight_campaign_complex
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	
/*
 * Set Campaign to archived
 */

update film_campaign 
   set campaign_status = 'Z',
       cinelight_status = 'Z',
	   inclusion_status = 'Z'
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

update campaign_package 
set campaign_package_status = 'Z'
where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

update cinelight_package 
set cinelight_package_status = 'Z'
where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

update inclusion 
set inclusion_status = 'Z'
where campaign_no = @campaign_no

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
