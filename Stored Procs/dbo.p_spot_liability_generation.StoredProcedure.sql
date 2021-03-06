/****** Object:  StoredProcedure [dbo].[p_spot_liability_generation]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_spot_liability_generation]
GO
/****** Object:  StoredProcedure [dbo].[p_spot_liability_generation]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC [dbo].[p_spot_liability_generation] @campaign_no			int,
												@mode            		int,
												@tran_id                int,
												@media_product_mode		int
as
set nocount on  

/*
 * Declare Variables
 */

declare @error        						int,
        @rowcount     						int,
        @errorode								int,
        @liability_id						int,
        @spot_id							int,		
        @complex_id							int,
        @spot_csr_open						tinyint,
        @liability_amount					numeric(18,4),
        @rate								numeric(18,4),
        @country_code						char(1),
        @bill_total                         numeric(18,4),
        @makegood_rate                      numeric(18,4),
        @spot_weighting                     float,
        @cinema_weighting                   float,
        @agency_comm                        numeric(6,4),
        @ltype                              smallint,
        @mg_acomm_rate                      numeric(18,4),
        @mg_acomm_lbamt                     numeric(18,4),
        @mg_credit_rate                     numeric(18,4),
        @mg_credit_lbamt                    numeric(18,4),
        @spot_redirect                      int,
        @sr_spot_id                         int,
        @sr_complex_id						int,
        @session                            int,
        @original_liability                 int,
        @billing_period                     datetime,
        @media_product_id                   int

/*
 * If the @mode = 4 The Return Immediately - No Action Required
 */

if(@mode=4)
    return 0

if @mode = 5
    select @original_liability = 1
else
    select @original_liability = 0
    
/*
 * Get Agency Commission Value
 */

select @agency_comm = fc.commission
  from film_campaign fc
 where fc.campaign_no = @campaign_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error !=0 or @rowcount=0)
begin
    raiserror ('Failed to Load Agency Commission on Campaign: %1!', 11, 1, @campaign_no)
	return -1
end	

select @agency_comm = isnull(@agency_comm,0)

/*
 * Get Session Id
 */
 
execute @errorode = p_get_sequence_number 'work_session', 5, @session OUTPUT
if(@errorode !=0)
begin
	goto error
end
 
/*
 * Initialise Spot List
 */

