/****** Object:  StoredProcedure [dbo].[p_seedooh_print_uuid_detailed_api]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_seedooh_print_uuid_detailed_api]
GO
/****** Object:  StoredProcedure [dbo].[p_seedooh_print_uuid_detailed_api]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







create proc [dbo].[p_seedooh_print_uuid_detailed_api]		@uuid				char(36),
															@session_time		datetime,
															@complex_id			int

as

select			agency_name as 'client.booking_agency_name',
				client_name as 'client.client_name',
				client_product_desc as 'client.client_product_desc',
				filepath as 'print.filepath',
				filename as 'print.filename',
				uuid as 'print.print_uuid',
				film_print.print_id as 'print.content_id',
				print_name as  'print.content_name',
				film_campaign.campaign_no as 'campaign.campaign_no',
				product_desc as 'campaign.product_desc',
				package_code as 'campaign.package_code',
				package_desc as 'campaign.package_desc', 
				business_unit_desc as 'campaign.business_unit_desc', 
				campaign_type_desc as 'campaign.campaign_type',
				campaign_package.start_date as 'campaign.start_date',
				campaign_package.used_by_date as 'campaign.used_by_date',
				(select 		movie_name 
				from 			data_translate_movie  with (nolock) 
				where 			movie_history.movie_id = data_translate_movie.movie_id 
				and 			data_provider_id in (	select			data_provider_id 
														from 			data_translate_complex  with (nolock) 
														where 			complex_id = campaign_spot.complex_id) 
				and 			process_date = (		select 			max(process_date) 
														from 			data_translate_movie with (nolock)  
														where 			data_provider_id in (	select			data_provider_id 
																								from 			data_translate_complex  with (nolock) 
																								where 			complex_id = campaign_spot.complex_id) 
														and 			data_translate_movie.movie_id = movie_history.movie_id)) as 'playlist.movie_name',
				movie_history.occurence as 'playlist.playlist_no',
				complex_name as'playlist.complex_name'
from			film_print_file_locations fpfl with (nolock) 
inner join		film_print  with (nolock) on fpfl.print_id = film_print.print_id
inner join		certificate_item with (nolock)  on fpfl.print_id = certificate_item.print_id
inner join		campaign_spot  with (nolock) on certificate_item.spot_reference = campaign_spot.spot_id
inner join		campaign_package  with (nolock) on campaign_spot.package_id = campaign_package.package_id
inner join		film_campaign  with (nolock) on campaign_package.campaign_no = film_campaign.campaign_no
inner join		agency  with (nolock) on film_campaign.agency_id = agency.agency_id
inner join		client  with (nolock) on film_campaign.client_id = client.client_id
inner join		client_product  with (nolock) on film_campaign.client_product_id = client_product.client_product_id
inner join		business_unit with (nolock)  on film_campaign.business_unit_id = business_unit.business_unit_id
inner join		campaign_type with (nolock) on film_campaign.campaign_type = campaign_type.campaign_type_code
inner join		movie_history with (nolock)  on certificate_item.certificate_group = movie_history.certificate_group
inner join		complex  with (nolock) on movie_history.complex_id = complex.complex_id
where			fpfl.uuid = @uuid
and				campaign_spot.screening_date between  dateadd(ss, 1, dateadd(wk, -1, @session_time)) and @session_time
and				campaign_spot.complex_id = @complex_id
and				film_campaign.campaign_status <> 'P'
and				fpfl.print_id not in (select print_id from film_print_end_tags with (nolock) )
and				movie_history.movie_id <> 102
group by		filepath, 
				filename, 
				uuid, 
				film_print.print_id, 
				print_name, 
				film_campaign.campaign_no, 
				product_desc, 
				package_code, 
				package_desc, 
				agency_name, 
				client_name, 
				business_unit_desc, 
				campaign_type_desc,
				client_product_desc,
				campaign_package.start_date,
				campaign_package.used_by_date,
				movie_history.movie_id,
				campaign_spot.complex_id,
				movie_history.occurence,
				complex_name
union all
select			agency_name as 'client.booking_agency_name',
				client_name as 'client.client_name',
				client_product_desc as 'client.client_product_desc',
				filepath as 'print.filepath',
				filename as 'print.filename',
				uuid as 'print.print_uuid',
				film_print.print_id as 'print.content_id',
				print_name as  'print.content_name',
				film_campaign.campaign_no as 'campaign.campaign_no',
				product_desc as 'campaign.product_desc',
				package_code as 'campaign.package_code',
				package_desc as 'campaign.package_desc', 
				business_unit_desc as 'campaign.business_unit_desc', 
				campaign_type_desc as 'campaign.campaign_type',
				campaign_package.start_date as 'campaign.start_date',
				campaign_package.used_by_date as 'campaign.used_by_date',
				movie.long_name as 'playlist.movie_name',
				movie_history.occurence as 'playlist.playlist_no',
				complex_name as'playlist.complex_name'
from			film_print_file_locations fpfl with (nolock) 
inner join		film_print  with (nolock) on fpfl.print_id = film_print.print_id
inner join		certificate_item  with (nolock) on fpfl.print_id = certificate_item.print_id
inner join		campaign_spot  with (nolock) on certificate_item.spot_reference = campaign_spot.spot_id
inner join		campaign_package  with (nolock) on campaign_spot.package_id = campaign_package.package_id
inner join		film_campaign  with (nolock) on campaign_package.campaign_no = film_campaign.campaign_no
inner join		agency  with (nolock) on film_campaign.agency_id = agency.agency_id
inner join		client  with (nolock) on film_campaign.client_id = client.client_id
inner join		client_product with (nolock)  on film_campaign.client_product_id = client_product.client_product_id
inner join		business_unit with (nolock)  on film_campaign.business_unit_id = business_unit.business_unit_id
inner join		campaign_type with (nolock)  on film_campaign.campaign_type = campaign_type.campaign_type_code
inner join		movie_history with (nolock)  on certificate_item.certificate_group = movie_history.certificate_group
inner join		movie with (nolock)  on movie_history.movie_id = movie.movie_id
inner join		complex  with (nolock) on movie_history.complex_id = complex.complex_id
where			fpfl.uuid = @uuid
and				campaign_spot.screening_date between  dateadd(ss, 1, dateadd(wk, -1, @session_time)) and @session_time
and				campaign_spot.complex_id = @complex_id
and				film_campaign.campaign_status <> 'P'
and				fpfl.print_id not in (select print_id from film_print_end_tags  with (nolock) )
and				movie_history.movie_id = 102
group by		filepath, 
				filename, 
				uuid, 
				film_print.print_id, 
				print_name, 
				film_campaign.campaign_no, 
				product_desc, 
				package_code, 
				package_desc, 
				agency_name, 
				client_name, 
				business_unit_desc, 
				campaign_type_desc,
				client_product_desc,
				campaign_package.start_date,
				campaign_package.used_by_date,
				movie_history.movie_id,
				campaign_spot.complex_id,
				movie_history.occurence,
				complex_name,
				long_name
for json path
return 0
GO
