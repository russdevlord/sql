/****** Object:  StoredProcedure [dbo].[p_acdc_galeforce_cache_dead_prints]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_acdc_galeforce_cache_dead_prints]
GO
/****** Object:  StoredProcedure [dbo].[p_acdc_galeforce_cache_dead_prints]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[p_acdc_galeforce_cache_dead_prints]  @country_code		char(1)

as

declare		@min_date					datetime,
					@max_date				datetime
					
set nocount on

select @min_date  = dateadd(wk, -13, (select screening_date from film_screening_dates where screening_date_status = 'C'))
select @max_date  = dateadd(wk, 26, (select screening_date from film_screening_dates where screening_date_status = 'C'))

create table #prints
(
print_id							int,
complex_id						int,
print_package_id			int
)

insert into		#prints
SELECT			pp.print_id, 
						c.complex_id,
						pp.print_package_id
FROM				campaign_package cp, 
						print_package  pp, 
						film_campaign_complex  cs,
						film_campaign  fc,
						complex  c,
						(	select			package_id,
												complex_id
							from				campaign_spot 
							where			spot_status <> 'P'
							group by		package_id,
												complex_id) as pack_tmp					
WHERE			fc.start_date <= @max_date
and					fc.makeup_deadline >= @min_date 
and					fc.campaign_no = cp.campaign_no
and					fc.campaign_status <> 'P' 
and					pp.package_id = cp.package_id
and					c.complex_id = cs.complex_id
and					fc.campaign_no = cs.campaign_no
and					cp.package_id = pack_tmp.package_id
and					pp.package_id = pack_tmp.package_id
and					c.complex_id = pack_tmp.complex_id
and					pack_tmp.complex_id = cs.complex_id
and					c.branch_code in (select branch_code from branch where country_code = @country_code)
GROUP BY		pp.print_id, 
						c.complex_id,
						pp.print_package_id
ORDER BY		c.complex_id

insert into		#prints
SELECT			pp.print_id, 
						c.complex_id,
						pp.print_package_id
FROM				campaign_package cp, 
						print_package pp, 
						inclusion_cinetam_settings ,
						inclusion_cinetam_package ,
						film_campaign fc, 
						film_print fp,
						complex c
WHERE			inclusion_cinetam_settings.complex_id = c.complex_id
and					fc.start_date <= @max_date
AND					fc.makeup_deadline >= @min_date 
AND					fc.campaign_no = cp.campaign_no
AND					fc.campaign_status <> 'P' 
AND					pp.package_id = cp.package_id
and					inclusion_cinetam_package.package_id = cp.package_id
and					inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
AND					fp.print_id = pp.print_id 
and					c.branch_code in (select branch_code from branch where country_code = @country_code)
GROUP BY		pp.print_id, 
						c.complex_id,
						pp.print_package_id

update				#prints
set					#prints.print_id = substitution_print_id
from					film_campaign_print_substitution
where				#prints.print_package_id = film_campaign_print_substitution.print_package_id
and					#prints.print_id = film_campaign_print_substitution.original_print_id
and					#prints.complex_id = film_campaign_print_substitution.complex_id

select				film_print_file_locations.print_id,  
						CASE WHEN ISNULL(galeforce_folder_is_UUID,'N') = 'Y' THEN CONVERT(VARCHAR(10),film_print_file_locations.print_id) + ' - '+ filename ELSE filepath END AS filepath,
						filename,
						uuid,
						galeforce_transfer_date
from					#prints, 
						film_print_file_locations
where				#prints.print_id = film_print_file_locations.print_id
 and					film_print_file_locations.country_code = @country_code
group by			film_print_file_locations.print_id,  
						CASE WHEN ISNULL(galeforce_folder_is_UUID,'N') = 'Y' THEN CONVERT(VARCHAR(10),film_print_file_locations.print_id) + ' - '+ filename ELSE filepath END,
						filename,
						uuid,
						galeforce_transfer_date
order by			film_print_file_locations.print_id
				
return 0
GO