if @mode <= 3 -- Called from the Billing Run
begin
	if @media_product_mode = 1 or @media_product_mode = 10
	begin		
	    insert into work_spot_list  --onscreen
	         select @session,
	                spot.campaign_no,
	                @tran_id,
	                spot.spot_id,
	                spot.spot_redirect,
	                spot.spot_status,
	                spot.charge_rate,
	                case fc.business_unit_id when 9 then case when fc.campaign_type >= 5 then 1 else crg.weighting end  else crg.weighting end weighting,
	                cplx.complex_id,
	                spot.package_id,
	                fsd.screening_date,
	                st.country_code,
	                cplx.complex_region_class,
	                case fc.business_unit_id when 9 then case when fc.campaign_type >= 5 then 1 else crc.rent_distribution_weighting end  else crc.rent_distribution_weighting end rent_distribution_weighting,
	                null,
	                null,
	                null,
	                pack.media_product_id
	           from campaign_spot spot,
	                complex cplx,
	                state st,
	                complex_rent_groups crg,
	                film_screening_dates fsd,
	                complex_region_class crc,
	                campaign_package pack,
	                film_campaign fc
	          where spot.campaign_no = @campaign_no and
	                spot.tran_id = @tran_id and 
	                spot.billing_date = fsd.screening_date and
	                spot.complex_id = cplx.complex_id and
	                spot.package_id = pack.package_id and
	                cplx.state_code = st.state_code and
	                cplx.complex_rent_group = crg.rent_group_no and
	                cplx.complex_region_class = crc.complex_region_class and
	                pack.campaign_no = fc.campaign_no
	       order by st.country_code,
	                spot.package_id,
	                spot.spot_id
	end 
	else if @media_product_mode = 2  --cinelights
	begin
	    insert into work_spot_list
	         select @session,
	                spot.campaign_no,
	                @tran_id,
	                spot.spot_id,
	                null,
	                spot.spot_status,
	                spot.charge_rate,
	                crg.weighting,
	                cplx.complex_id,
	                spot.package_id,
	                fsd.screening_date,
	                st.country_code,
	                cplx.complex_region_class,
	                crc.cinelight_distribution_weighting,
	                spot.charge_rate,
	                null,
	                null,
	                pack.media_product_id
	           from cinelight_spot spot,
					cinelight cl,
	                complex cplx,
	                state st,
	                complex_rent_groups crg,
	                film_screening_dates fsd,
	                complex_region_class crc,
	                cinelight_package pack
	          where spot.campaign_no = @campaign_no and
	                spot.tran_id = @tran_id and 
	                spot.billing_date = fsd.screening_date and
	                spot.cinelight_id = cl.cinelight_id and
	                cl.complex_id = cplx.complex_id and
	                spot.package_id = pack.package_id and
	                cplx.state_code = st.state_code and
	                cplx.cinelight_rent_group = crg.rent_group_no and
	                cplx.complex_region_class = crc.complex_region_class
	       order by st.country_code,
	                spot.package_id,
	                spot.spot_id
	end
	else if @media_product_mode = 3 --cinemarketing
	begin
	    insert into work_spot_list
	         select @session,
	                spot.campaign_no,
	                @tran_id,
	                spot.spot_id,
	                null,
	                spot.spot_status,
	                spot.charge_rate,
	                crg.weighting,
	                cplx.complex_id,
	                spot.inclusion_id,
	                fsd.screening_date,
	                st.country_code,
	                cplx.complex_region_class,
	                crc.cinelight_distribution_weighting,
	                spot.charge_rate,
	                null,
	                null,
	                6
	           from inclusion_spot spot,
	                complex cplx,
	                state st,
	                complex_rent_groups crg,
	                film_screening_dates fsd,
	                complex_region_class crc,
	                inclusion inc
	          where spot.campaign_no = @campaign_no and
	                spot.tran_id = @tran_id and
	                spot.billing_date = fsd.screening_date and
	                spot.complex_id = cplx.complex_id and
	                spot.inclusion_id = inc.inclusion_id and
	                cplx.state_code = st.state_code and
	                cplx.cinelight_rent_group = crg.rent_group_no and
	                cplx.complex_region_class = crc.complex_region_class and
					inc.inclusion_type = 5 --cinemarketing
	       order by st.country_code,
	                spot.inclusion_id,
	                spot.spot_id
	end
	else if @media_product_mode = 4 --retail panels
	begin
	    insert into work_spot_list
	         select @session,
	                spot.campaign_no,
	                @tran_id,
	                spot.spot_id,
	                null,
	                spot.spot_status,
	                spot.charge_rate,
	                crg.weighting,
	                cplx.outpost_venue_id,
	                spot.package_id,
	                fsd.screening_date,
	                st.country_code,
	                cplx.region_class,
	                crc.rent_distribution_weighting,
	                spot.charge_rate,
	                null,
	                null,
	                pack.media_product_id
	           from outpost_spot spot,
					outpost_panel cl,
	                outpost_venue cplx,
	                state st,
	                outpost_venue_rent_groups crg,
	                outpost_screening_dates fsd,
	                outpost_venue_region_class crc,
	                outpost_package pack
	          where spot.campaign_no = @campaign_no and
	                spot.tran_id = @tran_id and 
	                spot.billing_date = fsd.screening_date and
	                spot.outpost_panel_id = cl.outpost_panel_id and
	                cl.outpost_venue_id = cplx.outpost_venue_id and
	                spot.package_id = pack.package_id and
	                cplx.state_code = st.state_code and
	                cplx.rent_group_no = crg.rent_group_no and
	                cplx.region_class = crc.region_class
	       order by st.country_code,
	                spot.package_id,
	                spot.spot_id
	end
	else if @media_product_mode = 5 --retail wall
	begin
	    insert into work_spot_list
	         select @session,
	                spot.campaign_no,
	                @tran_id,
	                spot.spot_id,
	                null,
	                spot.spot_status,
	                spot.charge_rate,
	                crg.weighting,
	                cplx.outpost_venue_id,
	                spot.inclusion_id,
	                fsd.screening_date,
	                st.country_code,
	                cplx.region_class,
	                crc.rent_distribution_weighting,
	                spot.charge_rate,
	                null,
	                null,
	                10
	           from inclusion_spot spot,
	                outpost_venue cplx,
	                state st,
	                outpost_venue_rent_groups crg,
	                outpost_screening_dates fsd,
	                outpost_venue_region_class crc,
	                inclusion inc
	          where spot.campaign_no = @campaign_no and
	                spot.tran_id = @tran_id and
	                spot.op_billing_date = fsd.screening_date and
	                spot.outpost_venue_id = cplx.outpost_venue_id and
	                spot.inclusion_id = inc.inclusion_id and
	                cplx.state_code = st.state_code and
	                cplx.rent_group_no = crg.rent_group_no and
	                cplx.region_class = crc.region_class and
					inc.inclusion_type = 18 --retail wall
	       order by st.country_code,
	                spot.inclusion_id,
	                spot.spot_id
	end
	else if @media_product_mode = 14 --FANDOM
	begin
	    insert into work_spot_list
	         select @session,
	                spot.campaign_no,
	                @tran_id,
	                spot.spot_id,
	                null,
	                spot.spot_status,
	                spot.charge_rate,
	                1,
	                null,
	                spot.inclusion_id,
	                fsd.screening_date,
	                br.country_code,
	                'M',
	                1,
	                spot.charge_rate,
	                null,
	                null,
	                6
	           from inclusion_spot spot,
	                film_screening_dates fsd,
	                inclusion inc,
					film_campaign fc,
					branch br
	          where spot.campaign_no = @campaign_no and
	                spot.tran_id = @tran_id and
	                spot.billing_date = fsd.screening_date and
	                spot.inclusion_id = inc.inclusion_id and
					inc.campaign_no = fc.campaign_no and 
					fc.branch_code = br.branch_code and
					inc.inclusion_type between 34 and 65
	       order by br.country_code,
	                spot.inclusion_id,
	                spot.spot_id
	end

