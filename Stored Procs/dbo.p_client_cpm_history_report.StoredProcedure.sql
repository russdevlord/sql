/****** Object:  StoredProcedure [dbo].[p_client_cpm_history_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_client_cpm_history_report]
GO
/****** Object:  StoredProcedure [dbo].[p_client_cpm_history_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc		[dbo].[p_client_cpm_history_report]		@start_date				datetime,
														@end_date				datetime,
														@agency_id				varchar(max),
														@client_id				varchar(max)

as			

set nocount on

declare			@error								int,
				@rowcount							int,
				@campaign_no						int,
				@product_desc						varchar(100),
				@start_year							int,
				@end_year							int,
				@band_id							int,
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
				@inclusion_type_desc				varchar(100)

create table #agencies
(
	agency_id									int			not null
)

create table #clients
(
	client_id									int			not null
)

create table #report_data
(
	campaign_no									int							not null,
	product_desc								varchar(100)				not null,
	inclusion_type								varchar(100)				not null,
	start_year									int							not null,
	end_year									int							not null,
	start_date									datetime					not null,
	end_date									datetime					not null,
	band_id										int							not null,
	client_name									varchar(100)				not null,
	agency_name									varchar(100)				not null,
	actual_attendance							int							not null,
	target_attendance							int							not null,
	target_demographic_id						int							not null,
	target_demographic_desc						varchar(100)				not null,
	has_digilites								int							not null,
	media_spend									money						not null,
	estimated_cpm								money						not null,
	actual_cpm									money						not null
)

insert into #agencies                
select * from dbo.f_multivalue_parameter(@agency_id,',')           

insert into #clients                
select * from dbo.f_multivalue_parameter(@client_id,',')                
     

declare			campaign_csr cursor for
select			temp_table.campaign_no,
				temp_table.product_desc,
				temp_table.inclusion_type_desc, 
				temp_table.start_year,
				temp_table.end_year,
				temp_table.start_date, 
				temp_table.end_date,
				temp_table.band_id,
				temp_table.client_name, 
				temp_table.agency_name,
				sum(temp_table.media_spend) as media_spend,
				sum(temp_table.has_digilites) as has_digilites,
				target_demographic_id,
				sum(target_attendance) as target_attendance,
				sum(actual_attendance) as actual_attendance
from			(select			film_campaign.campaign_no,
								product_desc,
								'Spot Buy' as inclusion_type_desc, 
								DATEPART(yy, film_campaign.start_date) as start_year,
								DATEPART(yy, film_campaign.makeup_deadline) as end_year,
								film_campaign.start_date, 
								end_date,
								band_id,
								client_name, 
								agency_name,
								sum(campaign_spot.charge_rate) as media_spend,
								(select count(spot_id) from cinelight_spot where campaign_no = film_campaign.campaign_no and spot_status <> 'P') as has_digilites,
								(select cinetam_reporting_demographics_id from cinetam_campaign_settings where campaign_no = @campaign_no) as target_demographic_id,
								(select sum(attendance) from cinetam_campaign_settings where campaign_no = @campaign_no) as target_attendance,
								(select			isnull(sum(attendance),0)
								from			campaign_spot spot
								inner join		campaign_package pack on spot.package_id = pack.package_id
								inner join		v_certificate_item_distinct v_item on spot.spot_id = v_item.spot_reference
								inner join		v_cinetam_movie_history_reporting_demos v_hist on v_item.certificate_group = v_hist.certificate_group_id
								inner join		inclusion_campaign_spot_xref inc_spot_xref on spot.spot_id = inc_spot_xref.spot_id
								where			spot.campaign_no = @campaign_no
								and				band_id = campaign_package.band_id
								and				cinetam_reporting_demographics_id = (select cinetam_reporting_demographics_id from cinetam_campaign_settings where campaign_no = @campaign_no)) as actual_attendance
				from			film_campaign 
				inner join		campaign_spot on film_campaign.campaign_no = campaign_spot.campaign_no
				inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id
				inner join		client on film_campaign.reporting_client = client.client_id
				inner join		#clients on client.client_id = #clients.client_id
				inner join		agency on film_campaign.reporting_agency = agency.agency_id
				inner join		#agencies on agency.agency_id = #agencies.agency_id
				where			film_campaign.start_date between @start_date and @end_date
				and				spot_type not in ('A', 'F', 'K', 'T')
				and				premium_screen_type = 'N'
				and				spot_status <> 'P'
				group by		film_campaign.campaign_no,
								product_desc,
								DATEPART(yy, film_campaign.start_date),
								DATEPART(yy, film_campaign.makeup_deadline),
								film_campaign.start_date, 
								end_date,
								band_id,
								client_name, 
								agency_name
				union all		
				select			campaign_no,
								product_desc,
								inclusion_type_desc,
								start_year,
								end_year,
								start_date, 
								end_date,
								band_id,
								client_name, 
								agency_name,
								media_spend,
								has_digilites,
								target_demographic_id,
								target_attendance,
								(case when temp_audience.cinetam_reporting_demographics_id = 0 then
								(select			isnull(sum(v_hist.attendance),0)
								from			campaign_spot spot
								inner join		campaign_package pack on spot.package_id = pack.package_id
								inner join		v_certificate_item_distinct v_item on spot.spot_id = v_item.spot_reference
								inner join		movie_history v_hist on v_item.certificate_group = v_hist.certificate_group
								inner join		inclusion_campaign_spot_xref inc_spot_xref on spot.spot_id = inc_spot_xref.spot_id
								where			pack.band_id = temp_audience.band_id
								and				inc_spot_xref.inclusion_id = temp_audience.inclusion_id)
								else
								(select			isnull(sum(v_hist.attendance),0)
								from			campaign_spot spot
								inner join		campaign_package pack on spot.package_id = pack.package_id
								inner join		v_certificate_item_distinct v_item on spot.spot_id = v_item.spot_reference
								inner join		cinetam_movie_history v_hist on v_item.certificate_group = v_hist.certificate_group_id
								inner join		cinetam_reporting_demographics_xref on v_hist.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
								and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = temp_audience.cinetam_reporting_demographics_id
								inner join		inclusion_campaign_spot_xref inc_spot_xref on spot.spot_id = inc_spot_xref.spot_id
								where			pack.band_id = temp_audience.band_id
								and				inc_spot_xref.inclusion_id = temp_audience.inclusion_id) end) as actual_attendance

				from			(select			film_campaign.campaign_no,
												product_desc,
												inclusion_type_desc,
												DATEPART(yy, film_campaign.start_date) as start_year,
												DATEPART(yy, film_campaign.makeup_deadline) as end_year,
												film_campaign.start_date, 
												end_date,
												band_id,
												client_name, 
												agency_name,
												(select sum(charge_rate) from inclusion_spot where inclusion_id = inclusion_campaign_spot_xref.inclusion_id) as media_spend,
												(select count(spot_id) from cinelight_spot where campaign_no = film_campaign.campaign_no and spot_status <> 'P') as has_digilites,
												(select cinetam_reporting_demographics_id from inclusion_cinetam_master_target where inclusion_id = inclusion_campaign_spot_xref.inclusion_id) as target_demographic_id,
												(select sum(attendance) from inclusion_cinetam_master_target where inclusion_id = inclusion_campaign_spot_xref.inclusion_id) as target_attendance,
												(select cinetam_reporting_demographics_id from inclusion_cinetam_master_target where inclusion_id = inclusion_campaign_spot_xref.inclusion_id) as cinetam_reporting_demographics_id,
												inclusion_campaign_spot_xref.inclusion_id
								from			film_campaign 
								inner join		campaign_spot on film_campaign.campaign_no = campaign_spot.campaign_no
								inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
								inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
								inner join		inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
								inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id
								inner join		client on film_campaign.reporting_client = client.client_id
								inner join		#clients on client.client_id = #clients.client_id
								inner join		agency on film_campaign.reporting_agency = agency.agency_id
								inner join		#agencies on agency.agency_id = #agencies.agency_id
								where			film_campaign.start_date between @start_date and @end_date
								and				spot_type in ('A', 'F', 'K', 'T')
								and				premium_screen_type = 'N'
								and				spot_status <> 'P'
								group by		film_campaign.campaign_no,
												product_desc,
												inclusion_type_desc,
												DATEPART(yy, film_campaign.start_date),
												DATEPART(yy, film_campaign.makeup_deadline),
												film_campaign.start_date, 
												end_date,
												band_id,
												client_name, 
												agency_name,
												inclusion_campaign_spot_xref.inclusion_id) as temp_audience) as temp_table
group by		campaign_no,
				product_desc,
				inclusion_type_desc,
				start_year,
				end_year,
				start_date, 
				end_date,
				band_id,
				client_name, 
				agency_name,
--				media_spend,
				has_digilites,
				target_demographic_id/*,
				target_attendance*/
								
