/****** Object:  StoredProcedure [dbo].[p_eom_con_film_revenue_creation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_con_film_revenue_creation]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_con_film_revenue_creation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_eom_con_film_revenue_creation]  @accounting_period      datetime

as

declare @error                  int

/*
 * Begin Transaction
 */

begin transaction

delete film_revenue_creation 
 where accounting_period = @accounting_period

select @error = @@error
if @error <> 0
begin
    rollback transaction
    raiserror ('EOM - Failed to Delete Old Film Revenue Data.', 16, 1)
    return -100
end

/*
 * Insert Onscreen Rows into Film Revenue Table
 */
 
insert into film_revenue_creation
        (campaign_no,
         complex_id,
         business_unit_id,
         media_product_id,
         country_code,
         product_desc,
         accounting_period,
         liability_type_id,
         currency_code,
         spot_amount,
         cinema_amount,
         revenue_source   )
  select spot.campaign_no,
         sl.complex_id,
         fc.business_unit_id,
         cp.media_product_id,         
         c.country_code,
         fc.product_desc,
         sl.creation_period,
         sl.liability_type,
         c.currency_code,
         isnull(sum(sl.spot_amount),0),
         isnull(sum(sl.cinema_amount),0),
         cp.revenue_source
    from campaign_spot spot,
         spot_liability sl,
         film_campaign fc,
         branch b,
         country c,
         campaign_package cp
   where sl.spot_id = spot.spot_id
     and fc.campaign_no = spot.campaign_no
     and sl.creation_period = @accounting_period
     and b.branch_code = fc.branch_code
     and c.country_code = b.country_code
     and spot.package_id = cp.package_id
     and cp.campaign_no = fc.campaign_no
     and spot.campaign_no = cp.campaign_no     
        --and fc.campaign_type < 5  
group by spot.campaign_no,
         sl.complex_id,
         fc.business_unit_id,
         cp.media_product_id,         
         c.country_code,
         fc.product_desc,
         sl.creation_period,
         sl.liability_type,
         c.currency_code,
         cp.revenue_source
         
select @error = @@error
if @error <> 0
begin
    rollback transaction
    raiserror ('EOM - Failed to Update Film Revenue Table.', 16, 1)
    return -100
end

/*
 * Insert Cinelight Rows into Film Revenue Table
 */

insert into film_revenue_creation
        (campaign_no,
         complex_id,
         business_unit_id,
         media_product_id,
         country_code,
         product_desc,
         accounting_period,
         liability_type_id,
         currency_code,
         spot_amount,
         cinema_amount,
         revenue_source   )
  select spot.campaign_no,
         sl.complex_id,
         fc.business_unit_id,
         cp.media_product_id,         
         c.country_code,
         fc.product_desc,
         sl.creation_period,
         sl.liability_type,
         c.currency_code,
         isnull(sum(sl.spot_amount),0),
         isnull(sum(sl.cinema_amount),0),
         cp.revenue_source
    from cinelight_spot spot,
         cinelight_spot_liability sl,
         film_campaign fc,
         branch b,
         country c,
         cinelight_package cp
   where sl.spot_id = spot.spot_id
     and fc.campaign_no = spot.campaign_no
     and sl.creation_period = @accounting_period
     and b.branch_code = fc.branch_code
     and c.country_code = b.country_code
     and spot.package_id = cp.package_id
     and cp.campaign_no = fc.campaign_no
     and spot.campaign_no = cp.campaign_no     
        --and fc.campaign_type < 5  
group by spot.campaign_no,
         sl.complex_id,
         fc.business_unit_id,
         cp.media_product_id,         
         c.country_code,
         fc.product_desc,
         sl.creation_period,
         sl.liability_type,
         c.currency_code,
         cp.revenue_source
         
select @error = @@error
if @error <> 0
begin
    rollback transaction
    raiserror ('EOM - Failed to Update Film Revenue Table.', 16, 1)
    return -100
end

/*
 * Insert Cinemarketing Rows into Film Revenue Table
 */

insert into film_revenue_creation
        (campaign_no,
         complex_id,
         business_unit_id,
         media_product_id,
         country_code,
         product_desc,
         accounting_period,
         liability_type_id,
         currency_code,
         spot_amount,
         cinema_amount,
         revenue_source   )
  select spot.campaign_no,
         sl.complex_id,
         fc.business_unit_id,
         inc_typ.media_product_id,         
         c.country_code,
         fc.product_desc,
         sl.creation_period,
         sl.liability_type,
         c.currency_code,
         isnull(sum(sl.spot_amount),0),
         isnull(sum(sl.cinema_amount),0),
         mp.revenue_source
    from inclusion_spot spot,
         inclusion_spot_liability sl,
         film_campaign fc,
         branch b,
         country c,
         inclusion inc,
		 inclusion_type inc_typ,
		 media_product mp
   where sl.spot_id = spot.spot_id
     and fc.campaign_no = spot.campaign_no
     and sl.creation_period = @accounting_period
     and b.branch_code = fc.branch_code
     and c.country_code = b.country_code
     and spot.inclusion_id = inc.inclusion_id
     and inc.campaign_no = fc.campaign_no
     and spot.campaign_no = inc.campaign_no     
	 and mp.media_product_id = inc_typ.media_product_id
	 and inc_typ.inclusion_type = inc.inclusion_type
	 and inc_typ.inclusion_type  = 5
	    --and fc.campaign_type < 5  
group by spot.campaign_no,
         sl.complex_id,
         fc.business_unit_id,
         inc_typ.media_product_id,         
         c.country_code,
         fc.product_desc,
         sl.creation_period,
         sl.liability_type,
         c.currency_code,
         mp.revenue_source
         
select @error = @@error
if @error <> 0
begin
    rollback transaction
    raiserror ('EOM - Failed to Update Film Revenue Table.', 16, 1)
    return -100
end

/*
 * Commit Transaction And Return
 */

commit transaction
return 0
GO
