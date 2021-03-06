/****** Object:  StoredProcedure [dbo].[p_slide_liability_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_liability_report]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_liability_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_liability_report]	@mode              int,
											 @accounting_period datetime,
											 @run_date			datetime,
											 @country_code      char(1)      
as
set nocount on 
/*
 * Declare Valiables
 */ 

declare @error							int,
        @errorode							int,
        @atb_dist						money,
        @slide_charges				    money,
        @sound_charges				    money,
        @atb_gross					    money,
        @atb_nett						money,
        @adv_not_paid				    money,
        @adv_pre_paid				    money,
        @adv_total					    money,
        @complex_id					    int,
        @bill_tran_id				    int,
        @allocation					    money,
        @day_of_week					tinyint,
        @advance_part				    money,
        @bill_part					    money,
        @nett_rate					    money,
        @paid_amount					money,
        @screenings_cnt				    int,
        @total_weight				    decimal(15,8),
        @weight						    decimal(15,8),
        @list_rate					    money,
        @screen_weeks				    money,
        @theatre_total				    money,
        @dist_amount					money,
        @ratio							decimal(15,8),
        @camp_name					    varchar(50),
        @agency_deal					char(1),
        @extra_advance				    money,
        @spot_total					    money,
        @paid_portion				    money,
        @adv_portion					money,
        @pre_paid						money,
        @liability					    money,
        @accrue_amount				    money,
        @alloc_amount				    money,
        @avail_alloc					money,
        @rent_actual					money,
        @rent_bill					    money,
        @rent_adj						money,
        @rent_calc					    money,
        @cinema_alloc				    money,
        @rent_total_accrue			    money,
        @discount_amount			    money,
        @discount_tran_id			    int,
        @first_insert				    tinyint,
        @campaign_no                    char(7),
        @liability_amount               money

/*
 * Create Temporary Tables
 */

create table #results 
(
    campaign_no		    char(7)		    null,
    atb_dist		    money           null,
    atb_nett			money			null,
    slide_charges	    money			null,
    sound_charges	    money			null,
    atb_gross		    money			null,
    adv_not_paid	    money			null,
    adv_pre_paid	    money			null,
    adv_total		    money			null,
    complex_id		    int		        null,
    allocation		    money			null,
    original_allocation money           null,
    billing_accrual     money           null
)


 declare campaign_csr cursor static for
  select distinct sc.campaign_no
    from slide_campaign sc,   
         branch b,
         rent_distribution rd
   where sc.branch_code = b.branch_code
     and b.country_code = @country_code
     and sc.is_closed = 'N'
     and sc.campaign_status <> 'U'
     and sc.campaign_status <> 'Z'
group by sc.campaign_no
order by sc.campaign_no
     for read only     
     
