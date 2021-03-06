/****** Object:  StoredProcedure [dbo].[p_clientpack_prog_report_rep]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_clientpack_prog_report_rep]
GO
/****** Object:  StoredProcedure [dbo].[p_clientpack_prog_report_rep]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_clientpack_prog_report_rep] 	@campaign_no			integer,
													@screening_date		datetime, @arg_package_id int
    
as

declare  @product_desc varchar(100)

                                                       

select @product_desc = product_desc
  from film_campaign fc
 where campaign_no = @campaign_no

  select @screening_date as screening_date,
         @campaign_no as campaign_no,
         @product_desc as product_desc,
         pack.package_code,
         pack.package_desc,
         spot.spot_id,
         cplx.complex_name,
         cg.group_short_name,
         cg.group_name,
		 cplx.film_market_no,
		 ci.certificate_source,
         spot.spot_type
    from campaign_spot spot,
         campaign_package pack,
         certificate_item ci,
         certificate_group cg,
         complex cplx
   where spot.campaign_no = @campaign_no and
		 spot.package_id = pack.package_id and
         spot.spot_id = ci.spot_reference and
         ci.certificate_group = cg.certificate_group_id and
         cg.is_movie = 'Y' and
	 pack.package_id = @arg_package_id and
         cg.complex_id = cplx.complex_id and
         cg.screening_date = @screening_date and
         spot.screening_date = @screening_date and
            spot.spot_status != 'N'
group by pack.package_code,
         pack.package_desc,
         spot.spot_id,
         cplx.complex_name,
         cg.group_short_name,
         cg.group_name,
		 cplx.film_market_no,
		 ci.certificate_source,
         spot.spot_type
   union
  select @screening_date as screening_date,
         @campaign_no as campaign_no,
         @product_desc as product_desc,
         pack.package_code,
         pack.package_desc,
         spot.spot_id,
         cplx.complex_name,
         'Unknown',
         'Unknown',
		 cplx.film_market_no,
		 ci.certificate_source,
         spot.spot_type
    from campaign_spot spot,
         campaign_package pack,
         certificate_item ci,
         certificate_group cg,
         complex cplx
   where spot.campaign_no = @campaign_no and
		 spot.package_id = pack.package_id and
         spot.spot_id = ci.spot_reference and
         ci.certificate_group = cg.certificate_group_id and
         cg.is_movie = 'N' and
         cg.complex_id = cplx.complex_id and
	 pack.package_id = @arg_package_id and
         cg.screening_date = @screening_date and
         spot.screening_date = @screening_date and
            spot.spot_status != 'N'
group by pack.package_code,
         pack.package_desc,
         spot.spot_id,
         cplx.complex_name,
		 cplx.film_market_no,
		 ci.certificate_source,
         spot.spot_type
GO
