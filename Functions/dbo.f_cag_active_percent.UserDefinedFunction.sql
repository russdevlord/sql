/****** Object:  UserDefinedFunction [dbo].[f_cag_active_percent]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_cag_active_percent]
GO
/****** Object:  UserDefinedFunction [dbo].[f_cag_active_percent]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_cag_active_percent] (@screening_date as datetime, @complex_id as int, @revenue_source as char(2))
RETURNS numeric(6,4)
AS
BEGIN
DECLARE  @percentage_entitlement		numeric(6,4)


select          @percentage_entitlement = isnull(ap.percentage_entitlement ,0.0)
from			cinema_agreement_policy ap
inner join		cinema_agreement ca on ap.cinema_agreement_id = ca.cinema_agreement_id
where   		ap.policy_status_code = 'A'
and     		ap.active_flag = 'Y'
and     		ap.suspend_contribution = 'N'
and     		ca.agreement_status ='A'
and				ap.complex_id = @complex_id
and				ap.revenue_source = @revenue_source
and     		isnull(ap.rent_inclusion_start,'1-jan-1900') <= @screening_date
and     		isnull(ap.rent_inclusion_end,'1-jan-2050') >= @screening_date
and				ap.complex_id not in (	select			ap.complex_id
										from    		cinema_agreement_policy ap
										inner join		cinema_agreement ca on ap.cinema_agreement_id = ca.cinema_agreement_id
										where   		ap.policy_status_code = 'A'
										and     		ap.active_flag = 'Y'
										and     		ap.suspend_contribution = 'N'
										and     		ca.agreement_status ='A'
										and				ap.complex_id = @complex_id
										and				ap.revenue_source = 'P'
										and     		isnull(ap.rent_inclusion_start,'1-jan-1900') <= @screening_date
										and     		isnull(ap.rent_inclusion_end,'1-jan-2050') >= @screening_date)

return(@percentage_entitlement)

END
GO
