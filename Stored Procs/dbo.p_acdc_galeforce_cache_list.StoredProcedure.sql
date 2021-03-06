/****** Object:  StoredProcedure [dbo].[p_acdc_galeforce_cache_list]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_acdc_galeforce_cache_list]
GO
/****** Object:  StoredProcedure [dbo].[p_acdc_galeforce_cache_list]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   proc [dbo].[p_acdc_galeforce_cache_list]	

as

set nocount on

/*
 * Extract complexes for the print - both dimensions
 */

select			fpfl.three_d_type,
				three_d_type_desc,
				fpfl.filename,
				fp.print_name,
				fpfl.galeforce_folder_is_UUID,
				fpfl.galeforce_transfer_date,
				fpfl.uuid,
				fp.print_id
from			campaign_package cp
inner join		print_package pp on pp.package_id = cp.package_id
inner join		campaign_spot cs on cp.package_id = cs.package_id
inner join		film_campaign fc on cp.campaign_no = fc.campaign_no
inner join		acdc_complex_details acd on cs.complex_id = acd.complex_id
inner join		complex cplx on cs.complex_id = cplx.complex_id
inner join		branch br on cplx.branch_code = br.branch_code
inner join		film_print fp on fp.print_id = pp.print_id 
inner join		film_print_file_locations fpfl ON fp.print_id = fpfl.print_id
inner join		three_d ON three_d.three_d_type = fpfl.three_d_type
where			acd.deluxe_live = 'Y'
and				fc.campaign_status <> 'P' 
and				fp.print_id not in (select original_print_id from v_print_substitution)
and				cp.used_by_date >= dateadd(wk, -13, getdate())
and				fp.print_status = 'A'
group by 		fpfl.three_d_type,
				three_d_type_desc,
				fpfl.filename,
				fp.print_name,
				fpfl.galeforce_folder_is_UUID,
				fpfl.galeforce_transfer_date,
				fpfl.uuid,
				fp.print_id
union
select			fpfl.three_d_type,
				three_d_type_desc,
				fpfl.filename,
				fp.print_name,
				fpfl.galeforce_folder_is_UUID,
				fpfl.galeforce_transfer_date,
				fpfl.uuid,
				fp.print_id
from			campaign_package cp
inner join		print_package pp on cp.package_id = pp.package_id
inner join		inclusion_cinetam_package on cp.package_id = inclusion_cinetam_package.package_id
inner join		inclusion_cinetam_settings on inclusion_cinetam_package.inclusion_id = inclusion_cinetam_settings.inclusion_id
inner join 		complex cplx on inclusion_cinetam_settings.complex_id = cplx.complex_id
inner join		branch br on cplx.branch_code = br.branch_code
inner join		acdc_complex_details acd on cplx.complex_id = acd.complex_id
inner join		film_campaign fc on cp.campaign_no = fc.campaign_no
inner join		film_print fp on pp.print_id = fp.print_id
inner join		film_print_file_locations fpfl ON fp.print_id = fpfl.print_id
inner join		three_d ON three_d.three_d_type = fpfl.three_d_type
WHERE			acd.deluxe_live = 'Y'
and		        fc.campaign_status <> 'P' 
and				fp.print_id not in (select original_print_id from v_print_substitution)
and				cp.used_by_date >= dateadd(wk, -13, getdate())
and				fp.print_status = 'A'
group by		fpfl.three_d_type,
				three_d_type_desc,
				fpfl.filename,
				fp.print_name,
				fpfl.galeforce_folder_is_UUID,
				fpfl.galeforce_transfer_date,
				fpfl.uuid,
				fp.print_id
union
select			fpfl.three_d_type,
				three_d_type_desc,
				fpfl.filename,
				fp.print_name,
				fpfl.galeforce_folder_is_UUID,
				fpfl.galeforce_transfer_date,
				fpfl.uuid,
				fp.print_id
from			campaign_package cp
inner join		print_package pp on pp.package_id = cp.package_id
inner join		campaign_spot cs on cp.package_id = cs.package_id
inner join		film_campaign fc on cp.campaign_no = fc.campaign_no
inner join		acdc_complex_details acd on cs.complex_id = acd.complex_id
inner join		complex cplx on cs.complex_id = cplx.complex_id
inner join		branch br on cplx.branch_code = br.branch_code
inner join		v_print_substitution vps on pp.print_id = vps.original_print_id and cplx.complex_id = vps.complex_id
inner join		film_print fp on vps.substitution_print_id = pp.print_id 
inner join		film_print_file_locations fpfl ON fp.print_id = fpfl.print_id
inner join		three_d ON three_d.three_d_type = fpfl.three_d_type
where			acd.deluxe_live = 'Y'
and				fc.campaign_status <> 'P' 
and				fp.print_id not in (select original_print_id from v_print_substitution)
and				cp.used_by_date >= dateadd(wk, -13, getdate())
and				fp.print_status = 'A'
group by 		fpfl.three_d_type,
				three_d_type_desc,
				fpfl.filename,
				fp.print_name,
				fpfl.galeforce_folder_is_UUID,
				fpfl.galeforce_transfer_date,
				fpfl.uuid,
				fp.print_id
union
select			fpfl.three_d_type,
				three_d_type_desc,
				fpfl.filename,
				fp.print_name,
				fpfl.galeforce_folder_is_UUID,
				fpfl.galeforce_transfer_date,
				fpfl.uuid,
				fp.print_id
from			campaign_package cp
inner join		print_package pp on cp.package_id = pp.package_id
inner join		inclusion_cinetam_package on cp.package_id = inclusion_cinetam_package.package_id
inner join		inclusion_cinetam_settings on inclusion_cinetam_package.inclusion_id = inclusion_cinetam_settings.inclusion_id
inner join 		complex cplx on inclusion_cinetam_settings.complex_id = cplx.complex_id
inner join		branch br on cplx.branch_code = br.branch_code
inner join		v_print_substitution vps on pp.print_id = vps.original_print_id and cplx.complex_id = vps.complex_id
inner join		acdc_complex_details acd on cplx.complex_id = acd.complex_id
inner join		film_campaign fc on cp.campaign_no = fc.campaign_no
inner join		film_print fp on vps.substitution_print_id = fp.print_id
inner join		film_print_file_locations fpfl ON fp.print_id = fpfl.print_id
inner join		three_d ON three_d.three_d_type = fpfl.three_d_type
WHERE			acd.deluxe_live = 'Y'
and		        fc.campaign_status <> 'P' 
and				fp.print_id not in (select original_print_id from v_print_substitution)
and				cp.used_by_date >= dateadd(wk, -13, getdate())
and				fp.print_status = 'A'
group by		fpfl.three_d_type,
				three_d_type_desc,
				fpfl.filename,
				fp.print_name,
				fpfl.galeforce_folder_is_UUID,
				fpfl.galeforce_transfer_date,
				fpfl.uuid,
				fp.print_id
order by		fpfl.three_d_type,
				three_d_type_desc,
				fpfl.filename

return 0
GO
