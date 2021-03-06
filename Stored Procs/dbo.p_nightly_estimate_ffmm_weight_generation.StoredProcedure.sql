/****** Object:  StoredProcedure [dbo].[p_nightly_estimate_ffmm_weight_generation]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_nightly_estimate_ffmm_weight_generation]
GO
/****** Object:  StoredProcedure [dbo].[p_nightly_estimate_ffmm_weight_generation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_nightly_estimate_ffmm_weight_generation]		@campaign_no				int,
																												@inclusion_type			int,
																												@screening_date			datetime
                                            
as
set nocount on 

/*
 * Declare Variables
 */

declare				@error        											int,
						@billing_date										datetime,
						@spot_id												int,		
						@complex_id										int,
						@pack_weight										float,
						@total_complex_met_weight				float,
						@total_complex_met_attendance		float,
						@total_complex_reg_weight				float,
						@total_complex_reg_attendance		float,
						@total_complex_cnty_weight				float,
						@total_complex_cnty_attendance		float,
						@total_spot_count								float,
						@cinema_weight									float,
						@spot_weight										float,
						@rent_distribution_weighting				numeric(18,4),
						@total_cin_weight								float,
						@total_cin_attendance						float,
						@spot_type											varchar(50),
						@status												char(1),
						@country_code									char(1),
						@complex_region_class						char(1),
						@weighting											float,
						@attendance										float,
						@pack_id												int,
						@spot_count										int,
						@package_id										int

/*
create table #temp
(
	complex_id										int			null,
	weighting											float			null,
	total_cin_weight								float			null,
	attendance										float			null,
	total_complex_met_attendance		float			null,
	total_complex_reg_attendance		float			null,
	total_complex_cnty_attendance		float			null,
	spot_count										int			null,
	complex_region_class						char(1)		null,
)
*/      

/*
 * Get Country Information about the Campaign 
 */

select		@country_code = b.country_code
from			film_campaign fc,
				branch b
where		fc.campaign_no = @campaign_no
and			fc.branch_code = b.branch_code 

select @error = @@error
if (@error !=0)
begin
	raiserror ('Error could not get campaign details', 16, 1)
	return -1
end	

/*
 * Get total weight of all complexes for this month
 */

select		@total_complex_met_weight = sum(temp_table.weighting)
from			(select			complex.complex_id, 
									weighting
				from				campaign_spot
				inner join 		complex on campaign_spot.complex_id = complex.complex_id
				inner join		complex_rent_groups on complex.complex_rent_group = complex_rent_groups.rent_group_no
				inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
				inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
				where			campaign_spot.campaign_no = @campaign_no
				and				inclusion_type = @inclusion_type
				and				spot_status = 'X'
				and				campaign_spot.screening_date = @screening_date
				and				campaign_spot.spot_id not in (select spot_id from spot_liability)
				and				complex_region_class = 'M'
				group by		complex.complex_id,
									weighting,
									campaign_spot.spot_id) as temp_table

select @error = @@error
if (@error !=0)
begin
	raiserror ('Error could not get campaign details', 16, 1)
	return -1
end	

select		@total_complex_reg_weight = sum(temp_table.weighting)
from			(select			complex.complex_id, 
									weighting
				from				campaign_spot
				inner join 		complex on campaign_spot.complex_id = complex.complex_id
				inner join		complex_rent_groups on complex.complex_rent_group = complex_rent_groups.rent_group_no
				inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
				inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
				where			campaign_spot.campaign_no = @campaign_no
				and				inclusion_type = @inclusion_type
				and				spot_status = 'X'
				and				campaign_spot.screening_date = @screening_date
				and				campaign_spot.spot_id not in (select spot_id from spot_liability)
				and				complex_region_class = 'R'
				group by		complex.complex_id,
									weighting,
									campaign_spot.spot_id) as temp_table

select @error = @@error
if (@error !=0)
begin
	raiserror ('Error could not get campaign details', 16, 1)
	return -1
end	

select		@total_complex_cnty_weight = sum(temp_table.weighting)
from			(select			complex.complex_id, 
									weighting
				from				campaign_spot
				inner join 		complex on campaign_spot.complex_id = complex.complex_id
				inner join		complex_rent_groups on complex.complex_rent_group = complex_rent_groups.rent_group_no
				inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
				inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
				where			campaign_spot.campaign_no = @campaign_no
				and				inclusion_type = @inclusion_type
				and				spot_status = 'X'
				and				campaign_spot.screening_date = @screening_date
				and				campaign_spot.spot_id not in (select spot_id from spot_liability)
				and				complex_region_class = 'C'
				group by		complex.complex_id,
									weighting,
									campaign_spot.spot_id) as temp_table

