/****** Object:  StoredProcedure [dbo].[p_ffin_deferred_billings_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_deferred_billings_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_deferred_billings_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_ffin_deferred_billings_rpt]        @cutoff_date        datetime,
                                                @rpt_campaign_no    int

as

declare @error                          int,
        @campaign_no                    int,
        @count                          int,
        @product_desc                   varchar(100),
        @confirmed_cost                 money,
        @deferred_amount                money,
        @part_deferred_amount           money,        
        @average_weeks_deferred         int,
        @part_average_weeks_deferred    int,
        @deferred_finyear_amt           money,
        @first_name                     varchar(50),
        @last_name                      varchar(50),
        @business_unit_id               int,
        @business_unit_desc             varchar(30),
        @media_product_id               int,
        @media_product_desc             varchar(30),
        @no_spots                       int,
        @part_no_spots                  int,
        @average_weeks_left             int,
        @screened_dest_dandc_amount     int,
        @rowcount                       int
        
/*
 * Create Temporary Table
 */ 

create table #deferred_billing_campaigns
(
    campaign_no                 int             null,
    product_desc                varchar(100)    null,
    confirmed_cost              money           null,
    deferred_amount             money           null,
    average_weeks_deferred      int             null,
    average_weeks_remaining     int             null,
    no_spots                    int             null,
    deferred_finyear_amt        money           null,
    first_name                  varchar(50)     null,
    last_name                   varchar(50)     null,
    business_unit_id            int             null,
    business_unit_desc          varchar(30)     null,
    media_product_id            int             null,
    media_product_desc          varchar(30)     null,
    deferred_type               varchar(30)     null
)
  

/*
 * Populate Temporary Table
 */
 
insert into #deferred_billing_campaigns
  select fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         sum(cs.charge_rate),
         avg(datediff(wk, cs.billing_date, cs.screening_date)),
         avg(datediff(wk, @cutoff_date, cs.screening_date)),
         count(spot_id),
         0.0,
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc,
         'Normal Deferred'
    from campaign_spot cs,
         film_campaign fc,
         sales_rep sr,
         business_unit bu,
         media_product mp,
         campaign_package cp
   where cs.screening_date <> cs.billing_date 
     and cs.campaign_no = fc.campaign_no
     and fc.rep_id = sr.rep_id
     and cs.screening_date > @cutoff_date
     and dateadd(dd, 6, cs.billing_date) <= @cutoff_date
     and fc.campaign_no = cp.campaign_no
     and cp.package_id = cs.package_id
     and fc.business_unit_id = bu.business_unit_id 
     and cp.media_product_id = mp.media_product_id
     and cs.spot_status <> 'U'     
     and cs.screening_date is not null
     and (fc.campaign_no = @rpt_campaign_no 
      or @rpt_campaign_no = -1)
     and cs.charge_rate != 0
     and cs.spot_redirect is null
     and fc.campaign_status != 'P'
     and fc.campaign_status != 'X'
     and fc.campaign_status != 'Z'
group by fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
union
  select fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         sum(cs.charge_rate),
         avg(datediff(wk, cs.billing_date, cs.screening_date)),
         avg(datediff(wk, @cutoff_date, cs.screening_date)),
         count(spot_id),
         0.0,
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc,
         'Normal Deferred'
    from cinelight_spot cs,
         film_campaign fc,
         sales_rep sr,
         business_unit bu,
         media_product mp,
         cinelight_package cp
   where cs.screening_date <> cs.billing_date 
     and cs.campaign_no = fc.campaign_no
     and fc.rep_id = sr.rep_id
     and cs.screening_date > @cutoff_date
     and dateadd(dd, 6, cs.billing_date) <= @cutoff_date
     and fc.campaign_no = cp.campaign_no
     and cp.package_id = cs.package_id
     and fc.business_unit_id = bu.business_unit_id 
     and cp.media_product_id = mp.media_product_id
     and cs.spot_status <> 'U'     
     and cs.screening_date is not null
     and (fc.campaign_no = @rpt_campaign_no 
      or @rpt_campaign_no = -1)
     and cs.charge_rate != 0
     and fc.campaign_status != 'P'
     and fc.campaign_status != 'X'
     and fc.campaign_status != 'Z'