end                
else if @mode = 5 -- Delete and Charge Confirm

    insert into work_spot_list
	select 		@session,
				spot.campaign_no,
				dc.source_campaign,
				spot.spot_id,
				spot.spot_redirect,
				spot.spot_status,
				spot.makegood_rate,
				crg.weighting,
				cplx.complex_id,
				spot.package_id,
				fsd.screening_date,
				st.country_code,
				cplx.complex_region_class,
				crc.rent_distribution_weighting,
				null,
				null,
				null,
				pack.media_product_id
	from 		campaign_spot spot,
				complex cplx,
				state st,
				complex_rent_groups crg,
				film_screening_dates fsd,
				complex_region_class crc,
				delete_charge dc,
				delete_charge_spots dcs,
				campaign_package pack
	where 		spot.campaign_no = @campaign_no and
				spot.campaign_no = dcs.campaign_no and 
				dcs.source_dest = 'D' and
				dcs.delete_charge_id = dc.delete_charge_id and 
				dcs.spot_id = spot.spot_id and
				spot.billing_date = fsd.screening_date and
				spot.complex_id = cplx.complex_id and
				spot.package_id = pack.package_id and
				cplx.state_code = st.state_code and
				cplx.complex_rent_group = crg.rent_group_no and
				cplx.complex_region_class = crc.complex_region_class
	union
	select 		@session,
				spot.campaign_no,
				dc.source_campaign,
				spot.spot_id,
				null,
				spot.spot_status,
				spot.makegood_rate,
				crg.weighting,
				cplx.complex_id,
				spot.package_id,
				fsd.screening_date,
				st.country_code,
				cplx.complex_region_class,
				crc.cinelight_distribution_weighting,
				spot.charge_rate,
				null,
				null,
				pack.media_product_id
	from 		cinelight_spot spot,
				complex cplx,
				state st,
				cinelight cl,
				complex_rent_groups crg,
				film_screening_dates fsd,
				complex_region_class crc,
				delete_charge dc,
				delete_charge_cinelight_spots dcs,
				cinelight_package pack
	where 		spot.campaign_no = @campaign_no and
				spot.campaign_no = dcs.campaign_no and 
				dcs.source_dest = 'D' and
				dcs.delete_charge_id = dc.delete_charge_id and 
				dcs.spot_id = spot.spot_id and
				spot.billing_date = fsd.screening_date and
				spot.cinelight_id = cl.cinelight_id and
				cl.complex_id = cplx.complex_id and
				spot.package_id = pack.package_id and
				cplx.state_code = st.state_code and
				cplx.cinelight_rent_group = crg.rent_group_no and
				cplx.complex_region_class = crc.complex_region_class
	union
	select 		@session,
				spot.campaign_no,
				dc.source_campaign,
				spot.spot_id,
				spot.spot_redirect,
				spot.spot_status,
				spot.makegood_rate,
				crg.weighting,
				cplx.complex_id,
				spot.inclusion_id,
				fsd.screening_date,
				st.country_code,
				cplx.complex_region_class,
				crc.rent_distribution_weighting,
				null,
				null,
				null,
				6
	from 		inclusion_spot spot,
				complex cplx,
				state st,
				complex_rent_groups crg,
				film_screening_dates fsd,
				complex_region_class crc,
				delete_charge dc,
				delete_charge_inclusion_spots dcs,
				inclusion pack
	where 		spot.campaign_no = @campaign_no and
				spot.campaign_no = dcs.campaign_no and 
				dcs.source_dest = 'D' and
				dcs.delete_charge_id = dc.delete_charge_id and 
				dcs.spot_id = spot.spot_id and
				spot.billing_date = fsd.screening_date and
				spot.complex_id = cplx.complex_id and
				spot.inclusion_id = pack.inclusion_id and
				cplx.state_code = st.state_code and
				cplx.complex_rent_group = crg.rent_group_no and
				cplx.complex_region_class = crc.complex_region_class
	order by 	st.country_code,
				spot.package_id,
				spot.spot_id

