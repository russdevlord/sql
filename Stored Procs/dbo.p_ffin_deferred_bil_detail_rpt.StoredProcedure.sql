/****** Object:  StoredProcedure [dbo].[p_ffin_deferred_bil_detail_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_deferred_bil_detail_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_deferred_bil_detail_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_ffin_deferred_bil_detail_rpt] @campaign_no             int,
                                           @business_unit_id        int,
                                           @media_product_id        int,
                                           @cutoff_date             datetime

as

declare @error                          int,
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
        @branch_name                    varchar(50),
        @branch_code                    char(2),
        @no_spots                       int,
        @part_no_spots                  int,
        @spot_id                        int,
        @screened_dest_dandc_amount     money,
        @dandc_amount                   money,
        @dandc_percentage               numeric(10,4),
        @spot_status                    char(1),
        @spot_type                      char(1),
        @dandc                          char(1),
        @screening_date                 datetime,
        @billing_date                   datetime,
        @rowcount                       int
/*
 * Create Temporary Table
 */ 

create table #deferred_billing_spots
(
    spot_id                     int             null,
    film_market_no              int             null,
    film_market_desc            varchar(100)    null,
    complex_name                varchar(100)    null,
    billing_date                datetime        null,
    screening_date              datetime        null,
    charge_rate                 money           null,
    deferred_amount             money           null,
    weeks_deferred              int             null,
    weeks_remaining             int             null,
    deferred_finyear_amt        money           null,
    spot_status                 char(1)         null,
    spot_type                   char(1)         null,
    dandc                       char(1)         null
)

    

/*
 * Populate Temporary Table
 */
 
-- pre amounts 
insert into #deferred_billing_spots
  select cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         case spot_status when 'U' then null when 'N' then null else cs.screening_date end,
         cs.charge_rate,
         isnull(convert(money, (cs.charge_rate * convert(numeric(10,6), 1 + datediff(dd, cs.billing_date, @cutoff_date))  / 7.0)),0) as deferref_amount,
         datediff(wk, cs.billing_date, case spot_status when 'U' then null when 'N' then null else cs.screening_date end),
         datediff(wk, @cutoff_date, case spot_status when 'U' then null when 'N' then null else cs.screening_date end),
         0.0,
         cs.spot_status,
         cs.spot_type,
         cs.dandc
    from campaign_spot cs,
         complex cplx,
         film_market fm,
         film_campaign fc,
         campaign_package cp
   where cs.screening_date <> cs.billing_date 
     and cs.campaign_no = @campaign_no
     and cs.billing_date < @cutoff_date
     and dateadd(dd, 6, cs.billing_date) > @cutoff_date
     and fm.film_market_no = cplx.film_market_no
     and cs.complex_id = cplx.complex_id
     and cs.screening_date is not null
     and cp.package_id = cs.package_id 
     and fc.campaign_no = cp.campaign_no
     and fc.campaign_no = cs.campaign_no
     and cp.media_product_id = @media_product_id
     and fc.business_unit_id = @business_unit_id
     and cs.charge_rate != 0
     and cs.spot_redirect is null
     and cs.spot_status <> 'U'
group by cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         cs.screening_date,
         cs.charge_rate,
         isnull(convert(money, (cs.charge_rate * convert(numeric(10,6), 1 + datediff(dd, cs.billing_date, @cutoff_date))  / 7.0)),0),
         datediff(wk, cs.billing_date, cs.screening_date),
         datediff(wk, @cutoff_date, cs.screening_date),
         cs.spot_status,
         cs.spot_type,
         cs.dandc,
	     cp.media_product_id