group by fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
union
  select fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         sum(cs.charge_rate),
         avg(datediff(wk, cs.billing_date, cs.screening_date)),
         avg(datediff(wk, @cutoff_date, cs.screening_date)),
         count(spot_id),
         0.0,
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         mp.media_product_id,
         mp.media_product_desc,
         'Normal Deferred'
    from inclusion_spot cs,
         film_campaign fc,
         sales_rep sr,
         business_unit bu,
         media_product mp,
         inclusion inc
   where cs.screening_date <> cs.billing_date 
     and cs.campaign_no = fc.campaign_no
     and fc.rep_id = sr.rep_id
     and cs.screening_date > @cutoff_date
     and dateadd(dd, 6, cs.billing_date) <= @cutoff_date
     and fc.campaign_no = inc.campaign_no
     and inc.inclusion_id = cs.inclusion_id
     and fc.business_unit_id = bu.business_unit_id 
     and 6 = mp.media_product_id
     and cs.spot_status <> 'U'     
     and cs.screening_date is not null
     and (fc.campaign_no = @rpt_campaign_no 
      or @rpt_campaign_no = -1)
     and cs.charge_rate != 0
	 and inc.inclusion_type = 5
     and fc.campaign_status != 'P'
     and fc.campaign_status != 'X'
     and fc.campaign_status != 'Z'
group by fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         mp.media_product_id,
         mp.media_product_desc
order by fc.campaign_no

select @error = @@error      
if @error != 0
begin
    raiserror ('Error Inserting Full Values', 16, 1)
    return -100
end

/*
 * Add Part Deferred Amounts To The Main Amounts
 */
 declare pre_part_deferred_csr cursor static for 
  select fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         isnull(sum(convert(money, (cs.charge_rate * convert(numeric(10,6), 1 + datediff(dd, cs.billing_date, @cutoff_date)) / 7))),0),
         avg(datediff(wk, cs.billing_date, cs.screening_date)),
         avg(datediff(wk, @cutoff_date, cs.screening_date)),
         count(spot_id),
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
    from campaign_spot cs,
         film_campaign fc,
         sales_rep sr,
         business_unit bu,
         media_product mp,
         campaign_package cp
   where cs.screening_date <> cs.billing_date 
     and cs.campaign_no = fc.campaign_no
     and fc.rep_id = sr.rep_id
     and cs.billing_date < @cutoff_date
     and dateadd(dd, 6, cs.billing_date) > @cutoff_date
     and cs.screening_date is not null
     and cs.spot_status <> 'U'
     and fc.campaign_no = cp.campaign_no
     and cp.package_id = cs.package_id
     and fc.business_unit_id = bu.business_unit_id 
     and cp.media_product_id = mp.media_product_id
     and (fc.campaign_no = @rpt_campaign_no 
      or @rpt_campaign_no = -1)
     and cs.charge_rate != 0
     and cs.spot_redirect is null
     and fc.campaign_status != 'P'
     and fc.campaign_status != 'X'
     and fc.campaign_status != 'Z'
group by fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
union
  select fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         isnull(sum(convert(money, (cs.charge_rate * convert(numeric(10,6), 1 + datediff(dd, cs.billing_date, @cutoff_date)) / 7))),0),
         avg(datediff(wk, cs.billing_date, cs.screening_date)),
         avg(datediff(wk, @cutoff_date, cs.screening_date)),
         count(spot_id),
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
    from cinelight_spot cs,
         film_campaign fc,
         sales_rep sr,
         business_unit bu,
         media_product mp,
         cinelight_package cp
   where cs.screening_date <> cs.billing_date 
     and cs.campaign_no = fc.campaign_no
     and fc.rep_id = sr.rep_id
     and cs.billing_date < @cutoff_date
     and dateadd(dd, 6, cs.billing_date) > @cutoff_date
     and cs.screening_date is not null
     and cs.spot_status <> 'U'
     and fc.campaign_no = cp.campaign_no
     and cp.package_id = cs.package_id
     and fc.business_unit_id = bu.business_unit_id 
     and cp.media_product_id = mp.media_product_id
     and (fc.campaign_no = @rpt_campaign_no 
      or @rpt_campaign_no = -1)
     and cs.charge_rate != 0
     and fc.campaign_status != 'P'
     and fc.campaign_status != 'X'
     and fc.campaign_status != 'Z'
