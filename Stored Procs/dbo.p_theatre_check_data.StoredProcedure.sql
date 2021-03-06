/****** Object:  StoredProcedure [dbo].[p_theatre_check_data]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_theatre_check_data]
GO
/****** Object:  StoredProcedure [dbo].[p_theatre_check_data]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_theatre_check_data]  	@user_date 		datetime,
                                    @complex_id     int
as

select  @user_date 'screening_day',
        certificate_group.complex_id 'complex_id',
        complex.complex_name 'complex_name',
        certificate_item.sequence_no 'sequence_number',
        'F' 'slide_or_film_ad',
        certificate_group.group_name 'movie_name',
        film_print.print_name  'advertisment_description'
from    film_screening_dates,
        certificate_group,
        certificate_item,
        film_print,
        complex,
        complex_grouping
where   certificate_group.complex_id = complex.complex_id and
        certificate_group.screening_date = film_screening_dates.screening_date and 
        film_screening_dates.screening_date <= @user_date and
        film_screening_dates.screening_date >  dateadd(wk, -1, @user_date) and
        certificate_group.certificate_group_id = certificate_item.certificate_group and
        certificate_item.item_show = 'Y' and
        certificate_item.print_id = film_print.print_id and
        (complex.complex_id = @complex_id or @complex_id = -1) and
        complex.branch_code != 'Z' and
        complex_grouping.complex_group_id = 1 and
        complex_grouping.complex_id = complex.complex_id
order by complex.complex_name,
         movie_name,
         sequence_number

return 0
GO
