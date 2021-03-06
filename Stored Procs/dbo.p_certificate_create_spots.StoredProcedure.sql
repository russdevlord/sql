/****** Object:  StoredProcedure [dbo].[p_certificate_create_spots]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_create_spots]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_create_spots]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_certificate_create_spots]		@screening_date		datetime

as

declare		@error			int

set nocount on

/*
 * Insert spots for audience inclusions
 */

--Follow Film
--RoadBlock
--Movie Mix
--TAP

create table #new_spots
(
	spot_id								int,
	campaign_no							int,
	package_id							int,
	complex_id							int,
	screening_date						datetime,
	billing_date						datetime,
	spot_status							char(1),
	spot_type							char(1),
	rate								money,
	charge_rate							money,
	makegood_rate						money,
	cinema_rate							money,
	spot_instruction					varchar(100),
	schedule_auto_create				char(1),
	billing_period						datetime,
	spot_weighting						float,
	cinema_weighting					float,
	certificate_score					tinyint,
	dandc								char(1),
	onscreen							char(1),
	spot_redirect						int,
	inclusion_id						int,
	delete_this_row						char(1),
	movie_id							int,
	follow_film_restricted				char(1),
	inclusion_type						int,
	inclusion_spot_id					int
)

create table #new_spots2
(
	spot_id								int,
	campaign_no							int,
	package_id							int,
	complex_id							int,
	screening_date						datetime,
	billing_date						datetime,
	spot_status							char(1),
	spot_type							char(1),
	rate								money,
	charge_rate							money,
	makegood_rate						money,
	cinema_rate							money,
	spot_instruction					varchar(100),
	schedule_auto_create				char(1),
	billing_period						datetime,
	spot_weighting						float,
	cinema_weighting					float,
	certificate_score					tinyint,
	dandc								char(1),
	onscreen							char(1),
	spot_redirect						int,
	inclusion_id						int,
	inclusion_spot_id					int,
	movie_id							int
)

begin transaction

insert			into #new_spots	
select			(0) + row_number() over (order by inclusion_cinetam_settings.complex_id, inclusion_spot.inclusion_id) as spot_id,
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
from			inclusion_spot
inner join		inclusion_cinetam_package on inclusion_spot.inclusion_id = inclusion_cinetam_package.inclusion_id
inner join		campaign_package on inclusion_cinetam_package.package_id = campaign_package.package_id
inner join		inclusion_cinetam_settings on inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		movie_history on inclusion_cinetam_settings.complex_id = movie_history.complex_id and inclusion_spot.screening_date = movie_history.screening_date
where			inclusion_spot.screening_date = @screening_date
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



--Insert into table to get accurate sequence numbers
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
from			#new_spots

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
from			#new_spots2

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
select			(select max(spot_id) from campaign_spot) + row_number() over (order by campaign_spot.complex_id, campaign_spot.package_id) as spot_id,
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
from			campaign_spot
inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id
inner join		movie_history on campaign_spot.complex_id = movie_history.complex_id and campaign_spot.screening_date = movie_history.screening_date
where			campaign_package.all_movies = 'A'
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

update			sequence_no
set				next_value = next_spot_id
from			(select			max(spot_id) + 1 as next_spot_id
				from			campaign_spot) as temp_table
where			table_name = 'campaign_spot'

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error updating campaign spot sequence number table', 16, 1) 
   return -1
end	

commit transaction
return 0
GO
