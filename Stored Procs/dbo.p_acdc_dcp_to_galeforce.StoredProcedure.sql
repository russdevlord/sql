USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_acdc_dcp_to_galeforce]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   proc [dbo].[p_acdc_dcp_to_galeforce]		@country_code              char(1), 
                                                    @screening_date            datetime,
                                                    @projecting_next_x_days    smallint

as

/*==============================================================*
 * DESC:- send missing DCP to Galeforce.                        *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1  23-Nov-2016 DH  Initial Build                            *
 *                                                              *
 *==============================================================*/

set nocount on

DECLARE	@screening_date_end_range datetime

SELECT @screening_date_end_range = DATEADD(D,@projecting_next_x_days,@screening_date)

/*
 * Extract content for the complex
 */
 
SELECT    DISTINCT cs.complex_id,
				CONVERT(smallint,-1) AS file_validation_status,
				cp.campaign_no,
				fp.print_id,
				fp.print_name + ' [' + ISNULL(three_d.three_d_type_desc,'') + ']' AS print_name,
				MAX(fpfl.print_revision) AS print_revision,
				convert(varchar(255),null) AS filepath,
				convert(varchar(50),null) AS uuid,
				CONVERT(varchar(255),'No media has been linked to this print') AS error_msg,
				fp.actual_durAtion,
				fpfl.three_d_type,
				three_d_type_desc
INTO        #tmp_prints
FROM        campaign_package cp, 
				print_package pp, 
				film_campaign_complex cs,
				film_campaign fc, 
				film_print fp 
                LEFT OUTER JOIN film_print_file_locations fpfl ON fp.print_id = fpfl.print_id AND ISNULL(country_code,'A') = @country_code
                LEFT OUTER JOIN three_d ON three_d.three_d_type = fpfl.three_d_type
WHERE      (cs.complex_id IN (SELECT complex_id FROM acdc_complex_details WHERE ISNULL(deluxe_live,'N') = 'Y'))
AND         fc.start_date <= @screening_date_end_range
AND         fc.makeup_deadline >= @screening_date
AND         fc.campaign_no = cp.campaign_no
AND         fc.campaign_status <> 'P' 
AND         pp.package_id = cp.package_id
AND         fc.campaign_no = cs.campaign_no
AND         fp.print_id = pp.print_id 
and			  cp.package_id in (	select      package_id
								from        campaign_spot
								where       (campaign_no = fc.campaign_no or campaign_no is null) 
								and         complex_id = cs.complex_id 
								and         spot_status <> 'P'
								group by    package_id	)
GROUP BY    cs.complex_id,
            cp.campaign_no,
            fp.print_id,    
            fp.print_name,
            fp.actual_duration,
            fpfl.three_d_type,
            three_d_type_desc
ORDER BY    fp.print_id

insert into #tmp_prints
SELECT      DISTINCT cs.complex_id,
            CONVERT(smallint,-1) AS file_validation_status,
            cp.campaign_no,
            fp.print_id,
            fp.print_name + ' [' + ISNULL(three_d.three_d_type_desc,'') + ']' AS print_name,
            MAX(fpfl.print_revision) AS print_revision,
            convert(varchar(255),null) AS filepath,
            convert(varchar(50),null) AS uuid,
            CONVERT(varchar(255),'No media has been linked to this print') AS error_msg,
            fp.actual_durAtion,
            fpfl.three_d_type,
            three_d_type_desc
FROM        campaign_package cp, 
            print_package pp, 
            film_campaign_complex cs,
            film_campaign fc, 
            v_print_substitution vps,
            film_print fp 
                LEFT OUTER JOIN film_print_file_locations fpfl ON fp.print_id = fpfl.print_id AND ISNULL(country_code,'A') = @country_code
                LEFT OUTER JOIN three_d ON three_d.three_d_type = fpfl.three_d_type
