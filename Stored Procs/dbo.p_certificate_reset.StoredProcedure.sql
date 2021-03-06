/****** Object:  StoredProcedure [dbo].[p_certificate_reset]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_reset]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_reset]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



CREATE PROC [dbo].[p_certificate_reset]		@complex_id				int,
																		@screening_date 		datetime
as

/*
 * Declare Variables
 */

declare		@error     					int,
				@errorode							int,
				@spot_id						int,
				@cert_score				int,
				@charge_rate				money,
				@rate							money,
				@spot_redirect			int

set nocount on

/*
 * Begin Transaction
 */

begin transaction

/*
 * delete complex_tms_pack_uuid
 */

insert into	complex_tms_pack_uuid_delete_list
select			complex_tms_pack_uuid.*
from				complex_tms_pack_uuid
inner join		certificate_group on complex_tms_pack_uuid.certificate_group_id = certificate_group.certificate_group_id
where			certificate_group.screening_date = @screening_date 
and				certificate_group.complex_id = @complex_id
		

select @error = @@error
if (@error != 0)
begin
	raiserror	('Failed to store list of uuids to be deleted off of the TMS', 16, 1)
	rollback transaction
	return -1
end	

delete		complex_tms_pack_uuid
from			certificate_group
where		screening_date = @screening_date
and			complex_id = @complex_id
and			complex_tms_pack_uuid.certificate_group_id = certificate_group.certificate_group_id

select @error = @@error
if (@error != 0)
begin
	raiserror	('Failed to delete linked TMS packs', 16, 1)
	rollback transaction
	return -1
end	

/*
 * Declare Makeup Csr
 */     

declare			makeup_csr cursor static for
select			spot.spot_id,  --unalloc
					spot.spot_redirect  --makeup
from				campaign_spot spot
where			spot_redirect in (	select			spot_id
												from				campaign_spot
												where			complex_id = @complex_id
												and				screening_date = @screening_date
												and				spot_type = 'M' )
order by		spot.spot_id
for				read only

/*
 * Process Spot Liability and Spot Redirect Rollbacks of Makeup/Manual Spots
 */
 
open makeup_csr
fetch makeup_csr into @spot_id, @spot_redirect
while(@@fetch_status=0)
begin

    execute @errorode =  p_ffin_unallocate_makeup @spot_redirect
    
    if @errorode != 0 
    begin
        rollback transaction
        raiserror ('Failed to Remove makeup spot liability and spot redirect', 16, 1)
        return -1
    end
    
    fetch makeup_csr into @spot_id, @spot_redirect
end

close makeup_csr
deallocate makeup_csr

commit transaction

/*
 * Reset Complex Date Record
 */

begin transaction

update			complex_date 
set				certificate_generation_user = Null,
					certificate_generation = Null,
					certificate_status = 'N'
where			complex_id = @complex_id 
and				screening_date = @screening_date

select @error = @@error

if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
    return -1
end	

/*
 * Reset All Allocated, Unallocated and No Shows
 */

update			campaign_spot
set				spot_status = 'A',
					spot_instruction = '',
					certificate_score = 0
where			complex_id = @complex_id 
and				screening_date = @screening_date 
and				(spot_status = 'X' 
or					spot_status = 'U' 
or					spot_status = 'N')

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	

update			inclusion_spot
set				spot_status = 'A'
where			screening_date = @screening_date 
and				(spot_status = 'X' 
or					spot_status = 'U' 
or					spot_status = 'N'  )
and				(spot_type = 'K'
or					spot_type = 'F'
or					spot_type = 'T' 
or					spot_type = 'A')

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	

delete			certificate_item_tms_section_xref 
where			certificate_item_id in (	select				certificate_item_id 
															from					certificate_item 
															where				certificate_group in (	select				certificate_group_id 
																														from					certificate_group
																														where				complex_id = @complex_id 
																														and					screening_date = @screening_date))

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return -1
end	

delete			movie_history_sessions_certificate 
where			certificate_group_id in (	select				certificate_group_id 
															from					certificate_group
															where				complex_id = @complex_id 
															and					screening_date = @screening_date)


select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	


delete				certificate_item
where				certificate_group in (	select				certificate_group_id 
															from					certificate_group
															where				complex_id = @complex_id 
															and					screening_date = @screening_date)

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	

/*
 * Remove all Certificate Groups and (Certificate Items -> Cascade)
 */

delete				certificate_group
where				complex_id = @complex_id 
and					screening_date = @screening_date

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	