for read only

open campaign_csr
fetch campaign_csr into @campaign_no, @product_desc, @inclusion_type_desc, @start_year, @end_year, @cmp_start_date, @cmp_end_date, @band_id, @client_name, @agency_name, @media_spend, @has_digilites, @target_demographic_id, @target_attendance, @actual_attendance
while(@@FETCH_STATUS = 0) 
begin

	
	if @target_demographic_id is null
	begin
		select			@target_demographic_desc = 'No Campaign Demo - All People Used',
						@target_attendance = 0,
						@target_demographic_id = 0

		select			@actual_attendance = isnull(sum(attendance),0)
		from			campaign_spot
		inner join		campaign_package on campaign_spot.package_id = campaign_package.package_id
		inner join		v_certificate_item_distinct on campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
		inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
		where			campaign_spot.campaign_no = @campaign_no
		and				band_id = @band_id
		and				spot_type not in ('A', 'F', 'K', 'T')
	end
	else
	begin
		select			@target_demographic_desc = cinetam_reporting_demographics_desc
		from			cinetam_reporting_demographics
		where			cinetam_reporting_demographics_id = @target_demographic_id
	end

	if @actual_attendance > 0
		select @actual_cpm = @media_spend / @actual_attendance * 1000
	else
		select @actual_cpm = 0

	if @target_attendance > 0
		select @estimated_cpm = @media_spend / @target_attendance * 1000
	else
		select @estimated_cpm = 0

	insert into #report_data
	(
		campaign_no,
		product_desc,
		inclusion_type,
		start_year,
		end_year,
		start_date,
		end_date,
		band_id,
		client_name,
		agency_name,
		actual_attendance,
		target_attendance,
		target_demographic_id,
		target_demographic_desc,
		has_digilites,
		media_spend,
		estimated_cpm,
		actual_cpm	
	)
	values
	(
		@campaign_no,
		@product_desc,
		@inclusion_type_desc,
		@start_year,
		@end_year,
		@cmp_start_date, 
		@cmp_end_date,
		@band_id,
		@client_name,
		@agency_name,
		@actual_attendance,
		@target_attendance,
		@target_demographic_id,
		@target_demographic_desc,
		@has_digilites,
		@media_spend,
		@estimated_cpm,
		@actual_cpm
	)		

	fetch campaign_csr into @campaign_no, @product_desc, @inclusion_type_desc, @start_year, @end_year, @cmp_start_date, @cmp_end_date, @band_id, @client_name, @agency_name, @media_spend, @has_digilites, @target_demographic_id, @target_attendance, @actual_attendance
end

select #report_data.*, band_desc from #report_data
inner join film_duration_bands on #report_Data.band_id = film_duration_bands.band_id

return 0
GO