WHERE      (cs.complex_id IN (SELECT complex_id FROM acdc_complex_details WHERE ISNULL(deluxe_live,'N') = 'Y'))
AND         fc.start_date <= @screening_date_end_range
AND         fc.makeup_deadline >= @screening_date
AND         fc.campaign_no = cp.campaign_no
AND         fc.campaign_status <> 'P' 
AND         pp.package_id = cp.package_id
AND         fc.campaign_no = cs.campaign_no
and			vps.print_package_id = pp.print_package_id
and			vps.substitution_print_id = fp.print_id
and			vps.complex_id = cs.complex_id
and			vps.three_d_type =  fpfl.three_d_type
and         cp.package_id in (	select      package_id
								from        campaign_spot
								where       (campaign_no = fc.campaign_no or campaign_no is null) 
								and         complex_id = cs.complex_id 
								and         spot_status <> 'P'
								group by    package_id	)
GROUP BY    cs.complex_id,
            cp.campaign_no,
            fp.print_id,    
            fp.print_name,
            fp.actual_duration,
            fpfl.three_d_type,
            three_d_type_desc
ORDER BY    fp.print_id

insert into #tmp_prints
SELECT      DISTINCT inclusion_cinetam_settings.complex_id,
            CONVERT(smallint,-1) AS file_validation_status,
            cp.campaign_no,
            fp.print_id,
            fp.print_name + ' [' + ISNULL(three_d.three_d_type_desc,'') + ']' AS print_name,
            MAX(fpfl.print_revision) AS print_revision,
            convert(varchar(255),null) AS filepath,
            convert(varchar(50),null) AS uuid,
            CONVERT(varchar(255),'No media has been linked to this print') AS error_msg,
            fp.actual_durAtion,
            fpfl.three_d_type,
            three_d_type_desc
FROM        campaign_package cp, 
            print_package pp, 
            inclusion_cinetam_settings ,
            inclusion_cinetam_package ,
            film_campaign fc, 
            v_print_substitution vps,
            film_print fp 
                LEFT OUTER JOIN film_print_file_locations fpfl ON fp.print_id = fpfl.print_id AND ISNULL(country_code,'A') = @country_code
                LEFT OUTER JOIN three_d ON three_d.three_d_type = fpfl.three_d_type
WHERE      (inclusion_cinetam_settings.complex_id IN (SELECT complex_id FROM acdc_complex_details WHERE ISNULL(deluxe_live,'N') = 'Y'))
AND         fc.start_date <= @screening_date_end_range
AND         fc.makeup_deadline >= @screening_date
AND         fc.campaign_no = cp.campaign_no
AND         fc.campaign_status <> 'P' 
AND         pp.package_id = cp.package_id
and			inclusion_cinetam_package.package_id = cp.package_id
and			inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
AND         fp.print_id = pp.print_id 
and			vps.print_package_id = pp.print_package_id
and			vps.substitution_print_id = fp.print_id
and			vps.complex_id = inclusion_cinetam_settings.complex_id
and			vps.three_d_type =  fpfl.three_d_type
GROUP BY    inclusion_cinetam_settings.complex_id,
					cp.campaign_no,
					fp.print_id,    
					fp.print_name,
					fp.actual_duration,
					fpfl.three_d_type,
					three_d_type_desc      
ORDER BY    fp.print_id

insert into #tmp_prints
SELECT      DISTINCT inclusion_cinetam_settings.complex_id,
            CONVERT(smallint,-1) AS file_validation_status,
            cp.campaign_no,
            fp.print_id,
            fp.print_name + ' [' + ISNULL(three_d.three_d_type_desc,'') + ']' AS print_name,
            MAX(fpfl.print_revision) AS print_revision,
            convert(varchar(255),null) AS filepath,
            convert(varchar(50),null) AS uuid,
            CONVERT(varchar(255),'No media has been linked to this print') AS error_msg,
            fp.actual_durAtion,
            fpfl.three_d_type,
            three_d_type_desc
FROM        campaign_package cp, 
            print_package pp, 
            v_print_substitution vps,
            inclusion_cinetam_settings ,
            inclusion_cinetam_package ,
            film_campaign fc, 
            film_print fp 
                LEFT OUTER JOIN film_print_file_locations fpfl ON fp.print_id = fpfl.print_id AND ISNULL(country_code,'A') = @country_code
                LEFT OUTER JOIN three_d ON three_d.three_d_type = fpfl.three_d_type
