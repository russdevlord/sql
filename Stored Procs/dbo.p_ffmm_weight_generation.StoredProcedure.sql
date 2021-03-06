/****** Object:  StoredProcedure [dbo].[p_ffmm_weight_generation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffmm_weight_generation]
GO
/****** Object:  StoredProcedure [dbo].[p_ffmm_weight_generation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC [dbo].[p_ffmm_weight_generation]	@campaign_no				int,
												@inclusion_type				int,
												@accounting_period			datetime,
												@tran_id					int,
												@spot_type					char(1)

as

set nocount on 

/*
 * Declare Variables
 */

declare		@error        							int,
			@screening_date							datetime,
			@spot_id								int,		
			@complex_id								int,
			@pack_weight							float,
			@total_complex_weight					float,
			@total_complex_met_weight				float,
			@total_complex_reg_weight				float,
			@total_complex_cnty_weight				float,
			@total_cin_weight						float,
			@total_complex_attendance				float,
			@total_complex_met_attendance			float,
			@total_complex_reg_attendance			float,
			@total_complex_cnty_attendance			float,
			@total_cin_attendance					float,
			@total_spot_count						float,
			@cinema_weight							float,
			@spot_weight							float,
			@rent_distribution_weighting			numeric(18,4),
			@metro_cin_weight						float,		
			@regional_cin_weight					float,	
			@country_cin_weight						float,
			@status									char(1),
			@country_code							char(1),
			@complex_region_class					char(1),
			@weighting								float,
			@attendance								float,
			@pack_id								int,
			@spot_count								int,
			@package_id								int
      
/*
 * Get Country Information about the Campaign 
 */

select			@country_code = b.country_code
from			film_campaign fc,
				branch b
where			fc.campaign_no = @campaign_no
and				fc.branch_code = b.branch_code 

select @error = @@error
if (@error !=0)
begin
	raiserror ('Error could not get campaign details', 16, 1)
	return -1
end	

/*
 * Get number of spots
 */

select			@total_spot_count = count(campaign_spot.spot_id) 
from			campaign_spot
inner join		complex on campaign_spot.complex_id = complex.complex_id
inner join		complex_rent_groups on complex.complex_rent_group = complex_rent_groups.rent_group_no 
inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
inner join		inclusion_spot	on inclusion_campaign_spot_xref.inclusion_spot_id = inclusion_spot.spot_id 
where			campaign_spot.spot_type = @spot_type				
and				campaign_spot.campaign_no = @campaign_no
and				campaign_spot.spot_status = 'X'
and				inclusion_spot.billing_period = @accounting_period
and				inclusion_spot.tran_id = @tran_id
and				campaign_spot.spot_id not in (select spot_id from spot_liability)

select @error = @@error
if (@error !=0)
begin
	raiserror ('Error could not get campaign details', 16, 1)
	return -1
end	

begin transaction