/*
 * Delete Makeups, Manual and Stand-By Spots
 */

delete		inclusion_campaign_spot_xref
where		spot_id in (	select		spot_id 
									from			campaign_spot
									where		complex_id = @complex_id 
									and			screening_date = @screening_date)

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	

delete			campaign_spot
where			complex_id = @complex_id 
and				screening_date = @screening_date 
and				(spot_type = 'M' 
or					spot_type = 'Y' 
or					spot_type = 'G' 
or					spot_type = 'F' 
or					spot_type = 'K'
or					spot_type = 'T' 
or					spot_type = 'A')

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	

/*
 * Delete Spots Created By Sponsorship Campaigns
 */

delete			campaign_spot
where			complex_id = @complex_id 
and				screening_date = @screening_date 
and				schedule_auto_create in ('C', 'S')
and				(spot_status = 'X' 
or					spot_status = 'U' 
or					spot_status = 'N'
or					spot_status = 'A')

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	

/*
 * Delete any certificte print records
 */

delete				certificate_prints
where				complex_id = @complex_id 
and					screening_date = @screening_date 

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	

/*
delete				certificate_prints
where				complex_id = @complex_id 
and					screening_date <= dateadd(mm, -6, @screening_date)

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	
*/

/*
 * Reset Audience Based Targets
 */
 
update				inclusion_follow_film_targets 
set					achieved_attendance = 0, 
						processed = 'N' 
where				complex_id = @complex_id
and					screening_date = @screening_date

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	

update				inclusion_cinetam_targets 
set					achieved_attendance = 0, 
						processed = 'N' 
where				complex_id = @complex_id
and					screening_date = @screening_date

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	

/*
 * Insert spots for audience inclusions
 */

--Follow Film
--RoadBlock
--Movie Mix
--TAP

create table #new_spots
(
	spot_id									int,
	campaign_no							int,
	package_id							int,
	complex_id							int,
	screening_date					datetime,
	billing_date							datetime,
	spot_status							char(1),
	spot_type								char(1),
	rate										money,
	charge_rate							money,
	makegood_rate					money,
	cinema_rate							money,
	spot_instruction					varchar(100),
	schedule_auto_create			char(1),
	billing_period						datetime,
	spot_weighting						float,
	cinema_weighting					float,
	certificate_score					tinyint,
	dandc									char(1),
	onscreen								char(1),
	spot_redirect						int,
	inclusion_id							int,
	delete_this_row					char(1),
	movie_id								int,
	follow_film_restricted			char(1),
	inclusion_type						int,
	inclusion_spot_id					int
)

create table #new_spots2
(
	spot_id									int,
	campaign_no							int,
	package_id							int,
	complex_id							int,
	screening_date					datetime,
	billing_date							datetime,
	spot_status							char(1),
	spot_type								char(1),
	rate										money,
	charge_rate							money,
	makegood_rate					money,
	cinema_rate							money,
	spot_instruction					varchar(100),
	schedule_auto_create			char(1),
	billing_period						datetime,
	spot_weighting						float,
	cinema_weighting					float,
	certificate_score					tinyint,
	dandc									char(1),
	onscreen								char(1),
	spot_redirect						int,
	inclusion_id							int,
	inclusion_spot_id					int,
	movie_id								int
)


insert into	#new_spots	
--select			(select max(spot_id) from campaign_spot) + row_number() over (order by inclusion_spot.inclusion_id) as spot_id,
select			(0) + row_number() over (order by inclusion_spot.inclusion_id) as spot_id,
					inclusion_spot.campaign_no,
					inclusion_cinetam_package.package_id,
					inclusion_cinetam_settings.complex_id,
					inclusion_spot.screening_date,
					billing_date,
					'A',
					case inclusion_type when 24 then 'T' when 29 then 'F' when 30 then 'K' when 31 then 'K' when 32 then 'A' end,
					0,
					0,
					0,
					0,
					'',
					'C',
					inclusion_spot.billing_period,
					null,
					null,
					0,
					'N',
					'N',
					null,
					inclusion_spot.inclusion_id,
					'N',
					movie_id,
					follow_film_restricted,
					inclusion_type,
					inclusion_spot.spot_id
