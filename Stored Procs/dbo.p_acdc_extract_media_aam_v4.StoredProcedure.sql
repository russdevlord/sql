/****** Object:  StoredProcedure [dbo].[p_acdc_extract_media_aam_v4]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_acdc_extract_media_aam_v4]
GO
/****** Object:  StoredProcedure [dbo].[p_acdc_extract_media_aam_v4]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   proc [dbo].[p_acdc_extract_media_aam_v4]		@complex_id                int,
                                            @screening_date            datetime

as

/*==============================================================*
 * DESC:- retrieves ad content files for distribution.          *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1  21-Jul-2015 DH   Initial Build                           *
 *  2  17-Jan-2019 DH  new storage location for ACDC            *
 *                                                              *
 *==============================================================*/

set nocount on

DECLARE	@screening_date_end_range datetime
DECLARE	@country_code CHAR(1)

SELECT @screening_date_end_range = DATEADD(d,21,@screening_date)

SELECT @country_code = CASE state_code WHEN 'NZ' THEN 'Z' ELSE 'A' END FROM complex WHERE complex_id = @complex_id 

/*
 * Extract content for the complex
 */
 
SELECT      DISTINCT CONVERT(smallint,-1) AS file_validation_status,
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
WHERE      (cs.complex_id IN (SELECT shared_complex_id FROM acdc_disc_shares WHERE complex_id = @complex_id AND shared_complex_id <> 0 UNION SELECT @complex_id))
AND         fc.start_date <= @screening_date_end_range
AND         fc.makeup_deadline >= @screening_date
AND         fc.campaign_no = cp.campaign_no
AND         fc.campaign_status <> 'P' 
AND         pp.package_id = cp.package_id
AND         fc.campaign_no = cs.campaign_no
AND         fp.print_id = pp.print_id 
and         cp.package_id in (	select      package_id
								from        campaign_spot
								where       (campaign_no = fc.campaign_no or campaign_no is null) 
								and         complex_id = cs.complex_id 
								and         spot_status <> 'P'
								group by    package_id)
GROUP BY    cp.campaign_no,
            fp.print_id,    
            fp.print_name,
            fp.actual_duration,
            fpfl.three_d_type,
            three_d_type_desc
ORDER BY    fp.print_id

insert into #tmp_prints
SELECT      DISTINCT CONVERT(smallint,-1) AS file_validation_status,
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
WHERE      (cs.complex_id IN (SELECT shared_complex_id FROM acdc_disc_shares WHERE complex_id = @complex_id AND shared_complex_id <> 0 UNION SELECT @complex_id))
AND         fc.start_date <= @screening_date_end_range
AND         fc.makeup_deadline >= @screening_date
AND         fc.campaign_no = cp.campaign_no
AND         fc.campaign_status <> 'P' 
AND         pp.package_id = cp.package_id
AND         fc.campaign_no = cs.campaign_no
and			vps.print_package_id = pp.print_package_id
and			vps.substitution_print_id = fp.print_id
and			vps.complex_id = @complex_id
and			vps.three_d_type =  fpfl.three_d_type
and         cp.package_id in (	select      package_id
								from        campaign_spot
								where       (campaign_no = fc.campaign_no or campaign_no is null) 
								and         complex_id = cs.complex_id 
								and         spot_status <> 'P'
								group by    package_id)
GROUP BY    cp.campaign_no,
            fp.print_id,    
            fp.print_name,
            fp.actual_duration,
            fpfl.three_d_type,
            three_d_type_desc
ORDER BY    fp.print_id



insert into #tmp_prints
SELECT      DISTINCT CONVERT(smallint,-1) AS file_validation_status,
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
            film_print fp 
                LEFT OUTER JOIN film_print_file_locations fpfl ON fp.print_id = fpfl.print_id AND ISNULL(country_code,'A') = @country_code
                LEFT OUTER JOIN three_d ON three_d.three_d_type = fpfl.three_d_type