WHERE      (inclusion_cinetam_settings.complex_id IN (SELECT complex_id FROM acdc_complex_details WHERE ISNULL(deluxe_live,'N') = 'Y'))
AND         fc.start_date <= @screening_date_end_range
AND         fc.makeup_deadline >= @screening_date
AND         fc.campaign_no = cp.campaign_no
AND         fc.campaign_status <> 'P' 
AND         pp.package_id = cp.package_id
and			inclusion_cinetam_package.package_id = cp.package_id
and			inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
and			vps.print_package_id = pp.print_package_id
and			vps.substitution_print_id = fp.print_id
and			vps.complex_id = inclusion_cinetam_settings.complex_id
and			vps.three_d_type =  fpfl.three_d_type
GROUP BY	inclusion_cinetam_settings.complex_id,
            cp.campaign_no,
			fp.print_id,    
			fp.print_name,
			fp.actual_duration,
			fpfl.three_d_type,
			three_d_type_desc      
ORDER BY    fp.print_id

update	#tmp_prints
set		#tmp_prints.print_id = substitution_print_id,
		print_name = fp.print_name + ' [' + ISNULL(three_d.three_d_type_desc,'') + ']',
		actual_duration = fp.duration
from	v_print_substitution, 
		film_print fp,
		three_d
where	#tmp_prints.print_id = original_print_id
and		fp.print_id = v_print_substitution.substitution_print_id
and		v_print_substitution.complex_id = #tmp_prints.complex_id
and		v_print_substitution.print_medium = 'D'
and		#tmp_prints.three_d_type = v_print_substitution.three_d_type
and		three_d.three_d_type = v_print_substitution.three_d_type
AND     v_print_substitution.start_date <= @screening_date_end_range
AND     v_print_substitution.used_by_date >= @screening_date

/*
 * Set the filepath for the revision
 */

UPDATE #tmp_prints
   SET file_validation_status = CASE fpfl.print_verified WHEN 'Y' THEN 1 ELSE -1 END,
       filepath = fpfl.filepath,
       uuid = fpfl.uuid,
       error_msg = CASE fpfl.print_verified WHEN 'Y' THEN null ELSE 'Content has not been verified on-screen' END
  FROM #tmp_prints tp, film_print_file_locations fpfl
 WHERE fpfl.print_id = tp.print_id
  AND  fpfl.three_d_type = tp.three_d_type
--DIH 26OCT2010 - Not required:  AND  fpfl.print_revision = tp.print_revision

/*
 * Don't report known missing media as an error
 */

UPDATE #tmp_prints
   SET file_validation_status = -2,
       error_msg = 'This media is known to be missing'
  FROM #tmp_prints tp LEFT OUTER JOIN acdc_missing_media mm ON tp.print_id = mm.print_id
 WHERE tp.file_validation_status = -1 
  AND  mm.print_id IS NOT NULL

/*
 * Flag 3D prints if the complex is 2D only
 */

UPDATE #tmp_prints
   SET file_validation_status = -2,
       error_msg = '3D ad is skipped for this complex'
 WHERE three_d_type <> 1
  AND  NOT EXISTS (SELECT TOP 1 complex_id FROM complex_three_d_type_xref WHERE complex_id = #tmp_prints.complex_id AND three_d_type <> 1)

/*
 * return the results
 */

SELECT DISTINCT TP.file_validation_status,
		TP.print_id,
		TP.three_d_type,
		TP.print_revision,
		TP.print_name,
		TP.filepath,
		TP.error_msg,
		FPFL.galeforce_transfer_date
FROM	#tmp_prints TP LEFT OUTER JOIN film_print_file_locations FPFL ON FPFL.print_id = TP.print_id AND FPFL.three_d_type = TP.three_d_type AND FPFL.country_code = @country_code
WHERE   FPFL.galeforce_transfer_date IS NULL
ORDER BY TP.file_validation_status,
		TP.print_id

DROP TABLE #tmp_prints

return 0
GO
