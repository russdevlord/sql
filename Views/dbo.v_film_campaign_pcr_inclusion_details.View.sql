/****** Object:  View [dbo].[v_film_campaign_pcr_inclusion_details]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_film_campaign_pcr_inclusion_details]
GO
/****** Object:  View [dbo].[v_film_campaign_pcr_inclusion_details]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view	[dbo].[v_film_campaign_pcr_inclusion_details]
as
select 			inclusion_spot.campaign_no,
					inclusion_spot.inclusion_id, 
					inclusion_desc,
					inclusion_type,
					(select			count(inclusion_id) from inclusion_cinetam_package
					inner join		campaign_category on inclusion_cinetam_package.package_id = campaign_category.package_id
					where			instruction_type =2
					and				movie_category_code in ('B', 'CA') 
					and				inclusion_id = inclusion_spot.inclusion_id) as cineasia_count,
					sum(inclusion_spot.charge_rate) as charge_rate_sum
from				inclusion_spot
inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
where			inclusion_type in (24,29,30,31,32)
and				screening_date is not null 
group by 		inclusion_spot.campaign_no,
					inclusion_spot.inclusion_id, 
					inclusion_desc,
					inclusion_type
GO