if(@@error !=0)
	goto error

if(@mode = 99) -- Projected Billings
begin


    /*
     * Loop Media Product, Billing Combinations and 
     * Insert Records into Spot Work Table
     */

    select @tran_id = 0
    
	declare 	tran_csr cursor static for
	select 		distinct
				pack.media_product_id,
				spot.billing_period
	from 		campaign_spot spot,
				campaign_package pack
	where 		spot.campaign_no = @campaign_no and
				spot.package_id = pack.package_id and
				spot.tran_id is null and
				spot.charge_rate > 0 and
				spot.spot_type <> 'C'
	union
	select 		distinct
				pack.media_product_id,
				spot.billing_period
	from 		cinelight_spot spot,
				cinelight_package pack
	where 		spot.campaign_no = @campaign_no and
				spot.package_id = pack.package_id and
				spot.tran_id is null and
				spot.charge_rate > 0 and
				spot.spot_type <> 'C'
	union		
	select 		distinct
				pack.media_product_id,
				spot.billing_period
	from 		inclusion_spot spot,
				inclusion inc,
				inclusion_type pack
	where 		spot.campaign_no = @campaign_no and
				spot.inclusion_id = inc.inclusion_id and
				inc.inclusion_type = pack.inclusion_type and
				inc.inclusion_type = 5 and
				spot.tran_id is null and
				spot.charge_rate > 0 and
				spot.spot_type <> 'C'
	order by 	pack.media_product_id,
				spot.billing_period
	
	for read only

	open tran_csr
	fetch tran_csr into @media_product_id, @billing_period
	while(@@fetch_status = 0)
	begin

        /*
         * Increment Tran Counter
         */

        select @tran_id = @tran_id + 1
                 
        /*
         * Insert Spots
         */
         
		insert into work_spot_list
		select 		@session,
					spot.campaign_no,
					@tran_id,
					spot.spot_id,
					spot.spot_redirect,
					spot.spot_status,
					spot.charge_rate,
					crg.weighting,
					cplx.complex_id,
					spot.package_id,
					fsd.screening_date,
					st.country_code,
					cplx.complex_region_class,
					crc.rent_distribution_weighting,
					null,
					null,
					null,
					pack.media_product_id
		from 		campaign_spot spot,
					campaign_package pack,
					complex cplx,
					state st,
					complex_rent_groups crg,
					film_screening_dates fsd,
					complex_region_class crc
		where 		spot.campaign_no = @campaign_no and
					spot.package_id = pack.package_id and
					pack.media_product_id = @media_product_id and
					spot.tran_id is null and
					spot.charge_rate > 0 and
					spot.billing_date = fsd.screening_date and
					spot.complex_id = cplx.complex_id and
					cplx.state_code = st.state_code and
					cplx.complex_rent_group = crg.rent_group_no and
					cplx.complex_region_class = crc.complex_region_class and
					spot.billing_period = @billing_period
		union
		select 		@session,
					spot.campaign_no,
					@tran_id,
					spot.spot_id,
					null,
					spot.spot_status,
					spot.charge_rate,
					crg.weighting,
					cplx.complex_id,
					spot.package_id,
					fsd.screening_date,
					st.country_code,
					cplx.complex_region_class,
					crc.cinelight_distribution_weighting,
					spot.charge_rate,
					null,
					null,
					pack.media_product_id
		from 		cinelight_spot spot,
					cinelight_package pack,
					complex cplx,
					cinelight cl,
					state st,
					complex_rent_groups crg,
					film_screening_dates fsd,
					complex_region_class crc
		where 		spot.campaign_no = @campaign_no and
					spot.package_id = pack.package_id and
					pack.media_product_id = @media_product_id and
					spot.tran_id is null and
					spot.charge_rate > 0 and
					spot.billing_date = fsd.screening_date and
					spot.cinelight_id = cl.cinelight_id and
					cl.complex_id = cplx.complex_id and
					cplx.state_code = st.state_code and
					cplx.cinelight_rent_group = crg.rent_group_no and
					cplx.complex_region_class = crc.complex_region_class and
					spot.billing_period = @billing_period
		union
		select 		@session,
					spot.campaign_no,
					@tran_id,
					spot.spot_id,
					null,
					spot.spot_status,
					spot.charge_rate,
					crg.weighting,
					cplx.complex_id,
					spot.inclusion_id,
					fsd.screening_date,
					st.country_code,
					cplx.complex_region_class,
					crc.cinelight_distribution_weighting,
					spot.charge_rate,
					null,
					null,
					pack.media_product_id
		from 		inclusion_spot spot,
					inclusion_type pack,
					complex cplx,
					inclusion inc,
					state st,
					complex_rent_groups crg,
					film_screening_dates fsd,
					complex_region_class crc
		where 		spot.campaign_no = @campaign_no and
					spot.inclusion_id = inc.inclusion_id and
					inc.inclusion_type = pack.inclusion_type and
					pack.media_product_id = @media_product_id and
					spot.tran_id is null and
					spot.charge_rate > 0 and
					spot.billing_date = fsd.screening_date and
					spot.complex_id = cplx.complex_id and
					cplx.state_code = st.state_code and
					cplx.complex_rent_group = crg.rent_group_no and
					cplx.complex_region_class = crc.complex_region_class and
					spot.billing_period = @billing_period
		order by 	st.country_code,
					spot.package_id,
					spot.spot_id

        if(@@error !=0)
	        goto error

        /*
         * Fetch Next
         */
         
        fetch tran_csr into @media_product_id, @billing_period

    end
    close tran_csr
    deallocate tran_csr
                 