group by fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
union
  select fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
	     isnull(sum(convert(money, (cs.charge_rate * convert(numeric(10,6), 1 + datediff(dd, cs.billing_date, @cutoff_date)) / 7))),0),
         avg(datediff(wk, cs.billing_date, cs.screening_date)),
         avg(datediff(wk, @cutoff_date, cs.screening_date)),
         count(spot_id),
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         mp.media_product_id,
         mp.media_product_desc
    from inclusion_spot cs,
         film_campaign fc,
         sales_rep sr,
         business_unit bu,
         media_product mp,
         inclusion inc
   where cs.screening_date <> cs.billing_date 
     and cs.campaign_no = fc.campaign_no
     and fc.rep_id = sr.rep_id
     and cs.billing_date < @cutoff_date
     and dateadd(dd, 6, cs.billing_date) > @cutoff_date
     and fc.campaign_no = inc.campaign_no
     and inc.inclusion_id = cs.inclusion_id
     and fc.business_unit_id = bu.business_unit_id 
     and 6 = mp.media_product_id
     and cs.spot_status <> 'U'     
     and cs.screening_date is not null
     and (fc.campaign_no = @rpt_campaign_no 
      or @rpt_campaign_no = -1)
     and cs.charge_rate != 0
	 and inc.inclusion_type = 5
     and fc.campaign_status != 'P'
     and fc.campaign_status != 'X'
     and fc.campaign_status != 'Z'
group by fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         mp.media_product_id,
         mp.media_product_desc
order by fc.campaign_no
     for read only
 
open pre_part_deferred_csr
fetch pre_part_deferred_csr into @campaign_no, @product_desc, @confirmed_cost, @part_deferred_amount, @part_average_weeks_deferred, @average_weeks_left, @part_no_spots, @first_name, @last_name, @business_unit_id, @business_unit_desc, @media_product_id, @media_product_desc
while(@@fetch_status=0)
begin

    if @part_deferred_amount != 0
    begin

        select @count = count(campaign_no)
          from #deferred_billing_campaigns
         where campaign_no = @campaign_no
           and media_product_id = @media_product_id
           and business_unit_id = @business_unit_id
         
         if @count > 0
         begin
            update #deferred_billing_campaigns
               set deferred_amount = deferred_amount +  @part_deferred_amount,
                   average_weeks_deferred = (average_weeks_deferred + @part_average_weeks_deferred) / 2,
                   average_weeks_remaining = (average_weeks_remaining + @average_weeks_left) / 2,
                   no_spots = no_spots + @part_no_spots
             where campaign_no = @campaign_no
               and media_product_id = @media_product_id
               and business_unit_id = @business_unit_id
             
             select @error = @@error
             if @error != 0
             begin
                raiserror ('Error Updating Part Values', 16, 1)
                return -100
             end
         end
         else if @count = 0
         begin 
         
            insert into #deferred_billing_campaigns (campaign_no, product_desc, confirmed_cost, deferred_amount, average_weeks_deferred, average_weeks_remaining, deferred_finyear_amt, no_spots, first_name, last_name, business_unit_id, business_unit_desc, media_product_id, media_product_desc, deferred_type)
                values(@campaign_no, @product_desc, @confirmed_cost, @part_deferred_amount, @part_average_weeks_deferred, @average_weeks_left, 0.0, @part_no_spots, @first_name, @last_name, @business_unit_id, @business_unit_desc, @media_product_id, @media_product_desc, 'Normal Deferred')

             select @error = @@error
             if @error != 0
             begin
                raiserror ('Error Inserting Part Values', 16, 1)
                return -100
             end
         end
    end
    fetch pre_part_deferred_csr into @campaign_no, @product_desc, @confirmed_cost, @part_deferred_amount, @part_average_weeks_deferred, @average_weeks_left, @part_no_spots, @first_name, @last_name, @business_unit_id, @business_unit_desc, @media_product_id, @media_product_desc
end

