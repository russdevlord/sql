/****** Object:  StoredProcedure [dbo].[p_booking_yield_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_booking_yield_report]
GO
/****** Object:  StoredProcedure [dbo].[p_booking_yield_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create proc		[dbo].[p_booking_yield_report]	@start_date				datetime,
												@end_date				datetime,
												@branches				varchar(max)

as			

set nocount on

declare	@error								int,
		@rowcount							int,
		@campaign_no						int,
		@product_desc						varchar(100),
		@start_year							int,
		@end_year							int,
		@duration							int,
		@client_name						varchar(100),
		@agency_name						varchar(100),
		@actual_attendance					int,
		@target_attendance					int,
		@target_demographic_id				int,
		@target_demographic_desc			varchar(100),
		@has_digilites						int,
		@media_spend						money,
		@estimated_cpm						money,
		@actual_cpm							money,
		@cmp_start_date						datetime,
		@cmp_end_date						datetime,
		@inclusion_type_desc				varchar(100),
		@business_unit_desc					varchar(100),
		@agency_group_name					varchar(100),
		@buying_group_desc					varchar(100)


create table #branches
(
	branch_code							char(2)			not null
)

create table #report_data
(
	campaign_no									int							not null,
	product_desc								varchar(100)				not null,
	business_unit_desc							varchar(100)				not null,
	country_code								char(1)						null,
	inclusion_type								varchar(100)				not null,
	start_year									int							not null,
	end_year									int							not null,
	start_date									datetime					not null,
	end_date									datetime					not null,
	duration									int							not null,
	client_name									varchar(100)				not null,
	agency_name									varchar(100)				not null,
	agency_group_name							varchar(100)				not null,
	buying_group_desc							varchar(100)				not null,
	original_target_attendance					int							not null,
	original_ap_target_attendance				int							null,
	target_demographic_id						int							null,
	target_demographic_desc						varchar(100)				null,
	has_digilites								int							not null,
	media_spend									money						not null,
	estimated_cpm								money						null,
	estimated_30sec_eqv_cpm						money						null
)

insert into #branches                
select * from dbo.f_multivalue_parameter(@branches,',')           


insert into		#report_data
			(	campaign_no,
				product_desc,
				business_unit_desc,
				inclusion_type,
				start_year,
				end_year,
				start_date,
				end_date,
				duration,
				client_name,
				agency_name,
				agency_group_name,
				buying_group_desc,
				original_target_attendance,
				original_ap_target_attendance,
				target_demographic_id,
				target_demographic_desc,
				has_digilites,
				media_spend,
				estimated_cpm,
				estimated_30sec_eqv_cpm)
select			temp_table.campaign_no,
				temp_table.product_desc,
				temp_table.business_unit_desc,
				temp_table.inclusion_type_desc, 
				temp_table.start_year,
				temp_table.end_year,
				temp_table.start_date, 
				temp_table.end_date,
				temp_table.duration,
				temp_table.client_name, 
				temp_table.agency_name,
				temp_table.agency_group_name,
				temp_table.buying_group_desc,
				sum(isnull(original_target_attendance,0)),
				sum(isnull(original_target_attendance,0)),
				target_demographic_id,
				'',
				sum(temp_table.has_digilites) as has_digilites,
				sum(temp_table.media_spend) as media_spend,
				0,
				0
from			(select			film_campaign.campaign_no,
								product_desc,
								business_unit_desc,
								'Spot Buy' as inclusion_type_desc, 
								DATEPART(yy, film_campaign.start_date) as start_year,
								DATEPART(yy, film_campaign.makeup_deadline) as end_year,
								film_campaign.start_date, 
								end_date,
								duration,
								client_name, 
								agency_name,
								agency_group_name,
								buying_group_desc,
								sum(campaign_spot.charge_rate) as media_spend,
								(select count(spot_id) from cinelight_spot where campaign_no = film_campaign.campaign_no and spot_status <> 'P') as has_digilites,
								(select cinetam_reporting_demographics_id from cinetam_campaign_settings where campaign_no = @campaign_no) as target_demographic_id,
								(select sum(attendance) from cinetam_campaign_settings where campaign_no = @campaign_no) as original_target_attendance
				from			film_campaign
				inner join		business_unit on film_campaign.business_unit_id = business_unit.business_unit_id				
				inner join		campaign_spot on film_campaign.campaign_no = campaign_spot.campaign_no
				inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id
				inner join		client on film_campaign.reporting_client = client.client_id
				inner join		#branches on film_campaign.branch_code = #branches.branch_code
				inner join		agency on film_campaign.reporting_agency = agency.agency_id
				inner join		agency_groups on agency.agency_group_id = agency_groups.agency_group_id
				inner join		agency_buying_groups on agency_groups.buying_group_id = agency_buying_groups.buying_group_id
				inner join		v_statrev_campaign_confirmdate on film_campaign.campaign_no = v_statrev_campaign_confirmdate.campaign_no
				where			v_statrev_campaign_confirmdate.confirm_date between @start_date and @end_date
				and				spot_type not in ('A', 'F', 'K', 'T')
				and				premium_screen_type = 'N'
				and				spot_status <> 'P'
				group by		film_campaign.campaign_no,
								product_desc,
								business_unit_desc,
								DATEPART(yy, film_campaign.start_date),
								DATEPART(yy, film_campaign.makeup_deadline),
								film_campaign.start_date, 
								end_date,
								duration,
								client_name, 
								agency_name,
								agency_group_name,
								buying_group_desc
				union all		
				select			campaign_no,
								product_desc,
								business_unit_desc,
								inclusion_type_desc,
								start_year,
								end_year,
								start_date, 
								end_date,
								duration,
								client_name, 
								agency_name,
								agency_group_name,
								buying_group_desc,
								media_spend,
								has_digilites,
								target_demographic_id,
								original_target_attendance
				from			(select			film_campaign.campaign_no,
												product_desc,
												business_unit_desc,
												inclusion_type_desc,
												DATEPART(yy, film_campaign.start_date) as start_year,
												DATEPART(yy, film_campaign.makeup_deadline) as end_year,
												film_campaign.start_date, 
												end_date,
												duration,
												client_name, 
												agency_name,
												agency_group_name,
												buying_group_desc,
												(select sum(charge_rate) from inclusion_spot where inclusion_id = inclusion_campaign_spot_xref.inclusion_id) as media_spend,
												(select count(spot_id) from cinelight_spot where campaign_no = film_campaign.campaign_no and spot_status <> 'P') as has_digilites,
												(select cinetam_reporting_demographics_id from inclusion_cinetam_master_target where inclusion_id = inclusion_campaign_spot_xref.inclusion_id) as target_demographic_id,
												(select sum(attendance) from inclusion_cinetam_master_target where inclusion_id = inclusion_campaign_spot_xref.inclusion_id) as original_target_attendance,
												(select cinetam_reporting_demographics_id from inclusion_cinetam_master_target where inclusion_id = inclusion_campaign_spot_xref.inclusion_id) as cinetam_reporting_demographics_id,
												inclusion_campaign_spot_xref.inclusion_id
								from			film_campaign 
								inner join		business_unit on film_campaign.business_unit_id = business_unit.business_unit_id				
								inner join		campaign_spot on film_campaign.campaign_no = campaign_spot.campaign_no
								inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
								inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
								inner join		inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
								inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id
								inner join		client on film_campaign.reporting_client = client.client_id
								inner join		#branches on film_campaign.branch_code = #branches.branch_code
								inner join		agency on film_campaign.reporting_agency = agency.agency_id
								inner join		agency_groups on agency.agency_group_id = agency_groups.agency_group_id
								inner join		agency_buying_groups on agency_groups.buying_group_id = agency_buying_groups.buying_group_id
								inner join		v_statrev_campaign_confirmdate on film_campaign.campaign_no = v_statrev_campaign_confirmdate.campaign_no
								where			v_statrev_campaign_confirmdate.confirm_date between @start_date and @end_date
								and				spot_type in ('A', 'F', 'K', 'T')
								and				premium_screen_type = 'N'
								and				spot_status <> 'P'
								group by		film_campaign.campaign_no,
												product_desc,
												business_unit_desc,
												inclusion_type_desc,
												DATEPART(yy, film_campaign.start_date),
												DATEPART(yy, film_campaign.makeup_deadline),
												film_campaign.start_date, 
												end_date,
												duration,
												client_name, 
												agency_name,
												agency_group_name,
												buying_group_desc,
												inclusion_campaign_spot_xref.inclusion_id) as temp_audience) as temp_table
group by		temp_table.campaign_no,
				temp_table.product_desc,
				temp_table.business_unit_desc,
				temp_table.inclusion_type_desc, 
				temp_table.start_year,
				temp_table.end_year,
				temp_table.start_date, 
				temp_table.end_date,
				temp_table.duration,
				temp_table.client_name, 
				temp_table.agency_name,
				temp_table.agency_group_name,
				temp_table.buying_group_desc,
				temp_table.target_demographic_id

update			#report_data
set				country_code = 'A'
where			campaign_no < 900000

update			#report_data
set				country_code = 'Z'
where			campaign_no > 900000

update			#report_data
set				target_demographic_desc = cinetam_reporting_demographics_desc
from			#report_data
inner join		cinetam_reporting_demographics on #report_data.target_demographic_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id

update			#report_data
set				target_demographic_desc = 'No Campaign Demo - All People Used',
				original_target_attendance = 0,
				target_demographic_id = 0
where			target_demographic_id is null

update			#report_data
set				original_ap_target_attendance = original_ap_target_attendance / case when target_demo.attendance_share = 0 then 1 else target_demo.attendance_share end * case when criteria_demo.attendance_share = 0 then 1 else criteria_demo.attendance_share end
from			#report_data
inner join		(select			country_code,
								cinetam_reporting_demographics_id,
								avg(attendance_share) as attendance_share
				from			film_screening_date_attendance_prev 
				inner join		availability_demo_matching on film_screening_date_attendance_prev.prev_screening_date = availability_demo_matching.screening_date
				and				film_screening_date_attendance_prev.screening_date between @start_date and @end_date 
				inner join		complex on availability_demo_matching.complex_id = complex.complex_id
				inner join		branch on complex.branch_code = branch.branch_code
				group by		country_code,
								film_screening_date_attendance_prev.screening_date,
								cinetam_reporting_demographics_id) as target_demo 
on				#report_data.target_demographic_id = target_demo.cinetam_reporting_demographics_id
and				#report_data.country_code = target_demo.country_code
inner join		(select			country_code,
								film_screening_date_attendance_prev.screening_date,
								cinetam_reporting_demographics_id,
								avg(attendance_share) as attendance_share
				from			film_screening_date_attendance_prev 
				inner join		availability_demo_matching on film_screening_date_attendance_prev.prev_screening_date = availability_demo_matching.screening_date
				and				film_screening_date_attendance_prev.screening_date between @start_date and @end_date 
				inner join		complex on availability_demo_matching.complex_id = complex.complex_id
				inner join		branch on complex.branch_code = branch.branch_code
				group by		country_code,
								film_screening_date_attendance_prev.screening_date,
								cinetam_reporting_demographics_id) as criteria_demo 
on				criteria_demo.cinetam_reporting_demographics_id = 0
and				#report_data.country_code = target_demo.country_code

update			#report_data
set				estimated_cpm = media_spend / original_target_attendance * 1000,
				estimated_30sec_eqv_cpm  = (media_spend / duration * 30) / original_ap_target_attendance * 1000
where			original_target_attendance <> 0

select			#report_data.*,
				first_name + ' ' + last_name as rep_name
from			#report_data
inner join		film_campaign on #report_data.campaign_no = film_campaign.campaign_no
inner join		sales_rep on film_campaign.rep_id = sales_rep.rep_id

return 0
GO