end
    
/*
 * Initialise Spot Cursor Open Indicator
 */
 
select @spot_csr_open = 0

/*
 * Begin Transaction
 */

begin transaction

/*
 * Generate Spot Weighted Values
 */

if @media_product_mode < 6 or @media_product_mode = 10 or @media_product_mode = 14
begin
	execute @errorode = p_spot_weight_generation @session, @bill_total OUTPUT
		
	if(@errorode !=0)
	begin
		rollback transaction
		goto error
	end
end

/*******************************************************
 * Create Liability Records and Update Spot Weightings *
 *******************************************************/

if(@mode = 99)
begin

    /*
     * Update Campaign Spots
     */

    update campaign_spot
       set cinema_rate = 0
     where campaign_no = @campaign_no and
           cinema_rate <> 0 and
           tran_id is null and
           charge_rate = 0

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end	

    /*
     * Update Cinelight Spots
     */

    update cinelight_spot
       set cinema_rate = 0
     where campaign_no = @campaign_no and
           cinema_rate <> 0 and
           tran_id is null and
           charge_rate = 0

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end	
    
	/*
     * Update Inclusion Spots
     */

    update inclusion_spot
       set cinema_rate = 0
	  from inclusion
     where inclusion_spot.campaign_no = @campaign_no and
           cinema_rate <> 0 and
           inclusion_spot.tran_id is null and
           charge_rate = 0 and
		   inclusion.inclusion_id = inclusion_spot.inclusion_id and
		   inclusion.inclusion_type = 5

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end

    /*
     * Update Campaign Spots
     */

	update 	campaign_spot
	set 	cinema_rate = wsl.liability_amount
	from 	work_spot_list wsl,
			campaign_package cp
	where 	wsl.spot_id = campaign_spot.spot_id
	and		campaign_spot.package_id = cp.package_id
	and		cp.media_product_id = wsl.media_product_id

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end	

    /*
     * Update Cinelight Spots
     */

	update 	cinelight_spot
	set 	cinema_rate = wsl.liability_amount
	from 	work_spot_list wsl,
			cinelight_package cp
	where 	wsl.spot_id = cinelight_spot.spot_id
	and		cinelight_spot.package_id = cp.package_id
	and		cp.media_product_id = wsl.media_product_id

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end	

    /*
     * Update Inclusion Spots
     */

	update 	inclusion_spot
	set 	cinema_rate = wsl.liability_amount
	from 	work_spot_list wsl,
			inclusion inc,
			inclusion_type inc_typ
	where 	wsl.spot_id = inclusion_spot.spot_id
	and		inclusion_spot.inclusion_id = inc.inclusion_id
	and		inc_typ.inclusion_type = inc.inclusion_type
	and		inc_typ.media_product_id = wsl.media_product_id

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end	
end

