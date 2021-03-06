/****** Object:  StoredProcedure [dbo].[p_cinetam_tap_weight_generation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_tap_weight_generation]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_tap_weight_generation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinetam_tap_weight_generation]			@campaign_no           int
                                            
as
set nocount on 

/*
 * Declare Variables
 */

declare			@error        											int,
						@billing_date										datetime,
						@spot_id												int,		
						@complex_id										int,
						@pack_weight									float,
						@cinema_weight								float,
						@spot_weight									float,
						@rent_distribution_weighting	    numeric(18,4),
						@metro_cin_weight							float,		
						@regional_cin_weight					float,	
						@country_cin_weight					    float,
						@spot_type										varchar(50),
						@status												char(1),
						@country_code									char(1),
						@region_class									char(1),
						@weighting											numeric(6,4),
						@pack_id											int,
						@spot_count										int
      
/*
 * Get Country Information about the Campaign 
 */

select		@country_code = b.country_code
from			film_campaign fc,
					branch b
where		fc.campaign_no = @campaign_no 
and				fc.branch_code = b.branch_code 

select @error = @@error
if (@error !=0)
begin
	raiserror ('Error', 16, 1)
	return -1
end	

/*
 * Loop Tap Spots
 */
     
declare			spot_csr cursor static for
select			spot_id,
						spot_status,
						weighting,
						spot.complex_id,
						spot.package_id,
						spot.screening_date,
						country_code,
						cplx.complex_region_class,
						crc.rent_distribution_weighting    
from				campaign_spot spot,
						complex cplx, 
						state st,
						complex_rent_groups crg,
						film_screening_dates fsd,
						complex_region_class crc,
						campaign_package pack
where			spot.campaign_no = @campaign_no 
and					spot.spot_type = 'T'
and					spot.spot_status = 'X'
and					spot.billing_date = fsd.screening_date 
and					spot.complex_id = cplx.complex_id 
and					spot.package_id = pack.package_id 
and					cplx.state_code = st.state_code 
and					cplx.complex_rent_group = crg.rent_group_no 
and					cplx.complex_region_class = crc.complex_region_class
order by		country_code,
						spot.package_id,
						spot.spot_id
for					read only
       
open spot_csr
fetch spot_csr into @spot_id, @status, @weighting, @complex_id, @pack_id, @billing_date, @country_code, @region_class, @rent_distribution_weighting
while(@@fetch_status = 0.0)
begin
	

        /*
         * Increment Rate and Weighting totals
         */

     	select		@spot_count					= isnull(@spot_count,0) + 1
		select		@pack_weight				= isnull(@pack_weight,0) + isnull(@weighting,0)
    	 
		if @region_class = 'M'
		begin
			select		@metro_cin_weight			=  isnull(@metro_cin_weight,0) + isnull(@weighting,0)
		end

		if @region_class = 'R'
		begin
			select		@regional_cin_weight	=  isnull(@regional_cin_weight,0) + isnull(@weighting,0)
		end
		
		if @region_class = 'C'
		begin
			select		@country_cin_weight		=  isnull(@country_cin_weight,0) + isnull(@weighting,0)
		end

        /*
         * Fetch Next Spot
         */

    	fetch spot_csr into @spot_id, @status,  @weighting, @complex_id, @pack_id, @billing_date, @country_code, @region_class, @rent_distribution_weighting
end
close spot_csr
deallocate spot_csr

    
begin transaction
      
declare			spot_csr cursor static for
select			spot_id,
						spot_status,
						weighting,
						spot.complex_id,
						spot.package_id,
						spot.screening_date,
						country_code,
						cplx.complex_region_class,   
						crc.rent_distribution_weighting    
from				campaign_spot spot,
						complex cplx,
						state st,
						complex_rent_groups crg,
						film_screening_dates fsd,
						complex_region_class crc,
						campaign_package pack
where				spot.campaign_no = @campaign_no 
and					spot.spot_type = 'T'
and					spot.billing_date = fsd.screening_date 
and					spot.complex_id = cplx.complex_id 
and					spot.package_id = pack.package_id 
and					cplx.state_code = st.state_code 
and					cplx.complex_rent_group = crg.rent_group_no 
and					cplx.complex_region_class = crc.complex_region_class
order by			country_code,
						spot.package_id,
						spot.spot_id
for					read only
 
/*
 * Update all Spots
 */

open spot_csr
fetch spot_csr into @spot_id, @status,  @weighting, @complex_id, @pack_id, @billing_date, @country_code, @region_class, @rent_distribution_weighting
while(@@fetch_status = 0.0)
begin
		
	/*
	 * Calculate Spot Weighting
	 */

	if(@region_class = 'M')
		select @cinema_weight = @weighting / @pack_weight

	if(@region_class = 'R')
		select @cinema_weight = @weighting / @pack_weight

	if(@region_class = 'C')
		select @cinema_weight = @weighting / @pack_weight

        /*
         * If New Zealand -> Override the Regional Weighting
         */
    
    if(@country_code <> 'A')
    begin
       select @cinema_weight = @weighting / @pack_weight
    end

	select @spot_weight = 1 / @spot_count

	update	campaign_spot
	set			spot_weighting			= @spot_weight,
					cinema_weighting		= @cinema_weight
	where	spot_id = @spot_id
	
	select @error = @@error
	if (@error !=0)
	begin
		raiserror ('Error', 16, 1)
		rollback transaction
		return -1
	end	
		
	/*
	 * Fetch Next Spot
	 */

	fetch spot_csr into @spot_id, @status,  @weighting, @complex_id, @pack_id, @billing_date, @country_code, @region_class, @rent_distribution_weighting
end
deallocate spot_csr

/*
 * Return Sucess
 */
      
commit transaction
return 0
GO