select @error = @@error
if (@error !=0)
begin
	raiserror ('Error could not get campaign details', 16, 1)
	return -1
end	
 
select			@total_spot_count = count(campaign_spot.spot_id) 
from				campaign_spot
inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
where			campaign_spot.campaign_no = @campaign_no
and				inclusion_type = @inclusion_type
and				spot_status = 'X'
and				campaign_spot.screening_date = @screening_date
and				campaign_spot.spot_id not in (select spot_id from spot_liability)

select @error = @@error
if (@error !=0)
begin
	raiserror ('Error could not get campaign details', 16, 1)
	return -1
end	

select			@total_cin_weight = isnull(@total_complex_met_weight,0.0) + isnull(@total_complex_reg_weight * 0.75,0.0) + isnull(@total_complex_cnty_weight * 0.5,0.0)


/*
print @total_complex_met_weight
print @total_complex_reg_weight
print @total_complex_cnty_weight
print	@total_cin_weight
print @total_spot_count
*/

begin transaction

if @total_spot_count > 0 
begin 
	update			campaign_spot
	set				spot_weighting = 1.00 / @total_spot_count
	from			inclusion_campaign_spot_xref,
					inclusion	
	where			campaign_spot.campaign_no = @campaign_no
	and				campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
	and				inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
	and				inclusion_type = @inclusion_type
	and				spot_status = 'X'
	and				campaign_spot.screening_date = @screening_date
	and				campaign_spot.spot_id not in (select spot_id from spot_liability)

	select @error = @@error
	if (@error !=0)
	begin
		raiserror ('Error could not get campaign details', 16, 1)
		rollback transaction
		return -1
	end	

	select			@total_complex_met_attendance = sum(cinetam_complex_date_settings.percent_market)
	from			cinetam_complex_date_settings
	inner join		complex on cinetam_complex_date_settings.complex_id = complex.complex_id
	where			screening_date = @screening_date
	and				cinetam_complex_date_settings.complex_id in (		select			campaign_spot.complex_id
																										from				campaign_spot
																										inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
																										inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
																										where			campaign_spot.campaign_no = @campaign_no
																										and				inclusion_type = @inclusion_type
																										and				spot_status = 'X'
																										and				campaign_spot.screening_date = @screening_date
																										and				campaign_spot.spot_id not in (select spot_id from spot_liability))
	and				complex_region_class = 'M'
	and				cinetam_reporting_demographics_id = 0

	select			@total_complex_reg_attendance = sum(cinetam_complex_date_settings.percent_market)
	from				cinetam_complex_date_settings
	inner join		complex on cinetam_complex_date_settings.complex_id = complex.complex_id
	where			screening_date = @screening_date
	and				cinetam_complex_date_settings.complex_id in (		select			campaign_spot.complex_id
																										from				campaign_spot
																										inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
																										inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
																										where			campaign_spot.campaign_no = @campaign_no
																										and				inclusion_type = @inclusion_type
																										and				spot_status = 'X'
																										and				campaign_spot.screening_date = @screening_date
																										and				campaign_spot.spot_id not in (select spot_id from spot_liability))
	and				complex_region_class = 'R'
	and				cinetam_reporting_demographics_id = 0

	select			@total_complex_cnty_attendance = sum(cinetam_complex_date_settings.percent_market)
	from				cinetam_complex_date_settings
	inner join		complex on cinetam_complex_date_settings.complex_id = complex.complex_id
	where			screening_date = @screening_date
	and				cinetam_complex_date_settings.complex_id in (		select			campaign_spot.complex_id
																										from				campaign_spot
																										inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
																										inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
																										where			campaign_spot.campaign_no = @campaign_no
																										and				inclusion_type = @inclusion_type
																										and				spot_status = 'X'
																										and				campaign_spot.screening_date = @screening_date
																										and				campaign_spot.spot_id not in (select spot_id from spot_liability))
	and				complex_region_class = 'C'
	and				cinetam_reporting_demographics_id = 0


	select			@total_cin_attendance = isnull(@total_complex_met_attendance,0.0) + isnull(@total_complex_reg_attendance * 0.75,0.0) + isnull(@total_complex_cnty_attendance * 0.5,0.0)

	declare			complex_csr cursor static for
	select			complex.complex_id, 
						complex_region_class,
						weighting,
						sum(cinetam_complex_date_settings.percent_market)
	from				cinetam_complex_date_settings
	inner join		complex on cinetam_complex_date_settings.complex_id = complex.complex_id
	inner join		complex_rent_groups on complex.complex_rent_group = complex_rent_groups.rent_group_no 
	where			screening_date = @screening_date
	and				complex.complex_id in (		select			campaign_spot.complex_id
																	from				campaign_spot
																	inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
																	inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
																	where			campaign_spot.campaign_no = @campaign_no
																	and				inclusion_type = @inclusion_type
																	and				spot_status = 'X'
																	and				campaign_spot.screening_date = @screening_date
																	and				campaign_spot.spot_id not in (select spot_id from spot_liability))
	and				cinetam_reporting_demographics_id = 0
	group by		complex.complex_id, 
						complex_region_class,
						weighting
				
	open complex_csr
	fetch complex_csr into @complex_id, @complex_region_class, @weighting, @attendance
	while(@@fetch_status = 0)
	begin

		select			@cinema_weight = 0.0

		select			@spot_count = count(campaign_spot.spot_id)
		from				campaign_spot
		inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
		inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
		where			campaign_spot.campaign_no = @campaign_no
		and				inclusion_type = @inclusion_type
		and				spot_status = 'X'
		and				campaign_spot.screening_date = @screening_date
		and				campaign_spot.spot_id not in (select spot_id from spot_liability)
		and				campaign_spot.complex_id = @complex_id
		
		select @error = @@error
		if (@error !=0)
		begin
			raiserror ('Error could not get campaign details', 16, 1)
			rollback transaction
			return -1
		end	

		if @complex_region_class = 'M'
		begin
			if @total_complex_met_weight <> 0 and @spot_count <> 0 and @total_complex_met_attendance <> 0
			begin
				select		@cinema_weight = (((@weighting * @spot_count) / @total_cin_weight) + (@attendance / @total_cin_attendance)) / 2 / @spot_count

				select @error = @@error
				if (@error !=0)
				begin
					raiserror ('Error could not get campaign details', 16, 1)
					rollback transaction
					return -1
				end	
			end 
			else
			begin
				select @cinema_weight = 0
			end
		end
		else if @complex_region_class = 'R'
		begin
			if @total_complex_reg_weight <> 0 and @spot_count <> 0 and @total_complex_reg_attendance <> 0
			begin
				select		@cinema_weight = (((@weighting * @spot_count * 0.75) / @total_cin_weight) + (@attendance * 0.75 / @total_cin_attendance)) / 2 / @spot_count

				select @error = @@error
				if (@error !=0)
				begin
					raiserror ('Error could not get campaign details', 16, 1)
					rollback transaction
					return -1
				end	
			end 
			else
			begin
				select @cinema_weight = 0
			end
		end
		else if @complex_region_class = 'C'
		begin
			if @total_complex_cnty_weight <> 0 and @spot_count <> 0 and @total_complex_cnty_attendance <> 0
			begin
				select		@cinema_weight = (((@weighting * @spot_count * .5) / @total_cin_weight) + (@attendance * 0.5 / @total_cin_attendance)) / 2 / @spot_count

				select @error = @@error
				if (@error !=0)
				begin
					raiserror ('Error could not get campaign details', 16, 1)
					rollback transaction
					return -1
				end	
			end 
			else
			begin
				select @cinema_weight = 0
			end
		end

		update			campaign_spot
		set				cinema_weighting = @cinema_weight
		from				inclusion_campaign_spot_xref,
							inclusion
		where			campaign_spot.campaign_no = @campaign_no
		and				campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
		and				inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
		and				inclusion_type = @inclusion_type
		and				spot_status = 'X'
		and				campaign_spot.screening_date = @screening_date
		and				campaign_spot.spot_id not in (select spot_id from spot_liability)
		and				campaign_spot.complex_id = @complex_id

		select @error = @@error
		if (@error !=0)
		begin
			raiserror ('Error could not get campaign details', 16, 1)
			rollback transaction
			return -1
		end	

	--	insert into #temp values (@complex_id, @weighting, @total_cin_weight, @attendance	, @total_complex_met_attendance, @total_complex_reg_attendance, @total_complex_cnty_attendance, @spot_count, @complex_region_class)

		fetch complex_csr into @complex_id, @complex_region_class, @weighting, @attendance
	end
end

/*
 * Return Sucess
 */
      
--select * from #temp
commit transaction
return 0
GO