union
  select cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         case spot_status when 'U' then null when 'N' then null else cs.screening_date end,
         cs.charge_rate,
         isnull(convert(money, (cs.charge_rate * convert(numeric(10,6), 1 + datediff(dd, cs.billing_date, @cutoff_date))  / 7.0)),0) as deferref_amount,
         datediff(wk, cs.billing_date, case spot_status when 'U' then null when 'N' then null else cs.screening_date end),
         datediff(wk, @cutoff_date, case spot_status when 'U' then null when 'N' then null else cs.screening_date end),
         0.0,
         cs.spot_status,
         cs.spot_type,
         cs.dandc
    from cinelight_spot cs,
		 cinelight cl,
         complex cplx,
         film_market fm,
         film_campaign fc,
         cinelight_package cp
   where cs.screening_date <> cs.billing_date 
     and cs.campaign_no = @campaign_no
     and cs.billing_date < @cutoff_date
     and dateadd(dd, 6, cs.billing_date) > @cutoff_date
     and fm.film_market_no = cplx.film_market_no
     and cs.cinelight_id = cl.cinelight_id
     and cl.complex_id = cplx.complex_id
     and cs.screening_date is not null
     and cp.package_id = cs.package_id 
     and fc.campaign_no = cp.campaign_no
     and fc.campaign_no = cs.campaign_no
     and cp.media_product_id = @media_product_id
     and fc.business_unit_id = @business_unit_id
     and cs.charge_rate != 0
     and cs.spot_status <> 'U'
group by cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         cs.screening_date,
         cs.charge_rate,
         isnull(convert(money, (cs.charge_rate * convert(numeric(10,6), 1 + datediff(dd, cs.billing_date, @cutoff_date))  / 7.0)),0),
         datediff(wk, cs.billing_date, cs.screening_date),
         datediff(wk, @cutoff_date, cs.screening_date),
         cs.spot_status,
         cs.spot_type,
         cs.dandc,
	     cp.media_product_id
union
  select cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         case spot_status when 'U' then null when 'N' then null else cs.screening_date end,
         cs.charge_rate,
         isnull(convert(money, (cs.charge_rate * convert(numeric(10,6), 1 + datediff(dd, cs.billing_date, @cutoff_date))  / 7.0)),0) as deferref_amount,
         datediff(wk, cs.billing_date, case spot_status when 'U' then null when 'N' then null else cs.screening_date end),
         datediff(wk, @cutoff_date, case spot_status when 'U' then null when 'N' then null else cs.screening_date end),
         0.0,
         cs.spot_status,
         cs.spot_type,
         cs.dandc
    from inclusion_spot cs,
         complex cplx,
         film_market fm,
         film_campaign fc,
         inclusion inc
   where cs.screening_date <> cs.billing_date 
     and cs.campaign_no = @campaign_no
     and cs.billing_date < @cutoff_date
     and dateadd(dd, 6, cs.billing_date) > @cutoff_date
     and fm.film_market_no = cplx.film_market_no
     and cs.complex_id = cplx.complex_id
     and cs.screening_date is not null
     and inc.inclusion_id = cs.inclusion_id 
     and fc.campaign_no = inc.campaign_no
     and fc.campaign_no = cs.campaign_no
     and 6 = @media_product_id
     and fc.business_unit_id = @business_unit_id
     and cs.charge_rate != 0
     and cs.spot_redirect is null
     and cs.spot_status <> 'U'
group by cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         cs.screening_date,
         cs.charge_rate,
         isnull(convert(money, (cs.charge_rate * convert(numeric(10,6), 1 + datediff(dd, cs.billing_date, @cutoff_date))  / 7.0)),0),
         datediff(wk, cs.billing_date, cs.screening_date),
         datediff(wk, @cutoff_date, cs.screening_date),
         cs.spot_status,
         cs.spot_type,
         cs.dandc
order by cplx.film_market_no,
         cplx.complex_name,
         cs.billing_date
         
select @rowcount = @@rowcount

