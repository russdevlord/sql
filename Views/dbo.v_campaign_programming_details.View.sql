/****** Object:  View [dbo].[v_campaign_programming_details]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_campaign_programming_details]
GO
/****** Object:  View [dbo].[v_campaign_programming_details]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view	[dbo].[v_campaign_programming_details]
as
select		client_name,
			client_group_desc,
			agency_name, 
			agency_group_name,
			buying_group_desc,
			country, 
			branch_name, 
			business_unit_desc, 
			campaign_no, 
			product_desc, 
			package_desc, 
			package_code, 
			follow_film, 
			screening_date, 
			spot_type_desc, 
            duration,
			sum(cinema_rate_30sec) as sum_revenue_30sec, 
			sum(cinema_rate) as sum_revenue,
			sum(attendance) as sum_allpeep_attendance, 
			sum(isnull(all_18_39,0)) as sum_1839_attendance, 
			sum(isnull(all_25_54,0)) as sum_2554_attendance,
			count(spot_id) as no_spots,
			dbo.f_package_followed_films(package_id) as follow_films
from		(SELECT		client_name,
						client_group_desc,
						agency.agency_name, 
						agency_groups.agency_group_name,
						buying_group_desc,
						film_campaign.campaign_no, 
						film_campaign.product_desc, 
						branch_name, 
						v_spot_util_liab.cinema_rate_30sec, 
						v_spot_util_liab.cinema_rate,
						movie_history.attendance, 
						(select		sum(attendance) from v_cinetam_movie_history_reporting_demos with(nolock) where cinetam_reporting_demographics_id = 3
						and			movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
						and			movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
						and			movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
						and			movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
						and			movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
						and			movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type) as all_18_39, 
						(select		sum(attendance) from v_cinetam_movie_history_reporting_demos with(nolock)  where cinetam_reporting_demographics_id = 5
						and			movie_history.complex_id = v_cinetam_movie_history_reporting_demos.complex_id
						and			movie_history.movie_id = v_cinetam_movie_history_reporting_demos.movie_id
						and			movie_history.screening_date = v_cinetam_movie_history_reporting_demos.screening_date
						and			movie_history.occurence = v_cinetam_movie_history_reporting_demos.occurence
						and			movie_history.print_medium = v_cinetam_movie_history_reporting_demos.print_medium
						and			movie_history.three_d_type = v_cinetam_movie_history_reporting_demos.three_d_type) as all_25_54,            
						campaign_spot.spot_id,
						movie_history.country, 
						movie_history.screening_date, 
						business_unit.business_unit_desc, 
						campaign_package.package_id, 
						campaign_package.package_desc, 
						campaign_package.package_code, 
						campaign_package.follow_film, 
						spot_status_desc, 
						spot_type_desc, 
						campaign_package.duration
			FROM        movie_history, 
						v_certificate_item_distinct,
						film_campaign, 
						client, 
						client_group,
						v_spot_util_liab, 
						agency_groups, 
						agency,
						campaign_spot,
						campaign_package,
						business_unit,
						agency_buying_groups,
						complex, 
						exhibitor,
						movie,
						spot_status,
						spot_type,
						branch
			where		movie_history.movie_id = movie.movie_id 
			and			movie_history.certificate_group = v_certificate_item_distinct.certificate_group 
			and			client.client_group_id = client_group.client_group_id 
			and			film_campaign.reporting_client = client.client_id 
			and			agency_groups.agency_group_id = agency.agency_group_id 
			and			film_campaign.reporting_agency = agency.agency_id 
			and			film_campaign.campaign_no = campaign_spot.campaign_no 
			and			v_certificate_item_distinct.spot_reference = campaign_spot.spot_id 
			and			film_campaign.campaign_no = campaign_package.campaign_no 
			and			campaign_spot.package_id = campaign_package.package_id 
			and			film_campaign.business_unit_id = business_unit.business_unit_id 
			and			agency_groups.buying_group_id = agency_buying_groups.buying_group_id 
			and			movie_history.complex_id = complex.complex_id 
			and			campaign_spot.complex_id = complex.complex_id 
			and			complex.exhibitor_id = exhibitor.exhibitor_id 
			and			campaign_spot.spot_id = v_spot_util_liab.spot_id
			and			campaign_spot.screening_date > '1-jan-2013'
			and			campaign_spot.spot_type = spot_type.spot_type_code
			and			campaign_spot.spot_status = spot_status.spot_status_code
			and			film_campaign.branch_code = branch.branch_code
			and			spot_status = 'X') as temp_table
group by	client_name,
			client_group_desc,
			agency_name, 
			agency_group_name,
			buying_group_desc,
			country, 
			branch_name, 
			business_unit_desc, 
			campaign_no, 
			product_desc, 
			package_id,
			package_desc, 
			package_code, 
			follow_film, 
			screening_date, 
			spot_status_desc, 
			spot_type_desc, 
            duration			
GO
