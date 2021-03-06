/****** Object:  StoredProcedure [dbo].[p_campaign_liability_gen_hoyts]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_liability_gen_hoyts]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_liability_gen_hoyts]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_campaign_liability_gen_hoyts] @mode                  int,
                                     @accounting_period	    datetime,
                                     @cut_off				datetime,
                                     @country_code			char(1)
as

set nocount on
/*
 * Declare Variables
 */

declare @error                  	int,
        @tran_id                    int,
        @sum_uwl					money,
        @spot_id                    int,
        @cinema_weighting		    float,
        @wl							money,
        @alloc_wl					money,
        @counter					int,
        @count						int,
        @errorode						int,
        @advance_ratio			    float,
        @csr_open				    tinyint,
        @bill_total				    money,
        @canc_bill_total			money,
        @bill_curr				    money,
        @acomm_total			    money,
        @canc_acomm_total			money,
        @acomm_curr				    money,
        @bill_adv				    money,
        @acomm_adv				    money,
        @deductions				    money,
        @canc_deductions			money,
        @w_bill_total				money,
        @w_bill_curr				money,
        @w_acomm_total			    money,
        @w_acomm_curr				money,
        @w_bill_adv				    money,
        @w_acomm_adv				money,
        @w_deductions				money,
        @rent_held				    money,
        @uwl					    money,
        @billing_start			    datetime,
        @billing_end			    datetime,
        @diff					    int,
        @no_liability			    char(1),
        @atb_flag				    tinyint,
        @atb_alloc				    money,
        @spot_status			    char(1),
        @complex_id                 int,
        @liability_amount           money,
        @liability_type             char(1),
        @business_unit_id           int,
        @media_product_id           int,
        @revenue_source             char(1),
        @dandc                      char(1),
        @cancelled                  money,
        @cancelled_held             money,
        @spot_redirect              int,
		@origin_period				datetime
        

/* 
 * Create Temporary Table
 */

create table #liability_gen
(
	campaign_no             int             null,
    product_desc            varchar(100)    null,
    country_code            char(1)         null,
    country_name            varchar(50)     null,
    branch_code             char(2)         null,
    branch_name             varchar(50)     null,
    media_product_id        int             null,
    media_product_desc      varchar(50)     null,
    business_unit_id        int             null,
    business_unit_desc      varchar(30)     null,
    revenue_source          char(1)         null,
    revenue_source_desc     varchar(255)    null,
    spot_id					int             null,
    spot_status				char(1)         null,
    dandc                   char(1)         null,
	tran_id					int             null,
	billing_date			datetime        null,
	origin_period			datetime		null,
	complex_id				int             null,
    complex_name            varchar(100)    null,
	cinema_weighting		float           null,
	adv_ratio				float           null,
	bill_curr				money           null,
	bill_adv				money           null,
	acomm_curr				money           null,
	acomm_adv				money           null,
	uwl						money           null,
	wl						money           null,
	cl						money           null,
    cl_held                 money           null,
	held_rent				money           null,
	atb_gross				money           null,
	atb_nett				money           null,
  	atb_inc 				money           null,
	no_liability			char(1)         null
)

/*
 * Insert Spots into Temp Table
 */

insert into #liability_gen (
        campaign_no,
        product_desc,
        country_code,
        country_name,
        branch_code,
        branch_name,
        media_product_id,
        media_product_desc,
        business_unit_id,
        business_unit_desc,
        spot_id,
        spot_status,
        dandc,
	    tran_id,
	    billing_date,
		origin_period,
	    complex_id,
        complex_name,
	    cinema_weighting,
	    adv_ratio,
	    bill_curr,
	    bill_adv,
	    acomm_curr,
	    acomm_adv,
	    uwl,
	    wl,
	    cl,
        cl_held,
	    held_rent,
	    atb_gross,
	    atb_nett,
        atb_inc,
	    no_liability,
        revenue_source,
        revenue_source_desc )