-- post amounts  
insert into #deferred_billing_spots
  select cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         cs.screening_date,
         cs.charge_rate,
         isnull(convert(money, (cs.charge_rate * convert(numeric(10,6), 6 - datediff(dd, cs.screening_date, @cutoff_date)) / 7)),0),
         datediff(wk, cs.billing_date, cs.screening_date),
         datediff(wk, dateadd(dd, -6, @cutoff_date), cs.screening_date),
         0.0,
         cs.spot_status,
         cs.spot_type,
         cs.dandc
    from campaign_spot cs,
         complex cplx,
         film_market fm,
         film_campaign fc,
         campaign_package cp
   where cs.screening_date <> cs.billing_date 
     and cs.campaign_no = @campaign_no
     and cs.screening_date < @cutoff_date
     and dateadd(dd, 6, cs.screening_date) > @cutoff_date
     and fm.film_market_no = cplx.film_market_no
     and cs.complex_id = cplx.complex_id
     and cs.screening_date is not null
     and cp.package_id = cs.package_id 
     and fc.campaign_no = cp.campaign_no
     and fc.campaign_no = cs.campaign_no
     and cp.media_product_id = @media_product_id
     and fc.business_unit_id = @business_unit_id
     and cs.spot_status <> 'U'
     and cs.charge_rate != 0
     and cs.spot_redirect is null
group by cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         cs.screening_date,
         cs.charge_rate,
         isnull(convert(money, (cs.charge_rate * convert(numeric(10,6), 6 - datediff(dd, cs.screening_date, @cutoff_date)) / 7)),0),
         datediff(wk, cs.billing_date, cs.screening_date),
         datediff(wk, @cutoff_date, cs.screening_date),
         cs.spot_status,
         cs.spot_type,
         cs.dandc
union
  select cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         cs.screening_date,
         cs.charge_rate,
         isnull(convert(money, (cs.charge_rate * convert(numeric(10,6), 6 - datediff(dd, cs.screening_date, @cutoff_date)) / 7)),0),
         datediff(wk, cs.billing_date, cs.screening_date),
         datediff(wk, dateadd(dd, -6, @cutoff_date), cs.screening_date),
         0.0,
         cs.spot_status,
         cs.spot_type,
         cs.dandc
    from cinelight_spot cs,
		 cinelight cl,
         complex cplx,
         film_market fm,
         film_campaign fc,
         cinelight_package cp
   where cs.screening_date <> cs.billing_date 
     and cs.campaign_no = @campaign_no
     and cs.screening_date < @cutoff_date
     and dateadd(dd, 6, cs.screening_date) > @cutoff_date
     and fm.film_market_no = cplx.film_market_no
     and cs.cinelight_id = cl.cinelight_id
     and cl.complex_id = cplx.complex_id
     and cs.screening_date is not null
     and cp.package_id = cs.package_id 
     and fc.campaign_no = cp.campaign_no
     and fc.campaign_no = cs.campaign_no
     and cp.media_product_id = @media_product_id
     and fc.business_unit_id = @business_unit_id
     and cs.spot_status <> 'U'
     and cs.charge_rate != 0
group by cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         cs.screening_date,
         cs.charge_rate,
         isnull(convert(money, (cs.charge_rate * convert(numeric(10,6), 6 - datediff(dd, cs.screening_date, @cutoff_date)) / 7)),0),
         datediff(wk, cs.billing_date, cs.screening_date),
         datediff(wk, @cutoff_date, cs.screening_date),
         cs.spot_status,
         cs.spot_type,
         cs.dandc
