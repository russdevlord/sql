/****** Object:  StoredProcedure [dbo].[p_slide_billings_by_exhibitor]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_billings_by_exhibitor]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_billings_by_exhibitor]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_slide_billings_by_exhibitor]  @accounting_period	datetime,
					 @country_code			char(1)
as
set nocount on 
/*
 * Declare Valiables
 */ 

declare @error							integer,
        @errorode							integer,
        @complex_id					integer,
		  @billing_value				money,
		  @production					money,
		  @adjust_val					money,
		  @adjust_prod					money,
		  @bad_debts					money,
        @spot_pool_id				integer,
        @spot_id						integer,
        @adj_total_amnt				money,
        @ratio							decimal(15,8),
        @gst_rate						decimal(6,4), 
	     @country_name				varchar(50)

create table #results (
	complex_id		integer		null,
   billing_value	money			null,
   production		money			null,
   adjust_val		money 		null,
   adjsut_prod		money			null,
   bad_debts		money			null
)

declare complex_csr cursor static for
select distinct pool.complex_id
  from slide_spot_pool pool,
       slide_campaign_spot spot,
       slide_campaign sc,
       branch b
 where pool.spot_id = spot.spot_id and
       spot.campaign_no = sc.campaign_no and
       b.branch_code = sc.branch_code and
       b.country_code = @country_code and
       pool.release_period = @accounting_period
order by complex_id
for read only

open complex_csr
fetch complex_csr into @complex_id
while (@@fetch_status = 0)
begin
	select @billing_value = isnull(sum(total_amount),0),
          @production = isnull(sum(sound_amount + slide_amount) * -1,0) 
     from slide_spot_pool
    where complex_id = @complex_id and
          release_period = @accounting_period and
          spot_pool_type = 'B' --Billings

	select @adjust_val  = 0
	select @adjust_prod = 0

	declare campaign_csr cursor static for
	 select spot_id, total_amount
	   from slide_spot_pool
	  where complex_id = @complex_id and
	        release_period = @accounting_period and
	        spot_pool_type = 'C' --Credits
	order by spot_id
	for read only

	open campaign_csr
	fetch campaign_csr into @spot_id, @adj_total_amnt
	while (@@fetch_status = 0)
	begin
			
		select @ratio = ( slide_amount + sound_amount ) / ( total_amount )
        from slide_spot_pool
       where spot_id = @spot_id and
             spot_pool_type = 'B'

		select @adjust_val  = @adjust_val + @adj_total_amnt

		select @adjust_prod = @adjust_prod + round((@adj_total_amnt  * @ratio ),2) * -1

		fetch campaign_csr into @spot_id, @adj_total_amnt
	end
	close campaign_csr
	deallocate campaign_csr

	select @bad_debts = isnull(sum(total_amount),0)
     from slide_spot_pool
    where complex_id = @complex_id and
          release_period = @accounting_period and
          spot_pool_type = 'D' --Bad Debts

	/*
    * Inser the record into the temp table
    */

	insert into #results (
		complex_id,
		billing_value,
		production,
		adjust_val,
		adjsut_prod,
		bad_debts
      ) values (
		@complex_id,
		@billing_value,
		@production,
		@adjust_val,
		@adjust_prod,
		@bad_debts
		)
			

	fetch complex_csr into @complex_id
end
close complex_csr
deallocate complex_csr


select @gst_rate = gst_rate,
       @country_name = country_name
  from country
 where country_code = @country_code
/*
 * Commit and Return
 */
  select e.exhibitor_id,
		   e.exhibitor_name,
			e.contact,
			e.phone,
		   c.complex_name,
		   r.billing_value,
		   r.production,
		   r.adjust_val,
		   r.adjsut_prod,
		   r.bad_debts,
         @gst_rate as gst_rate,
         @country_name as country_code,
         @accounting_period as accounting_period,
         c.branch_code,
		   c.complex_id
    from #results r,
         complex c,
   		exhibitor e
   where r.complex_id = c.complex_id and
	 	   c.exhibitor_id = e.exhibitor_id
order by e.exhibitor_id

return 0
GO
