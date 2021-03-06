/****** Object:  StoredProcedure [dbo].[p_eom_takeout_summary]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_takeout_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_takeout_summary]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE proc [dbo].[p_eom_takeout_summary] 	@accounting_period_from		datetime,
											@accounting_period_to		datetime,
											@country_code				char(1)

as

declare		@error						int,
			@billing_period				datetime,
			@takeout_amount				money,
			@billing_credit				money,
			@payment					money,
			@billings					money,
			@commission					money,
			@inclusion_category			char(1),
			@trantype_id				int,
			@inclusion_type				int,
			@campaign_no				int,
			@other_takeout_amt			int,
            @inclusion_id               int,
            @product_desc               varchar(100),
            @inclusion_desc             varchar(100),
            @accounting_period			datetime

create table #takeout_summary
(
	accounting_period	datetime,
    campaign_no         int,
    product_desc        varchar(100),
	inclusion_id		int,
    inclusion_desc      varchar(100),
	billing_period		datetime,
	takeout_amount		money,
	billing_credit		money,
	payment				money,
	billings			money,
	commission			money,
	other_takeout_amt	money
)

declare     eom_takeout_csr cursor forward_only for
select 		distinct inc.inclusion_id,
			inclusion_desc,
			film_campaign.campaign_no,
			film_campaign.product_desc,
			spot.billing_period 
from 		inclusion_spot spot,
            inclusion inc,
            film_campaign
where 		spot.inclusion_id = inc.inclusion_id 
and         spot.billing_period between @accounting_period_from and @accounting_period_to
and         spot.spot_status <> 'P' 
and         inc.inclusion_category <> 'S' --standard - not bundled
and         inc.inclusion_category <> 'G' --invoicing plan 
and         inc.inclusion_category <> 'M' --standard - bundled
and			inc.campaign_no = film_campaign.campaign_no
and			film_campaign.branch_code in (select branch_code from branch where country_code = @country_code)
order by 	inc.inclusion_id
for         read only

open eom_takeout_csr
fetch eom_takeout_csr into @inclusion_id, @inclusion_desc, @campaign_no, @product_desc, @accounting_period
while (@@fetch_status = 0)
begin
    select 		@inclusion_category = inclusion_category,
			    @inclusion_type = inclusion_type,
			    @campaign_no = campaign_no
    from		inclusion
    where 		inclusion_id = @inclusion_id

    select 		@error = @@error
    if @error <> 0
    begin
	    raiserror ('Error: could not retrieve takeout summary.', 16, 1)
	    return -1
    end 

    select		@trantype_id = trantype_id
    from		inclusion_type_category_xref
    where		inclusion_type = @inclusion_type 
    and			inclusion_category = @inclusion_category

    select 		@error = @@error
    if @error <> 0
    begin
	    raiserror ('Error: could not retrieve takeout summary.', 16, 1)
	    return -1
    end 

    declare		takeout_csr cursor static forward_only for
    select		billing_period,
			    sum(takeout_rate)
    from		inclusion_spot
    where		inclusion_id = @inclusion_id
    and         billing_period = @accounting_period
    group by 	billing_period
    order by 	billing_period

    open takeout_csr
    fetch takeout_csr into @billing_period,  @takeout_amount
    while(@@fetch_status=0)
    begin
	
	    if @inclusion_category = 'F' --film
	    begin
		    select 	@billings = sum(campaign_spot.charge_rate)
		    from	campaign_spot,
				    campaign_package
		    where	campaign_spot.package_id = campaign_package.package_id
		    and		campaign_package.media_product_id = 1
		    and		campaign_spot.campaign_no = campaign_package.campaign_no
		    and		campaign_spot.campaign_no = @campaign_no
		    and		campaign_package.campaign_no = @campaign_no
		    and		billing_period = @billing_period

		    select 	@billings = isnull(@billings,0)  + isnull(sum(inclusion_spot.charge_rate),0)
		    from	inclusion_spot,
					inclusion_cinetam_package,
				    campaign_package
		    where	inclusion_spot.inclusion_id = inclusion_cinetam_package.inclusion_id
		    and		inclusion_cinetam_package.package_id = campaign_package.package_id
		    and		campaign_package.media_product_id = 1
		    and		inclusion_spot.campaign_no = campaign_package.campaign_no
		    and		inclusion_spot.campaign_no = @campaign_no
		    and		campaign_package.campaign_no = @campaign_no
		    and		billing_period = @billing_period

		    select 	@commission = 0 - sum(campaign_spot.charge_rate * film_campaign.commission)
		    from	campaign_spot,
				    campaign_package,
				    film_campaign
		    where	campaign_spot.package_id = campaign_package.package_id
		    and		campaign_package.media_product_id = 1
		    and		campaign_spot.campaign_no = campaign_package.campaign_no
		    and		campaign_spot.campaign_no = @campaign_no
		    and		campaign_package.campaign_no = @campaign_no
		    and		billing_period = @billing_period
		    and		film_campaign.campaign_no = @campaign_no
		    and		film_campaign.campaign_no = campaign_spot.campaign_no
		    and		film_campaign.campaign_no = campaign_package.campaign_no
		    
		    select 	@commission = isnull(@commission,0)  + isnull(sum(inclusion_spot.charge_rate * film_campaign.commission),0)
		    from	inclusion_spot,
					inclusion_cinetam_package,
				    campaign_package,
				    film_campaign
		    where	inclusion_spot.inclusion_id = inclusion_cinetam_package.inclusion_id
		    and		inclusion_cinetam_package.package_id = campaign_package.package_id
		    and		campaign_package.media_product_id = 1
		    and		inclusion_spot.campaign_no = campaign_package.campaign_no
		    and		inclusion_spot.campaign_no = @campaign_no
		    and		campaign_package.campaign_no = @campaign_no
		    and		film_campaign.campaign_no = campaign_package.campaign_no
		    and		billing_period = @billing_period		    

		    select 	@billing_credit = sum(spot_amount)
		    from	spot_liability,
				    campaign_spot,
				    campaign_package,
				    liability_type
		    where	campaign_spot.package_id = campaign_package.package_id
		    and		campaign_package.media_product_id = 1
		    and		campaign_spot.campaign_no = campaign_package.campaign_no
		    and		campaign_spot.campaign_no = @campaign_no
		    and		campaign_package.campaign_no = @campaign_no
		    and		billing_period = @billing_period
		    and		spot_liability.spot_id = campaign_spot.spot_id
		    and		liability_type.liability_type_id = spot_liability.liability_type
		    and		liability_category_id = 2		

		    select 	@payment = sum(spot_amount)
		    from	spot_liability,
				    campaign_spot,
				    campaign_package,
				    liability_type
		    where	campaign_spot.package_id = campaign_package.package_id
		    and		campaign_package.media_product_id = 1
		    and		campaign_spot.campaign_no = campaign_package.campaign_no
		    and		campaign_spot.campaign_no = @campaign_no
		    and		campaign_package.campaign_no = @campaign_no
		    and		billing_period = @billing_period
		    and		spot_liability.spot_id = campaign_spot.spot_id
		    and		liability_category_id = 6		
		    and		liability_type.liability_type_id = spot_liability.liability_type

		    select	@other_takeout_amt = sum(takeout_rate)
		    from	inclusion_spot,
				    inclusion
		    where	inclusion.inclusion_id = inclusion_spot.inclusion_id
		    and		inclusion.inclusion_id <> @inclusion_id
		    and		inclusion.campaign_no = @campaign_no
		    and		inclusion_spot.billing_period = @billing_period
		    and		inclusion_category = 'F'

	    end
	    else if @inclusion_category = 'D' --dmg
	    begin
		    select 	@billings = sum(campaign_spot.charge_rate)
		    from	campaign_spot,
				    campaign_package
		    where	campaign_spot.package_id = campaign_package.package_id
		    and		campaign_package.media_product_id = 2
		    and		campaign_spot.campaign_no = campaign_package.campaign_no
		    and		campaign_spot.campaign_no = @campaign_no
		    and		campaign_package.campaign_no = @campaign_no
		    and		billing_period = @billing_period

		    select 	@billings = isnull(@billings,0)  + isnull(sum(inclusion_spot.charge_rate),0)
		    from	inclusion_spot,
					inclusion_cinetam_package,
				    campaign_package
		    where	inclusion_spot.inclusion_id = inclusion_cinetam_package.inclusion_id
		    and		inclusion_cinetam_package.package_id = campaign_package.package_id
		    and		campaign_package.media_product_id = 2
		    and		inclusion_spot.campaign_no = campaign_package.campaign_no
		    and		inclusion_spot.campaign_no = @campaign_no
		    and		campaign_package.campaign_no = @campaign_no
		    and		billing_period = @billing_period
		    
		    select 	@commission = 0 - sum(campaign_spot.charge_rate * film_campaign.commission)
		    from	campaign_spot,
				    campaign_package,
				    film_campaign
		    where	campaign_spot.package_id = campaign_package.package_id
		    and		campaign_package.media_product_id = 2
		    and		campaign_spot.campaign_no = campaign_package.campaign_no
		    and		campaign_spot.campaign_no = @campaign_no
		    and		campaign_package.campaign_no = @campaign_no
		    and		billing_period = @billing_period
		    and		film_campaign.campaign_no = @campaign_no
		    and		film_campaign.campaign_no = campaign_spot.campaign_no
		    and		film_campaign.campaign_no = campaign_package.campaign_no

		    select 	@commission = isnull(@commission,0)  + isnull(sum(inclusion_spot.charge_rate * film_campaign.commission),0)
		    from	inclusion_spot,
					inclusion_cinetam_package,
				    campaign_package,
				    film_campaign
		    where	inclusion_spot.inclusion_id = inclusion_cinetam_package.inclusion_id
		    and		inclusion_cinetam_package.package_id = campaign_package.package_id
		    and		campaign_package.media_product_id = 2
		    and		inclusion_spot.campaign_no = campaign_package.campaign_no
		    and		inclusion_spot.campaign_no = @campaign_no
		    and		campaign_package.campaign_no = @campaign_no
		    and		film_campaign.campaign_no = campaign_package.campaign_no
		    and		billing_period = @billing_period		    

		    select 	@billing_credit = sum(spot_amount)
		    from	spot_liability,
				    campaign_spot,
				    campaign_package,
				    liability_type
		    where	campaign_spot.package_id = campaign_package.package_id
		    and		campaign_package.media_product_id = 2
		    and		campaign_spot.campaign_no = campaign_package.campaign_no
		    and		campaign_spot.campaign_no = @campaign_no
		    and		campaign_package.campaign_no = @campaign_no
		    and		billing_period = @billing_period
		    and		spot_liability.spot_id = campaign_spot.spot_id
		    and		liability_type.liability_type_id = spot_liability.liability_type
		    and		liability_category_id = 2		

		    select 	@payment = sum(spot_amount)
		    from	spot_liability,
				    campaign_spot,
				    campaign_package,
				    liability_type
		    where	campaign_spot.package_id = campaign_package.package_id
		    and		campaign_package.media_product_id = 2
		    and		campaign_spot.campaign_no = campaign_package.campaign_no
		    and		campaign_spot.campaign_no = @campaign_no
		    and		campaign_package.campaign_no = @campaign_no
		    and		billing_period = @billing_period
		    and		spot_liability.spot_id = campaign_spot.spot_id
		    and		liability_category_id = 6		
		    and		liability_type.liability_type_id = spot_liability.liability_type

		    select	@other_takeout_amt = sum(takeout_rate)
		    from	inclusion_spot,
				    inclusion
		    where	inclusion.inclusion_id = inclusion_spot.inclusion_id
		    and		inclusion.inclusion_id <> @inclusion_id
		    and		inclusion_spot.billing_period = @billing_period
		    and		inclusion.campaign_no = @campaign_no
		    and		inclusion_category = 'D'
	    end
	    else if @inclusion_category = 'C' --cinelights
	    begin
		    select 	@billings = sum(cinelight_spot.charge_rate)
		    from	cinelight_spot,
				    cinelight_package
		    where	cinelight_spot.package_id = cinelight_package.package_id
		    and		cinelight_package.media_product_id = 3
		    and		cinelight_spot.campaign_no = cinelight_package.campaign_no
		    and		cinelight_spot.campaign_no = @campaign_no
		    and		cinelight_package.campaign_no = @campaign_no
		    and		billing_period = @billing_period

		    select 	@commission = 0 - sum(cinelight_spot.charge_rate * film_campaign.commission)
		    from	cinelight_spot,
				    cinelight_package,
				    film_campaign
		    where	cinelight_spot.package_id = cinelight_package.package_id
		    and		cinelight_package.media_product_id = 3
		    and		cinelight_spot.campaign_no = cinelight_package.campaign_no
		    and		cinelight_spot.campaign_no = @campaign_no
		    and		cinelight_package.campaign_no = @campaign_no
		    and		billing_period = @billing_period
		    and		film_campaign.campaign_no = @campaign_no
		    and		film_campaign.campaign_no = cinelight_spot.campaign_no
		    and		film_campaign.campaign_no = cinelight_package.campaign_no

		    select 	@billing_credit = sum(spot_amount)
		    from	cinelight_spot_liability,
				    cinelight_spot,
				    cinelight_package,
				    liability_type
		    where	cinelight_spot.package_id = cinelight_package.package_id
		    and		cinelight_package.media_product_id = 1
		    and		cinelight_spot.campaign_no = cinelight_package.campaign_no
		    and		cinelight_spot.campaign_no = @campaign_no
		    and		cinelight_package.campaign_no = @campaign_no
		    and		billing_period = @billing_period
		    and		cinelight_spot_liability.spot_id = cinelight_spot.spot_id
		    and		liability_type.liability_type_id = cinelight_spot_liability.liability_type
		    and		liability_category_id = 2		

		    select 	@payment = sum(spot_amount)
		    from	cinelight_spot_liability,
				    cinelight_spot,
				    cinelight_package,
				    liability_type
		    where	cinelight_spot.package_id = cinelight_package.package_id
		    and		cinelight_package.media_product_id = 1
		    and		cinelight_spot.campaign_no = cinelight_package.campaign_no
		    and		cinelight_spot.campaign_no = @campaign_no
		    and		cinelight_package.campaign_no = @campaign_no
		    and		billing_period = @billing_period
		    and		cinelight_spot_liability.spot_id = cinelight_spot.spot_id
		    and		liability_category_id = 6		
		    and		liability_type.liability_type_id = cinelight_spot_liability.liability_type

		    select	@other_takeout_amt = sum(takeout_rate)
		    from	inclusion_spot,
				    inclusion
		    where	inclusion.inclusion_id = inclusion_spot.inclusion_id
		    and		inclusion.inclusion_id <> @inclusion_id
		    and		inclusion_spot.billing_period = @billing_period
		    and		inclusion.campaign_no = @campaign_no
		    and		inclusion_category = 'C'
	    end
	    else if @inclusion_category = 'I' --cinemarketing
	    begin
		    select 	@billings = sum(charge_rate)
		    from	inclusion_spot,
				    inclusion,
				    inclusion_type
		    where	inclusion_spot.inclusion_id = inclusion.inclusion_id
		    and		inclusion_spot.campaign_no = inclusion.campaign_no
		    and		inclusion_spot.campaign_no = @campaign_no
		    and		inclusion.campaign_no = @campaign_no
		    and		inclusion_spot.billing_period = @billing_period
		    and		inclusion.inclusion_type = inclusion_type.inclusion_type
		    and		inclusion_type.inclusion_type_group = 'C'	

		    select 	@commission = 0 - sum(charge_rate * inclusion.commission)
		    from	inclusion_spot,
				    inclusion,
				    inclusion_type
		    where	inclusion_spot.inclusion_id = inclusion.inclusion_id
		    and		inclusion_spot.campaign_no = inclusion.campaign_no
		    and		inclusion_spot.campaign_no = @campaign_no
		    and		inclusion.campaign_no = @campaign_no
		    and		inclusion_spot.billing_period = @billing_period
		    and		inclusion.inclusion_type = inclusion_type.inclusion_type
		    and		inclusion_type.inclusion_type_group = 'C'	

		    select 	@billing_credit = sum(spot_amount)
		    from	inclusion_spot_liability,
				    inclusion_spot,
				    inclusion,
				    liability_type
		    where	inclusion_spot.inclusion_id = inclusion.inclusion_id
		    and		inclusion_spot.campaign_no = inclusion.campaign_no
		    and		inclusion_spot.campaign_no = @campaign_no
		    and		inclusion.campaign_no = @campaign_no
		    and		inclusion_spot.billing_period = @billing_period
		    and		inclusion_spot_liability.spot_id = inclusion_spot.spot_id
		    and		liability_type.liability_type_id = inclusion_spot_liability.liability_type
		    and		liability_category_id = 2		

		    select 	@payment = sum(spot_amount)
		    from	inclusion_spot_liability,
				    inclusion_spot,
				    inclusion,
				    liability_type
		    where	inclusion_spot.inclusion_id = inclusion.inclusion_id
		    and		inclusion_spot.campaign_no = inclusion.campaign_no
		    and		inclusion_spot.campaign_no = @campaign_no
		    and		inclusion.campaign_no = @campaign_no
		    and		inclusion_spot.billing_period = @billing_period
		    and		inclusion_spot_liability.spot_id = inclusion_spot.spot_id
		    and		liability_category_id = 6		
		    and		liability_type.liability_type_id = inclusion_spot_liability.liability_type

		    select	@other_takeout_amt = sum(takeout_rate)
		    from	inclusion_spot,
				    inclusion
		    where	inclusion.inclusion_id = inclusion_spot.inclusion_id
		    and		inclusion.inclusion_id <> @inclusion_id
		    and		inclusion_spot.billing_period = @billing_period
		    and		inclusion.campaign_no = @campaign_no
		    and		inclusion_category = 'I'
	    end
	else if @inclusion_category = 'R' --retail
	begin
		select 	@billings = sum(outpost_spot.charge_rate)
		from	outpost_spot,
					outpost_package
		where	outpost_spot.package_id = outpost_package.package_id
		and		outpost_package.media_product_id = 9
		and		outpost_spot.campaign_no = outpost_package.campaign_no
		and		outpost_spot.campaign_no = @campaign_no
		and		outpost_package.campaign_no = @campaign_no
		and		billing_period = @billing_period

		select 	@commission = 0 - sum(outpost_spot.charge_rate * film_campaign.commission)
		from	outpost_spot,
				outpost_package,
				film_campaign
		where	outpost_spot.package_id = outpost_package.package_id
		and		outpost_package.media_product_id = 9
		and		outpost_spot.campaign_no = outpost_package.campaign_no
		and		outpost_spot.campaign_no = @campaign_no
		and		outpost_package.campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		film_campaign.campaign_no = @campaign_no
		and		film_campaign.campaign_no = outpost_spot.campaign_no
		and		film_campaign.campaign_no = outpost_package.campaign_no

		select 	@billing_credit = sum(spot_amount)
		from	outpost_spot_liability,
				outpost_spot,
				outpost_package,
				liability_type
		where	outpost_spot.package_id = outpost_package.package_id
		and		outpost_package.media_product_id = 1
		and		outpost_spot.campaign_no = outpost_package.campaign_no
		and		outpost_spot.campaign_no = @campaign_no
		and		outpost_package.campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		outpost_spot_liability.spot_id = outpost_spot.spot_id
		and		liability_type.liability_type_id = outpost_spot_liability.liability_type
		and		liability_category_id = 2		

		select 	@payment = sum(spot_amount)
		from	outpost_spot_liability,
					outpost_spot,
					outpost_package,
					liability_type
		where	outpost_spot.package_id = outpost_package.package_id
		and		outpost_package.media_product_id = 1
		and		outpost_spot.campaign_no = outpost_package.campaign_no
		and		outpost_spot.campaign_no = @campaign_no
		and		outpost_package.campaign_no = @campaign_no
		and		billing_period = @billing_period
		and		outpost_spot_liability.spot_id = outpost_spot.spot_id
		and		liability_category_id = 6		
		and		liability_type.liability_type_id = outpost_spot_liability.liability_type

		select	@other_takeout_amt = sum(takeout_rate)
		from	inclusion_spot,
					inclusion
		where	inclusion.inclusion_id = inclusion_spot.inclusion_id
		and		inclusion.inclusion_id <> @inclusion_id
		and		inclusion_spot.billing_period = @billing_period
		and		inclusion.campaign_no = @campaign_no
		and		inclusion_category = 'R'
	end
	else if @inclusion_category = 'T' --TAP
	begin
		select 	@billings = sum(charge_rate)
		from	inclusion_spot,
				inclusion
		where	inclusion_spot.inclusion_id = inclusion.inclusion_id
		and		inclusion_spot.campaign_no = inclusion.campaign_no
		and		inclusion_spot.campaign_no = @campaign_no
		and		inclusion.campaign_no = @campaign_no
		and		inclusion_spot.billing_period = @billing_period
		and		inclusion.inclusion_type = 24

		select 	@commission = 0 - sum(charge_rate * inclusion.commission)
		from	inclusion_spot,
				inclusion
		where	inclusion_spot.inclusion_id = inclusion.inclusion_id
		and		inclusion_spot.campaign_no = inclusion.campaign_no
		and		inclusion_spot.campaign_no = @campaign_no
		and		inclusion.campaign_no = @campaign_no
		and		inclusion_spot.billing_period = @billing_period
		and		inclusion.inclusion_type = 24	

		select 	@billing_credit = sum(spot_amount)
		from	inclusion_spot_liability,
				inclusion_spot,
				inclusion,
				liability_type
		where	inclusion_spot.inclusion_id = inclusion.inclusion_id
		and		inclusion_spot.campaign_no = inclusion.campaign_no
		and		inclusion_spot.campaign_no = @campaign_no
		and		inclusion.campaign_no = @campaign_no
		and		inclusion_spot.billing_period = @billing_period
		and		inclusion_spot_liability.spot_id = inclusion_spot.spot_id
		and		liability_type.liability_type_id = inclusion_spot_liability.liability_type
		and		liability_category_id = 2		

		select 	@payment = sum(spot_amount)
		from	inclusion_spot_liability,
				inclusion_spot,
				inclusion,
				liability_type
		where	inclusion_spot.inclusion_id = inclusion.inclusion_id
		and		inclusion_spot.campaign_no = inclusion.campaign_no
		and		inclusion_spot.campaign_no = @campaign_no
		and		inclusion.campaign_no = @campaign_no
		and		inclusion_spot.billing_period = @billing_period
		and		inclusion_spot_liability.spot_id = inclusion_spot.spot_id
		and		liability_category_id = 6		
		and		liability_type.liability_type_id = inclusion_spot_liability.liability_type

		select	@other_takeout_amt = sum(takeout_rate)
		from	inclusion_spot,
				inclusion
		where	inclusion.inclusion_id = inclusion_spot.inclusion_id
		and		inclusion.inclusion_id <> @inclusion_id
		and		inclusion_spot.billing_period = @billing_period
		and		inclusion.campaign_no = @campaign_no
		and		inclusion_category = 'T'
	end
	    

	    insert into #takeout_summary
	    (accounting_period, 
	    inclusion_id,
        inclusion_desc,
        campaign_no,
        product_desc,
	    billing_period,
	    takeout_amount,
	    billing_credit,
	    payment,
	    billings,
	    commission,
	    other_takeout_amt) values
	    (@accounting_period,
	    @inclusion_id,
        @inclusion_desc,
        @campaign_no,
        @product_desc,
	    @billing_period,
	    isnull(@takeout_amount,0),
	    isnull(@billing_credit,0),
	    isnull(@payment,0),
	    isnull(@billings,0),
	    isnull(@commission,0),
	    isnull(@other_takeout_amt,0)) 

	    select 		@error = @@error
	    if @error <> 0
	    begin
		    raiserror ('Error: could not update takeout summary.', 16, 1)
		    return -1
	    end 

	    fetch takeout_csr into @billing_period, @takeout_amount
    end 
    
    deallocate takeout_csr
    
fetch eom_takeout_csr into @inclusion_id, @inclusion_desc, @campaign_no, @product_desc, @accounting_period
end

deallocate eom_takeout_csr

select 		Temp.campaign_no,
            Temp.product_desc,
            Temp.inclusion_id,
			Temp.inclusion_desc,
            Temp.billing_period,
			takeout_amount,
			billing_credit,
			payment,
			billings,
			Temp.commission,
			other_takeout_amt,
			inclusion_type.inclusion_type,
			inclusion_type.inclusion_type_desc,
			sales_rep = sales_rep.first_name + ' ' + sales_rep.last_name,
			fc.branch_code,
			branch.branch_name,
			fc.business_unit_id,
			business_unit.business_unit_desc,
			Temp.accounting_period
from		#takeout_summary AS Temp,
			inclusion,
			inclusion_type,
			film_campaign fc,
			sales_rep,
			business_unit,
			branch
WHERE		Temp.inclusion_id = inclusion.inclusion_id
AND			inclusion.inclusion_type = inclusion_type.inclusion_type
AND			Temp.campaign_no = fc.campaign_no
and			fc.rep_id = sales_rep.rep_id
AND			fc.business_unit_id = business_unit.business_unit_id
AND			fc.branch_code = branch.branch_code

return 0
GO
