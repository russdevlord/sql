/****** Object:  StoredProcedure [dbo].[p_client_programming_report_mkt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_client_programming_report_mkt]
GO
/****** Object:  StoredProcedure [dbo].[p_client_programming_report_mkt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_client_programming_report_mkt] 	@film_campaign_program_id		integer,
                                                @screening_date					datetime,
                                                @package_id						integer,
                                                @film_market_no                 integer
    
as

declare @campaign_no	integer,
        @product_desc   varchar(100)

/*
 * Retrieve the client programming information
 */

select @campaign_no = fcp.campaign_no
  from film_campaign_program fcp
 where fcp.film_campaign_program_id = @film_campaign_program_id

select @product_desc = product_desc
  from film_campaign fc
 where campaign_no = @campaign_no

	/*
	 * Return Dataset
	 */

    select @screening_date as screening_date,
            @campaign_no as campaign_no,
            @product_desc as product_desc,
            pack.package_code,
            pack.package_desc,
            spot.spot_id,
            cplx.complex_name,
            cg.group_short_name,
            cg.group_name,
            cplx.film_market_no
       from campaign_spot spot,
            campaign_package pack,
            certificate_item ci,
            certificate_group cg,
            complex cplx
      where spot.campaign_no = @campaign_no and
            spot.package_id = pack.package_id and
            spot.spot_id = ci.spot_reference and
            (pack.package_id = @package_id or
			@package_id = -1) and
            ci.certificate_group = cg.certificate_group_id and
            cg.is_movie = 'Y' and
            cg.complex_id = cplx.complex_id and
            cg.screening_date = @screening_date and
            spot.screening_date = @screening_date and
            spot.spot_status != 'N' and
            cplx.film_market_no = @film_market_no
  group by  pack.package_code,
            pack.package_desc,
            spot.spot_id,
            cplx.complex_name,
            cg.group_short_name,
            cg.group_name,
            cplx.film_market_no
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
            cplx.film_market_no
       from campaign_spot spot,
            campaign_package pack,
            certificate_item ci,
            certificate_group cg,
            complex cplx
      where spot.campaign_no = @campaign_no and
            spot.package_id = pack.package_id and
            spot.spot_id = ci.spot_reference and
            (pack.package_id = @package_id or
			@package_id = -1) and
            ci.certificate_group = cg.certificate_group_id and
            cg.is_movie = 'N' and
            cg.complex_id = cplx.complex_id and
            cg.screening_date = @screening_date and
            spot.screening_date = @screening_date and
            spot.spot_status != 'N' and
            cplx.film_market_no = @film_market_no
  group by  pack.package_code,
            pack.package_desc,
            spot.spot_id,
            cplx.complex_name,
            cplx.film_market_no
GO
