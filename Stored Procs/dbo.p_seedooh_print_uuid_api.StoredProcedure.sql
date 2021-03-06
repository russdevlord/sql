/****** Object:  StoredProcedure [dbo].[p_seedooh_print_uuid_api]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_seedooh_print_uuid_api]
GO
/****** Object:  StoredProcedure [dbo].[p_seedooh_print_uuid_api]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





create proc [dbo].[p_seedooh_print_uuid_api]		@uuid	char(36)

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
				campaign_package.used_by_date as 'campaign.used_by_date'
from			film_print_file_locations fpfl with (nolock) 
inner join		film_print with (nolock)  on fpfl.print_id = film_print.print_id
inner join		v_print_package_incl_subs with (nolock)  on v_print_package_incl_subs.print_id = fpfl.print_id
inner join		campaign_package with (nolock)  on v_print_package_incl_subs.package_id = campaign_package.package_id
inner join		film_campaign with (nolock)  on campaign_package.campaign_no = film_campaign.campaign_no
inner join		agency with (nolock)  on film_campaign.agency_id = agency.agency_id
inner join		client with (nolock)  on film_campaign.client_id = client.client_id
inner join		client_product with (nolock)  on film_campaign.client_product_id = client_product.client_product_id
inner join		business_unit with (nolock)  on film_campaign.business_unit_id = business_unit.business_unit_id
inner join		campaign_type with (nolock)  on film_campaign.campaign_type = campaign_type.campaign_type_code
where			fpfl.uuid = @uuid
and				fpfl.print_id not in (select print_id from film_print_end_tags with (nolock) )
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
				campaign_package.used_by_date
/*union all		
select			'VM Ident' as 'client.booking_agency_name',
				'VM Ident' as 'client.client_name',
				'VM Ident' as 'client.client_product_desc',
				filepath as 'print.filepath',
				filename as 'print.filename',
				uuid as 'print.print_uuid',
				film_print.print_id as 'print.content_id',
				print_name as  'print.content_name',
				-200 as 'campaign.campaign_no',
				'VM Ident' as 'campaign.product_desc',
				'VM Ident' as 'campaign.package_code',
				'VM Ident' as 'campaign.package_desc', 
				'VM Ident' as 'campaign.business_unit_desc', 
				'VM Ident' as 'campaign.campaign_type',
				convert(datetime, '1-jan-1980') as 'campaign.start_date',
				convert(datetime, '1-jan-2100') as 'campaign.used_by_date'
from			film_print_file_locations fpfl
inner join		film_print on fpfl.print_id = film_print.print_id
where			fpfl.uuid = @uuid
and				fpfl.print_id in (select print_id from film_print_end_tags)
group by		filepath,
				filename,
				uuid,
				film_print.print_id,
				print_name*/
for json path
return 0
GO
