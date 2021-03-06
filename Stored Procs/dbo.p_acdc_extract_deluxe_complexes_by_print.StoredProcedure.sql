/****** Object:  StoredProcedure [dbo].[p_acdc_extract_deluxe_complexes_by_print]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_acdc_extract_deluxe_complexes_by_print]
GO
/****** Object:  StoredProcedure [dbo].[p_acdc_extract_deluxe_complexes_by_print]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   proc [dbo].[p_acdc_extract_deluxe_complexes_by_print]		@print_id						int

as

/*==============================================================*
 * DESC:- retrieves ad content files for distribution.										*
 *																																*
 *                       CHANGE HISTORY																	*
 *                       ==============																			*
 *																																*
 * Ver    DATE     BY   DESCRIPTION																	*
 * === =========== ===  ===========																*
 *  1  12-Jul-2016 MR   Initial Build																		*
 *																																*
 *==============================================================	*/

set nocount on

--DECLARE	@screening_date_end_range datetime
DECLARE	@country_code			char(1),
					@screening_date		datetime
					
SELECT		@screening_date = getdate()

/*
 * Extract content for the print
 */
 
SELECT			c.complex_id, 
						c.complex_name,
						pp.print_package_id
INTO				#tmp_complexes
FROM				campaign_package cp, 
						print_package  pp, 
						film_campaign_complex  cs,
						film_campaign  fc,
						complex  c,
						((	select			package_id,
												complex_id
							from				campaign_spot 
							where			spot_status <> 'P'
							group by		package_id,
												complex_id)) as pack_tmp					
WHERE			fc.makeup_deadline >= @screening_date
AND					fc.campaign_no = cp.campaign_no
AND					fc.campaign_status <> 'P' 
AND					pp.package_id = cp.package_id
and					c.complex_id = cs.complex_id
AND					fc.campaign_no = cs.campaign_no
AND					pp.print_id = @print_id
and					cp.package_id = pack_tmp.package_id
and					pp.package_id = pack_tmp.package_id
and					c.complex_id = pack_tmp.complex_id
and					pack_tmp.complex_id = cs.complex_id
GROUP BY		c.complex_id, 
						c.complex_name,
						pp.print_package_id
ORDER BY		c.complex_id, 
						c.complex_name

insert into		#tmp_complexes
SELECT			c.complex_id, 
						c.complex_name,
						pp.print_package_id
FROM				campaign_package cp, 
						print_package pp, 
						film_campaign_complex cs,
						film_campaign fc,
						v_print_substitution vps,
						complex c,
						((	select			package_id,
												complex_id
							from				campaign_spot
							where			spot_status <> 'P'
							group by		package_id,
												complex_id)) as pack_tmp					
WHERE			fc.makeup_deadline >= @screening_date
AND					fc.campaign_no = cp.campaign_no
AND					fc.campaign_status <> 'P' 
AND					pp.package_id = cp.package_id
and					c.complex_id = cs.complex_id
AND					fc.campaign_no = cs.campaign_no
AND					pp.print_id = vps.original_print_id
and					vps.substitution_print_id = @print_id
and					cp.package_id = pack_tmp.package_id
and					pp.package_id = pack_tmp.package_id
and					c.complex_id = pack_tmp.complex_id
and					pack_tmp.complex_id = cs.complex_id
and					c.complex_id = vps.complex_id
and					pack_tmp.complex_id = vps.complex_id
and					vps.complex_id = cs.complex_id
GROUP BY		c.complex_id, 
						c.complex_name,
						pp.print_package_id
ORDER BY		c.complex_id, 
						c.complex_name

insert into		#tmp_complexes
SELECT			c.complex_id, 
						c.complex_name,
						pp.print_package_id
FROM				campaign_package cp, 
						print_package pp, 
						inclusion_cinetam_settings ,
						inclusion_cinetam_package ,
						film_campaign fc, 
						complex c
WHERE			fc.makeup_deadline >= @screening_date
AND					fc.campaign_no = cp.campaign_no
AND					fc.campaign_status <> 'P' 
AND					pp.package_id = cp.package_id
and					inclusion_cinetam_package.package_id = cp.package_id
and					inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
AND					pp.print_id = @print_id
and					inclusion_cinetam_settings.complex_id = c.complex_id
GROUP BY		c.complex_id, 
						c.complex_name,
						pp.print_package_id
ORDER BY		c.complex_id, 
						c.complex_name
						
						

insert into		#tmp_complexes
SELECT			c.complex_id, 
						c.complex_name,
						pp.print_package_id
FROM				campaign_package cp, 
						print_package pp, 
						v_print_substitution vps,
						inclusion_cinetam_settings ,
						inclusion_cinetam_package ,
						film_campaign fc, 
						complex c
WHERE			fc.makeup_deadline >= @screening_date
AND					fc.campaign_no = cp.campaign_no
AND					fc.campaign_status <> 'P' 
AND					pp.package_id = cp.package_id
and					inclusion_cinetam_package.package_id = cp.package_id
and					inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
and					vps.print_package_id = pp.print_package_id
and					c.complex_id = inclusion_cinetam_settings.complex_id
and					vps.substitution_print_id = @print_id
and					vps.complex_id = c.complex_id
GROUP BY		c.complex_id, 
						c.complex_name,
						pp.print_package_id
ORDER BY		c.complex_id, 
						c.complex_name

/* 
 * Remove complexes where there is a  substitution for the host print
 */ 

delete			#tmp_complexes
from				v_print_substitution vps
where			original_print_id = @print_id
and				#tmp_complexes.complex_id = vps.complex_id
and				#tmp_complexes.print_package_id = vps.print_package_id


/*
 * return the results
 */

SELECT		DISTINCT TC.complex_id,TC.complex_name,ACD.deluxe_site_id, ACD.site_code
FROM			#tmp_complexes TC JOIN acdc_complex_details ACD ON ACD.complex_id = TC.complex_id AND ISNULL(deluxe_live,'N') = 'Y'
order by		TC.complex_name	

return 0
GO
