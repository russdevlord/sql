/****** Object:  UserDefinedFunction [dbo].[f_wk_rpt_avg_rate_count]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_wk_rpt_avg_rate_count]
GO
/****** Object:  UserDefinedFunction [dbo].[f_wk_rpt_avg_rate_count]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[f_wk_rpt_avg_rate_count] (@spot_type as varchar(100), @start_date as datetime, @end_date as datetime, @mode as char(1), @mode_id as int, @country_code as char(2))
RETURNS int
AS
BEGIN

declare		@error				int,
			@count				int

select 	@count = isnull(count(cs.charge_rate),0)
from	campaign_spot cs,
		film_campaign fc,
		campaign_package cp,
		branch b
where	cs.campaign_no = fc.campaign_no
and		cs.package_id = cp.package_id
and		fc.branch_code = b.branch_code
and		b.country_code = @country_code
and		cs.billing_date <= @end_date
and		cs.billing_date >=  @start_date
and    	((@spot_type != 'All'
and		cs.spot_type = @spot_type)
or		(@spot_type = 'All'
and		cs.spot_type in ('S','B','C','N')))
and 	cs.spot_status != 'P'
and		((@mode = 'B'
and		fc.business_unit_id = @mode_id)
or		(@mode = 'M'
and		cp.media_product_id = @mode_id))

return @count
END
GO
