USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_theatre_check_ads]    Script Date: 11/03/2021 2:30:35 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE proc [dbo].[p_theatre_check_ads]		@complex_id int,@screening_date date,@movie_id int,@cinema_no smallint

as

/*==============================================================*
 * DESC:- get all the ads for a cinema session.                 *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1   22-Feb-2019 DH  Initial Build                            *
 *==============================================================*/

set nocount on

select 'C' as ad_type,CI.sequence_no, CG.certificate_group_id, CI.certificate_item_id, FP.print_name, CI.print_id, FP.print_status, CG.three_d_type, CI.three_d_type, CI.premium_cinema, FP.print_type, 'N' AS decision_required, 0 AS trailer_count
from certificate_item CI, 
     film_print FP, 
     certificate_group CG 
where CG.certificate_group_id IN (SELECT ISNULL(MH.certificate_group,-1) FROM movie_history MH WHERE MH.complex_id = @complex_id AND MH.screening_date = @screening_date AND MH.movie_id = 102)
 and  CI.certificate_group = CG.certificate_group_id 
 and  CG.group_no = @cinema_no
 and  CI.item_show = 'Y' 
 and  FP.print_id = CI.print_id 
UNION
select 'M' as ad_type,CI.sequence_no, CG.certificate_group_id, CI.certificate_item_id, FP.print_name, CI.print_id, FP.print_status, CG.three_d_type, CI.three_d_type, CI.premium_cinema, FP.print_type, 'N' AS decision_required, 0 AS trailer_count
from certificate_item CI, 
     film_print FP, 
     certificate_group CG 
where CG.certificate_group_id IN (SELECT DISTINCT MH.certificate_group FROM movie_history MH WHERE MH.movie_id = @movie_id AND MH.complex_id = @complex_id AND MH.screening_date = @screening_date)
 and  CI.certificate_group = CG.certificate_group_id 
 and  CI.item_show = 'Y' 
 and  FP.print_id = CI.print_id 
order by ad_type,CG.certificate_group_id,sequence_no,print_name

return 0
GO
