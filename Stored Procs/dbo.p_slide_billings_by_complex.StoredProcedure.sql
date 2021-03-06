/****** Object:  StoredProcedure [dbo].[p_slide_billings_by_complex]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_billings_by_complex]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_billings_by_complex]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_slide_billings_by_complex]  @accounting_period		datetime,
										 @country_code			char(1)
	 													 
as
set nocount on 
/*
 * Declare Valiables
 */ 

declare @error						integer,
        @errorode						integer,
        @complex_id					integer,
		@billings    				money,
		@production					money,
		@billings_ytd				money,
		@production_ytd				money,
		@bill_adjust				money,
		@prod_adjust				money,
		@bill_adjust_ytd			money,
		@prod_adjust_ytd			money,
		@bad_debts					money,
		@bad_debts_ytd				money,
        @spot_id					integer,
        @credit_amt				    money,
        @release_period				datetime,
        @ratio						decimal(15,8),
        @gst_rate					decimal(6,4), 
        @country_name				varchar(50),
        @finyear_end                datetime

create table #results 
(
    complex_id		    integer		    null,
    billings    	    money			null,
    production		    money			null,
    bill_adjust 	    money 		    null,
    prod_adjust		    money			null,
    bad_debts		    money			null,
    billings_ytd    	money			null,
    production_ytd		money			null,
    bill_adjust_ytd 	money 		    null,
    prod_adjust_ytd		money			null,
    bad_debts_ytd		money			null
)

/*
 * Get Financial Year
 */

select @finyear_end = finyear_end
  from accounting_period
 where end_date = @accounting_period

/*
 * Loop Complexes
 */

declare complex_csr cursor static for
select distinct pool.complex_id
  from slide_spot_pool pool,
       slide_campaign_spot spot,
       slide_campaign sc,
       branch b,
       accounting_period acp
 where pool.spot_id = spot.spot_id and
       spot.campaign_no = sc.campaign_no and
       b.branch_code = sc.branch_code and
       pool.release_period = acp.end_date and
       acp.finyear_end = @finyear_end and
       b.country_code = @country_code
order by complex_id
for read only