union
  select cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         cs.screening_date,
         cs.charge_rate,
         isnull(convert(money, (cs.charge_rate * convert(numeric(10,6), 6 - datediff(dd, cs.screening_date, @cutoff_date)) / 7)),0),
         datediff(wk, cs.billing_date, cs.screening_date),
         datediff(wk, dateadd(dd, -6, @cutoff_date), cs.screening_date),
         0.0,
         cs.spot_status,
         cs.spot_type,
         cs.dandc
    from inclusion_spot cs,
         complex cplx,
         film_market fm,
         film_campaign fc,
         inclusion inc
   where cs.screening_date <> cs.billing_date 
     and cs.campaign_no = @campaign_no
     and cs.screening_date < @cutoff_date
     and dateadd(dd, 6, cs.screening_date) > @cutoff_date
     and fm.film_market_no = cplx.film_market_no
     and cs.complex_id = cplx.complex_id
     and cs.screening_date is not null
     and inc.inclusion_id = cs.inclusion_id
     and fc.campaign_no = inc.campaign_no
     and fc.campaign_no = cs.campaign_no
     and 6 = @media_product_id
     and fc.business_unit_id = @business_unit_id
     and cs.spot_status <> 'U'
     and cs.charge_rate != 0
     and cs.spot_redirect is null
group by cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         cs.screening_date,
         cs.charge_rate,
         isnull(convert(money, (cs.charge_rate * convert(numeric(10,6), 6 - datediff(dd, cs.screening_date, @cutoff_date)) / 7)),0),
         datediff(wk, cs.billing_date, cs.screening_date),
         datediff(wk, @cutoff_date, cs.screening_date),
         cs.spot_status,
         cs.spot_type,
         cs.dandc
order by cplx.film_market_no,
         cplx.complex_name,
         cs.billing_date

select @rowcount = @@rowcount

--full amount
insert into #deferred_billing_spots
  select cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         case spot_status when 'U' then null when 'N' then null else cs.screening_date end,
         cs.charge_rate,
         cs.charge_rate,
         datediff(wk, cs.billing_date, case spot_status when 'U' then null when 'N' then null else cs.screening_date end),
         datediff(wk, @cutoff_date, case spot_status when 'U' then null when 'N' then null else cs.screening_date end),
         0.0,
         cs.spot_status,
         cs.spot_type,
         cs.dandc
    from campaign_spot cs,
         complex cplx,
         film_market fm,
         film_campaign fc,
         campaign_package cp
   where cs.screening_date <> cs.billing_date 
     and fm.film_market_no = cplx.film_market_no
     and cs.campaign_no = @campaign_no
     and cs.complex_id = cplx.complex_id
     and cs.screening_date > @cutoff_date
     and dateadd(dd, 6, cs.billing_date) <= @cutoff_date
     and cs.screening_date is not null
     and cp.package_id = cs.package_id 
     and fc.campaign_no = cp.campaign_no
     and fc.campaign_no = cs.campaign_no
     and cp.media_product_id = @media_product_id
     and fc.business_unit_id = @business_unit_id
     and cs.charge_rate != 0
     and cs.spot_redirect is null
     and cs.spot_status <> 'U'
group by cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         cs.screening_date,
         cs.charge_rate,
         cs.charge_rate,
         datediff(wk, cs.billing_date, cs.screening_date),
         datediff(wk, @cutoff_date, cs.screening_date),
         cs.spot_status,
         cs.spot_type,
         cs.dandc
union
  select cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         case spot_status when 'U' then null when 'N' then null else cs.screening_date end,
         cs.charge_rate,
         cs.charge_rate,
         datediff(wk, cs.billing_date, case spot_status when 'U' then null when 'N' then null else cs.screening_date end),
         datediff(wk, @cutoff_date, case spot_status when 'U' then null when 'N' then null else cs.screening_date end),
         0.0,
         cs.spot_status,
         cs.spot_type,
         cs.dandc
    from cinelight_spot cs,
		 cinelight cl,
         complex cplx,
         film_market fm,
         film_campaign fc,
         cinelight_package cp
   where cs.screening_date <> cs.billing_date 
     and fm.film_market_no = cplx.film_market_no
     and cs.campaign_no = @campaign_no
     and cs.cinelight_id = cl.cinelight_id
     and cl.complex_id = cplx.complex_id
     and cs.screening_date > @cutoff_date
     and dateadd(dd, 6, cs.billing_date) <= @cutoff_date
     and cs.screening_date is not null
     and cp.package_id = cs.package_id 
     and fc.campaign_no = cp.campaign_no
     and fc.campaign_no = cs.campaign_no
     and cp.media_product_id = @media_product_id
     and fc.business_unit_id = @business_unit_id
     and cs.charge_rate != 0
     and cs.spot_status <> 'U'