from				inclusion_spot
inner join		inclusion_cinetam_package on inclusion_spot.inclusion_id = inclusion_cinetam_package.inclusion_id
inner join		campaign_package on inclusion_cinetam_package.package_id = campaign_package.package_id
inner join		inclusion_cinetam_settings on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		movie_history on inclusion_cinetam_settings.complex_id = movie_history.complex_id and inclusion_spot.screening_date = movie_history.screening_date
where			inclusion_cinetam_settings.complex_id = @complex_id
and				inclusion_spot.screening_date = @screening_date
and				inclusion_type <> 33
and				premium_cinema <> 'Y'
and				movie_history.movie_id <> 102
and				inclusion_spot.spot_status <> 'P'

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error inserting inclusion audience spots', 16, 1)
   return -1
end	

--restrcited categories
update			#new_spots
set				delete_this_row = 'Y'
from				(select			campaign_category.package_id,
										movie_history.movie_id,
										movie_history.screening_date,
										movie_history.complex_id
					from				campaign_category
					inner join		target_categories on campaign_category.movie_category_code = target_categories.movie_category_code
					inner join		movie_history on target_categories.movie_id = movie_history.movie_id
					where 			instruction_type = 3
					and				movie_history.screening_date = @screening_date
					and				movie_history.complex_id = @complex_id
					group by		campaign_category.package_id,
										movie_history.movie_id,
										movie_history.screening_date,
										movie_history.complex_id) as temp_table
where			#new_spots.complex_id = temp_table.complex_id
and				#new_spots.screening_date = temp_table.screening_date
and				#new_spots.package_id = temp_table.package_id
and				#new_spots.movie_id = temp_table.movie_id

--restrcitied classifications
update			#new_spots
set				delete_this_row = 'Y'
from				(select			campaign_classification.package_id,
										movie_history.movie_id,
										movie_history.screening_date,
										movie_history.complex_id
					from				campaign_classification
					inner join		movie_country on campaign_classification.classification_id = movie_country.classification_id
					inner join		movie_history on movie_country.movie_id = movie_history.movie_id and movie_history.country = movie_country.country_code
					where 			instruction_type = 3
					and				movie_history.screening_date = @screening_date
					and				movie_history.complex_id = @complex_id
					group by		campaign_classification.package_id,
										movie_history.movie_id,
										movie_history.screening_date,
										movie_history.complex_id) as temp_table
where			#new_spots.complex_id = temp_table.complex_id
and				#new_spots.screening_date = temp_table.screening_date
and				#new_spots.package_id = temp_table.package_id
and				#new_spots.movie_id = temp_table.movie_id

--restrcited movies
update			#new_spots
set				delete_this_row = 'Y'
from				(select			movie_screening_instructions.package_id,
										movie_history.movie_id,
										movie_history.screening_date,
										movie_history.complex_id
					from				movie_screening_instructions
					inner join		movie_history on movie_screening_instructions.movie_id = movie_history.movie_id
					where 			instruction_type = 3
					and				movie_history.screening_date = @screening_date
					and				movie_history.complex_id = @complex_id
					group by		movie_screening_instructions.package_id,
										movie_history.movie_id,
										movie_history.screening_date,
										movie_history.complex_id) as temp_table
where			#new_spots.complex_id = temp_table.complex_id
and				#new_spots.screening_date = temp_table.screening_date
and				#new_spots.package_id = temp_table.package_id
and				#new_spots.movie_id = temp_table.movie_id

update			#new_spots
set				delete_this_row = 'Y'
where			inclusion_type = 29
and				follow_film_restricted = 'Y'

update			#new_spots
set				delete_this_row = 'N'
from				(select			campaign_package.package_id,
										movie_screening_instructions .movie_id,
										movie_history.complex_id,
										movie_history.screening_date
					from				campaign_package
					inner join		movie_screening_instructions on campaign_package.package_id = movie_screening_instructions.package_id
					inner join		movie_history on movie_screening_instructions.movie_id = movie_history.movie_id
					where			instruction_type = 1 
					and				movie_history.screening_date = @screening_date
					and				movie_history.complex_id = @complex_id) as temp_table
where			#new_spots.complex_id = temp_table.complex_id
and				#new_spots.screening_date = temp_table.screening_date
and				#new_spots.package_id = temp_table.package_id
and				#new_spots.movie_id = temp_table.movie_id

delete			#new_spots
where			delete_this_row = 'Y'

/*
select			campaign_package.package_id,
										movie_screening_instructions .movie_id
					from				campaign_package
					inner join		movie_screening_instructions on campaign_package.package_id = movie_screening_instructions.package_id
					inner join		movie_history on movie_screening_instructions.movie_id = movie_history.movie_id
					where			instruction_type = 1
					and				complex_id = 547
					and				screening_date = '7-jun-2018'
*/

