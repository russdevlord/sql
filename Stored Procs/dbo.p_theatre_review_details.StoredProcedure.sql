/****** Object:  StoredProcedure [dbo].[p_theatre_review_details]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_theatre_review_details]
GO
/****** Object:  StoredProcedure [dbo].[p_theatre_review_details]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   proc [dbo].[p_theatre_review_details]		@review_id                int

as

/*==============================================================*
 * DESC:- retrieves theatre review detail rows.                 *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1   31-Mar-2015 DH  Initial Build                            *
 *==============================================================*/

set nocount on

DECLARE @max_cineads INT

SELECT @max_cineads = 0
SELECT @max_cineads = (SELECT COUNT(*) FROM theatre_review TR JOIN certificate_item CI ON CI.certificate_group = TR.cineads_certificate_group_id where TR.theatre_review_id = @review_id AND item_show = 'Y') 

SELECT			1 AS playlist_type,
				sequence_no,
				print_name,
				item_ticks,
				SUBSTRING(item_ticks,sequence_no,1) AS ticked_value,
				theatre_review_id 
from			theatre_review TR 
JOIN			certificate_item CI ON CI.certificate_group = TR.cineads_certificate_group_id 
JOIN			film_print FP ON FP.print_id = CI.print_id 
where			TR.theatre_review_id = @review_id AND item_show = 'Y' 
UNION
SELECT			2 AS playlist_type,
				(sequence_no + @max_cineads) AS sequence_no,
				print_name,
				item_ticks,
				SUBSTRING(item_ticks,(sequence_no + @max_cineads),1) AS ticked_value,
				theatre_review_id 
from			theatre_review TR JOIN certificate_item CI ON CI.certificate_group = TR.vm_certificate_group_id 
JOIN			film_print FP ON FP.print_id = CI.print_id 
where			TR.theatre_review_id = @review_id 
AND				item_show = 'Y' 
ORDER BY		playlist_type,
				sequence_no

return 0
GO