group by cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         cs.screening_date,
         cs.charge_rate,
         cs.charge_rate,
         datediff(wk, cs.billing_date, cs.screening_date),
         datediff(wk, @cutoff_date, cs.screening_date),
         cs.spot_status,
         cs.spot_type,
         cs.dandc
union
  select cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         case spot_status when 'U' then null when 'N' then null else cs.screening_date end,
         cs.charge_rate,
         cs.charge_rate,
         datediff(wk, cs.billing_date, case spot_status when 'U' then null when 'N' then null else cs.screening_date end),
         datediff(wk, @cutoff_date, case spot_status when 'U' then null when 'N' then null else cs.screening_date end),
         0.0,
         cs.spot_status,
         cs.spot_type,
         cs.dandc
    from inclusion_spot cs,
         complex cplx,
         film_market fm,
         film_campaign fc,
         inclusion inc
   where cs.screening_date <> cs.billing_date 
     and fm.film_market_no = cplx.film_market_no
     and cs.campaign_no = @campaign_no
     and cs.complex_id = cplx.complex_id
     and cs.screening_date > @cutoff_date
     and dateadd(dd, 6, cs.billing_date) <= @cutoff_date
     and cs.screening_date is not null
     and inc.inclusion_id = cs.inclusion_id
     and fc.campaign_no = inc.campaign_no
     and fc.campaign_no = cs.campaign_no
     and 6 = @media_product_id
     and fc.business_unit_id = @business_unit_id
     and cs.charge_rate != 0
     and cs.spot_redirect is null
     and cs.spot_status <> 'U'
group by cs.spot_id,
         cplx.film_market_no,
         fm.film_market_desc,
         cplx.complex_name,
         cs.billing_date,
         cs.screening_date,
         cs.charge_rate,
         cs.charge_rate,
         datediff(wk, cs.billing_date, cs.screening_date),
         datediff(wk, @cutoff_date, cs.screening_date),
         cs.spot_status,
         cs.spot_type,
         cs.dandc
order by cplx.film_market_no,
         cplx.complex_name,
         cs.billing_date

