/****** Object:  StoredProcedure [dbo].[p_eom_consolidate_slide_rev]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_consolidate_slide_rev]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_consolidate_slide_rev]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_eom_consolidate_slide_rev]  @accounting_period      datetime

as

declare     @error                  int
         
/*
 * Begin Transaction
 */

begin transaction

delete slide_revenue 
 where accounting_period = @accounting_period


select @error = @@error
if @error <> 0
begin
    rollback transaction
    raiserror ('EOM - Failed to Delete Old Slide Revenue Data.', 16, 1)
    return -100
end


/*
 * Insert Collection Information into Slide Revenue Table
 */
 
insert into slide_revenue
         (campaign_no,
         complex_id,
         country_code,
         name_on_slide,
         accounting_period,
         origin_period,
         liability_type_id,
         currency_code,
         spot_amount,
         cinema_amount,
         media_product_id,
         business_unit_id,
         revenue_source)
  select rd.campaign_no,
         rd.complex_id,
         b.country_code,
         sc.name_on_slide,
         rdp.release_period,
         rdp.release_period,
         3,
         c.currency_code,
         -1 * sum(rdp.amount),
         -1 * sum(rdp.amount),
         5,
         1,
         'S'
    from rent_distribution_pool rdp,
         rent_distribution rd, 
         slide_campaign sc,   
         branch b,
         country c
   where rdp.release_period = @accounting_period and
         rdp.amount <> 0 and
         rdp.rent_distribution_id = rd.rent_distribution_id and
         rd.campaign_no = sc.campaign_no and
         sc.branch_code = b.branch_code and
         c.country_code = b.country_code
group by rd.campaign_no,
         rd.complex_id,
         b.country_code,
         sc.name_on_slide,
         rdp.release_period,
         rdp.release_period,
         c.currency_code
  having sum(rdp.amount) <> 0
order by b.country_code ASC,
         rd.complex_id ASC 
                  
select @error = @@error
if @error <> 0
begin
    rollback transaction
    raiserror ('EOM - Failed to Update Collection Info in Slide Revenue Table.', 16, 1)
    return -100
end
                 

/*
 * Insert Billing Information into Slide Revenue Table
 */

insert into slide_revenue
        (campaign_no,
         complex_id,
         country_code,
         name_on_slide,
         accounting_period,
         origin_period,
         liability_type_id,
         currency_code,
         spot_amount,
         cinema_amount,
         media_product_id,
         business_unit_id,
         revenue_source)
  select sc.campaign_no,
         ssp.complex_id,
         c.country_code,
         sc.name_on_slide,
         ssp.release_period,
         ssp.release_period,
         50,
         c.currency_code,
         sum(ssp.total_amount),
         sum(ssp.total_amount),
         5,
         1,
         'S'
    from slide_spot_pool ssp,
         slide_campaign_spot scs,
         slide_campaign sc,
         branch b,
         country c
   where ssp.release_period = @accounting_period and
         ssp.spot_id = scs.spot_id and
         scs.campaign_no = sc.campaign_no and
         sc.branch_code = b.branch_code and
         b.country_code = c.country_code
group by sc.campaign_no,
         ssp.complex_id,
         c.country_code,
         sc.name_on_slide,
         ssp.release_period,
         ssp.release_period,
         c.currency_code

select @error = @@error
if @error <> 0
begin
    rollback transaction
    raiserror ('EOM - Failed to Update Billing Info in Slide Revenue Table.', 16, 1)
    return -100
end


/*
 * Insert Production Billing Information into Slide Revenue Table
 */

insert into slide_revenue
        (campaign_no,
         complex_id,
         country_code,
         name_on_slide,
         accounting_period,
         origin_period,
         liability_type_id,
         currency_code,
         spot_amount,
         cinema_amount,
         media_product_id,
         business_unit_id,
         revenue_source)
  select sc.campaign_no,
         ssp.complex_id,
         c.country_code,
         sc.name_on_slide,
         ssp.release_period,
         ssp.release_period,
         96,
         c.currency_code,
         0 - sum(ssp.slide_amount),
         0 - sum(ssp.slide_amount),
         5,
         1,
         'S'
    from slide_spot_pool ssp,
         slide_campaign_spot scs,
         slide_campaign sc,
         branch b,
         country c
   where ssp.release_period = @accounting_period and
         ssp.spot_id = scs.spot_id and
         scs.campaign_no = sc.campaign_no and
         sc.branch_code = b.branch_code and
         b.country_code = c.country_code
group by sc.campaign_no,
         ssp.complex_id,
         c.country_code,
         sc.name_on_slide,
         ssp.release_period,
         ssp.release_period,
         c.currency_code

select @error = @@error
if @error <> 0
begin
    rollback transaction
    raiserror ('EOM - Failed to Update Billing Info in Slide Revenue Table.', 16, 1)
    return -100
end

/*
 * Insert Sound Billing Information into Slide Revenue Table
 */

insert into slide_revenue
        (campaign_no,
         complex_id,
         country_code,
         name_on_slide,
         accounting_period,
         origin_period,
         liability_type_id,
         currency_code,
         spot_amount,
         cinema_amount,
         media_product_id,
         business_unit_id,
         revenue_source)
  select sc.campaign_no,
         ssp.complex_id,
         c.country_code,
         sc.name_on_slide,
         ssp.release_period,
         ssp.release_period,
         97,
         c.currency_code,
         0 - sum(ssp.sound_amount),
         0 - sum(ssp.sound_amount),
         5,
         1,
         'S'
    from slide_spot_pool ssp,
         slide_campaign_spot scs,
         slide_campaign sc,
         branch b,
         country c
   where ssp.release_period = @accounting_period and
         ssp.spot_id = scs.spot_id and
         scs.campaign_no = sc.campaign_no and
         sc.branch_code = b.branch_code and
         b.country_code = c.country_code
group by sc.campaign_no,
         ssp.complex_id,
         c.country_code,
         sc.name_on_slide,
         ssp.release_period,
         ssp.release_period,
         c.currency_code

select @error = @@error
if @error <> 0
begin
    rollback transaction
    raiserror ('EOM - Failed to Update Billing Info in Slide Revenue Table.', 16, 1)
    return -100
end

/*
 * Commit Transaction And Return
 */

commit transaction
return 0
GO
