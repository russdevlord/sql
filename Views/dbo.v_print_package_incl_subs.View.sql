/****** Object:  View [dbo].[v_print_package_incl_subs]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_print_package_incl_subs]
GO
/****** Object:  View [dbo].[v_print_package_incl_subs]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_print_package_incl_subs]

as

select		print_package_id,
			print_id,
			package_id
from		print_package
where		print_package_id not in (select			print_package_id 
									from			film_campaign_print_substitution)
union all
select		film_campaign_print_substitution.print_package_id,
			substitution_print_id,
			package_id
from		film_campaign_print_substitution
inner join	print_package on film_campaign_print_substitution.print_package_id = print_package.print_package_id
GO