close pre_part_deferred_csr
deallocate pre_part_deferred_csr

 declare post_part_deferred_csr cursor static for 
  select fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         isnull(sum(convert(money, (cs.charge_rate * convert(numeric(10,6), 6 - datediff(dd, cs.screening_date, @cutoff_date)) / 7))),0),
         avg(datediff(wk, cs.billing_date, cs.screening_date)),
         avg(datediff(wk, @cutoff_date, cs.screening_date)),
         count(spot_id),
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
    from campaign_spot cs,
         film_campaign fc,
         sales_rep sr,
         business_unit bu,
         media_product mp,
         campaign_package cp
   where cs.screening_date <> cs.billing_date 
     and cs.campaign_no = fc.campaign_no
     and fc.rep_id = sr.rep_id
     and cs.screening_date < @cutoff_date
     and dateadd(dd, 6, cs.screening_date) > @cutoff_date
     and fc.campaign_no = cp.campaign_no
     and cp.package_id = cs.package_id
     and fc.business_unit_id = bu.business_unit_id 
     and cp.media_product_id = mp.media_product_id
     and (fc.campaign_no = @rpt_campaign_no 
      or @rpt_campaign_no = -1)
     and cs.screening_date is not null
     and cs.spot_status <> 'U'     
     and cs.charge_rate != 0
     and cs.spot_redirect is null
     and fc.campaign_status != 'P'
     and fc.campaign_status != 'X'
     and fc.campaign_status != 'Z'
group by fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
union
  select fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         isnull(sum(convert(money, (cs.charge_rate * convert(numeric(10,6), 6 - datediff(dd, cs.screening_date, @cutoff_date)) / 7))),0),
         avg(datediff(wk, cs.billing_date, cs.screening_date)),
         avg(datediff(wk, @cutoff_date, cs.screening_date)),
         count(spot_id),
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
    from cinelight_spot cs,
         film_campaign fc,
         sales_rep sr,
         business_unit bu,
         media_product mp,
         cinelight_package cp
   where cs.screening_date <> cs.billing_date 
     and cs.campaign_no = fc.campaign_no
     and fc.rep_id = sr.rep_id
     and cs.screening_date < @cutoff_date
     and dateadd(dd, 6, cs.screening_date) > @cutoff_date
     and fc.campaign_no = cp.campaign_no
     and cp.package_id = cs.package_id
     and fc.business_unit_id = bu.business_unit_id 
     and cp.media_product_id = mp.media_product_id
     and (fc.campaign_no = @rpt_campaign_no 
      or @rpt_campaign_no = -1)
     and cs.screening_date is not null
     and cs.spot_status <> 'U'     
     and cs.charge_rate != 0
     and fc.campaign_status != 'P'
     and fc.campaign_status != 'X'
     and fc.campaign_status != 'Z'
group by fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
union
  select fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         isnull(sum(convert(money, (cs.charge_rate * convert(numeric(10,6), 6 - datediff(dd, cs.screening_date, @cutoff_date)) / 7))),0),
         avg(datediff(wk, cs.billing_date, cs.screening_date)),
         avg(datediff(wk, @cutoff_date, cs.screening_date)),
         count(spot_id),
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         mp.media_product_id,
         mp.media_product_desc
    from inclusion_spot cs,
         film_campaign fc,
         sales_rep sr,
         business_unit bu,
         media_product mp,
         inclusion inc
   where cs.screening_date <> cs.billing_date 
     and cs.campaign_no = fc.campaign_no
     and fc.rep_id = sr.rep_id
     and cs.screening_date < @cutoff_date
     and dateadd(dd, 6, cs.billing_date) > @cutoff_date
     and fc.campaign_no = inc.campaign_no
     and inc.inclusion_id = cs.inclusion_id
     and fc.business_unit_id = bu.business_unit_id 
     and 6 = mp.media_product_id
     and cs.spot_status <> 'U'     
     and cs.screening_date is not null
     and (fc.campaign_no = @rpt_campaign_no 
      or @rpt_campaign_no = -1)
     and cs.charge_rate != 0
	 and inc.inclusion_type = 5
     and fc.campaign_status != 'P'
     and fc.campaign_status != 'X'
     and fc.campaign_status != 'Z'
group by fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         mp.media_product_id,
         mp.media_product_desc
order by fc.campaign_no
     for read only

