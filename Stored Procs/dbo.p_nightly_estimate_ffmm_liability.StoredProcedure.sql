/****** Object:  StoredProcedure [dbo].[p_nightly_estimate_ffmm_liability]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_nightly_estimate_ffmm_liability]
GO
/****** Object:  StoredProcedure [dbo].[p_nightly_estimate_ffmm_liability]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_nightly_estimate_ffmm_liability]		

as

declare			@screening_date								datetime,
				@current_accounting_period					datetime,
				@error										int,
				@inclusion_id								int,
				@billing_amount								float,
				@acom_amount								float,
				@takeout_amount								float,
				@payment_amount								float,
				@cinema_weighting							float,
				@spot_weighting								float,
				@cinema_weighting_tot					    float,
				@spot_id									int,
				@liability_id								int,
				@complex_id									int,
				@liability_amount							float,
				@origin_period								datetime,
				@balance_outstanding						money,
				@package_id									int,
				@inclusion_type								int,
				@spot_type									char(1),
				@business_unit_id							int,
				@commission									numeric(6,4),
				@liability_type								int,
				@campaign_no								int,
				@tran_id									int,
				@spot_count									int
						
set nocount on

select			@current_accounting_period = min(end_date)
from			accounting_period
where			status = 'O'

declare			inclusion_csr cursor for
select			film_campaign.campaign_no,
				business_unit_id,
				inclusion_type,
				inclusion_spot.screening_date
from			inclusion_spot,
				inclusion,
				inclusion_cinetam_package,
				film_campaign
where			inclusion.campaign_no not in (select campaign_no from film_campaign where test_campaign = 'Y')
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				inclusion_spot.billing_period >= @current_accounting_period
and				spot_status <> 'P'
and				inclusion_type in (24,29,30,31,32) --TAP, Follow Film & Roadblock
and				inclusion.inclusion_id = inclusion_cinetam_package.inclusion_id
and				film_campaign.campaign_no = inclusion.campaign_no
group by		film_campaign.campaign_no,
				business_unit_id,
				inclusion_type,
				inclusion_spot.screening_date
order by		film_campaign.campaign_no,
				business_unit_id,
				inclusion_type,
				inclusion_spot.screening_date

begin transaction

open inclusion_csr
fetch inclusion_csr into @campaign_no, @business_unit_id, @inclusion_type, @screening_date
while(@@fetch_status = 0)
begin
	
	if @inclusion_type = 29
		select @spot_type = 'F'
	else if @inclusion_type = 30
		select @spot_type = 'K'
	else if @inclusion_type = 31
		select @spot_type = 'K'
	else if @inclusion_type = 24
		select @spot_type = 'T'
	else if @inclusion_type = 32
		select @spot_type = 'A'

	exec @error = p_nightly_estimate_ffmm_weight_generation @campaign_no, @inclusion_type, @screening_date
	
	if @error <> 0 
	begin
		raiserror	('Error doing the weighty bit', 16, 1)
		rollback transaction
		return -1
	end
	
	select			@billing_amount = isnull(sum(charge_rate),0)
	from			inclusion_spot
	where			campaign_no = @campaign_no
	and				spot_type = @spot_type
	and				screening_date = @screening_date

	select @error = @@error	
	if @error <> 0 
	begin
		raiserror	('Error doing the weighty bit', 16, 1)
		rollback transaction
		return -1
	end	
			
	declare		spot_csr cursor forward_only for
	select			spot_id,
						cinema_weighting,
						spot_weighting, 
						complex_id
	from			campaign_spot
	where			spot_type = @spot_type				
	and				campaign_no = @campaign_no
	and				spot_status = 'X'
	and				screening_date = @screening_date
	and				spot_id not in (select spot_id from spot_liability)
	group by		spot_id,
						cinema_weighting,
						spot_weighting, 
						complex_id
	order by		spot_id
	for				read only
	
	open spot_csr
	fetch spot_csr into @spot_id, @cinema_weighting, @spot_weighting, @complex_id
	while(@@fetch_status = 0)
	begin
	
		/*
		 * Update Spot Cinema Rate
		 */
	
		
		select			@spot_count = count(*) 
		from			campaign_spot_cinema_rate
		where			spot_id = @spot_id 
		
		if @spot_count > 0
		begin
			update			campaign_spot_cinema_rate
			set				cinema_rate = isnull(@billing_amount * @cinema_weighting,0)
			where			spot_id = @spot_id
		
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				raiserror ('Error: Failed to update cinema_rate', 16, 1)
				return -1
			end	
		end
		else
		begin
			insert into campaign_spot_cinema_rate values (@spot_id, isnull(@billing_amount * @cinema_weighting,0))
		end
				
		fetch spot_csr into @spot_id, @cinema_weighting, @spot_weighting, @complex_id
	end
	
	deallocate spot_csr 
	
	fetch inclusion_csr into @campaign_no, @business_unit_id, @inclusion_type, @screening_date
end

commit transaction
return 0
GO