if @total_spot_count > 0 
begin 
	/*
	 * Get total weights of all complexes for this month
	 */
 
	select			@total_complex_met_weight = sum(temp_table.weighting)
	from			(select			campaign_spot.complex_id,
									weighting,
									campaign_spot.screening_date
					from			campaign_spot
					inner join		complex on campaign_spot.complex_id = complex.complex_id
					inner join		complex_rent_groups on complex.complex_rent_group = complex_rent_groups.rent_group_no 
					inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
					inner join		inclusion_spot	on inclusion_campaign_spot_xref.inclusion_spot_id = inclusion_spot.spot_id 
					where			campaign_spot.spot_type = @spot_type				
					and				campaign_spot.campaign_no = @campaign_no
					and				campaign_spot.spot_status = 'X'
					and				inclusion_spot.billing_period = @accounting_period
					and				inclusion_spot.tran_id = @tran_id
					and				campaign_spot.spot_id not in (select spot_id from spot_liability)
					and				complex_region_class = 'M'
					group by		campaign_spot.complex_id,
									weighting,
									campaign_spot.screening_date) as temp_table


	select @error = @@error
	if (@error !=0)
	begin
		raiserror ('Error could not get campaign met weight details', 16, 1)
		return -1
	end	

	select			@total_complex_reg_weight = sum(temp_table.weighting)
	from			(select			campaign_spot.complex_id,
									weighting,
									campaign_spot.screening_date
					from			campaign_spot
					inner join		complex on campaign_spot.complex_id = complex.complex_id
					inner join		complex_rent_groups on complex.complex_rent_group = complex_rent_groups.rent_group_no 
					inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
					inner join		inclusion_spot	on inclusion_campaign_spot_xref.inclusion_spot_id = inclusion_spot.spot_id 
					where			campaign_spot.spot_type = @spot_type				
					and				campaign_spot.campaign_no = @campaign_no
					and				campaign_spot.spot_status = 'X'
					and				inclusion_spot.billing_period = @accounting_period
					and				inclusion_spot.tran_id = @tran_id
					and				campaign_spot.spot_id not in (select spot_id from spot_liability)
					and				complex_region_class = 'R'
					group by		campaign_spot.complex_id,
									weighting,
									campaign_spot.screening_date) as temp_table

	select @error = @@error
	if (@error !=0)
	begin
		raiserror ('Error could not get campaign reg weight details', 16, 1)
		return -1
	end	

	select			@total_complex_cnty_weight = sum(temp_table.weighting)
	from			(select			campaign_spot.complex_id,
									weighting,
									campaign_spot.screening_date
					from			campaign_spot
					inner join		complex on campaign_spot.complex_id = complex.complex_id
					inner join		complex_rent_groups on complex.complex_rent_group = complex_rent_groups.rent_group_no 
					inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
					inner join		inclusion_spot	on inclusion_campaign_spot_xref.inclusion_spot_id = inclusion_spot.spot_id 
					where			campaign_spot.spot_type = @spot_type				
					and				campaign_spot.campaign_no = @campaign_no
					and				campaign_spot.spot_status = 'X'
					and				inclusion_spot.billing_period = @accounting_period
					and				inclusion_spot.tran_id = @tran_id
					and				campaign_spot.spot_id not in (select spot_id from spot_liability)
					and				complex_region_class = 'C'
					group by		campaign_spot.complex_id,
									weighting,
									campaign_spot.screening_date) as temp_table


	select @error = @@error
	if (@error !=0)
	begin
		raiserror ('Error could not get campaign cnty weight details', 16, 1)
		return -1
	end	

	select			@total_complex_met_attendance = sum(temp_table.percent_market)
	from			(select			campaign_spot.complex_id,
									cinetam_complex_date_settings.percent_market,
									campaign_spot.screening_date
					from			campaign_spot
					inner join		complex on campaign_spot.complex_id = complex.complex_id
					inner join		cinetam_complex_date_settings on cinetam_complex_date_settings.complex_id = complex.complex_id and cinetam_complex_date_settings.screening_date = campaign_spot.screening_date
					inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
					inner join		inclusion_spot	on inclusion_campaign_spot_xref.inclusion_spot_id = inclusion_spot.spot_id 
					where			campaign_spot.spot_type = @spot_type				
					and				campaign_spot.campaign_no = @campaign_no
					and				campaign_spot.spot_status = 'X'
					and				inclusion_spot.billing_period = @accounting_period
					and				inclusion_spot.tran_id = @tran_id
					and				campaign_spot.spot_id not in (select spot_id from spot_liability)
					and				complex_region_class = 'M'
					and				cinetam_reporting_demographics_id = 0
					group by		campaign_spot.complex_id,
									cinetam_complex_date_settings.percent_market,
									campaign_spot.screening_date) as temp_table
	
	select @error = @@error
	if (@error !=0)
	begin
		raiserror ('Error could not get campaign met att details', 16, 1)
		return -1
	end	
	
	select			@total_complex_reg_attendance = sum(temp_table.percent_market)
	from			(select			campaign_spot.complex_id,
									cinetam_complex_date_settings.percent_market,
									campaign_spot.screening_date
					from			campaign_spot
					inner join		complex on campaign_spot.complex_id = complex.complex_id
					inner join		cinetam_complex_date_settings on cinetam_complex_date_settings.complex_id = complex.complex_id and cinetam_complex_date_settings.screening_date = campaign_spot.screening_date
					inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
					inner join		inclusion_spot	on inclusion_campaign_spot_xref.inclusion_spot_id = inclusion_spot.spot_id 
					where			campaign_spot.spot_type = @spot_type				
					and				campaign_spot.campaign_no = @campaign_no
					and				campaign_spot.spot_status = 'X'
					and				inclusion_spot.billing_period = @accounting_period
					and				inclusion_spot.tran_id = @tran_id
					and				campaign_spot.spot_id not in (select spot_id from spot_liability)
					and				complex_region_class = 'R'
					and				cinetam_reporting_demographics_id = 0
					group by		campaign_spot.complex_id,
									cinetam_complex_date_settings.percent_market,
									campaign_spot.screening_date) as temp_table
	
	select @error = @@error
	if (@error !=0)
	begin
		raiserror ('Error could not get campaign reg att details', 16, 1)
		return -1
	end	

	select			@total_complex_cnty_attendance = sum(temp_table.percent_market)
	from			(select			campaign_spot.complex_id,
									cinetam_complex_date_settings.percent_market,
									campaign_spot.screening_date
					from			campaign_spot
					inner join		complex on campaign_spot.complex_id = complex.complex_id
					inner join		cinetam_complex_date_settings on cinetam_complex_date_settings.complex_id = complex.complex_id and cinetam_complex_date_settings.screening_date = campaign_spot.screening_date
					inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
					inner join		inclusion_spot	on inclusion_campaign_spot_xref.inclusion_spot_id = inclusion_spot.spot_id 
					where			campaign_spot.spot_type = @spot_type				
					and				campaign_spot.campaign_no = @campaign_no
					and				campaign_spot.spot_status = 'X'
					and				inclusion_spot.billing_period = @accounting_period
					and				inclusion_spot.tran_id = @tran_id
					and				campaign_spot.spot_id not in (select spot_id from spot_liability)
					and				complex_region_class = 'C'
					and				cinetam_reporting_demographics_id = 0
					group by		campaign_spot.complex_id,
									cinetam_complex_date_settings.percent_market,
									campaign_spot.screening_date) as temp_table
	
	select @error = @@error
	if (@error !=0)
	begin
		raiserror ('Error could not get campaign cnty att details', 16, 1)
		return -1
	end	
	

	update			campaign_spot
	set				spot_weighting = 1.00 / @total_spot_count
	from			complex,
					complex_rent_groups,
					inclusion_campaign_spot_xref, 
					inclusion_spot	
	where			campaign_spot.complex_id = complex.complex_id
	and				complex.complex_rent_group = complex_rent_groups.rent_group_no 
	and				campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
	and				inclusion_campaign_spot_xref.inclusion_spot_id = inclusion_spot.spot_id 
	and				campaign_spot.campaign_no = inclusion_spot.campaign_no 
	and				campaign_spot.spot_type = inclusion_spot.spot_type
	and				campaign_spot.spot_type = @spot_type				
	and				campaign_spot.campaign_no = @campaign_no
	and				campaign_spot.spot_status = 'X'
	and				inclusion_spot.billing_period = @accounting_period
	and				inclusion_spot.tran_id = @tran_id
	and				campaign_spot.spot_id not in (select spot_id from spot_liability)

	select @error = @@error
	if (@error !=0)
	begin
		raiserror ('Error could not get campaign details', 16, 1)
		rollback transaction
		return -1
	end	

	select			@total_cin_weight = isnull(@total_complex_met_weight,0.0) + isnull(@total_complex_reg_weight * 0.75,0.0) + isnull(@total_complex_cnty_weight * 0.5,0.0)
	select			@total_cin_attendance = isnull(@total_complex_met_attendance,0.0) + isnull(@total_complex_reg_attendance * 0.75,0.0) + isnull(@total_complex_cnty_attendance * 0.5,0.0)

	declare			complex_csr cursor static for
	select			campaign_spot.complex_id,
					weighting,
					cinetam_complex_date_settings.percent_market,
					complex_region_class,
					campaign_spot.screening_date,
					count(campaign_spot.spot_id)
	from			campaign_spot
	inner join		complex on campaign_spot.complex_id = complex.complex_id
	inner join		cinetam_complex_date_settings on cinetam_complex_date_settings.complex_id = complex.complex_id and cinetam_complex_date_settings.screening_date = campaign_spot.screening_date
	inner join		complex_rent_groups on complex.complex_rent_group = complex_rent_groups.rent_group_no 
	inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
	inner join		inclusion_spot	on inclusion_campaign_spot_xref.inclusion_spot_id = inclusion_spot.spot_id 
	where			campaign_spot.spot_type = @spot_type				
	and				campaign_spot.campaign_no = @campaign_no
	and				campaign_spot.spot_status = 'X'
	and				inclusion_spot.billing_period = @accounting_period
	and				inclusion_spot.tran_id = @tran_id
	and				campaign_spot.spot_id not in (select spot_id from spot_liability)
	and				cinetam_reporting_demographics_id = 0
	group by		campaign_spot.complex_id, 
					weighting,
					cinetam_complex_date_settings.percent_market,
					complex_region_class,
					campaign_spot.screening_date
				
	open complex_csr
	fetch complex_csr into @complex_id, @weighting, @attendance, @complex_region_class, @screening_date, @spot_count
	while(@@fetch_status = 0)
	begin

		select			@cinema_weight = 0.0
		
		if @complex_region_class = 'M'
		begin
			if @total_cin_weight <> 0 and @spot_count <> 0 and @total_cin_attendance <> 0
			begin
				select		@cinema_weight = ((@weighting / @total_cin_weight) + (@attendance / @total_cin_attendance)) / 2 / @spot_count

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
			if @total_cin_weight <> 0 and @spot_count <> 0 and @total_cin_attendance <> 0
			begin
				select		@cinema_weight = (((@weighting * 0.75) / @total_cin_weight) + (@attendance * 0.75 / @total_cin_attendance)) / 2 / @spot_count

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
			if @total_cin_weight <> 0 and @spot_count <> 0 and @total_cin_attendance <> 0
			begin
				select		@cinema_weight = (((@weighting * .5) / @total_cin_weight) + (@attendance * 0.5 / @total_cin_attendance)) / 2 / @spot_count

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
		select @error = @@error
		if (@error !=0)
		begin
			raiserror ('Error could not get campaign details', 16, 1)
			rollback transaction
			return -1
		end	

		update			campaign_spot
		set				cinema_weighting = @cinema_weight
		from			complex,
						inclusion_campaign_spot_xref, 
						inclusion_spot	
		where			campaign_spot.complex_id = complex.complex_id
		and				campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
		and				inclusion_campaign_spot_xref.inclusion_spot_id = inclusion_spot.spot_id 
		and				campaign_spot.campaign_no = inclusion_spot.campaign_no 
		and				campaign_spot.spot_type = inclusion_spot.spot_type
		and				campaign_spot.spot_type = @spot_type				
		and				campaign_spot.campaign_no = @campaign_no
		and				campaign_spot.spot_status = 'X'
		and				inclusion_spot.billing_period = @accounting_period
		and				inclusion_spot.tran_id = @tran_id
		and				campaign_spot.spot_id not in (select spot_id from spot_liability)
		and				campaign_spot.complex_id = @complex_id
		and				campaign_spot.screening_date = @screening_date
		and				complex_region_class = @complex_region_class

		select @error = @@error
		if (@error !=0)
		begin
			raiserror ('Error could not update cinema weighting', 16, 1)
			rollback transaction
			return -1
		end	

		fetch complex_csr into  @complex_id, @weighting, @attendance, @complex_region_class, @screening_date, @spot_count
	end
end

/*
 * Return Sucess
 */
      
commit transaction
return 0
GO
