/****** Object:  StoredProcedure [dbo].[p_screening_confirmations_auto_complete]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_screening_confirmations_auto_complete]
GO
/****** Object:  StoredProcedure [dbo].[p_screening_confirmations_auto_complete]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_screening_confirmations_auto_complete]
as
begin
/*==============================================================*
 * DESC:- Auto completes screening confirmations on complexes   *
 *        with no ads (for the last week's screening dates)     *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1  18-Sep-2013 DH  Initial Build                            *
 *                                                              *
 *==============================================================*/

set nocount on

/*
 * Declare Variables
 */


/*
 * find complexes with no ads in last week's screening date
 */
SELECT complex_id INTO #tmp_complexes FROM (SELECT CG.complex_id,SUM(CASE WHEN ISNULL(CI.spot_reference,0) = 0 THEN 0 ELSE 1 END) AS AdCount from certificate_group CG LEFT OUTER JOIN certificate_item CI ON CI.certificate_group = CG.certificate_group_id LEFT OUTER JOIN film_print FP ON FP.print_id = CI.print_id WHERE CG.screening_date = CAST(DATEADD(wk, DATEDIFF(wk,0,GETDATE()), 0)-4 AS DATE) AND CI.item_show = 'Y' GROUP BY CG.complex_id) Ads WHERE AdCount = 0

/*
 * insert completed confirmation records for those complexes, any that already have a comment by the projectionist will be skipped
 */
INSERT screening_confirmations SELECT CG.certificate_group_id,-1,'Y',NULL,NULL,'Y',getdate() FROM #tmp_complexes TC 
       CROSS APPLY (SELECT TOP 1 complex_id,certificate_group_id,group_no FROM certificate_group CertGrp WHERE complex_id = TC.complex_id AND screening_date = CAST(DATEADD(wk, DATEDIFF(wk,0,GETDATE()), 0)-4 AS DATE) ORDER BY group_no) AS CG 
	                             LEFT OUTER JOIN screening_confirmations SC ON SC.certificate_group_id = CG.certificate_group_id AND certificate_item_id = -1 WHERE SC.certificate_group_id IS NULL

DROP TABLE #tmp_complexes 

return 0

end

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
GO
