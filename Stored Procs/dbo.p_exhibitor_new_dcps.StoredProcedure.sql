/****** Object:  StoredProcedure [dbo].[p_exhibitor_new_dcps]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_exhibitor_new_dcps]
GO
/****** Object:  StoredProcedure [dbo].[p_exhibitor_new_dcps]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   proc [dbo].[p_exhibitor_new_dcps]		@exhibitor_id_arg              int,
                                            @screening_date_arg            datetime

as

set nocount on

DECLARE	    @complex_id                int,
            @exhibitor_id              int,
            @screening_date            datetime
            
select         @exhibitor_id =     @exhibitor_id_arg
select         @screening_date = @screening_date_arg

/*
 * Extract content for the complex
 */
SELECT      cp.campaign_no,
            fp.print_id,
            cs.complex_id,
            fp.print_name + ' [' + ISNULL(three_d.three_d_type_desc,'') + ']' AS print_name,
            MAX(fpfl.print_revision) AS print_revision,
            convert(varchar(255),null) AS filepath,
            convert(varchar(50),null) AS uuid,
            CONVERT(varchar(255),'No media has been linked to this print') AS error_msg,
            fp.actual_durAtion,
            fpfl.three_d_type,
            three_d_type_desc,
            (SELECT     COUNT(ci.print_id)
            FROM        certificate_item ci with (nolock), certificate_group cg with (nolock)
            WHERE       cg.complex_id = cs.complex_id 
            AND         cg.screening_date < @screening_date
            AND         ci.print_id = fp.print_id
            and         ci.certificate_group = cg.certificate_group_id) as times_in
INTO        #tmp_prints
FROM        campaign_package cp, 
            campaign_spot cs,
            print_package pp, 
            film_campaign fc, 
            film_print fp 
                LEFT OUTER JOIN film_print_file_locations fpfl ON fp.print_id = fpfl.print_id 
                LEFT OUTER JOIN three_d ON three_d.three_d_type = fpfl.three_d_type
WHERE       cs.complex_id IN (SELECT complex_id FROM complex WHERE exhibitor_id = @exhibitor_id)
AND         cs.screening_date = @screening_date
AND         fc.campaign_no = cp.campaign_no
AND         fc.campaign_status <> 'P' 
AND         pp.package_id = cp.package_id
and         cs.package_id = cp.package_id
AND         fc.campaign_no = cs.campaign_no
AND         fp.print_id = pp.print_id 
GROUP BY    cp.campaign_no,
            fp.print_id,    
            fp.print_name,
            fp.actual_duration,
            fpfl.three_d_type,
            three_d_type_desc,
            cs.complex_id
ORDER BY    fp.print_id


/*
 * Set the filepath for the revision
 */

UPDATE #tmp_prints
SET filepath = fpfl.filepath,
uuid = fpfl.uuid,
error_msg = CASE fpfl.print_verified WHEN 'Y' THEN null ELSE 'Content has not been verified on-screen' END
FROM #tmp_prints tp, film_print_file_locations fpfl
WHERE fpfl.print_id = tp.print_id
AND  fpfl.three_d_type = tp.three_d_type

/*
 * return the results
 */
SELECT 	TP.print_id,
		TP.print_name,
		TP.print_revision,
		TP.filepath,
		TP.uuid,
		TP.error_msg,
		TP.actual_duration,
		TP.three_d_type,
		TP.three_d_type_desc,
        c.complex_name,
        TP.times_in
FROM	#tmp_prints TP,
        complex c
where   c.complex_id = TP.complex_id
and     TP.times_in = 0
order by TP.print_id,
         c.complex_name   


return 0
GO