open campaign_csr
fetch campaign_csr into @campaign_no
while (@@fetch_status = 0)
begin

    select @first_insert = 1 

    /*
     * Get Nett Amount from campaign outstanding balance (ex gst amount)
     */

    select @atb_dist = sum(sa.nett_amount)
      from slide_transaction st,
           slide_allocation sa
     where st.campaign_no = @campaign_no and
           st.tran_id = sa.to_tran_id

    select @atb_dist = isnull(@atb_dist,0)

    select @atb_dist = @atb_dist - IsNull(sum(sa.gross_amount),0)
      from slide_transaction st,
           slide_allocation sa
     where st.campaign_no = @campaign_no and
           st.gross_amount < 0 and
           st.tran_id = sa.from_tran_id

    select @atb_nett = @atb_dist

    /*
     * Get Agency Deal
     */

    select @agency_deal = agency_deal
      from slide_campaign
     where campaign_no = @campaign_no

    if @agency_deal = 'N' 
    begin
	    select @camp_name = c.client_name
         from slide_campaign sc,
              client c
        where sc.client_id = c.client_id and
              sc.campaign_no = @campaign_no
    end
    else
    begin
	    select @camp_name = a.agency_name
         from slide_campaign sc,
              agency a
        where sc.agency_id = a.agency_id and
              sc.campaign_no = @campaign_no
    end

    /*
     * Get Day of Week
     */

    select @day_of_week = datepart(dw, @run_date)
    if(@day_of_week = 6) --Friday, no need to split any of the values.
    begin

	    select @advance_part = isnull(sum(nett_rate),0)
         from	slide_campaign_spot
        where	campaign_no = @campaign_no and
				billing_status = 'B' and
				screening_date > @run_date

	    select @advance_part = isnull(@advance_part,0)

	    select @bill_part = 0 --Set this to zero as we add it to the amount to include in the report and here we dont need to add anything
	
    end
    else
    begin

	    select @day_of_week = @day_of_week + 1
	    if(@day_of_week = 8)   -- the new number for saturday
		    select @day_of_week = 1

	    --Set day of week to the number of days not to count in the in advance, ie saturday dont count 1 day.
    --	select @advance_part = round( ( @day_of_week / 7 ) * nett_rate,2),
	    select @bill_part = round((convert(decimal(15,8),convert(decimal(15,8),@day_of_week)/convert(decimal(15,8),7)) * nett_rate),2), 
              @nett_rate = nett_rate
         from slide_campaign_spot
        where campaign_no = @campaign_no and
              billing_status = 'B' and
			     screening_date = dateadd(dd,-1*(@day_of_week - 1),@run_date)

    -- GC, 28/7/2003, removed because it was always picking up one spot even if was 2 years ago
    --          screening_date = ( select max(screening_date)
    --                               from slide_campaign_spot
    --                              where campaign_no = @campaign_no and
    --                                    screening_date <= @run_date )

    --	select @advance_part = isnull(@advance_part,0)
	    select @bill_part = isnull(@bill_part,0)
	    select @nett_rate = isnull(@nett_rate,0)

	    --Set the billed portion to the part of the spot that is included in the report.
    --	select @bill_part = @nett_rate - @advance_part
	    select @advance_part = @nett_rate - @bill_part

	    --Add on any other billed spots to advanced after this week we have just split up.
	    select @extra_advance = isnull(sum(nett_rate),0)
         from slide_campaign_spot
        where campaign_no = @campaign_no and
              billing_status = 'B' and
			     screening_date > @run_date
    --			 screening_date > dateadd(wk,1,@run_date) 

	    select @advance_part = @advance_part + @extra_advance

    end

    /*
     * Get paid amount
     */

    select @paid_portion = 0

	 declare alloc_csr cursor static for
	  select distinct sx.billing_tran_id,
	         sx.discount_tran_id
	    from slide_spot_trans_xref sx,
			 slide_campaign_spot sp
	   where sp.spot_id = sx.spot_id and
			 sp.campaign_no = @campaign_no and
			 sp.billing_status = 'B' and
			 sp.screening_date >= @run_date
	order by sx.billing_tran_id
	     for read only

    open alloc_csr
    fetch alloc_csr into @bill_tran_id, @discount_tran_id
    while (@@fetch_status = 0)
    begin

	    --Get amount paid for this billing (allocated to it)-
	    select @paid_amount = abs(isnull(sum(sa.nett_amount),0))
	      from slide_allocation sa
	     where sa.to_tran_id = @bill_tran_id and
              sa.from_tran_id is not null

	    if @discount_tran_id is not null
	    begin
		    select @discount_amount = abs(st.nett_amount)
		      from slide_transaction st
		     where st.tran_id = @discount_tran_id

		    select @paid_amount = @paid_amount - @discount_amount
	    end
	

	    --Spot total = total amount billed from the spots for this billing (should match billing_amount)
	    select @spot_total = isnull(sum(nett_rate),0)
         from slide_campaign_spot s,
              slide_spot_trans_xref x
	     where x.billing_tran_id = @bill_tran_id and
              s.spot_id = x.spot_id

       --advance portion = the amount on the spots billed that is in advance
	    select @adv_portion = isnull(sum(nett_rate),0)
         from slide_campaign_spot s,
              slide_spot_trans_xref x
	     where x.billing_tran_id = @bill_tran_id and
              s.spot_id = x.spot_id and
              s.screening_date >= @run_date

	    --Remove the non-advance portion from the spots
	    select @adv_portion = @adv_portion - @bill_part --Calculate the amount we wish to know if it is paid.

	    --Calculate portion of advance spots that has been paid for.
	    select @pre_paid = @paid_amount - (@spot_total  - @adv_portion)

	    --If its a positive value add it up. Otherwise ignore it.
	    if @pre_paid > 0 
		    select @paid_portion = @paid_portion + @pre_paid

	    fetch alloc_csr into @bill_tran_id, @discount_tran_id
    end
    close alloc_csr
    deallocate alloc_csr

    --Get only the portion paid for the advanced billed portion
    --select @paid_portion = @paid_portion

    select  @adv_total = @advance_part,
            @adv_not_paid = abs(@advance_part) - abs(@paid_portion),
   	      @adv_pre_paid = abs(@paid_portion)

    select  @liability = @atb_dist - @adv_total,
            @atb_dist = @atb_dist - @adv_total
            

    if @liability < 0 and abs(@paid_portion) < abs(@liability)
	    select  @atb_dist = abs(@paid_portion) * -1, --Ensure these values are negative.
   	         @liability = abs(@paid_portion) * -1

    /*
     * Now need to distribution the liability to slide_dist and theatres
     */

    select @slide_charges = 0,
           @sound_charges = 0

    if @liability >= 0
    begin

	    /*
	     * This pass goes through the liablity to decide where to allocate the money.
	     */

	    select @accrue_amount = sum(accrued_alloc)
	      from slide_distribution
	     where distribution_type = 'S' and --Sound
			     campaign_no = @campaign_no
	
	    select @alloc_amount = isnull(sum(sdp.alloc_amount),0)
	      from slide_distribution_pool sdp,
			     slide_distribution sd
	     where sdp.slide_distribution_id = sd.slide_distribution_id and
			     sd.distribution_type = 'S' and --Extra charges
			     sd.campaign_no = @campaign_no
	
	    select @avail_alloc = @accrue_amount - @alloc_amount
	
	    if( @avail_alloc < @liability)
		    select @sound_charges = @avail_alloc
	    else
		    select @sound_charges = @liability
	
	    select @liability = @liability - @sound_charges
	
	    if @liability > 0
	    begin
	
		    select @accrue_amount = sum(accrued_alloc)
		      from slide_distribution
		     where (distribution_type = 'C' or --Extra charges
				     distribution_type = 'P') and --Production
				     campaign_no = @campaign_no
		
		    select @alloc_amount = isnull(sum(sdp.alloc_amount),0)
		      from slide_distribution_pool sdp,
				     slide_distribution sd
		     where sdp.slide_distribution_id = sd.slide_distribution_id and
				     (sd.distribution_type = 'C' or --Extra charges
				     sd.distribution_type = 'P') and --Production
				     sd.campaign_no = @campaign_no
		
		    select @avail_alloc = @accrue_amount - @alloc_amount
		
		    if( @avail_alloc < @liability)
			    select @slide_charges = @avail_alloc
		    else
			    select @slide_charges = @liability
		
		    select @liability = @liability - @slide_charges
	
	    end
	
	    --This line may need to be changed if the gross payment is different to the nett payment
	    select @atb_gross = balance_outstanding
         from slide_campaign
        where campaign_no = @campaign_no
	
	    if @liability > 0
	    begin
	
		    /*
		     * Calculate Current Allocation Level
		     */
	
		    select @alloc_amount = isnull(sum(rdp.amount),0)
		      from rent_distribution_pool rdp,
				     rent_distribution rd
		     where rdp.rent_distribution_id = rd.rent_distribution_id and
				     rd.campaign_no = @campaign_no
	
		    select @rent_total_accrue = isnull(sum(rd.billing_accrual),0)
		      from rent_distribution rd
		     where rd.campaign_no = @campaign_no
	
		    select @alloc_amount = isnull(@rent_total_accrue,0) - isnull(@alloc_amount,0)
	
			 declare rent_csr cursor static for
			  select rd.original_allocation,
			         rd.billing_accrual,
			         rd.complex_id
			    from rent_distribution rd
			   where rd.campaign_no = @campaign_no
			order by rd.complex_id ASC
			     for read only

		    open rent_csr
		    fetch rent_csr into @rent_actual, @rent_bill, @complex_id
		    while (@@fetch_status = 0)
		    begin
		
			    select @cinema_alloc = isnull(sum(rdp.amount),0)
			      from rent_distribution_pool rdp,
					     rent_distribution rd
			     where rdp.rent_distribution_id = rd.rent_distribution_id and
					     rd.campaign_no = @campaign_no and
					     rd.complex_id = @complex_id
	
			    /*
			     * Calculate Adjustment
			     */
		
			    select @rent_adj = 0
		
			    select @cinema_alloc = @rent_bill - @cinema_alloc
			    if @alloc_amount <> 0
				    select @rent_adj = round((@liability * convert(decimal(15,8),(convert(decimal(15,8),@cinema_alloc) / convert(decimal(15,8),@alloc_amount)))),2)
		
			    insert into #results (
			    campaign_no,
			    atb_dist,
			    atb_nett,
			    slide_charges,
			    sound_charges,
			    atb_gross,
			    adv_not_paid,
			    adv_pre_paid,
			    adv_total,
			    complex_id,
			    allocation ) values (
			    @campaign_no,
			    @atb_dist,
			    @atb_nett,
			    @slide_charges,
			    @sound_charges,
			    @atb_gross,
			    @adv_not_paid,
			    @adv_pre_paid,
			    @adv_total,
			    @complex_id,
			    @rent_adj )
			
			    if @first_insert = 1
				    select 	@atb_dist = 0,
                         @atb_nett = 0,
							    @slide_charges = 0,
							    @sound_charges = 0,
							    @atb_gross  = 0,
							    @adv_not_paid  = 0,
							    @adv_pre_paid  = 0,
							    @adv_total     = 0,
                         @first_insert  = 0
	     
			    /*
			     * Update Running Totals
			     */
			
			    select @liability = @liability - @rent_adj
			    select @alloc_amount = @alloc_amount - @cinema_alloc
		
			    /*
			     * Fetch Next
			     */
			
			    fetch rent_csr into @rent_actual, @rent_bill, @complex_id
		
		    end
		    close rent_csr
		    deallocate rent_csr
	    end
	    else
	    begin
		    insert into #results (
		    campaign_no,
		    atb_dist,
		    atb_nett,
		    slide_charges,
		    sound_charges,
		    atb_gross,
		    adv_not_paid,
		    adv_pre_paid,
		    adv_total,
		    complex_id,
		    allocation ) values (
		    @campaign_no,
		    @atb_dist,
		    @atb_nett,
		    @slide_charges,
		    @sound_charges,
		    @atb_gross,
		    @adv_not_paid,
		    @adv_pre_paid,
		    @adv_total,
		    null,
		    null )
	    end
    end
    else if @liability < 0
    begin

	    --This line may need to be changed if the gross payment is different to the nett payment
	    select @atb_gross = @atb_dist

	    /*
	     * Calculate Theatre Allocation
	     */
	    select @alloc_amount = isnull(sum(rdp.amount),0)
	      from rent_distribution_pool rdp,
			     rent_distribution rd
	     where rdp.rent_distribution_id = rd.rent_distribution_id and
			     rd.campaign_no = @campaign_no

	    if @alloc_amount > abs(@liability)
   	    select @alloc_amount = @liability
	    else	
		    select @alloc_amount = @alloc_amount * -1

	    select @cinema_alloc = @alloc_amount --Store the theatre amount here to be distributed later

	    select @liability = @liability - @alloc_amount

	    --Allocate to production charges
	    if @liability < 0
	    begin
		    select @alloc_amount = isnull(sum(sdp.alloc_amount),0)
		      from slide_distribution_pool sdp,
				     slide_distribution sd
		     where sdp.slide_distribution_id = sd.slide_distribution_id and
				     sd.distribution_type = 'P' and --Production
				     sd.campaign_no = @campaign_no
		
		    if @alloc_amount > abs(@liability)
			    select @alloc_amount = @liability
		    else	
			    select @alloc_amount = @alloc_amount * -1
		
		    select @liability = @liability - @alloc_amount

		    select @slide_charges = @alloc_amount
	    end

	    --Allocate to sound charges
	    if @liability < 0
	    begin
		    select @alloc_amount = isnull(sum(sdp.alloc_amount),0)
		      from slide_distribution_pool sdp,
				     slide_distribution sd
		     where sdp.slide_distribution_id = sd.slide_distribution_id and
				     sd.distribution_type = 'S' and --Sound
				     sd.campaign_no = @campaign_no
		
		    if @alloc_amount > abs(@liability)
			    select @alloc_amount = @liability
		    else	
			    select @alloc_amount = @alloc_amount * -1
		
		    select @liability = @liability - @alloc_amount

		    select @sound_charges = @alloc_amount
	    end

	    --Allocate to extra charges
	    if @liability < 0
	    begin
		    select @alloc_amount = isnull(sum(sdp.alloc_amount),0)
		      from slide_distribution_pool sdp,
				     slide_distribution sd
		     where sdp.slide_distribution_id = sd.slide_distribution_id and
				     sd.distribution_type = 'C' and --Extra Charges
				     sd.campaign_no = @campaign_no
		
		    if @alloc_amount > abs(@liability)
			    select @alloc_amount = @liability
		    else	
			    select @alloc_amount = @alloc_amount * -1
		
		    select @liability = @liability - @alloc_amount

		    select @sound_charges = @alloc_amount
	    end

	    if @liability < 0
	    begin
		    select @camp_name = 'Error'
    --		raiserror ('Slide campaign with a negative liability that cannot be allocated detected. %1!' , @liability, 16, 1)
    --		return -1
	    end


	    if @cinema_alloc <> 0
	    begin
		    select @liability = @cinema_alloc
	
		    select @alloc_amount = isnull(sum(rdp.amount),0)
		      from rent_distribution_pool rdp,
				     rent_distribution rd
		     where rdp.rent_distribution_id = rd.rent_distribution_id and
				     rd.campaign_no = @campaign_no

			 declare rent_csr cursor static for
			  select rd.original_allocation,
			         rd.billing_accrual,
			         rd.complex_id
			    from rent_distribution rd
			   where rd.campaign_no = @campaign_no
			order by rd.complex_id ASC
			     for read only

		    open rent_csr
		    fetch rent_csr into @rent_actual, @rent_bill, @complex_id
		    while (@@fetch_status = 0)
		    begin
		
			    select @cinema_alloc = isnull(sum(rdp.amount),0)
			      from rent_distribution_pool rdp,
					     rent_distribution rd
			     where rdp.rent_distribution_id = rd.rent_distribution_id and
					     rd.campaign_no = @campaign_no and
					     rd.complex_id = @complex_id
	
			    /*
			     * Calculate Adjustment
			     */
		
			    select @rent_adj = 0
			    if @alloc_amount <> 0
				    select @rent_adj = round((@liability * convert(decimal(15,8),(convert(decimal(15,8),@cinema_alloc) / convert(decimal(15,8),@alloc_amount)))),2)
		
			    insert into #results (
			    campaign_no,
			    atb_dist,
			    atb_nett,
			    slide_charges,
			    sound_charges,
			    atb_gross,
			    adv_not_paid,
			    adv_pre_paid,
			    adv_total,
			    complex_id,
			    allocation ) values (
			    @campaign_no,
			    @atb_dist,
			    @atb_nett,
			    @slide_charges,
			    @sound_charges,
			    @atb_gross,
			    @adv_not_paid,
			    @adv_pre_paid,
			    @adv_total,
			    @complex_id,
			    @rent_adj )
			
			    if @first_insert = 1
				    select 	@atb_dist = 0,
                         @atb_nett = 0,
							    @slide_charges = 0,
							    @sound_charges = 0,
							    @atb_gross  = 0,
							    @adv_not_paid  = 0,
							    @adv_pre_paid  = 0,
							    @adv_total     = 0,
                         @first_insert  = 0
	
			    /*
			     * Update Running Totals
			     */
			
			    select @liability = @liability - @rent_adj
			    select @alloc_amount = @alloc_amount - @cinema_alloc
		
			    /*
			     * Fetch Next
			     */
			
			    fetch rent_csr into @rent_actual, @rent_bill, @complex_id
		
		    end
		    close rent_csr
		    deallocate rent_csr
	    end
	    else
	    begin
		    insert into #results (
		    campaign_no,
		    atb_dist,
		    atb_nett,
		    slide_charges,
		    sound_charges,
		    atb_gross,
		    adv_not_paid,
		    adv_pre_paid,
		    adv_total,
		    complex_id,
		    allocation ) values (
		    @campaign_no,
		    @atb_dist,
		    @atb_nett,
		    @slide_charges,
		    @sound_charges,
		    @atb_gross,
		    @adv_not_paid,
		    @adv_pre_paid,
		    @adv_total,
		    null,
		    null )
	    end
    end
	/*
	 * Fetch Next
	 */
	
	fetch campaign_csr into @campaign_no