open post_part_deferred_csr
fetch post_part_deferred_csr into @campaign_no, @product_desc, @confirmed_cost, @part_deferred_amount, @part_average_weeks_deferred, @average_weeks_left, @part_no_spots, @first_name, @last_name, @business_unit_id, @business_unit_desc, @media_product_id, @media_product_desc
while(@@fetch_status=0)
begin

    if @part_deferred_amount != 0
    begin

        select @count = count(campaign_no)
          from #deferred_billing_campaigns
         where campaign_no = @campaign_no
           and media_product_id = @media_product_id
           and business_unit_id = @business_unit_id
         
         if @count > 0
         begin
            update #deferred_billing_campaigns
               set deferred_amount = deferred_amount +  @part_deferred_amount,
                   average_weeks_deferred = (average_weeks_deferred + @part_average_weeks_deferred) / 2,
                   no_spots = no_spots + @part_no_spots
             where campaign_no = @campaign_no 
               and media_product_id = @media_product_id
               and business_unit_id = @business_unit_id
             
             select @error = @@error
             if @error != 0
             begin
                raiserror ('Error Updating Part Values', 16, 1)
                return -100
             end
         end
         else if @count = 0
         begin 
         
            insert into #deferred_billing_campaigns (campaign_no, product_desc, confirmed_cost, deferred_amount, average_weeks_deferred, average_weeks_remaining, deferred_finyear_amt, no_spots, first_name, last_name, business_unit_id, business_unit_desc, media_product_id, media_product_desc, deferred_type)
                values(@campaign_no, @product_desc, @confirmed_cost, @part_deferred_amount, @part_average_weeks_deferred, @average_weeks_left, 0.0, @part_no_spots, @first_name, @last_name, @business_unit_id, @business_unit_desc, @media_product_id, @media_product_desc, 'Normal Deferred')

             select @error = @@error
             if @error != 0
             begin
                raiserror ('Error Inserting Part Values', 16, 1)
                return -100
             end
         end
        end
    fetch post_part_deferred_csr into @campaign_no, @product_desc, @confirmed_cost, @part_deferred_amount, @part_average_weeks_deferred, @average_weeks_left, @part_no_spots, @first_name, @last_name, @business_unit_id, @business_unit_desc, @media_product_id, @media_product_desc
end

close post_part_deferred_csr
deallocate post_part_deferred_csr

/*
 * Add Part Deferred Amounts To The Main Amounts
 */

 declare dandc_deferred_csr cursor static for 
  select fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         isnull(sum(cs.charge_rate),0),
         0,
         0,
         count(spot_id),
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
    from campaign_spot cs,
         film_campaign fc,
         sales_rep sr,
         business_unit bu,
         media_product mp,
         campaign_package cp
   where cs.screening_date is null
     and cs.dandc = 'Y'
     and cs.campaign_no = fc.campaign_no
     and fc.rep_id = sr.rep_id
     and (fc.campaign_no = @rpt_campaign_no 
      or @rpt_campaign_no = -1)
     and fc.campaign_status <> 'X' 
     and fc.campaign_status <> 'Z'
     and cs.spot_status <> 'U'     
     and fc.campaign_no = cp.campaign_no
     and cp.package_id = cs.package_id
     and fc.business_unit_id = bu.business_unit_id 
     and cp.media_product_id = mp.media_product_id
     and fc.campaign_status != 'P'
     and dateadd(dd, 6, cs.billing_date) <= @cutoff_date
group by fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
union
  select fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         isnull(sum(cs.charge_rate),0),
         0,
         0,
         count(spot_id),
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
    from cinelight_spot cs,
         film_campaign fc,
         sales_rep sr,
         business_unit bu,
         media_product mp,
         cinelight_package cp
   where cs.screening_date is null
     and cs.dandc = 'Y'
     and cs.campaign_no = fc.campaign_no
     and fc.rep_id = sr.rep_id
     and (fc.campaign_no = @rpt_campaign_no 
      or @rpt_campaign_no = -1)
     and fc.campaign_status <> 'X' 
     and fc.campaign_status <> 'Z'
     and cs.spot_status <> 'U'     
     and fc.campaign_no = cp.campaign_no
     and cp.package_id = cs.package_id
     and fc.business_unit_id = bu.business_unit_id 
     and cp.media_product_id = mp.media_product_id
     and fc.campaign_status != 'P'
     and dateadd(dd, 6, cs.billing_date) <= @cutoff_date