select  fc.campaign_no,
        fc.product_desc,
        c.country_code,
        c.country_name,
        b.branch_code,
        b.branch_name,
        mp.media_product_id,
        mp.media_product_desc,
        bu.business_unit_id,
        bu.business_unit_desc,
        spot.spot_id,
        spot.spot_status,
        spot.dandc,
        spot.tran_id,   
        spot.billing_date,
		(select min(origin_period) from spot_liability where spot_id = spot.spot_id),
        spot.complex_id, 
        cplx.complex_name,  
        spot.cinema_weighting,   
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        ((select isnull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where  ct.campaign_no = fc.campaign_no and ct.tran_id = ca.to_tran_id) - (select IsNull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.campaign_no = fc.campaign_no and ct.gross_amount < 0 and ct.tran_id = ca.from_tran_id)),
        ((select isnull(sum(ca.nett_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category <> 'M' and ct.campaign_no = fc.campaign_no and ct.tran_id = ca.to_tran_id) - (select IsNull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category <> 'M' and ct.campaign_no = fc.campaign_no and ct.gross_amount < 0 and ct.tran_id = ca.from_tran_id)),
        ((select isnull(sum(ca.nett_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category = 'M' and ct.campaign_no = fc.campaign_no and ct.tran_id = ca.to_tran_id) - (select IsNull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category = 'M' and ct.campaign_no = fc.campaign_no and ct.gross_amount < 0 and ct.tran_id = ca.from_tran_id)),
        'N',
        cp.revenue_source,
        crs.revenue_desc
   from campaign_spot spot,
        media_product mp,
        business_unit bu,
        campaign_package cp,
        branch b,
        country c,
        film_campaign fc,
        complex cplx,
        cinema_revenue_source crs
  where fc.campaign_no = spot.campaign_no
    and (fc.campaign_status = 'L'
     or fc.campaign_status = 'F')
    and fc.branch_code = b.branch_code
    and b.country_code = c.country_code
    and c.country_code = @country_code
    and cplx.complex_id = spot.complex_id
    and cplx.complex_id in (select complex_id from complex where exhibitor_id = 205 )
    and cp.package_id = spot.package_id 
    and cp.campaign_no = spot.campaign_no
    and cp.campaign_no = fc.campaign_no
    and cp.media_product_id = mp.media_product_id
    and fc.business_unit_id = bu.business_unit_id
    and cp.revenue_source = crs.revenue_source
    
select @error = @@error
if (@error != 0)
begin
	return -1
end

insert into #liability_gen (
        campaign_no,
        product_desc,
        country_code,
        country_name,
        branch_code,
        branch_name,
        media_product_id,
        media_product_desc,
        business_unit_id,
        business_unit_desc,
        spot_id,
        spot_status,
        dandc,
	    tran_id,
	    billing_date,
		origin_period,
	    complex_id,
        complex_name,
	    cinema_weighting,
	    adv_ratio,
	    bill_curr,
	    bill_adv,
	    acomm_curr,
	    acomm_adv,
	    uwl,
	    wl,
	    cl,
        cl_held,
	    held_rent,
	    atb_gross,
	    atb_nett,
        atb_inc,
	    no_liability,
        revenue_source,
        revenue_source_desc )
select  fc.campaign_no,
        fc.product_desc,
        c.country_code,
        c.country_name,
        b.branch_code,
        b.branch_name,
        mp.media_product_id,
        mp.media_product_desc,
        bu.business_unit_id,
        bu.business_unit_desc,
        spot.spot_id,
        spot.spot_status,
        spot.dandc,
        spot.tran_id,   
        spot.billing_date, 
		(select min(origin_period) from cinelight_spot_liability where spot_id = spot.spot_id),
        cl.complex_id, 
        cplx.complex_name,  
        spot.cinema_weighting,   
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        ((select isnull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where  ct.campaign_no = fc.campaign_no and ct.tran_id = ca.to_tran_id) - (select IsNull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.campaign_no = fc.campaign_no and ct.gross_amount < 0 and ct.tran_id = ca.from_tran_id)),
        ((select isnull(sum(ca.nett_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category <> 'M' and ct.campaign_no = fc.campaign_no and ct.tran_id = ca.to_tran_id) - (select IsNull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category <> 'M' and ct.campaign_no = fc.campaign_no and ct.gross_amount < 0 and ct.tran_id = ca.from_tran_id)),
        ((select isnull(sum(ca.nett_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category = 'M' and ct.campaign_no = fc.campaign_no and ct.tran_id = ca.to_tran_id) - (select IsNull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category = 'M' and ct.campaign_no = fc.campaign_no and ct.gross_amount < 0 and ct.tran_id = ca.from_tran_id)),
        'N',
        cp.revenue_source,
        crs.revenue_desc
   from cinelight_spot spot,
        media_product mp,
        business_unit bu,
        cinelight_package cp,
        branch b,
        country c,
        film_campaign fc,
		cinelight cl,
        complex cplx,
        cinema_revenue_source crs
  where fc.campaign_no = spot.campaign_no
    and (fc.campaign_status = 'L'
     or fc.campaign_status = 'F')
    and fc.branch_code = b.branch_code
    and b.country_code = c.country_code
    and c.country_code = @country_code
    and cplx.complex_id = cl.complex_id
    and cplx.complex_id in (select complex_id from complex where exhibitor_id = 205 )
	and cl.cinelight_id = spot.cinelight_id
    and cp.package_id = spot.package_id 
    and cp.campaign_no = spot.campaign_no
    and cp.campaign_no = fc.campaign_no
    and cp.media_product_id = mp.media_product_id
    and fc.business_unit_id = bu.business_unit_id
    and cp.revenue_source = crs.revenue_source
    
select @error = @@error
if (@error != 0)
begin
	return -1
end

insert into #liability_gen (
        campaign_no,
        product_desc,
        country_code,
        country_name,
        branch_code,
        branch_name,
        media_product_id,
        media_product_desc,
        business_unit_id,
        business_unit_desc,
        spot_id,
        spot_status,
        dandc,
	    tran_id,
	    billing_date,
		origin_period,
	    complex_id,
        complex_name,
	    cinema_weighting,
	    adv_ratio,
	    bill_curr,
	    bill_adv,
	    acomm_curr,
	    acomm_adv,
	    uwl,
	    wl,
	    cl,
        cl_held,
	    held_rent,
	    atb_gross,
	    atb_nett,
        atb_inc,
	    no_liability,
        revenue_source,
        revenue_source_desc )
select  fc.campaign_no,
        fc.product_desc,
        c.country_code,
        c.country_name,
        b.branch_code,
        b.branch_name,
        mp.media_product_id,
        mp.media_product_desc,
        bu.business_unit_id,
        bu.business_unit_desc,
        spot.spot_id,
        spot.spot_status,
        spot.dandc,
        spot.tran_id,   
        spot.billing_date,   
		(select min(origin_period) from inclusion_spot_liability where spot_id = spot.spot_id),
        spot.complex_id, 
        cplx.complex_name,  
        spot.cinema_weighting,   
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        ((select isnull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where  ct.campaign_no = fc.campaign_no and ct.tran_id = ca.to_tran_id) - (select IsNull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.campaign_no = fc.campaign_no and ct.gross_amount < 0 and ct.tran_id = ca.from_tran_id)),
        ((select isnull(sum(ca.nett_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category <> 'M' and ct.campaign_no = fc.campaign_no and ct.tran_id = ca.to_tran_id) - (select IsNull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category <> 'M' and ct.campaign_no = fc.campaign_no and ct.gross_amount < 0 and ct.tran_id = ca.from_tran_id)),
        ((select isnull(sum(ca.nett_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category = 'M' and ct.campaign_no = fc.campaign_no and ct.tran_id = ca.to_tran_id) - (select IsNull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category = 'M' and ct.campaign_no = fc.campaign_no and ct.gross_amount < 0 and ct.tran_id = ca.from_tran_id)),
        'N',
        crs.revenue_source,
        crs.revenue_desc
   from inclusion_spot spot,
        media_product mp,
        business_unit bu,
        inclusion inc,
        branch b,
        country c,
        film_campaign fc,
        complex cplx,
        cinema_revenue_source crs
  where fc.campaign_no = spot.campaign_no
    and (fc.campaign_status = 'L'
     or fc.campaign_status = 'F')
    and fc.branch_code = b.branch_code
    and b.country_code = c.country_code
    and c.country_code = @country_code
    and cplx.complex_id = spot.complex_id
    and cplx.complex_id in (select complex_id from complex where exhibitor_id = 205 )
	and inc.inclusion_id = spot.inclusion_id 
    and inc.campaign_no = spot.campaign_no
    and inc.campaign_no = fc.campaign_no
    and 6 = mp.media_product_id
    and fc.business_unit_id = bu.business_unit_id
    and 'I' = crs.revenue_source
	and inc.inclusion_type = 5
    
select @error = @@error
if (@error != 0)
begin
	return -1
end

insert into #liability_gen (
        campaign_no,
        product_desc,
        country_code,
        country_name,
        branch_code,
        branch_name,
        media_product_id,
        media_product_desc,
        business_unit_id,
        business_unit_desc,
        spot_id,
        spot_status,
        dandc,
	    tran_id,
	    billing_date,
		origin_period,
	    complex_id,
        complex_name,
	    cinema_weighting,
	    adv_ratio,
	    bill_curr,
	    bill_adv,
	    acomm_curr,
	    acomm_adv,
	    uwl,
	    wl,
	    cl,
        cl_held,
	    held_rent,
	    atb_gross,
	    atb_nett,
        atb_inc,
	    no_liability,
        revenue_source,
        revenue_source_desc )
select  fc.campaign_no,
        fc.product_desc,
        c.country_code,
        c.country_name,
        b.branch_code,
        b.branch_name,
        mp.media_product_id,
        mp.media_product_desc,
        bu.business_unit_id,
        bu.business_unit_desc,
        spot.spot_id,
        spot.spot_status,
        spot.dandc,
        spot.tran_id,   
        spot.billing_date,   
		(select min(origin_period) from inclusion_spot_liability where spot_id = spot.spot_id),
        spot.complex_id, 
        cplx.complex_name,  
        spot.cinema_weighting,   
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        ((select isnull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where  ct.campaign_no = fc.campaign_no and ct.tran_id = ca.to_tran_id) - (select IsNull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.campaign_no = fc.campaign_no and ct.gross_amount < 0 and ct.tran_id = ca.from_tran_id)),
        ((select isnull(sum(ca.nett_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category <> 'M' and ct.campaign_no = fc.campaign_no and ct.tran_id = ca.to_tran_id) - (select IsNull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category <> 'M' and ct.campaign_no = fc.campaign_no and ct.gross_amount < 0 and ct.tran_id = ca.from_tran_id)),
        ((select isnull(sum(ca.nett_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category = 'M' and ct.campaign_no = fc.campaign_no and ct.tran_id = ca.to_tran_id) - (select IsNull(sum(ca.gross_amount),0) from campaign_transaction ct, transaction_allocation ca where ct.tran_category = 'M' and ct.campaign_no = fc.campaign_no and ct.gross_amount < 0 and ct.tran_id = ca.from_tran_id)),
        'N',
        crs.revenue_source,
        crs.revenue_desc
   from inclusion_spot spot,
        media_product mp,
        business_unit bu,
        inclusion inc,
        branch b,
        country c,
        film_campaign fc,
        complex cplx,
        cinema_revenue_source crs
  where fc.campaign_no = spot.campaign_no
    and (fc.campaign_status = 'L'
     or fc.campaign_status = 'F')
    and fc.branch_code = b.branch_code
    and b.country_code = c.country_code
    and c.country_code = @country_code
    and cplx.complex_id = spot.complex_id
    and cplx.complex_id in (select complex_id from complex where exhibitor_id = 205 )
	and inc.inclusion_id = spot.inclusion_id 
    and inc.campaign_no = spot.campaign_no
    and inc.campaign_no = fc.campaign_no
    and 7 = mp.media_product_id
    and fc.business_unit_id = bu.business_unit_id
    and 'I' = crs.revenue_source
	and inc.inclusion_type in (select inclusion_type from inclusion_type where inclusion_type_group = 'M')

select @error = @@error
if (@error != 0)
begin
	return -1
end

create index tti_spot_idx on #liability_gen (spot_id)


select @atb_flag = 0

/*
 * Declare Cursors, can only be created after index otherwise MS SQL gives an error ...?
 */ 

    
 declare spot_csr cursor static for
  select spot_id,
         billing_date,
         spot_status,
         dandc,
		 media_product_id,
		 origin_period
    from #liability_gen
order by spot_id
     for read only
     
/*
 * Loop Through Spots for the Campaign
 */

open spot_csr
select @csr_open = 1
fetch spot_csr into @spot_id, @billing_start, @spot_status, @dandc, @media_product_id, @origin_period
while(@@fetch_status = 0)
begin

	/*
    * Calculate In Advance Ratio (Assumes 7 Days)
    */

	select @billing_end = dateadd(day,6,@billing_start)
	select @diff = datediff(day, @cut_off, @billing_end)

	if(@diff < 0)
 		select @advance_ratio = 0
	else
	begin
		if(@diff >= 7)
			select @advance_ratio = 1
		else
			select @advance_ratio = convert(float,@diff) / 7
	end

	if @media_product_id = 1 or @media_product_id = 2 
	begin
		/*
		 * Select Total Billings
		 */
		
		select @bill_total = IsNull(sum(spot_amount),0)
		  from spot_liability,
	           liability_type
		 where spot_id = @spot_id
	       and liability_category_id = 1
	       and original_liability = 0
	       and cancelled = 0
	       and spot_liability.liability_type = liability_type.liability_type_id
		
		/*
		 * Select Total Agency Comm
		 */
		
		select @acomm_total = IsNull(sum(spot_amount),0)
		  from spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id = 3
	     and original_liability = 0
	       and cancelled = 0
	       and spot_liability.liability_type = liability_type.liability_type_id
	
		/*
		 * Calculate Deductions
		 */
		
		select @deductions = IsNull(sum(spot_amount),0)
		  from spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id not in (1,3)
	       and original_liability = 0
	       and cancelled = 0
	       and spot_liability.liability_type = liability_type.liability_type_id
		
		/*
		 * Select Total Billings
		 */
		
		select @w_bill_total = IsNull(sum(cinema_amount),0)
		  from spot_liability,
	           liability_type
		 where spot_id = @spot_id
	       and liability_category_id = 1
	       and original_liability = 0
	       and cancelled = 0
	       and spot_liability.liability_type = liability_type.liability_type_id
		
		/*
		 * Select Total Agency Comm
		 */
		
		select @w_acomm_total = IsNull(sum(cinema_amount),0)
		  from spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id = 3
	     and original_liability = 0
	       and cancelled = 0
	       and spot_liability.liability_type = liability_type.liability_type_id
	
		/*
		 * Calculate Deductions
		 */
		
		select @w_deductions = IsNull(sum(cinema_amount),0)
		  from spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id not in (1,3)
	       and original_liability = 0
	       and cancelled = 0
	       and spot_liability.liability_type = liability_type.liability_type_id
		
		/*
		 * Calculate Current and In Advance Components
		 */
		
		select @bill_adv = @advance_ratio * @bill_total
		select @acomm_adv = @advance_ratio * @acomm_total
		select @bill_curr = @bill_total - @bill_adv
		select @acomm_curr = @acomm_total - @acomm_adv
		select @w_bill_adv = @advance_ratio * @w_bill_total
		select @w_acomm_adv = @advance_ratio * @w_acomm_total
		select @w_bill_curr = @w_bill_total - @w_bill_adv
		select @w_acomm_curr = @w_acomm_total - @w_acomm_adv
		
		/*
		 * Calculate Cinema Rent Held
		 */
		
		select @rent_held = IsNull(sum(cinema_rent),0)
		  from spot_liability
		 where spot_id = @spot_id and
	           cinema_rent <> 0 and
			   release_period is null
	       and original_liability = 0
	       and cancelled = 0
	       
		select @canc_bill_total = IsNull(sum(spot_amount),0)
		  from spot_liability,
	           liability_type
		 where spot_id = @spot_id
	       and liability_category_id = 1
	       and original_liability = 0
	       and cancelled = 1
	       and spot_liability.liability_type = liability_type.liability_type_id
		
		/*
		 * Select Total Agency Comm
		 */
		
		select @canc_acomm_total = IsNull(sum(spot_amount),0)
		  from spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id = 3
	       and original_liability = 0
	       and cancelled = 1
	       and spot_liability.liability_type = liability_type.liability_type_id
	
		/*
		 * Calculate Deductions
		 */
		
		select @canc_deductions = IsNull(sum(spot_amount),0)
		  from spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id not in (1,3,2)
	       and original_liability = 0
	       and cancelled = 1
	       and spot_liability.liability_type = liability_type.liability_type_id
	
		/*
		 * Calculate Unweighted Liability
		 */
		
		select @uwl = round(@bill_curr + @acomm_curr + @deductions, 2)
	  	select @wl = round(@w_bill_curr + @w_acomm_curr + @w_deductions, 2)
	    select @cancelled = round(@canc_bill_total + @canc_acomm_total + @canc_deductions, 2)
	    select @cancelled_held = 0
	
	end 
	else if @media_product_id = 3
	begin
		/*
		 * Select Total Billings
		 */
		
		select @bill_total = IsNull(sum(spot_amount),0)
		  from cinelight_spot_liability,
	           liability_type
		 where spot_id = @spot_id
	       and liability_category_id = 1
	       and original_liability = 0
	       and cancelled = 0
	       and cinelight_spot_liability.liability_type = liability_type.liability_type_id
		
		/*
		 * Select Total Agency Comm
		 */
		
		select @acomm_total = IsNull(sum(spot_amount),0)
		  from cinelight_spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id = 3
	     and original_liability = 0
	       and cancelled = 0
	       and cinelight_spot_liability.liability_type = liability_type.liability_type_id
	
		/*
		 * Calculate Deductions
		 */
		
		select @deductions = IsNull(sum(spot_amount),0)
		  from cinelight_spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id not in (1,3)
	       and original_liability = 0
	       and cancelled = 0
	       and cinelight_spot_liability.liability_type = liability_type.liability_type_id
		
		/*
		 * Select Total Billings
		 */
		
		select @w_bill_total = IsNull(sum(cinema_amount),0)
		  from cinelight_spot_liability,
	           liability_type
		 where spot_id = @spot_id
	       and liability_category_id = 1
	       and original_liability = 0
	       and cancelled = 0
	       and cinelight_spot_liability.liability_type = liability_type.liability_type_id
		
		/*
		 * Select Total Agency Comm
		 */
		
		select @w_acomm_total = IsNull(sum(cinema_amount),0)
		  from cinelight_spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id = 3
	     and original_liability = 0
	       and cancelled = 0
	       and cinelight_spot_liability.liability_type = liability_type.liability_type_id
	
		/*
		 * Calculate Deductions
		 */
		
		select @w_deductions = IsNull(sum(cinema_amount),0)
		  from cinelight_spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id not in (1,3)
	       and original_liability = 0
	       and cancelled = 0
	       and cinelight_spot_liability.liability_type = liability_type.liability_type_id
		
		/*
		 * Calculate Current and In Advance Components
		 */
		
		select @bill_adv = @advance_ratio * @bill_total
		select @acomm_adv = @advance_ratio * @acomm_total
		select @bill_curr = @bill_total - @bill_adv
		select @acomm_curr = @acomm_total - @acomm_adv
		select @w_bill_adv = @advance_ratio * @w_bill_total
		select @w_acomm_adv = @advance_ratio * @w_acomm_total
		select @w_bill_curr = @w_bill_total - @w_bill_adv
		select @w_acomm_curr = @w_acomm_total - @w_acomm_adv
		
		/*
		 * Calculate Cinema Rent Held
		 */
		
		select @rent_held = IsNull(sum(cinema_rent),0)
		  from cinelight_spot_liability
		 where spot_id = @spot_id and
	           cinema_rent <> 0 and
			   release_period is null
	       and original_liability = 0
	       and cancelled = 0
	       
		select @canc_bill_total = IsNull(sum(spot_amount),0)
		  from cinelight_spot_liability,
	           liability_type
		 where spot_id = @spot_id
	       and liability_category_id = 1
	       and original_liability = 0
	       and cancelled = 1
	       and cinelight_spot_liability.liability_type = liability_type.liability_type_id
		
		/*
		 * Select Total Agency Comm
		 */
		
		select @canc_acomm_total = IsNull(sum(spot_amount),0)
		  from cinelight_spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id = 3
	       and original_liability = 0
	       and cancelled = 1
	       and cinelight_spot_liability.liability_type = liability_type.liability_type_id
	
		/*
		 * Calculate Deductions
		 */
		
		select @canc_deductions = IsNull(sum(spot_amount),0)
		  from cinelight_spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id not in (1,3,2)
	       and original_liability = 0
	       and cancelled = 1
	       and cinelight_spot_liability.liability_type = liability_type.liability_type_id
	
		/*
		 * Calculate Unweighted Liability
		 */
		
		select @uwl = round(@bill_curr + @acomm_curr + @deductions, 2)
	  	select @wl = round(@w_bill_curr + @w_acomm_curr + @w_deductions, 2)
	    select @cancelled = round(@canc_bill_total + @canc_acomm_total + @canc_deductions, 2)
	    select @cancelled_held = 0
	
	end
	else if @media_product_id = 6
	begin
		/*
		 * Select Total Billings
		 */
		
		select @bill_total = IsNull(sum(spot_amount),0)
		  from inclusion_spot_liability,
	           liability_type
		 where spot_id = @spot_id
	       and liability_category_id = 1
	       and original_liability = 0
	       and cancelled = 0
	       and inclusion_spot_liability.liability_type = liability_type.liability_type_id
		
		/*
		 * Select Total Agency Comm
		 */
		
		select @acomm_total = IsNull(sum(spot_amount),0)
		  from inclusion_spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id = 3
	     and original_liability = 0
	       and cancelled = 0
	       and inclusion_spot_liability.liability_type = liability_type.liability_type_id
	
		/*
		 * Calculate Deductions
		 */
		
		select @deductions = IsNull(sum(spot_amount),0)
		  from inclusion_spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id not in (1,3)
	       and original_liability = 0
	       and cancelled = 0
	       and inclusion_spot_liability.liability_type = liability_type.liability_type_id
		
		/*
		 * Select Total Billings
		 */
		
		select @w_bill_total = IsNull(sum(cinema_amount),0)
		  from inclusion_spot_liability,
	           liability_type
		 where spot_id = @spot_id
	       and liability_category_id = 1
	       and original_liability = 0
	       and cancelled = 0
	       and inclusion_spot_liability.liability_type = liability_type.liability_type_id
		
		/*
		 * Select Total Agency Comm
		 */
		
		select @w_acomm_total = IsNull(sum(cinema_amount),0)
		  from inclusion_spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id = 3
	     and original_liability = 0
	       and cancelled = 0
	       and inclusion_spot_liability.liability_type = liability_type.liability_type_id
	
		/*
		 * Calculate Deductions
		 */
		
		select @w_deductions = IsNull(sum(cinema_amount),0)
		  from inclusion_spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id not in (1,3)
	       and original_liability = 0
	       and cancelled = 0
	       and inclusion_spot_liability.liability_type = liability_type.liability_type_id
		
		/*
		 * Calculate Current and In Advance Components
		 */
		
		select @bill_adv = @advance_ratio * @bill_total
		select @acomm_adv = @advance_ratio * @acomm_total
		select @bill_curr = @bill_total - @bill_adv
		select @acomm_curr = @acomm_total - @acomm_adv
		select @w_bill_adv = @advance_ratio * @w_bill_total
		select @w_acomm_adv = @advance_ratio * @w_acomm_total
		select @w_bill_curr = @w_bill_total - @w_bill_adv
		select @w_acomm_curr = @w_acomm_total - @w_acomm_adv
		
		/*
		 * Calculate Cinema Rent Held
		 */
		
		select @rent_held = IsNull(sum(cinema_rent),0)
		  from inclusion_spot_liability
		 where spot_id = @spot_id and
	           cinema_rent <> 0 and
			   release_period is null
	       and original_liability = 0
	       and cancelled = 0
	       
		select @canc_bill_total = IsNull(sum(spot_amount),0)
		  from inclusion_spot_liability,
	           liability_type
		 where spot_id = @spot_id
	       and liability_category_id = 1
	       and original_liability = 0
	       and cancelled = 1
	       and inclusion_spot_liability.liability_type = liability_type.liability_type_id
		
		/*
		 * Select Total Agency Comm
		 */
		
		select @canc_acomm_total = IsNull(sum(spot_amount),0)
		  from inclusion_spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id = 3
	       and original_liability = 0
	       and cancelled = 1
	       and inclusion_spot_liability.liability_type = liability_type.liability_type_id
	
		/*
		 * Calculate Deductions
		 */
		
		select @canc_deductions = IsNull(sum(spot_amount),0)
		  from inclusion_spot_liability,
	           liability_type
		 where spot_id = @spot_id and
			   liability_category_id not in (1,3,2)
	       and original_liability = 0
	       and cancelled = 1
	       and inclusion_spot_liability.liability_type = liability_type.liability_type_id
	
		/*
		 * Calculate Unweighted Liability
		 */
		
		select @uwl = round(@bill_curr + @acomm_curr + @deductions, 2)
	  	select @wl = round(@w_bill_curr + @w_acomm_curr + @w_deductions, 2)
	    select @cancelled = round(@canc_bill_total + @canc_acomm_total + @canc_deductions, 2)
	    select @cancelled_held = 0
	
	end


	/*
     * Determine if this is a Liability
     */

	select @no_liability = 'N'

	if(@uwl = 0 and @bill_adv = 0 and @wl = 0 and @cancelled = 0 and @cancelled_held = 0)
	begin
		if(@rent_held = 0)
			select @no_liability = 'Y'
	end		
    
   if @spot_status = 'C' and @dandc = 'Y'
   begin
		select @cancelled_held = @cancelled
        select @cancelled = 0
   end

	if @origin_period is null
		select @origin_period = @accounting_period

	/*
    * Update Liability Generation Table
    */

	update #liability_gen
       set adv_ratio = @advance_ratio,
           bill_curr = @bill_curr,
           bill_adv = @bill_adv,
           acomm_curr = @acomm_curr,
           acomm_adv = @acomm_adv,
           uwl = @uwl,
           wl = @wl,
           held_rent = @rent_held,
           no_liability = @no_liability,
           cl = @cancelled,
           cl_held = @cancelled_held,
           cinema_weighting = @cinema_weighting,
           tran_id = @tran_id,
		   origin_period = @origin_period
     where spot_id = @spot_id

	select @error = @@error
	if (@error !=0)
	begin
        raiserror ('Film Liability: Error updating ', 16, 1)
        return -1
	end

	/*
     * Fetch Next Row
     */

	fetch spot_csr into @spot_id, @billing_start, @spot_status, @dandc, @media_product_id, @origin_period

end
close spot_csr
select @csr_open = 0
deallocate spot_csr

if @mode = 1 -- report mode
begin
    /*
     * Return Dataset
     */

      select @cut_off,
             campaign_no,
             product_desc,
             country_code,
             country_name,
             branch_code,
             branch_name,
             media_product_id,
             media_product_desc,
             business_unit_id,
             business_unit_desc,
	         complex_id,
             complex_name,
             spot_id,
             spot_status,
             dandc,
  	         tran_id,
	         billing_date,
	         cinema_weighting,
	         adv_ratio,
	         bill_curr,
	         bill_adv,
	         acomm_curr,
	         acomm_adv,
             (bill_adv + acomm_adv) as nett_adv,
             uwl,
	         wl,
	         cl,
             cl_held,
	         held_rent,
	         atb_gross,
	         atb_nett,
             atb_inc,
             no_liability,
             revenue_source,
             revenue_source_desc
        from #liability_gen
       where no_liability = 'N'
    order by campaign_no,
             complex_id
end
else if @mode = 2 -- save liability data mode
begin

    begin transaction
    
 	declare liability_csr cursor static for 
	  select complex_id,
	         country_code,
	         sum(held_rent + wl + cl_held),
	         business_unit_id,
	         media_product_id,
	         revenue_source,
			 origin_period
	    from #liability_gen
	group by complex_id,
	         country_code,
	         media_product_id,
	         business_unit_id,
	         revenue_source,
			 origin_period
	order by business_unit_id,
	         media_product_id,
	         complex_id
	     for read only

    open liability_csr
    fetch liability_csr into @complex_id, @country_code, @liability_amount, @business_unit_id, @media_product_id, @revenue_source, @origin_period
    while(@@fetch_status=0)
    begin
    
           
        exec @errorode = p_sfin_rent_liability_update @accounting_period, @country_code, @complex_id, @liability_amount, @business_unit_id, @media_product_id, @revenue_source, @origin_period
        
        if @errorode != 0
        begin
            raiserror ('Error creating group liability records', 16, 1)
            rollback transaction
            return -100
        end

        fetch liability_csr into @complex_id, @country_code, @liability_amount, @business_unit_id, @media_product_id, @revenue_source, @origin_period
    end
    close liability_csr
    deallocate liability_csr
    
    commit transaction
end
else if @mode = 3
begin    
	/*
	 * Generate In Advnace Acc Pac Data
 	 */     

    begin transaction
    
	declare 	acc_pac_adv_csr cursor forward_only static for
	select 		sum(bill_adv),
				complex_id,
				business_unit_id,
                media_product_id
	from 		#liability_gen
	group by 	complex_id,
				business_unit_id,
                media_product_id
	having		sum(bill_adv) <> 0
	order by 	complex_id
			

	open acc_pac_adv_csr
	fetch acc_pac_adv_csr into @liability_amount, @complex_id, @business_unit_id, @media_product_id
	while(@@fetch_status=0)
    begin
    
        exec @errorode = p_accpac_create_adv_dist @country_code, @business_unit_id, @complex_id, @accounting_period, @liability_amount, @media_product_id
        
        if @errorode != 0
        begin
            raiserror ('Error creating acc pac in advance amounts', 16, 1)
            rollback transaction
            return -100
        end

        fetch acc_pac_adv_csr into @liability_amount, @complex_id, @business_unit_id,@media_product_id
    end
    deallocate acc_pac_adv_csr

    commit transaction
end
else if @mode = 4
begin
		select complex_id,
	         country_code,
	         sum(held_rent + wl + cl_held),
	         business_unit_id,
	         media_product_id,
	         revenue_source,
			 origin_period
	    from #liability_gen
	group by complex_id,
	         country_code,
	         media_product_id,
	         business_unit_id,
	         revenue_source,
			 origin_period
	order by business_unit_id,
	         media_product_id,
	         complex_id
end

return 0
GO
