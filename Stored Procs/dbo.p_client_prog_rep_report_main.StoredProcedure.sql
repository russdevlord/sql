/****** Object:  StoredProcedure [dbo].[p_client_prog_rep_report_main]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_client_prog_rep_report_main]
GO
/****** Object:  StoredProcedure [dbo].[p_client_prog_rep_report_main]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_client_prog_rep_report_main] 	@campaign_no		integer,
											@screening_date		datetime,
											@include_package	char(1)

as

declare 	@product_desc 	varchar(100)

/*
 * Return Dataset
 */

if @include_package = 'Y'
begin
	select	@screening_date,
			film_campaign.campaign_no,
			product_desc,
			rep_id,
			package_id,
			package_code,
			@include_package,
			(select count(distinct pack.package_id)
						       from campaign_spot spot,
						            campaign_package pack,
						            certificate_item ci,
						            certificate_group cg,
						            complex cplx
						      where spot.campaign_no = @campaign_no and
						            spot.package_id = pack.package_id and
						            spot.spot_id = ci.spot_reference and
						            ci.certificate_group = cg.certificate_group_id and
						            cg.complex_id = cplx.complex_id and
						            cg.screening_date = @screening_date and
						            spot.screening_date = @screening_date and
						            spot.spot_status != 'N') as package_count,
			(select max(distinct pack.package_code)
						       from campaign_spot spot,
						            campaign_package pack,
						            certificate_item ci,
						            certificate_group cg,
						            complex cplx
						      where spot.campaign_no = @campaign_no and
						            spot.package_id = pack.package_id and
						            spot.spot_id = ci.spot_reference and
						            ci.certificate_group = cg.certificate_group_id and
						            cg.complex_id = cplx.complex_id and
						            cg.screening_date = @screening_date and
						            spot.screening_date = @screening_date and
						            spot.spot_status != 'N') as max_package_code
	from	film_campaign,
			campaign_package
	where	campaign_package.campaign_no = film_campaign.campaign_no
	and		film_campaign.campaign_no = @campaign_no
	and		package_id in (select distinct pack.package_id
						       from campaign_spot spot,
						            campaign_package pack,
						            certificate_item ci,
						            certificate_group cg,
						            complex cplx
						      where spot.campaign_no = @campaign_no and
						            spot.package_id = pack.package_id and
						            spot.spot_id = ci.spot_reference and
						            ci.certificate_group = cg.certificate_group_id and
						            cg.complex_id = cplx.complex_id and
						            cg.screening_date = @screening_date and
						            spot.screening_date = @screening_date and
						            spot.spot_status != 'N')
end 
else if @include_package = 'N'
begin 
	select	@screening_date,
			film_campaign.campaign_no,
			product_desc,
			rep_id,
			-1,
			'',
			@include_package,
			0,
			''
	from	film_campaign
	where	film_campaign.campaign_no = @campaign_no
end
GO