end
close campaign_csr
deallocate campaign_csr

if @mode = 1 -- report mode
begin
    /*
     * Return Dataset
     */
	select	co.country_name,
			co.country_code,
			b.branch_name,
			sc.campaign_no,
			sc.name_on_slide,
			r.atb_dist,
			r.atb_gross,
			r.slide_charges,
			r.sound_charges,
			r.atb_nett,
			r.adv_not_paid,
			r.adv_pre_paid,
			r.adv_total,
			c.complex_name,
			c.complex_id,
			r.allocation,
			@run_date AS cutoff_date
      -- from #results r,
      --      slide_campaign sc,
      --      complex c,
      --      branch b,
      --      country co
      --where sc.campaign_no = r.campaign_no and
      --      r.complex_id *= c.complex_id and
      --      sc.branch_code = b.branch_code and
      --      b.country_code = co.country_code          
	FROM	#results AS r LEFT OUTER JOIN
			complex AS c ON r.complex_id = c.complex_id INNER JOIN
			slide_campaign AS sc ON r.campaign_no = sc.campaign_no INNER JOIN
			branch AS b ON sc.branch_code = b.branch_code INNER JOIN
			country AS co ON b.country_code = co.country_code
end
else if @mode = 2 -- save liability data mode
begin

    begin transaction
    
	 declare liability_csr cursor static for 
	  select complex_id,
	         sum(allocation)
	    from #results
	   where complex_id is not null
	group by complex_id
	order by complex_id
	     for read only


	/*
	 * Store Complex Level Liability
 	 */     

    open liability_csr
    fetch liability_csr into @complex_id, @liability_amount
    while(@@fetch_status=0)
    begin
    
        exec @errorode = p_sfin_rent_liability_update @accounting_period, @country_code, @complex_id, @liability_amount, 1, 5, 'S', @accounting_period
        
        if @errorode != 0
        begin
            raiserror ('Error creating group liability records', 16, 1)
            rollback transaction
            return -100
        end

        fetch liability_csr into @complex_id, @liability_amount
    end
    close liability_csr
    deallocate liability_csr
    
    commit transaction 
    
end
else if @mode = 3
begin
	/*
	 * Generate In Advance Acc Pac Data
 	 */  
        
    begin transaction
    
	declare 	acc_pac_adv_csr cursor forward_only static for
	select 		sum(adv_total),
				complex_id
	from 		#results
	group by 	complex_id
	having		sum(adv_total) <> 0
	order by 	complex_id
			
	open acc_pac_adv_csr
	fetch acc_pac_adv_csr into @liability_amount, @complex_id
	while(@@fetch_status=0)
    begin
    
        exec @errorode = p_accpac_create_adv_dist @country_code, 1, @complex_id, @accounting_period, @liability_amount, 5
        
        if @errorode != 0
        begin
            raiserror ('Error creating acc pac in advance amounts', 16, 1)
            rollback transaction
            return -100
        end

        fetch acc_pac_adv_csr into @liability_amount, @complex_id
    end
    deallocate acc_pac_adv_csr
	
    commit transaction
end


return 0
GO
