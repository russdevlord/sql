/****** Object:  StoredProcedure [dbo].[p_wk_rpt_cpm_report_sub]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_wk_rpt_cpm_report_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_wk_rpt_cpm_report_sub]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_wk_rpt_cpm_report_sub]	@spot_type			varchar(100),
                                    @start_date			datetime,
                                    @end_date			datetime,
                                    @mode				char(1),
                                    @mode_id			int,
                                    @country_code		char(1),
                                    @regional_indicator	char(1),
                                    @cpm                money OUTPUT,
                                    @impacts            int OUTPUT

as 

declare		@error				int

select 	@cpm = isnull(sum(cs.charge_rate) / sum( mh.attendance) * 1000,0),
		@impacts = isnull(sum(mh.attendance),0)
from	v_spots_redirected_xref cs,
		film_campaign fc,
		campaign_package cp,
		branch b,
		complex,
		complex_region_class,
		v_certificate_item_distinct v_cert,
		movie_history mh
where	cs.campaign_no = fc.campaign_no
and		cs.package_id = cp.package_id
and		fc.branch_code = b.branch_code
and		b.country_code = @country_code
and		cs.billing_date <= @end_date
and		cs.billing_date >=  @start_date
and		cs.complex_id = complex.complex_id
and		complex_region_class.complex_region_class = complex.complex_region_class
and		complex_region_class.regional_indicator = @regional_indicator
and		cs.spot_id = v_cert.spot_reference
and		mh.certificate_group = v_cert.certificate_group
and		mh.attendance <> 0
and    	((@spot_type != 'All'
and		cs.spot_type = @spot_type)
or		(@spot_type = 'All'
and		cs.spot_type in ('S','B','C','N')))
and 	cs.spot_status != 'P'
and		((@mode = 'B'
and		fc.business_unit_id = @mode_id)
or		(@mode = 'M'
and		cp.media_product_id = @mode_id))

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could not determine Avg/Count of spots.', 16, 1)
	return -1
end


return 0
GO