if(@mode <> 99 and @bill_total > 0)
begin


    declare spot_list_csr cursor static for
     select sl.spot_id,
            sl.spot_redirect,
            sl.charge_rate,
            sl.country_code,
            sl.complex_id,
            sl.liability_amount,        
            sl.spot_weighting,
            sl.cinema_weighting,
            sl.media_product_id
       from work_spot_list sl
      where session_id = @session
   order by sl.tran_id,
            sl.country_code,
            sl.spot_id
        for read only

	/*
	 * Update all Spots
	 */

	open spot_list_csr
    select @spot_csr_open = 1
	fetch spot_list_csr into @spot_id, @spot_redirect, @rate, @country_code, @complex_id,  @liability_amount, @spot_weighting, @cinema_weighting, @media_product_id
	while(@@fetch_status = 0)
	begin
    
        /*
         * Calculate Spot Re-Direct
         */

        select @sr_spot_id = @spot_id,
               @sr_complex_id = @complex_id

       	while(isnull(@spot_redirect, 0) != 0)
    	begin

            select @sr_spot_id = spot_id,
                   @sr_complex_id = complex_id,
                   @spot_redirect = spot_redirect 
              from campaign_spot
             where spot_id = @spot_redirect

            select @error = @@error,
                   @rowcount = @@rowcount
            
            if(@error !=0 or @rowcount=0)
            begin
                raiserror ('Error Loading Spot Redirect Info for Spot Id: %1!', 11, 1, @spot_redirect)
            	rollback transaction
            	goto error
            end	

        end

        /*
         * Determine Liability Type
         */

        if @media_product_id = 1
            select @ltype = 1 --FILM
        else if @media_product_id = 2
            select @ltype = 5 --DMG
        else if @media_product_id = 3
            select @ltype = 11 --CINELIGHTS
        else if @media_product_id = 6
            select @ltype = 14 --CINEMARKETING
        else if @media_product_id = 9
            select @ltype = 150 --RETAIL PANEL
        else if @media_product_id = 10
            select @ltype = 154 --RETAIL WALL
        else if @media_product_id between 22 and 28 or @media_product_id = 50
		    select @ltype = 170 --FANDOM
        else if @media_product_id between 29 and 35 or @media_product_id = 51
		    select @ltype = 175 --The Latch
        else if @media_product_id between 36 and 42 or @media_product_id = 52
		    select @ltype = 180 --Thrillist
        else if @media_product_id between 43 and 49 or @media_product_id = 53
		    select @ltype = 185 --Popsugar

        /*
		 * Get Liability Id
		 */
	
		if @media_product_id = 1 or @media_product_id = 2
		begin
			execute @errorode = p_get_sequence_number 'spot_liability', 5, @liability_id OUTPUT
			if(@errorode !=0)
			begin
				rollback transaction
				goto error
			end
                
			/*
			 * Insert Liability Record
			 */
		
			insert into spot_liability (
					 spot_liability_id,
					 spot_id,
					 complex_id,
					 liability_type,
					 spot_amount,
					 cinema_amount,
	                 cinema_rent,
	                 cancelled,
	                 original_liability ) values (
					 @liability_id,
					 @sr_spot_id,
					 @sr_complex_id,
					 @ltype,
					 @rate,
					 @liability_amount,
	                 0,
	                 0,
	                 @original_liability )
	
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	
	        
	        /*
	         * Update the Campaign Spot
	         */
	                 
	        update campaign_spot 
	           set cinema_rate = @liability_amount,
	               spot_weighting = @spot_weighting,
	               cinema_weighting = @cinema_weighting
	         where spot_id = @spot_id
		
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	

		end
		else if @media_product_id = 3
		begin
			execute @errorode = p_get_sequence_number 'cinelight_spot_liability', 5, @liability_id OUTPUT
			if(@errorode !=0)
			begin
				rollback transaction
				goto error
			end
			/*
			 * Insert Liability Record
			 */
		
			insert into cinelight_spot_liability (
					 spot_liability_id,
					 spot_id,
					 complex_id,
					 liability_type,
					 spot_amount,
					 cinema_amount,
	                 cinema_rent,
	                 cancelled,
	                 original_liability ) values (
					 @liability_id,
					 @sr_spot_id,
					 @sr_complex_id,
					 @ltype,
					 @rate,
					 @liability_amount,
	                 0,
	                 0,
	                 @original_liability )
	
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	
	        
	        /*
	         * Update the Campaign Spot
	         */
	                 
	        update cinelight_spot 
	           set cinema_rate = @liability_amount,
	               spot_weighting = @spot_weighting,
	               cinema_weighting = @cinema_weighting
	         where spot_id = @spot_id
		
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	
		end	
		else if @media_product_id = 6 or @media_product_id = 22 or @media_product_id >= 34
		begin
			execute @errorode = p_get_sequence_number 'inclusion_spot_liability', 5, @liability_id OUTPUT
			if(@errorode !=0)
			begin
				rollback transaction
				goto error
			end
			/*
			 * Insert Liability Record
			 */
		
			insert into inclusion_spot_liability (
					 spot_liability_id,
					 spot_id,
					 complex_id,
					 liability_type,
					 spot_amount,
					 cinema_amount,
	                 cinema_rent,
	                 cancelled,
	                 original_liability ) values (
					 @liability_id,
					 @sr_spot_id,
					 @sr_complex_id,
					 @ltype,
					 @rate,
					 @liability_amount,
					 0,
	                 0,
	                 @original_liability )
	
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	
	        
	        /*
	         * Update the Campaign Spot
	         */
	                 
	        update inclusion_spot 
	           set cinema_rate = @liability_amount,
	               spot_weighting = @spot_weighting,
	               cinema_weighting = @cinema_weighting
	         where spot_id = @spot_id
		
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	
	
		end
		else if @media_product_id = 9 --Retail Panel
		begin
			execute @errorode = p_get_sequence_number 'outpost_spot_liability', 5, @liability_id OUTPUT
			if(@errorode !=0)
			begin
				rollback transaction
				goto error
			end
			/*
			 * Insert Liability Record
			 */
		
			insert into outpost_spot_liability (
					 spot_liability_id,
					 spot_id,
					 outpost_venue_id,
					 liability_type,
					 spot_amount,
					 cinema_amount,
	                 cinema_rent,
	                 cancelled,
	                 original_liability ) values (
					 @liability_id,
					 @sr_spot_id,
					 @sr_complex_id,
					 @ltype,
					 @rate,
					 @liability_amount,
	                 0,
	                 0,
	                 @original_liability )
	
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	
	        
	        /*
	         * Update the Campaign Spot
	         */
	                 
	        update outpost_spot 
	           set cinema_rate = @liability_amount,
	               spot_weighting = @spot_weighting,
	               cinema_weighting = @cinema_weighting
	         where spot_id = @spot_id
		
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	
		end	
		else if @media_product_id = 10 --Retail Wall
		begin
			execute @errorode = p_get_sequence_number 'inclusion_spot_liability', 5, @liability_id OUTPUT
			if(@errorode !=0)
			begin
				rollback transaction
				goto error
			end
			/*
			 * Insert Liability Record
			 */
		
			insert into outpost_inclusion_spot_liability (
					 spot_liability_id,
					 spot_id,
					 outpost_venue_id,
					 liability_type,
					 spot_amount,
					 cinema_amount,
	                 cinema_rent,
	                 cancelled,
	                 original_liability ) values (
					 @liability_id,
					 @sr_spot_id,
					 @sr_complex_id,
					 @ltype,
					 @rate,
					 @liability_amount,
	              	 0,
	                 0,
	                 @original_liability )
	
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	
	        
	        /*
	         * Update the Campaign Spot
	         */
	                 
	        update inclusion_spot 
	           set cinema_rate = @liability_amount,
	               spot_weighting = @spot_weighting,
	               cinema_weighting = @cinema_weighting
	         where spot_id = @spot_id
		
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	
	
		end
	
		/*
		 * Fetch Next Spot
		 */

    	fetch spot_list_csr into @spot_id, @spot_redirect, @rate, @country_code, @complex_id,  @liability_amount, @spot_weighting, @cinema_weighting, @media_product_id

	end
	close spot_list_csr
	deallocate spot_list_csr
    select @spot_csr_open = 0

end

if(@mode = 5) -- Delete & Charge Confirmation
begin

    execute @errorode = p_spot_liability_gen_dandc @session, @campaign_no
    if(@errorode !=0)
    begin
        raiserror ('Error: Failed to Generate D&C Liability for Campaign %1!', 11, 1, @campaign_no)
	    rollback transaction
	    goto error
    end

end

/*
 * Remove Rows from Work Table
 */

delete work_spot_list
where session_id = @session

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

    if (@spot_csr_open = 1)
    begin
        close spot_list_csr
        deallocate spot_list_csr
    end
    raiserror ( 'Error: Failed to Generate Liability for Campaign %1!', 11, 1, @campaign_no)
    return -100
GO
