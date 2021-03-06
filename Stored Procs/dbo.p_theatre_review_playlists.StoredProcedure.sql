/****** Object:  StoredProcedure [dbo].[p_theatre_review_playlists]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_theatre_review_playlists]
GO
/****** Object:  StoredProcedure [dbo].[p_theatre_review_playlists]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[p_theatre_review_playlists] @complex_id int, @screening_date datetime, @movie_id int

as

begin

/*==============================================================*
 * DESC:- Returns all the playlists.                            *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1  01-Oct-2018 DH   Initial Build                           *
 *                                                              *
 *==============================================================*/

set nocount on

CREATE TABLE #tmp_certificates (
	local_national_ad_flag CHAR(1),
	certificate_group int,
	occurence int
	)

/** get the local ad certificates **/
INSERT #tmp_certificates
	SELECT 'L' AS local_national_ad_flag,ISNULL(certificate_group,-1) AS certificate_group,occurence
	 FROM  movie_history
	 WHERE complex_id = @complex_id AND screening_date = @screening_date AND movie_id = 102 AND occurence = 1
	UNION
	/** get the national ad certificates **/
	SELECT 'N' AS local_national_ad_flag,ISNULL(certificate_group,-1) AS certificate_group,occurence
	 FROM  movie_history
	 WHERE complex_id = @complex_id AND screening_date = @screening_date AND movie_id = @movie_id

SELECT local_national_ad_flag,TC.certificate_group,TC.occurence,'' AS item_played,CI.certificate_group,CI.certificate_item_id,CI.sequence_no,FP.print_id,FP.print_name, FP.print_type, CI.print_id, 'N' AS decision_required, 0 AS trailer_count
FROM  #tmp_certificates TC,certificate_item CI,film_print FP
WHERE CI.certificate_group = TC.certificate_group
 AND  FP.print_id = CI.print_id
 AND  CI.item_show = 'Y' 
ORDER BY local_national_ad_flag,CI.sequence_no

return 0

end
GO