select @rowcount = @@rowcount

  select @screened_dest_dandc_amount = isnull(sum(cs.makegood_rate),0)
    from campaign_spot cs,
         delete_charge_spots dcs,
         delete_charge dc,
         film_campaign fc,
         campaign_package cp
   where dc.confirmed = 'Y'
     and dc.source_campaign = @campaign_no
     and dc.delete_charge_id = dcs.delete_charge_id
     and cs.spot_id = dcs.spot_id
     and dcs.source_dest = 'D'
     and cs.onscreen = 'Y'
     and cp.package_id = cs.package_id 
     and fc.campaign_no = cp.campaign_no
     and fc.campaign_no = cs.campaign_no
     and cp.media_product_id = @media_product_id
     and fc.business_unit_id = @business_unit_id

        
     select @error = @@error
     if @error != 0
     begin
        raiserror ('Error Figuring Different Finyear Values', 16, 1)
        return -100
     end
     
  select @screened_dest_dandc_amount = isnull(@screened_dest_dandc_amount,0) + isnull(sum(cs.makegood_rate),0)
    from cinelight_spot cs,
         delete_charge_cinelight_spots dcs,
         delete_charge dc,
         film_campaign fc,
         cinelight_package cp
   where dc.confirmed = 'Y'
     and dc.source_campaign = @campaign_no
     and dc.delete_charge_id = dcs.delete_charge_id
     and cs.spot_id = dcs.spot_id
     and dcs.source_dest = 'D'
     and cs.spot_status = 'X'
     and cp.package_id = cs.package_id 
     and fc.campaign_no = cp.campaign_no
     and fc.campaign_no = cs.campaign_no
     and cp.media_product_id = @media_product_id
     and fc.business_unit_id = @business_unit_id

        
     select @error = @@error
     if @error != 0
     begin
        raiserror ('Error Figuring Different Finyear Values', 16, 1)
        return -100
     end

  select @dandc_amount = isnull(sum(cs.charge_rate),0)
    from campaign_spot cs,
         film_campaign fc,
         campaign_package cp
   where cs.campaign_no = @campaign_no
     and cs.screening_date is null
     and cs.dandc = 'Y'
     and cp.package_id = cs.package_id 
     and fc.campaign_no = cp.campaign_no
     and fc.campaign_no = cs.campaign_no
     and cp.media_product_id = @media_product_id
     and fc.business_unit_id = @business_unit_id

     select @error = @@error
     if @error != 0
     begin
        raiserror ('Error Figuring Different Finyear Values', 16, 1)
        return -100
     end

  select @dandc_amount = isnull(@dandc_amount,0) +  isnull(sum(cs.charge_rate),0)
    from cinelight_spot cs,
         film_campaign fc,
         cinelight_package cp
   where cs.campaign_no = @campaign_no
     and cs.screening_date is null
     and cs.dandc = 'Y'
     and cp.package_id = cs.package_id 
     and fc.campaign_no = cp.campaign_no
     and fc.campaign_no = cs.campaign_no
     and cp.media_product_id = @media_product_id
     and fc.business_unit_id = @business_unit_id

     select @error = @@error
     if @error != 0
     begin
        raiserror ('Error Figuring Different Finyear Values', 16, 1)
        return -100
     end

if @dandc_amount = 0
    select @dandc_percentage = 0
else if @screened_dest_dandc_amount = 0
    select @dandc_percentage = 1
else
    select  @dandc_percentage = @screened_dest_dandc_amount / @dandc_amount
     
select @dandc_amount = @dandc_amount - @screened_dest_dandc_amount

if @dandc_amount != 0
begin
    --  D & C Amounts
    insert into #deferred_billing_spots
      select cs.spot_id,
             cplx.film_market_no,
             fm.film_market_desc,
             cplx.complex_name,
             cs.billing_date,
             cs.screening_date,
             cs.charge_rate,
             cs.charge_rate * @dandc_percentage,
             0,
             0,
             0.0,
             cs.spot_status,
             cs.spot_type,
             cs.dandc
        from campaign_spot cs,
             complex cplx,
             film_market fm,
             film_campaign fc,
             campaign_package cp
       where fm.film_market_no = cplx.film_market_no
         and cs.campaign_no = @campaign_no
         and cs.complex_id = cplx.complex_id
         and cs.screening_date is null
         and cs.dandc = 'Y'
         and cp.package_id = cs.package_id 
         and fc.campaign_no = cp.campaign_no
         and fc.campaign_no = cs.campaign_no
         and cp.media_product_id = @media_product_id
         and fc.business_unit_id = @business_unit_id
         and dateadd(dd, 6, cs.billing_date) <= @cutoff_date
    group by cs.spot_id,
             cplx.film_market_no,
             fm.film_market_desc,
             cplx.complex_name,
             cs.billing_date,
             cs.screening_date,
             cs.charge_rate,
             cs.spot_status,
             cs.spot_type,
             cs.dandc
	union
      select cs.spot_id,
             cplx.film_market_no,
             fm.film_market_desc,
             cplx.complex_name,
             cs.billing_date,
             cs.screening_date,
             cs.charge_rate,
             cs.charge_rate * @dandc_percentage,
             0,
             0,
             0.0,
             cs.spot_status,
             cs.spot_type,
             cs.dandc
        from cinelight_spot cs,
			 cinelight cl,
             complex cplx,
             film_market fm,
             film_campaign fc,
             cinelight_package cp
       where fm.film_market_no = cplx.film_market_no
         and cs.campaign_no = @campaign_no
         and cs.cinelight_id = cl.cinelight_id
         and cl.complex_id = cplx.complex_id
         and cs.screening_date is null
         and cs.dandc = 'Y'
         and cp.package_id = cs.package_id 
         and fc.campaign_no = cp.campaign_no
         and fc.campaign_no = cs.campaign_no
         and cp.media_product_id = @media_product_id
         and fc.business_unit_id = @business_unit_id
         and dateadd(dd, 6, cs.billing_date) <= @cutoff_date
    group by cs.spot_id,
             cplx.film_market_no,
             fm.film_market_desc,
             cplx.complex_name,
             cs.billing_date,
             cs.screening_date,
             cs.charge_rate,
             cs.spot_status,
             cs.spot_type,
             cs.dandc
    order by cplx.film_market_no,
             cplx.complex_name,
             cs.billing_date


    select @error = @@error
    if @error != 0
    begin
        raiserror ('Error Inserting D & C Values', 16, 1)
        return -100
    end
