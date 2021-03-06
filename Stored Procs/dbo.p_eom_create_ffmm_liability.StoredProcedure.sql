/****** Object:  StoredProcedure [dbo].[p_eom_create_ffmm_liability]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_create_ffmm_liability]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_create_ffmm_liability]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_eom_create_ffmm_liability]		@accounting_period					datetime

as

declare			@error							int,
				@inclusion_id					int,
				@billing_amount					float,
				@acom_amount					float,
				@takeout_amount					float,
				@payment_amount					float,
				@cinema_weighting				float,
				@spot_weighting					float,
				@cinema_weighting_tot		    float,
				@spot_id						int,
				@liability_id					int,
				@complex_id						int,
				@liability_amount				float,
				@origin_period					datetime,
				@balance_outstanding			money,
				@package_id						int,
				@inclusion_type					int,
				@spot_type						char(1),
				@business_unit_id				int,
				@commission						numeric(6,4),
				@liability_type					int,
				@campaign_no					int,
				@tran_id						int,
				@count							int,
				@inclusion_spot_id				int
						
set nocount on

declare			inclusion_csr cursor for
select			film_campaign.campaign_no,
				business_unit_id,
				film_campaign.commission,
				inclusion_type,
				inclusion_spot.tran_id,
				case when inclusion_type = 29 then 'F' when inclusion_type = 24 then 'T' when inclusion_type = 32 then 'A' end as spot_type
from			inclusion_spot,
				inclusion,
				film_campaign
where			test_campaign != 'Y'
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				inclusion_spot.billing_period = @accounting_period
and				spot_status <> 'P'
and				inclusion_type in (24,29,32) --TAP, Follow Film, Movie Mix
and				film_campaign.campaign_no = inclusion.campaign_no
group by		film_campaign.campaign_no,
				business_unit_id,
				film_campaign.commission,
				inclusion_type,
				inclusion_spot.tran_id
union all
select			film_campaign.campaign_no,
				business_unit_id,
				film_campaign.commission,
				30, --Roadblock
				inclusion_spot.tran_id,
				'K' as spot_type
from			inclusion_spot,
				inclusion,
				film_campaign
where			test_campaign != 'Y'
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				inclusion_spot.billing_period = @accounting_period
and				spot_status <> 'P'
and				inclusion_type in (30,31) -- Roadblock & First Run Roadblock
and				film_campaign.campaign_no = inclusion.campaign_no
group by		film_campaign.campaign_no,
				business_unit_id,
				film_campaign.commission,
				inclusion_type,
				inclusion_spot.tran_id
order by		film_campaign.campaign_no,
				business_unit_id,
				film_campaign.commission,
				inclusion_type

create table #spot_liability
(
	spot_id					int			NOT NULL,
	complex_id				int			NOT NULL,
	liability_type			tinyint		NOT NULL,
	allocation_id			int			NULL,
	creation_period			datetime	NULL,
	origin_period			datetime	NULL,
	release_period			datetime	NULL,
	spot_amount				money		NOT NULL,
	cinema_amount			money		NOT NULL,
	cinema_rent				money		NOT NULL,
	cancelled				tinyint		NOT NULL,
	original_liability		tinyint		NOT NULL
)

begin transaction

open inclusion_csr
fetch inclusion_csr into @campaign_no, @business_unit_id, @commission, @inclusion_type, @tran_id, @spot_type
while(@@fetch_status = 0)
begin

	delete			spot_liability
	from			campaign_spot,
					inclusion_campaign_spot_xref,
					inclusion_spot  
	where			spot_liability.spot_id = campaign_spot.spot_id
	and				campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
	and				inclusion_campaign_spot_xref.inclusion_spot_id = inclusion_spot.spot_id
	and				campaign_spot.campaign_no = inclusion_spot.campaign_no 
	and				campaign_spot.spot_type = inclusion_spot.spot_type
	and				campaign_spot.spot_type = @spot_type 
	and				campaign_spot.campaign_no = @campaign_no
	and				release_period = @accounting_period
	and				liability_type not in (3, 7, 8, 17, 18)
	and				campaign_spot.spot_status = 'X'
	and				inclusion_spot.billing_period = @accounting_period
	and				inclusion_spot.tran_id = @tran_id

	select @error = @@error
	if (@error !=0)
	begin
		raiserror ('Error could not get inclusion details', 16, 1)
		rollback transaction
		return -1
	end	

	exec @error = p_ffmm_weight_generation @campaign_no, @inclusion_type, @accounting_period, @tran_id, @spot_type
	
	if @error <> 0 
	begin
		raiserror	('Error doing the weighty bit', 16, 1)
		rollback transaction
		return -1
	end
	
	select		@billing_amount = isnull(sum(charge_rate),0)
	from		inclusion_spot
	where		campaign_no = @campaign_no
	and			spot_type = @spot_type
	and			billing_period = @accounting_period
	and			tran_id = @tran_id

	select @error = @@error	
	if @error <> 0 
	begin
		raiserror	('Error doing the weighty bit', 16, 1)
		rollback transaction
		return -1
	end	
			
	insert into		#spot_liability
	(
		spot_id,
		complex_id,
		liability_type,
		spot_amount,
		cinema_amount,
		cinema_rent,
		cancelled,
		original_liability,
		creation_period,
		origin_period,
		release_period
	)	
	select			campaign_spot.spot_id,
					campaign_spot.complex_id,
					case when campaign_spot.spot_type = 'T' then 34 when business_unit_id = 2 then 1 else 5 end as liability_type,
					isnull(@billing_amount * campaign_spot.spot_weighting,0),
					isnull(@billing_amount * campaign_spot.cinema_weighting,0),
					0,
					0,
					0,
					@accounting_period, 
					@accounting_period, 
					@accounting_period
	from			campaign_spot
	inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
	inner join		inclusion_spot on inclusion_campaign_spot_xref.inclusion_spot_id = inclusion_spot.spot_id
	inner join		film_campaign on campaign_spot.campaign_no = film_campaign.campaign_no
	where			campaign_spot.spot_type = @spot_type				
	and				campaign_spot.campaign_no = @campaign_no
	and				campaign_spot.spot_status = 'X'
	and				inclusion_spot.billing_period = @accounting_period
	and				inclusion_spot.tran_id = @tran_id
	and				campaign_spot.spot_id not in (select spot_id from spot_liability)
	group by		campaign_spot.spot_id,
					campaign_spot.cinema_weighting,
					campaign_spot.spot_weighting, 
					campaign_spot.complex_id,
					film_campaign.business_unit_id,
					campaign_spot.spot_type


	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		raiserror ('Error: Failed to insert temp billing liability', 16, 1)
		return -1
	end	
	
	insert into		film_spot_xref 
	select			campaign_spot.spot_id,
					@tran_id
	from			campaign_spot
	inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
	inner join		inclusion_spot on inclusion_campaign_spot_xref.inclusion_spot_id = inclusion_spot.spot_id
	inner join		film_campaign on campaign_spot.campaign_no = film_campaign.campaign_no
	where			campaign_spot.spot_type = @spot_type				
	and				campaign_spot.campaign_no = @campaign_no
	and				campaign_spot.spot_status = 'X'
	and				inclusion_spot.billing_period = @accounting_period
	and				inclusion_spot.tran_id = @tran_id
	and				campaign_spot.spot_id not in (select spot_id from spot_liability)
	and				campaign_spot.spot_id not in (select spot_id from film_spot_xref where tran_id = @tran_id)

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		raiserror ('Error: Failed to insert tan spot xref', 16, 1)
		return -1
	end	


	update			campaign_spot
	set				cinema_rate = isnull(@billing_amount * campaign_spot.cinema_weighting,0)
	from			campaign_spot
	inner join		inclusion_campaign_spot_xref on campaign_spot.spot_id = inclusion_campaign_spot_xref.spot_id
	inner join		inclusion_spot on inclusion_campaign_spot_xref.inclusion_spot_id = inclusion_spot.spot_id
	inner join		film_campaign on campaign_spot.campaign_no = film_campaign.campaign_no
	where			campaign_spot.spot_type = @spot_type				
	and				campaign_spot.campaign_no = @campaign_no
	and				campaign_spot.spot_status = 'X'
	and				inclusion_spot.billing_period = @accounting_period
	and				inclusion_spot.tran_id = @tran_id
	and				campaign_spot.spot_id not in (select spot_id from spot_liability)
		
	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		raiserror ('Error: Failed to update spot with cinema rate', 16, 1)
		return -1
	end	
				
	fetch inclusion_csr into @campaign_no, @business_unit_id, @commission, @inclusion_type, @tran_id, @spot_type
end

insert into spot_liability
(
	spot_liability_id,
	spot_id,
	complex_id,
	liability_type,
	spot_amount,
	cinema_amount,
	cinema_rent,
	cancelled,
	original_liability,
	creation_period,
	origin_period,
	release_period
)
select		(select max(spot_liability_id) from spot_liability) + row_number() over (order by #spot_liability.spot_id) as spot_liability_id,	
			spot_id,
			complex_id,
			liability_type,
			spot_amount,
			cinema_amount,
			cinema_rent,
			cancelled,
			original_liability,
			creation_period,
			origin_period,
			release_period
from		#spot_liability			

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error: Failed to insert actual liability records', 16, 1)
	return -1
end	

update		sequence_no
set			next_value = next_spot_id
from		(select			max(spot_liability_id) + 1 as next_spot_id
			from			spot_liability) as temp_table
where		table_name = 'spot_liability'

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error updating campaign spot sequence number table', 16, 1) 
   return -1
end	

commit transaction
return 0
GO