commit transaction

begin transaction

insert into #new_spots2
(
	spot_id,
	campaign_no,
	package_id,
	complex_id,
	screening_date,
	billing_date,
	spot_status,
	spot_type,
	rate,
	charge_rate,
	makegood_rate,
	cinema_rate,
	spot_instruction,
	schedule_auto_create,
	billing_period,
	spot_weighting,
	cinema_weighting,
	certificate_score,
	dandc,
	onscreen,
	spot_redirect,
	inclusion_id,
	inclusion_spot_id,
	movie_id
)
select			(select max(spot_id) from campaign_spot) + row_number() over (order by #new_spots.spot_id) as spot_id,
					campaign_no,
					package_id,
					complex_id,
					screening_date,
					billing_date,
					spot_status,
					spot_type,
					rate,
					charge_rate,
					makegood_rate,
					cinema_rate,
					spot_instruction,
					schedule_auto_create,
					billing_period,
					spot_weighting,
					cinema_weighting,
					certificate_score,
					dandc,
					onscreen,
					spot_redirect,
					inclusion_id,
					inclusion_spot_id,
					movie_id
from				#new_spots

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error inserting inclusion audience spots from temp', 16, 1) 
   return -1
end	

insert into campaign_spot
(
	spot_id,
	campaign_no,
	package_id,
	complex_id,
	screening_date,
	billing_date,
	spot_status,
	spot_type,
	rate,
	charge_rate,
	makegood_rate,
	cinema_rate,
	spot_instruction,
	schedule_auto_create,
	billing_period,
	spot_weighting,
	cinema_weighting,
	certificate_score,
	dandc,
	onscreen,
	spot_redirect
)
select			spot_id,
					campaign_no,
					package_id,
					complex_id,
					screening_date,
					billing_date,
					spot_status,
					spot_type,
					rate,
					charge_rate,
					makegood_rate,
					cinema_rate,
					spot_instruction,
					schedule_auto_create,
					billing_period,
					spot_weighting,
					cinema_weighting,
					certificate_score,
					dandc,
					onscreen,
					spot_redirect
from				#new_spots2

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error inserting inclusion audience spots from temp', 16, 1) 
   return -1
end	

insert into	inclusion_campaign_spot_xref
select			spot_id,
					inclusion_id,
					inclusion_spot_id,
					movie_id
from				#new_spots2

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error inserting inclusion audience spots xref from temp', 16, 1) 
   return -1
end	

commit transaction

begin transaction



/*
 * Insert spots for all movie packages
 */

  insert into	campaign_spot
 (
	spot_id,
	campaign_no,
	package_id,
	complex_id,
	screening_date,
	billing_date,
	spot_status,
	spot_type,
	rate,
	charge_rate,
	makegood_rate,
	cinema_rate,
	spot_instruction,
	schedule_auto_create,
	billing_period,
	spot_weighting,
	cinema_weighting,
	certificate_score,
	dandc,
	onscreen,
	spot_redirect
 )
select			(select max(spot_id) from campaign_spot) + row_number() over (order by campaign_spot.package_id) as spot_id,
					campaign_spot.campaign_no,
					campaign_spot.package_id,
					campaign_spot.complex_id,
					campaign_spot.screening_date,
					billing_date,
					'A',
					'W',
					0,
					0,
					0,
					0,
					'',
					'S',
					billing_period,
					null,
					null,
					0,
					'N',
					'N',
					null
from				campaign_spot
inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id
inner join		movie_history on campaign_spot.complex_id = movie_history.complex_id and campaign_spot.screening_date = movie_history.screening_date
where			campaign_package.all_movies = 'A'
and				campaign_spot.complex_id = @complex_id
and				campaign_spot.screening_date = @screening_date
and				movie_history.movie_id <> 102
and				movie_history.advertising_open = 'Y'
and				movie_history.premium_cinema <> 'N'
and				campaign_spot.spot_status = 'A'

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror (  'Error inserting all movie spots', 16, 1)
   return -1
end	

/*
 * Insert spots for all movie packages
 */

update		sequence_no
set			next_value = next_spot_id
from			(select		max(spot_id) + 1 as next_spot_id
				from			campaign_spot) as temp_table
where		table_name = 'campaign_spot'

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error updating campaign spot sequence number table', 16, 1) 
   return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
