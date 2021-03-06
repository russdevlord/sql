/****** Object:  View [dbo].[v_adam2]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_adam2]
GO
/****** Object:  View [dbo].[v_adam2]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_adam2]
as
select fc.campaign_no as 'Campaign_no',
       fc.product_desc as 'Product_desc',
       fprint.print_id as 'Print_Id',
       fprint.print_name as 'Print_Desc',
       fprint.duration as 'Print_Duration',
       c.complex_id as 'Comlpex_Id',
       c.complex_name as 'Complex_Name',
       spot.billing_date as 'Billing_Date',
       sum(spot.charge_rate)as 'Media_Cost',
       count(spot.spot_id) as 'Spot_Count'
  from film_campaign fc,
       campaign_spot spot,
       campaign_package pack,
       complex c,
       print_package pp,
       film_print fprint,
       film_screening_dates fsd
 where fc.campaign_no = spot.campaign_no and
       fc.campaign_status <> "P" and
       fc.branch_code <> "Z" and
       spot.spot_status <> "P" and
--     spot.charge_rate <> 0 and
       spot.spot_type not in ("M","D","V") and
       spot.complex_id = c.complex_id and
       spot.package_id = pack.package_id and
       pack.package_id = pp.package_id and
       pp.print_id = fprint.print_id and
       fc.start_date >= "1-DEC-2003" and
       fc.start_date <= "30-NOV-2004" and
       spot.billing_date = fsd.screening_date and
       spot.screening_date is null
group by fc.campaign_no,
         fc.product_desc,
         fprint.print_id,
         fprint.print_name,
         fprint.duration,
         c.complex_id,
         c.complex_name,
         spot.billing_date
GO
