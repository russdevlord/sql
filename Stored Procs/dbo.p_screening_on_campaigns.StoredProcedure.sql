/****** Object:  StoredProcedure [dbo].[p_screening_on_campaigns]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_screening_on_campaigns]
GO
/****** Object:  StoredProcedure [dbo].[p_screening_on_campaigns]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_screening_on_campaigns] 	@screening_date			datetime,
										@business_unit_id		int
as

set nocount on 

declare 		@campaign_no			integer,
				@standby_campaign_no	integer,
				@product_desc			varchar(100),
				@rep_id					integer,
				@first_name				varchar(30),
				@last_name				varchar(30),
				@start_date				datetime,
				@end_date				datetime,
				@campaign_status		char(1),
				@campaign_type			integer,
				@campaign_cost			decimal,
				@campaign_value		decimal,
				@no_screens				integer

if @business_unit_id = -1 
begin
  select 	fc.campaign_no ,
			max(fc.product_desc),
			fc.rep_id ,
			max(rep.first_name),
			max(rep.last_name),
			min(fc.start_date),
			max(fc.end_date),
			max(fc.campaign_status),
			max(fc.campaign_type),
			max(fc.confirmed_cost),
			max(fc.confirmed_value),
			count(spot.spot_id) as no_screens,
			max(spot.screening_date),
			pack.package_code,
			pack.package_desc,
			fc.business_unit_id
	 from 	film_campaign fc ,
			campaign_spot spot ,
			sales_rep rep,
			campaign_package pack     
	where 	fc.rep_id = rep.rep_id and
			spot.spot_status <> 'P' and 
			spot.screening_date = @screening_date and
			spot.campaign_no = fc.campaign_no and
			spot.package_id = pack.package_id and
			spot.campaign_no = pack.campaign_no and
			fc.campaign_no = pack.campaign_no
group by 	fc.campaign_no ,
			fc.product_desc,
			fc.rep_id,
			pack.package_code,
			pack.package_desc,
			fc.business_unit_id


union all

  select 	fc.campaign_no ,
			max(fc.product_desc),
			fc.rep_id ,
			max(rep.first_name),
			max(rep.last_name),
			min(fc.start_date),
			max(fc.end_date),
			max(fc.campaign_status),
			max(fc.campaign_type),
			max(fc.confirmed_cost),
			max(fc.confirmed_value),
			count(fpc.max_screens) as no_screens,
			max(fpd.screening_date),
			pack.package_code,
			pack.package_desc,
			fc.business_unit_id
    from 	film_campaign fc,
			film_plan fp,
			film_plan_dates fpd,
			film_plan_complex fpc,
			sales_rep rep,
			campaign_package pack
	where 	fc.rep_id = rep.rep_id and
			fpd.screening_date = @screening_date and
			fp.campaign_no = fc.campaign_no and
			fp.film_plan_id = fpd.film_plan_id and
			fp.film_plan_id = fpc.film_plan_id and
			fp.package_id = pack.package_id and
			fc.campaign_no = pack.campaign_no and 
			pack.campaign_no = fp.campaign_no
group by 	fc.campaign_no ,
			fc.product_desc,
			fc.rep_id,
			pack.package_code,
			pack.package_desc,
			fc.business_unit_id
end
else
begin
 select 	fc.campaign_no ,
			max(fc.product_desc),
			fc.rep_id ,
			max(rep.first_name),
			max(rep.last_name),
			min(fc.start_date),
			max(fc.end_date),
			max(fc.campaign_status),
			max(fc.campaign_type),
			max(fc.confirmed_cost),
			max(fc.confirmed_value),
			count(spot.spot_id) as no_screens,
			max(spot.screening_date),
			pack.package_code,
			pack.package_desc,
			fc.business_unit_id
	 from 	film_campaign fc ,
			campaign_spot spot ,
			sales_rep rep,
			campaign_package pack     
	where 	fc.rep_id = rep.rep_id and
			spot.spot_status <> 'P' and 
			spot.screening_date = @screening_date and
			spot.campaign_no = fc.campaign_no and
			spot.package_id = pack.package_id and
			spot.campaign_no = pack.campaign_no and
			fc.campaign_no = pack.campaign_no and
			fc.business_unit_id = @business_unit_id
group by 	fc.campaign_no ,
			fc.product_desc,
			fc.rep_id,
			pack.package_code,
			pack.package_desc,
			fc.business_unit_id
union all
  select 	fc.campaign_no ,
			max(fc.product_desc),
			fc.rep_id ,
			max(rep.first_name),
			max(rep.last_name),
			min(fc.start_date),
			max(fc.end_date),
			max(fc.campaign_status),
			max(fc.campaign_type),
			max(fc.confirmed_cost),
			max(fc.confirmed_value),
			count(fpc.max_screens) as no_screens,
			max(fpd.screening_date),
			pack.package_code,
			pack.package_desc,
			fc.business_unit_id
    from 	film_campaign fc,
			film_plan fp,
			film_plan_dates fpd,
			film_plan_complex fpc,
			sales_rep rep,
			campaign_package pack
	where 	fc.rep_id = rep.rep_id and
			fpd.screening_date = @screening_date and
			fp.campaign_no = fc.campaign_no and
			fp.film_plan_id = fpd.film_plan_id and
			fp.film_plan_id = fpc.film_plan_id and
			fp.package_id = pack.package_id and
			fc.campaign_no = pack.campaign_no and 
			pack.campaign_no = fp.campaign_no and
			fc.business_unit_id = @business_unit_id
group by fc.campaign_no ,
			fc.product_desc,
			fc.rep_id,
			pack.package_code,
			pack.package_desc,
			fc.business_unit_id
end

return 0
GO