group by fc.campaign_no,
         fc.product_desc,
         fc.confirmed_cost,
         sr.first_name,
         sr.last_name,
         fc.business_unit_id,
         bu.business_unit_desc,
         cp.media_product_id,
         mp.media_product_desc
order by fc.campaign_no
     for read only
     
open dandc_deferred_csr
fetch dandc_deferred_csr into @campaign_no, @product_desc, @confirmed_cost, @part_deferred_amount, @part_average_weeks_deferred, @average_weeks_left, @part_no_spots, @first_name, @last_name, @business_unit_id, @business_unit_desc, @media_product_id, @media_product_desc
while(@@fetch_status=0)
begin

	if @media_product_id = 1 or @media_product_id = 2
	begin
	    select @screened_dest_dandc_amount = isnull(sum(cs.makegood_rate),0)
	      from campaign_spot cs,
	           delete_charge_spots dcs,
	           delete_charge dc
	     where dc.confirmed = 'Y'
	       and dc.source_campaign = @campaign_no
	       and dc.delete_charge_id = dcs.delete_charge_id
	       and cs.spot_id = dcs.spot_id
	       and dcs.source_dest = 'D'
	       and dateadd(dd, 6, cs.billing_date) <= @cutoff_date
	       
	    select @error = @@error
	    if @error != 0
	    begin
	        raiserror ('Error Obtaining Screened D & C entitlements', 16, 1)
	        return -100
	    end
	end
	else if @media_product_id = 3
	begin
	    select @screened_dest_dandc_amount = isnull(sum(cs.makegood_rate),0)
	      from cinelight_spot cs,
	           delete_charge_spots dcs,
	           delete_charge dc
	     where dc.confirmed = 'Y'
	       and dc.source_campaign = @campaign_no
	       and dc.delete_charge_id = dcs.delete_charge_id
	       and cs.spot_id = dcs.spot_id
	       and dcs.source_dest = 'D'
	       and dateadd(dd, 6, cs.billing_date) <= @cutoff_date
	       
	    select @error = @@error
	    if @error != 0
	    begin
	        raiserror ('Error Obtaining Screened D & C entitlements', 16, 1)
	        return -100
	    end
	end

	       
    select @part_deferred_amount = @part_deferred_amount - @screened_dest_dandc_amount
    
    select @error = @@error
    if @error != 0
    begin
        raiserror ('Error Obtaining Screened D & C entitlements', 16, 1)
        return -100
    end
    
    if @part_deferred_amount <> 0
    begin       
        insert into #deferred_billing_campaigns (campaign_no, product_desc, confirmed_cost, deferred_amount, average_weeks_deferred, average_weeks_remaining, deferred_finyear_amt, no_spots, first_name, last_name, business_unit_id, business_unit_desc, media_product_id, media_product_desc, deferred_type)
            values(@campaign_no, @product_desc, @confirmed_cost, @part_deferred_amount, @part_average_weeks_deferred, @average_weeks_left, 0.0, @part_no_spots, @first_name, @last_name, @business_unit_id, @business_unit_desc, @media_product_id, @media_product_desc, 'Delete & Charge Deferred')

         select @error = @@error
         if @error != 0
         begin
            raiserror ('Error Inserting Part Values', 16, 1)
            return -100
         end
    end
    
    fetch dandc_deferred_csr into @campaign_no, @product_desc, @confirmed_cost, @part_deferred_amount, @part_average_weeks_deferred, @average_weeks_left, @part_no_spots, @first_name, @last_name, @business_unit_id, @business_unit_desc, @media_product_id, @media_product_desc
end

close dandc_deferred_csr
deallocate dandc_deferred_csr

     
 declare deferred_finyear_csr cursor static for
  select campaign_no,
         business_unit_id, 
         media_product_id
    from #deferred_billing_campaigns
group by campaign_no,
         business_unit_id, 
         media_product_id
order by campaign_no
     for read only    

