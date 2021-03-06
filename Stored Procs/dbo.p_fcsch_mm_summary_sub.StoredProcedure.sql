/****** Object:  StoredProcedure [dbo].[p_fcsch_mm_summary_sub]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_fcsch_mm_summary_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_fcsch_mm_summary_sub]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_fcsch_mm_summary_sub]			@campaign_no			int

as

declare		@error								int,
				@met_aus_count				int,
				@reg_aus_count				int,
				@met_3main_count			int,
				@met_5main_count			int,
				@reg_nz_count				int,
				@aus_count						int,
				@nz_count						int,
				@aus_esb_count				int,
				@met_aus_bool				bit,
				@reg_aus_bool				bit,
				@met_3main_bool			bit,
				@met_5main_bool			bit,
				@reg_nz_bool					bit,
				@aus_bool						bit,
				@nz_bool							bit,
				@individual_bool				bit,
				@aus_esb_bool				bit,
				@inclusion_count				int,
				@inclusion_met_aus_count				int,
				@inclusion_reg_aus_count				int,
				@inclusion_met_nz_count				int,
				@inclusion_reg_nz_count				int,
				@inclusion_id					int,
				@movie_id						int,
				@movie_name					varchar(50),
				@attendance					int,				
				@markets							varchar(500),
				@movies							varchar(500),
				@inclusion_desc				varchar(255),
				@prints							varchar(500),
				@print_id							int,
				@print_name					varchar(50),
				@market							varchar(10),
				@country_code				char(1),
				@start_date					datetime,
				@end_date						datetime,
				@product_desc				varchar(100),
				@revision_no					int,
				@business_unit_id			int,
				@market_count				int,
				@disclaimer						int,
				@inclusion_type				varchar(30),
				@cinetam_reporting_demographics_desc			varchar(30)


create table #audience_inclusions
(
	inclusion_type												varchar(30)				null,
	attendance													int							null,
	markets														varchar(500)			null,
	start_date													datetime					null,
	end_date														datetime					null,
	cinetam_reporting_demographics_desc		varchar(30)				null,
	inclusion_desc												varchar(255)			null,
	prints															varchar(500)			null
)	
	
declare			audience_inclusions_csr cursor for
select			inclusion.inclusion_id,
					sum(inclusion_cinetam_targets.original_target_attendance),
					inclusion.start_date,
					inclusion.used_by_date,
					inclusion_type_desc,
					cinetam_reporting_demographics_desc,
					inclusion_desc
from				inclusion,
					inclusion_cinetam_targets,
					inclusion_type,
					cinetam_reporting_demographics
where			inclusion.inclusion_id = 	inclusion_cinetam_targets.inclusion_id
and				inclusion.campaign_no = @campaign_no
and				inclusion_type.inclusion_type = inclusion.inclusion_type
and				inclusion_type_group = 'S'
and				inclusion_type.inclusion_type <> 29
and				inclusion_cinetam_targets.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
group by		inclusion.inclusion_id,
					inclusion.start_date,
					inclusion.used_by_date,
					inclusion_type_desc,
					cinetam_reporting_demographics_desc,
					inclusion_desc
order by		inclusion.inclusion_id			


open audience_inclusions_csr
fetch audience_inclusions_csr into @inclusion_id, @attendance, @start_date, @end_date, @inclusion_type, @cinetam_reporting_demographics_desc, @inclusion_desc
while(@@fetch_status = 0)
begin

	declare			film_print_csr cursor for
	select			film_print.print_id,
						print_name
	from				inclusion,
						inclusion_cinetam_package,
						print_package,
						film_print
	where			inclusion.inclusion_id = 	inclusion_cinetam_package.inclusion_id
	and				inclusion_cinetam_package.package_id = print_package.package_id
	and				print_package.print_id = film_print.print_id
	and				inclusion.inclusion_id = @inclusion_id
	group by		film_print.print_id,
						print_name
	order by		film_print.print_id,
						print_name					

	select			@prints = null
	select			@markets = null

	open film_print_csr
	fetch film_print_csr into @print_id, @print_name
	while(@@fetch_status = 0)
	begin

		if @prints is not null
			select @prints = @prints + ', '

		select @prints = isnull(@prints, '') + convert(varchar(8), @print_id) + ' - ' + @print_name
	
		fetch film_print_csr into @print_id, @print_name
	end
	
	close film_print_csr
	deallocate film_print_csr 

	/*Market Consolidation*/
	select 		@met_aus_count = count(distinct complex.complex_id)
	from		complex,
					film_market
	where		complex.film_market_no = film_market.film_market_no
	and			regional = 'N'
	and			country_code = 'A'
	and			film_complex_status != 'C'
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)
	
	select 		@inclusion_count = count(distinct complex.complex_id)
	from		complex,
					film_market,
					inclusion_cinetam_settings
	where		complex.film_market_no = film_market.film_market_no
	and			regional = 'N'
	and			country_code = 'A'
	and			film_complex_status != 'C'
	and			complex.complex_id = inclusion_cinetam_settings.complex_id
	and			inclusion_cinetam_settings.inclusion_id = @inclusion_id
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

	select @inclusion_met_aus_count = @inclusion_count
	
	if @met_aus_count =  @inclusion_count
		select @met_aus_bool = 1
	else
		select @met_aus_bool = 0
	

	select 		@reg_aus_count = count(distinct complex.complex_id)
	from		complex,
					film_market
	where		complex.film_market_no = film_market.film_market_no
	and			regional = 'Y'
	and			country_code = 'A'
	and			film_complex_status != 'C'
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

	select 		@inclusion_count = count(distinct complex.complex_id)
	from		complex,
					film_market,
					inclusion_cinetam_settings
	where		complex.film_market_no = film_market.film_market_no
	and			regional = 'Y'
	and			country_code = 'A'
	and			film_complex_status != 'C'
	and			complex.complex_id = inclusion_cinetam_settings.complex_id
	and			inclusion_cinetam_settings.inclusion_id = @inclusion_id
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

	select @inclusion_reg_aus_count = @inclusion_count
	
	if @reg_aus_count =  @inclusion_count
		select @reg_aus_bool = 1
	else
		select @reg_aus_bool = 0

	select 		@met_3main_count = count(distinct complex.complex_id)
	from		complex,
					film_market
	where		complex.film_market_no in (16,17,18)
	and			country_code = 'Z'
	and			film_complex_status != 'C'
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

	select 		@inclusion_count = count(distinct complex.complex_id)
	from		complex,
					film_market,
					inclusion_cinetam_settings
	where		complex.film_market_no in (16,17,18)
	and			country_code = 'Z'
	and			film_complex_status != 'C'
	and			complex.complex_id = inclusion_cinetam_settings.complex_id
	and			inclusion_cinetam_settings.inclusion_id = @inclusion_id
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

	if @met_3main_count =  @inclusion_count
		select @met_3main_bool = 1
	else
		select @met_3main_bool = 0
	
	select 		@met_5main_count = count(distinct complex.complex_id)
	from		complex
	where		complex.film_market_no in (16,17,18,19,22)
	and			film_complex_status != 'C'
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

	select 		@inclusion_count = count(distinct complex.complex_id)
	from		complex,
					inclusion_cinetam_settings
	where		complex.film_market_no in (16,17,18,19,22)
	and			film_complex_status != 'C'
	and			complex.complex_id = inclusion_cinetam_settings.complex_id
	and			inclusion_cinetam_settings.inclusion_id = @inclusion_id
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

	if @met_5main_count =  @inclusion_count
		select @met_5main_bool = 1
		if @met_3main_bool = 1 
			select @met_3main_bool = 0
	else
		select @met_5main_bool = 0
	
	select		@reg_nz_count = count(distinct complex.complex_id)
	from		complex,
					film_market
	where		complex.film_market_no = film_market.film_market_no
	and			regional = 'Y'
	and			country_code = 'Z'
	and			film_complex_status != 'C'
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

	select		@inclusion_count = count(distinct complex.complex_id)
	from		complex,
					film_market,
					inclusion_cinetam_settings
	where		complex.film_market_no = film_market.film_market_no
	and			regional = 'Y'
	and			country_code = 'Z'
	and			film_complex_status != 'C'
	and			complex.complex_id = inclusion_cinetam_settings.complex_id
	and			inclusion_cinetam_settings.inclusion_id = @inclusion_id
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

	select @inclusion_reg_nz_count = @inclusion_count

	if @reg_nz_count =  @inclusion_count
		select @reg_nz_bool = 1
	else
		select @reg_nz_bool = 0
	
	select		@aus_esb_count = count(distinct complex.complex_id)
	from		complex
	where		complex.film_market_no in (1,4,6,7,8)
	and			film_complex_status != 'C'
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

	select		@inclusion_count = count(distinct complex.complex_id)
	from		complex,
					inclusion_cinetam_settings
	where		/*complex.film_market_no in (1,4,6,7,8)
	and			*/film_complex_status != 'C'
	and			complex.complex_id = inclusion_cinetam_settings.complex_id
	and			inclusion_cinetam_settings.inclusion_id = @inclusion_id
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

	if @aus_esb_count =  @inclusion_count
		select @aus_esb_bool = 1
	else
		select @aus_esb_bool = 0
	
	select 		@aus_count = count(distinct complex.complex_id)
	from		complex,
					film_market
	where		complex.film_market_no = film_market.film_market_no
	and			country_code = 'A'
	and			film_complex_status != 'C'
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

	select 		@inclusion_count = count(distinct complex.complex_id)
	from			complex,
					film_market,
					inclusion_cinetam_settings
	where		complex.film_market_no = film_market.film_market_no
	and			country_code = 'A'
	and			film_complex_status != 'C'
	and			complex.complex_id = inclusion_cinetam_settings.complex_id
	and			inclusion_cinetam_settings.inclusion_id = @inclusion_id
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

	if @aus_count =  @inclusion_count
	begin
		select	@aus_bool = 1,
					@aus_esb_bool = 0,
					@reg_aus_bool = 0,
					@met_aus_bool = 0
	end
	else
	begin
		select @aus_bool = 0
	end

	select		@nz_count = count(distinct complex.complex_id)
	from		complex,
					film_market
	where		complex.film_market_no = film_market.film_market_no
	and			country_code = 'Z'
	and			film_complex_status != 'C'
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

	select		@inclusion_count = count(distinct complex.complex_id)
	from		complex,
					film_market,
					inclusion_cinetam_settings
	where		complex.film_market_no = film_market.film_market_no
	and			country_code = 'Z'
	and			film_complex_status != 'C'
	and			complex.complex_id = inclusion_cinetam_settings.complex_id
	and			inclusion_cinetam_settings.inclusion_id = @inclusion_id
	and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

	if @nz_count =  @inclusion_count
		select @nz_bool = 1,
					@met_3main_bool = 0,
					@met_5main_bool = 0,
					@reg_nz_bool	= 0
	else
		select @nz_bool = 0
	
	select		@markets = '',
					@individual_bool = 1

	if @met_aus_bool = 1 and @inclusion_reg_aus_count = 0
	begin
		select	@individual_bool = 0
		if len(@markets) <> 0
		begin
			select @markets = @markets + ', '
		end
	
		select @markets = @markets + 'National Metro (AUS)'
	end
			
	if @reg_aus_bool = 1 and @inclusion_met_aus_count = 0
	begin
		select	@individual_bool = 0
		if len(@markets) <> 0
		begin
			select @markets = @markets + ', '
		end
	
		select @markets = @markets + 'National Regional (AUS)'
	end
	
	if @met_3main_bool = 1 
	begin
		select	@individual_bool = 0
		if len(@markets) <> 0
		begin
			select @markets = @markets + ', '
		end
	
		select @markets = @markets + '3 Main Mets (NZ)'
	end
	
	if @met_5main_bool = 1 
	begin
		select	@individual_bool = 0
		if len(@markets) <> 0
		begin
			select @markets = @markets + ', '
		end
	
		select @markets = @markets + '5 Main Mets (NZ)'
	end
	
	if @reg_nz_bool = 1 
	begin
		select	@individual_bool = 0
		if len(@markets) <> 0
		begin
			select @markets = @markets + ', '
		end
	
		select @markets = @markets + 'National Regional (NZ)'
	end
	
	if @aus_bool = 1 
	begin
		select	@individual_bool = 0
		if len(@markets) <> 0
		begin
			select @markets = @markets + ', '
		end
	
		select @markets = @markets + 'National (AUS)'
	end
	
	if @nz_bool = 1 
	begin
		select	@individual_bool = 0
		if len(@markets) <> 0
		begin
			select @markets = @markets + ', '
		end
	
		select @markets = @markets + 'National (NZ)'
	end
	
	if @aus_esb_bool = 1 
	begin
		select	@individual_bool = 0
		if len(@markets) <> 0
		begin
			select @markets = @markets + ', '
		end
	
		select @markets = @markets + 'Eastern Seaboard (AUS)'
	end

	select			@disclaimer = 0

	if @individual_bool = 1 
	begin
	
		declare		market_csr cursor for
		select			film_market_code
		from			film_market,
							complex,
							inclusion_cinetam_settings
		where			film_market.film_market_no = complex.film_market_no
		and				complex.complex_id = inclusion_cinetam_settings.complex_id
		and				inclusion_cinetam_settings.inclusion_id = @inclusion_id
		group by		film_market_code, film_market.film_market_no
		order by		film_market.film_market_no
		for				read only
		
		
		open market_csr
		fetch market_csr into @market
		while(@@fetch_status = 0)
		begin
			
			select 		@market_count = count(distinct complex.complex_id)
			from		complex,
							film_market
			where		complex.film_market_no = film_market.film_market_no
			and			film_market.film_market_code = @market
			and			film_complex_status != 'C'
			and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)

			select 		@inclusion_count = count(distinct complex.complex_id)
			from		complex,
							film_market,
							inclusion_cinetam_settings
			where		complex.film_market_no = film_market.film_market_no
			and			film_market.film_market_code = @market
			and			film_complex_status != 'C'
			and			complex.complex_id = inclusion_cinetam_settings.complex_id
			and			inclusion_cinetam_settings.inclusion_id = @inclusion_id
			and			complex.complex_id not in (1,2,1338,1339,1341,1340,440,1240,1239,1343)		

			if @market_count <> @inclusion_count
				select		@disclaimer = 1
						
			if len(@markets) <> 0
				select @markets = @markets + ', '

			select @markets = isnull(@markets, '') + 	@market
		
			fetch market_csr into @market
		end
		
		close market_csr
		deallocate market_csr
		
	end

	if @disclaimer = 1 
		select @markets = @markets + ' (Geo-targeted)'
		
	insert into #audience_inclusions values (@inclusion_type, @attendance, @markets, @start_date, @end_date, @cinetam_reporting_demographics_desc, @inclusion_desc, @prints)
	
	fetch audience_inclusions_csr into @inclusion_id, @attendance, @start_date, @end_date, @inclusion_type, @cinetam_reporting_demographics_desc, @inclusion_desc
end

select			@product_desc = product_desc,
					@revision_no = revision_no,
					@business_unit_id = business_unit_id
from				film_campaign
where			campaign_no = @campaign_no

					
select			inclusion_type,
					sum(attendance	) as attendance,
					markets,
					start_date,
					end_date,
					@product_desc,
					@revision_no,
					@business_unit_id,
					cinetam_reporting_demographics_desc,
					inclusion_desc,
					prints
from				#audience_inclusions
group by		inclusion_type,
					markets,
					start_date,
					end_date,
					cinetam_reporting_demographics_desc,
					inclusion_desc,
					prints

return 0
GO
