/****** Object:  StoredProcedure [dbo].[p_acdc_dcp_complexes]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_acdc_dcp_complexes]
GO
/****** Object:  StoredProcedure [dbo].[p_acdc_dcp_complexes]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   proc [dbo].[p_acdc_dcp_complexes]		@print_id				int,
												@country_code			char(1)

as

/*==============================================================*
 * DESC:- retrieves all the complexes that require a DCP        *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1  16-Jul-2015 DH  Initial Build                            *
 *  2  17-Jul-2015 MR  Change over to print id                  *
 *                                                              *
 *==============================================================*/

set nocount on
declare				@substition_count		int

select @substition_count = count(*) from v_print_substitution where substitution_print_id = @print_id

/*
 * Extract complexes for the print - both dimensions
 */

if  @substition_count = 0 
begin
	SELECT      fpfl.three_d_type,
				three_d_type_desc,
				cs.complex_id,
				cplx.complex_name
	FROM        campaign_package cp, 
				print_package pp, 
				campaign_spot cs,
				film_campaign fc, 
				acdc_complex_details acd,
				complex cplx,
				film_print fp 
					LEFT OUTER JOIN film_print_file_locations fpfl ON fp.print_id = fpfl.print_id AND ISNULL(country_code,'A') = @country_code
					LEFT OUTER JOIN three_d ON three_d.three_d_type = fpfl.three_d_type
	WHERE       cs.complex_id = acd.complex_id
	and			acd.arts_alliance_live = 'Y'
	and			cs.complex_id = cplx.complex_id
	AND         fc.campaign_no = cp.campaign_no
	AND         fc.campaign_status <> 'P' 
	AND         pp.package_id = cp.package_id
	AND         fc.campaign_no = cs.campaign_no
	AND         fp.print_id = pp.print_id 
	and			fp.print_id = @print_id
	and			fp.print_id not in (select original_print_id from v_print_substitution)
	GROUP BY    fpfl.three_d_type,
				three_d_type_desc,
				cs.complex_id,
				cplx.complex_name
	union
	SELECT      fpfl.three_d_type,
				three_d_type_desc,
				inclusion_cinetam_settings.complex_id,
				cplx.complex_name
	FROM        campaign_package cp, 
				print_package pp, 
				inclusion_cinetam_settings ,
				inclusion_cinetam_package ,
				acdc_complex_details acd,
				complex cplx,
				film_campaign fc, 
				film_print fp 
					LEFT OUTER JOIN film_print_file_locations fpfl ON fp.print_id = fpfl.print_id AND ISNULL(country_code,'A') = @country_code
					LEFT OUTER JOIN three_d ON three_d.three_d_type = fpfl.three_d_type
	WHERE       inclusion_cinetam_settings.complex_id = acd.complex_id
	and			inclusion_cinetam_settings.complex_id = cplx.complex_id
	and			acd.arts_alliance_live = 'Y'
	AND         fc.campaign_no = cp.campaign_no
	AND         fc.campaign_status <> 'P' 
	AND         pp.package_id = cp.package_id
	and			inclusion_cinetam_package.package_id = cp.package_id
	and			inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
	AND         fp.print_id = pp.print_id 
	and			fp.print_id = @print_id
	and			fp.print_id not in (select original_print_id from v_print_substitution)
	GROUP BY    fpfl.three_d_type,
				three_d_type_desc,
				inclusion_cinetam_settings.complex_id,
				cplx.complex_name  
	order by	fpfl.three_d_type,
				three_d_type_desc,
				cs.complex_id,
				cplx.complex_name				
end
else
begin
	SELECT      fpfl.three_d_type,
				three_d_type_desc,
				cs.complex_id,
				cplx.complex_name
	FROM        campaign_package cp, 
				print_package pp, 
				campaign_spot cs,
				film_campaign fc, 
				acdc_complex_details acd,
				complex cplx,
				v_print_substitution vps,
				film_print fp 
					LEFT OUTER JOIN film_print_file_locations fpfl ON fp.print_id = fpfl.print_id AND ISNULL(country_code,'A') = @country_code
					LEFT OUTER JOIN three_d ON three_d.three_d_type = fpfl.three_d_type
	WHERE       cs.complex_id = acd.complex_id
	and			acd.arts_alliance_live = 'Y'
	and			cs.complex_id = cplx.complex_id
	AND         fc.campaign_no = cp.campaign_no
	AND         fc.campaign_status <> 'P' 
	AND         pp.package_id = cp.package_id
	AND         fc.campaign_no = cs.campaign_no
	AND         fp.print_id = pp.print_id 
	and			vps.substitution_print_id = @print_id
	and			vps.complex_id = cs.complex_id
	and			vps.original_print_id = pp.print_id
	and			vps.three_d_type =  fpfl.three_d_type
	GROUP BY    fpfl.three_d_type,
				three_d_type_desc,
				cs.complex_id,
				cplx.complex_name
	union
	SELECT      fpfl.three_d_type,
				three_d_type_desc,
				inclusion_cinetam_settings.complex_id,
				cplx.complex_name
	FROM        campaign_package cp, 
				print_package pp, 
				inclusion_cinetam_settings ,
				inclusion_cinetam_package ,
				acdc_complex_details acd,
				complex cplx,
				film_campaign fc, 
				v_print_substitution vps,
				film_print fp 
					LEFT OUTER JOIN film_print_file_locations fpfl ON fp.print_id = fpfl.print_id AND ISNULL(country_code,'A') = @country_code
					LEFT OUTER JOIN three_d ON three_d.three_d_type = fpfl.three_d_type
	WHERE       inclusion_cinetam_settings.complex_id = acd.complex_id
	and			inclusion_cinetam_settings.complex_id = cplx.complex_id
	and			acd.arts_alliance_live = 'Y'
	AND         fc.campaign_no = cp.campaign_no
	AND         fc.campaign_status <> 'P' 
	AND         pp.package_id = cp.package_id
	and			inclusion_cinetam_package.package_id = cp.package_id
	and			inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
	AND         fp.print_id = pp.print_id 
	and			vps.substitution_print_id = @print_id
	and			vps.complex_id = inclusion_cinetam_settings.complex_id
	and			vps.original_print_id = pp.print_id
	and			vps.three_d_type =  fpfl.three_d_type
	GROUP BY    fpfl.three_d_type,
				three_d_type_desc,
				inclusion_cinetam_settings.complex_id,
				cplx.complex_name  
	order by	fpfl.three_d_type,
				three_d_type_desc,
				cs.complex_id,
				cplx.complex_name				
end
return 0
GO