open deferred_finyear_csr
fetch deferred_finyear_csr into @campaign_no, @business_unit_id, @media_product_id
while(@@fetch_status=0)
begin

    select @deferred_finyear_amt = 0

	if @media_product_id = 1 or @media_product_id = 2
	begin
	    select @deferred_finyear_amt = isnull(sum(cs.charge_rate),0)
	      from campaign_spot cs,
	           film_screening_dates screening_year,
	           film_screening_dates billing_year, 
	           campaign_package cp,
	           film_campaign fc
	      where cs.screening_date = screening_year.screening_date 
	        and cs.billing_date = billing_year.screening_date 
	        and cs.campaign_no = @campaign_no
	        and cs.billing_date <> cs.screening_date
	        and screening_year.finyear_end <> billing_year.finyear_end
	        and cs.screening_date >= @cutoff_date
	        and cp.media_product_id = @media_product_id
	        and fc.business_unit_id = @business_unit_id
	        and fc.campaign_no = cp.campaign_no
	        and cs.campaign_no = fc.campaign_no
	        and cp.package_id = cs.package_id
	        and cs.charge_rate != 0
	        and cs.spot_status != 'U'

	     select @error = @@error
	     if @error != 0
	     begin
	        raiserror ('Error Figuring Different Finyear Values', 16, 1)
	        return -100
	     end
	end
	else if @media_product_id = 3
	begin
	    select @deferred_finyear_amt = isnull(sum(cs.charge_rate),0)
	      from cinelight_spot cs,
	           film_screening_dates screening_year,
	           film_screening_dates billing_year, 
	           cinelight_package cp,
	           film_campaign fc
	      where cs.screening_date = screening_year.screening_date 
	        and cs.billing_date = billing_year.screening_date 
	        and cs.campaign_no = @campaign_no
	        and cs.billing_date <> cs.screening_date
	        and screening_year.finyear_end <> billing_year.finyear_end
	        and cs.screening_date >= @cutoff_date
	        and cp.media_product_id = @media_product_id
	        and fc.business_unit_id = @business_unit_id
	        and fc.campaign_no = cp.campaign_no
	        and cs.campaign_no = fc.campaign_no
	        and cp.package_id = cs.package_id
	        and cs.charge_rate != 0
	        and cs.spot_status != 'U'

	     select @error = @@error
	     if @error != 0
	     begin
	        raiserror ('Error Figuring Different Finyear Values', 16, 1)
	        return -100
	     end
	end
	        

    if @deferred_finyear_amt != 0 
    begin
        update #deferred_billing_campaigns 
           set deferred_finyear_amt = @deferred_finyear_amt
         where campaign_no = @campaign_no
           and media_product_id = @media_product_id
           and business_unit_id = @business_unit_id
       
         select @error = @@error
         if @error != 0
         begin
            raiserror ('Error Updating Different Finyear Values', 16, 1)
            return -100
         end
         
    end
    
    fetch deferred_finyear_csr into @campaign_no, @business_unit_id, @media_product_id
end

close deferred_finyear_csr
deallocate deferred_finyear_csr
     
         
select #deferred_billing_campaigns.campaign_no,
 #deferred_billing_campaigns.product_desc,
  #deferred_billing_campaigns.confirmed_cost,
   #deferred_billing_campaigns.deferred_amount,
    #deferred_billing_campaigns.average_weeks_deferred,
     #deferred_billing_campaigns.average_weeks_remaining,
      #deferred_billing_campaigns.no_spots,
       #deferred_billing_campaigns.deferred_finyear_amt,
        #deferred_billing_campaigns.first_name,
         #deferred_billing_campaigns.last_name,
          #deferred_billing_campaigns.business_unit_id,
           #deferred_billing_campaigns.business_unit_desc,
            #deferred_billing_campaigns.media_product_id,
             #deferred_billing_campaigns.media_product_desc,
              #deferred_billing_campaigns.deferred_type,
               country_code 
from #deferred_billing_campaigns, film_Campaign, branch 
where #deferred_billing_campaigns.campaign_no = film_campaign.campaign_no 
and film_campaign.branch_code = branch.branch_code  
order by business_unit_desc, media_product_desc, #deferred_billing_campaigns.campaign_no
return 0
GO