WHERE      (inclusion_cinetam_settings.complex_id IN (SELECT shared_complex_id FROM acdc_disc_shares WHERE complex_id = @complex_id AND shared_complex_id <> 0 UNION SELECT @complex_id))
AND         fc.start_date <= @screening_date_end_range
AND         fc.makeup_deadline >= @screening_date
AND         fc.campaign_no = cp.campaign_no
AND         fc.campaign_status <> 'P' 
AND         pp.package_id = cp.package_id
and			inclusion_cinetam_package.package_id = cp.package_id
and			inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
AND         fp.print_id = pp.print_id 
GROUP BY    cp.campaign_no,
            fp.print_id,    
            fp.print_name,
            fp.actual_duration,
            fpfl.three_d_type,
            three_d_type_desc      
ORDER BY    fp.print_id

insert into #tmp_prints
SELECT      DISTINCT CONVERT(smallint,-1) AS file_validation_status,
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
WHERE      (inclusion_cinetam_settings.complex_id IN (SELECT shared_complex_id FROM acdc_disc_shares WHERE complex_id = @complex_id AND shared_complex_id <> 0 UNION SELECT @complex_id))
AND         fc.start_date <= @screening_date_end_range
AND         fc.makeup_deadline >= @screening_date
AND         fc.campaign_no = cp.campaign_no
AND         fc.campaign_status <> 'P' 
AND         pp.package_id = cp.package_id
and			inclusion_cinetam_package.package_id = cp.package_id
and			inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
and			vps.print_package_id = pp.print_package_id
and			vps.substitution_print_id = fp.print_id
and			vps.complex_id = @complex_id
and			vps.three_d_type =  fpfl.three_d_type
GROUP BY		cp.campaign_no,
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
and		v_print_substitution.complex_id = @complex_id
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
       filepath = CASE ISNULL(fpfl.acdc_folder_format,0) WHEN 0 THEN fpfl.filepath WHEN 2 THEN FPFL.filename+'_'+fpfl.uuid END ,
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
  AND  NOT EXISTS (SELECT TOP 1 complex_id FROM complex_three_d_type_xref WHERE complex_id = @complex_id AND three_d_type <> 1)

/*
 * return the results
 */

SELECT DISTINCT TP.file_validation_status,
		0,
		TP.print_id,
		RTRIM(LTRIM(TP.print_name)) AS print_name,
		TP.print_revision,
		CASE ISNULL(galeforce_folder_is_UUID,'N') WHEN '99' THEN FPFL.filename+'_'+TP.uuid ELSE FPFL.filename+'_'+TP.uuid END AS filepath,
		TP.uuid,
		TP.error_msg,
		TP.actual_duration,
		CASE TP.file_validation_status when 1 THEN 'Y' ELSE 'N' END AS include_print,
		ISNULL(FPFL.folder_size,
		CONVERT(BigInt,0)) AS folder_size,
		CONVERT(CHAR(1),'N') AS processed_flag,
		TP.three_d_type,
		TP.three_d_type_desc,
		ISNULL(ACD.download_progress,255) AS download_progress,
		ACD.download_uuid,
		ACD.timestamp,
		ISNULL(galeforce_folder_is_UUID,'N') AS galeforce_folder_is_UUID,
		TP.filepath AS ACDC_folder,
		(SELECT COUNT(*) FROM acdc_qubewire_prints_transferred where complex_id = @complex_id and print_id = TP.print_id) AS qubewire_count 
FROM	#tmp_prints TP 
        LEFT OUTER JOIN film_print_file_locations FPFL ON FPFL.print_id = TP.print_id AND FPFL.three_d_type = TP.three_d_type AND FPFL.country_code = @country_code
        LEFT OUTER JOIN acdc_complex_download ACD ON ACD.complex_id = @complex_id AND ACD.print_id = TP.print_id
ORDER BY TP.file_validation_status,
		TP.print_id

return 0
GO