end

/*
 * Declare Cursor
 */
 
 declare deferred_finyear_csr cursor static for
  select spot_id,
         billing_date,
         screening_date
    from #deferred_billing_spots
group by spot_id,
         billing_date,
         screening_date
order by spot_id
     for read only

/*
 * Add Part Deferred Amounts To The Main Amounts
 */
 
open deferred_finyear_csr
fetch deferred_finyear_csr into @spot_id, @billing_date, @screening_date
while(@@fetch_status=0)
begin

	if @media_product_id = 3 
	begin
		select 	@deferred_finyear_amt = isnull(sum(cs.charge_rate),0)
		from 	cinelight_spot cs,
				film_screening_dates screening_year,
				film_screening_dates billing_year
		where 	@screening_date = screening_year.screening_date 
		and 	@billing_date = billing_year.screening_date 
		and 	cs.spot_id = @spot_id
		and 	screening_year.finyear_end <> billing_year.finyear_end
		and 	cs.spot_status != 'U'
         
        
		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error Figuring Different Finyear Values', 16, 1)
			return -100
		end
	end
	else
	begin
		select 	@deferred_finyear_amt = isnull(sum(cs.charge_rate),0)
		from 	campaign_spot cs,
				film_screening_dates screening_year,
				film_screening_dates billing_year
		where 	@screening_date = screening_year.screening_date 
		and 	@billing_date = billing_year.screening_date 
		and 	cs.spot_id = @spot_id
		and 	screening_year.finyear_end <> billing_year.finyear_end
		and 	cs.spot_status != 'U'
         
        
		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error Figuring Different Finyear Values', 16, 1)
			return -100
		end
	end

    if @deferred_finyear_amt <> 0 
    begin
        update #deferred_billing_spots 
           set deferred_finyear_amt = @deferred_finyear_amt
         where spot_id = @spot_id
       
         select @error = @@error
         if @error != 0
         begin
            raiserror ('Error Updating Different Finyear Values', 16, 1)
            return -100
         end
         
    end
    
    
    fetch deferred_finyear_csr into @spot_id, @billing_date, @screening_date
end

close deferred_finyear_csr
deallocate deferred_finyear_csr
     
         
select #deferred_billing_spots.spot_id, #deferred_billing_spots.film_market_no, #deferred_billing_spots.film_market_desc, #deferred_billing_spots.complex_name, #deferred_billing_spots.billing_date, #deferred_billing_spots.screening_date, #deferred_billing_spots.charge_rate, #deferred_billing_spots.deferred_amount, #deferred_billing_spots.weeks_deferred, #deferred_billing_spots.weeks_remaining, #deferred_billing_spots.deferred_finyear_amt, #deferred_billing_spots.spot_status, #deferred_billing_spots.spot_type, #deferred_billing_spots.dandc from #deferred_billing_spots  order by film_market_no, complex_name, billing_date
return 0
GO
