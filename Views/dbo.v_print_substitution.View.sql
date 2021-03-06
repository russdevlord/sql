/****** Object:  View [dbo].[v_print_substitution]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_print_substitution]
GO
/****** Object:  View [dbo].[v_print_substitution]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create view  [dbo].[v_print_substitution] as
SELECT        film_campaign_print_sub_medium.print_medium, film_campaign_print_substitution.complex_id, film_campaign_print_substitution.original_print_id, 
                         film_campaign_print_substitution.substitution_print_id, campaign_package.start_date, campaign_package.used_by_date, 
                         film_campaign_print_sub_threed.three_d_type, film_campaign_print_substitution.print_package_id
FROM            film_campaign_print_sub_medium INNER JOIN
                         film_campaign_print_sub_threed ON film_campaign_print_sub_medium.substitution_print_id = film_campaign_print_sub_threed.substitution_print_id INNER JOIN
                         film_campaign_print_substitution ON film_campaign_print_sub_medium.substitution_print_id = film_campaign_print_substitution.substitution_print_id AND 
                         film_campaign_print_sub_medium.original_print_id = film_campaign_print_substitution.original_print_id AND 
                         film_campaign_print_sub_medium.complex_id = film_campaign_print_substitution.complex_id AND 
                         film_campaign_print_sub_medium.print_package_id = film_campaign_print_substitution.print_package_id AND 
                         film_campaign_print_sub_threed.substitution_print_id = film_campaign_print_substitution.substitution_print_id AND 
                         film_campaign_print_sub_threed.original_print_id = film_campaign_print_substitution.original_print_id AND 
                         film_campaign_print_sub_threed.complex_id = film_campaign_print_substitution.complex_id AND 
                         film_campaign_print_sub_threed.print_package_id = film_campaign_print_substitution.print_package_id INNER JOIN
                         print_package ON film_campaign_print_substitution.print_package_id = print_package.print_package_id INNER JOIN
                         campaign_package ON print_package.package_id = campaign_package.package_id

GO