open complex_csr
fetch complex_csr into @complex_id
while (@@fetch_status = 0)
begin

    /*
     * Reset Variables
     */
     
	select @billings = 0,
		   @production = 0,
		   @billings_ytd = 0,
		   @production_ytd = 0,
	   	   @bill_adjust = 0,
		   @prod_adjust = 0,
		   @bill_adjust_ytd = 0,
		   @prod_adjust_ytd = 0,
		   @bad_debts = 0,
		   @bad_debts_ytd = 0

    /*
     * Calculate Billing & Production Values
     */
     
	select @billings_ytd = isnull(sum(total_amount),0),
           @production_ytd = isnull(sum(sound_amount + slide_amount) * -1,0) 
      from slide_spot_pool pool,
           slide_campaign_spot spot,
           slide_campaign sc,
           branch b,
           accounting_period acp
     where pool.spot_id = spot.spot_id and
           spot.campaign_no = sc.campaign_no and
           b.branch_code = sc.branch_code and
           b.country_code = @country_code and
           pool.complex_id = @complex_id and
           pool.release_period = acp.end_date and
           acp.finyear_end = @finyear_end and
           pool.spot_pool_type = 'B' /* Billings */

	select @billings = isnull(sum(total_amount),0),
           @production = isnull(sum(sound_amount + slide_amount) * -1,0) 
      from slide_spot_pool pool,
           slide_campaign_spot spot,
           slide_campaign sc,
           branch b
     where pool.spot_id = spot.spot_id and
           spot.campaign_no = sc.campaign_no and
           b.branch_code = sc.branch_code and
           b.country_code = @country_code and
           pool.complex_id = @complex_id and
           pool.release_period = @accounting_period and
           pool.spot_pool_type = 'B' /* Billings */

    /*
     * Loop Campaign Credits
     */
     
	declare campaign_csr cursor static for
	 select pool.spot_id, 
	        pool.total_amount, 
	        pool.release_period
	  from slide_spot_pool pool,
	       slide_campaign_spot spot,
	       slide_campaign sc,
	       branch b,
	       accounting_period acp
	 where pool.spot_id = spot.spot_id and
	       spot.campaign_no = sc.campaign_no and
	       b.branch_code = sc.branch_code and
	       b.country_code = @country_code and
	       pool.complex_id = @complex_id and
	       pool.release_period = acp.end_date and
	       acp.finyear_end = @finyear_end and
	       pool.spot_pool_type = 'C' /* Credits */
	order by pool.spot_id
	for read only

	open campaign_csr
	fetch campaign_csr into @spot_id, @credit_amt, @release_period
	while (@@fetch_status = 0)
	begin

        /*
         * Determine Original Production Ratio
         */
         			
		select @ratio = (slide_amount + sound_amount) / (total_amount)
          from slide_spot_pool
         where spot_id = @spot_id and
               spot_pool_type = 'B'

        select @bill_adjust_ytd = @bill_adjust_ytd + @credit_amt
        select @prod_adjust_ytd = @prod_adjust_ytd + round((@credit_amt  * @ratio ),2) * -1
        if(@release_period = @accounting_period)
        begin
            select @bill_adjust = @bill_adjust + @credit_amt
            select @prod_adjust = @prod_adjust + round((@credit_amt  * @ratio ),2) * -1
        end
                
        /*
         * Fetch Next
         */
         
    	fetch campaign_csr into @spot_id, @credit_amt, @release_period

	end
	close campaign_csr
	deallocate campaign_csr

    /*
     * Select Bad Debt Information
     */
     
	select @bad_debts_ytd = isnull(sum(total_amount),0)
      from slide_spot_pool pool,
           slide_campaign_spot spot,
           slide_campaign sc,
           branch b,
           accounting_period acp
     where pool.spot_id = spot.spot_id and
           spot.campaign_no = sc.campaign_no and
           b.branch_code = sc.branch_code and
           b.country_code = @country_code and
           pool.complex_id = @complex_id and
           pool.release_period = acp.end_date and
           acp.finyear_end = @finyear_end and
           pool.spot_pool_type = 'D' /* Bad Debts */

	select @bad_debts = isnull(sum(total_amount),0)
      from slide_spot_pool pool,
           slide_campaign_spot spot,
           slide_campaign sc,
           branch b
     where pool.spot_id = spot.spot_id and
           spot.campaign_no = sc.campaign_no and
           b.branch_code = sc.branch_code and
           b.country_code = @country_code and
           pool.complex_id = @complex_id and
           pool.release_period = @accounting_period and
           pool.spot_pool_type = 'D' /* Bad Debts */

   /*
    * Insert the record into the temp table
    */

	insert into #results (
           complex_id,
           billings,
           production,
           bill_adjust,
           prod_adjust,
           bad_debts,
           billings_ytd,
           production_ytd,
           bill_adjust_ytd,
           prod_adjust_ytd,
           bad_debts_ytd ) values (
		   @complex_id,
           @billings,
           @production,
           @bill_adjust,
           @prod_adjust,
           @bad_debts,
           @billings_ytd,
           @production_ytd,
           @bill_adjust_ytd,
           @prod_adjust_ytd,
           @bad_debts_ytd )

   /*
    * Fetch Next
    */

    fetch complex_csr into @complex_id

end
close complex_csr
deallocate complex_csr

/*
 * Select GST Rate
 */
 
select @gst_rate = gst_rate,
       @country_name = country_name
  from country
 where country_code = @country_code

/*
 * Return Dataset
 */

select c.complex_name,
       r.billings,
       r.production,
       r.bill_adjust,
       r.prod_adjust,
       r.bad_debts,
       r.billings_ytd,
       r.production_ytd,
       r.bill_adjust_ytd,
       r.prod_adjust_ytd,
       r.bad_debts_ytd,
       @gst_rate as gst_rate,
       @country_name as country_code,
       @accounting_period as accounting_period,
       c.branch_code,
	   c.complex_id
  from #results r,
       complex c
 where r.complex_id = c.complex_id

/*
 * Return Success
 */
 
return 0
GO
