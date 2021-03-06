/****** Object:  StoredProcedure [dbo].[p_film_campaign_mthly_audit_creation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_mthly_audit_creation]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_mthly_audit_creation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_film_campaign_mthly_audit_creation]		@start_date					datetime,
											@end_date					datetime,
											@cinema_agreement_id		int,
											@mode						int

as
 
declare		@error						int,
			@accounting_period			datetime,
			@f_agreement_amount			money,
			@f_other_majors_amount		money,
			@f_others_amount			money,			
			@d_agreement_amount			money,
			@d_other_majors_amount		money,
			@d_others_amount			money			

set nocount on

create table #mthly_breakdown
(
	accounting_period			datetime		null,
	f_agreement_amount			money			null,
	f_other_majors_amount		money			null,
	f_others_amount				money			null,
	d_agreement_amount			money			null,
	d_other_majors_amount		money			null,
	d_others_amount				money			null
)

create table #complexes
(
	complex_id					int				null
)


declare		accounting_period_csr cursor forward_only static for
select		end_date
from		accounting_period 
where		end_date >= @start_date
and			end_date <= @end_date
order by 	end_date
for			read only

open accounting_period_csr
fetch accounting_period_csr into @accounting_period
while(@@fetch_status=0)
begin

	truncate table #complexes

	insert 		into #complexes
	select 		complex_id 
	from 		cinema_agreement_policy 
	where		cinema_agreement_id = @cinema_agreement_id
	and    		processing_start_date <= @accounting_period
	and    		isnull(processing_end_date,'1-jan-2050') >= @accounting_period
  
	select 		@f_agreement_amount =isnull( sum(cinema_amount),0)
	from		spot_liability,
				campaign_spot
	where 		liability_type = 1
	and			spot_liability.spot_id = campaign_spot.spot_id
	and			spot_liability.complex_id in (select complex_id from #complexes)
	and 		spot_liability.creation_period = @accounting_period
--    and         cinema_amount > 0
--    and         spot_liability.spot_id not in (select spot_id from campaign_spot where spot_type = 'M' or spot_type = 'V')
	and			(@mode = 1 
	or			(@mode = 2
	and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))
--    and        spot_liability.complex_id not in (288,307,308,550,602,604,653,682,816,884)
  
	select 		@f_other_majors_amount =isnull( sum(cinema_amount),0)
	from		spot_liability,
				campaign_spot
	where 		liability_type = 1
	and			spot_liability.spot_id = campaign_spot.spot_id
	and			spot_liability.complex_id not in (select complex_id from #complexes)
	and			spot_liability.complex_id in (select complex_id from complex where exhibitor_category_code = 'U' and branch_code != 'Z')
	and 		spot_liability.creation_period = @accounting_period
--    and         cinema_amount > 0
--    and         spot_liability.spot_id not in (select spot_id from campaign_spot where spot_type = 'M' or spot_type = 'V')
    and			(@mode = 1 
	or			(@mode = 2
	and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))
--    and        spot_liability.complex_id not in (288,307,308,550,602,604,653,682,816,884)

	select 		@f_others_amount =isnull( sum(cinema_amount),0)
	from		spot_liability,
				campaign_spot
	where 		liability_type = 1
	and			spot_liability.spot_id = campaign_spot.spot_id
	and			spot_liability.complex_id not in (select complex_id from #complexes)
	and			spot_liability.complex_id in (select complex_id from complex where exhibitor_category_code != 'U' and branch_code != 'Z')
--	and			spot_liability.complex_id not in (select complex_id from complex where exhibitor_category_code = 'U' and branch_code != 'Z')
--	and			spot_liability.complex_id in (select complex_id from complex where branch_code != 'Z')
	and 		spot_liability.creation_period = @accounting_period
--    and         cinema_amount > 0
--    and         spot_liability.spot_id not in (select spot_id from campaign_spot where spot_type = 'M' or spot_type = 'V')
	and			(@mode = 1 
	or			(@mode = 2
	and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))
--    and        spot_liability.complex_id not in (288,307,308,550,602,604,653,682,816,884)

	select 		@d_agreement_amount =isnull( sum(cinema_amount),0)
	from		spot_liability,
				campaign_spot
	where 		liability_type = 5
	and			spot_liability.spot_id = campaign_spot.spot_id
	and			spot_liability.complex_id in (select complex_id from #complexes)
	and 		spot_liability.creation_period = @accounting_period
--    and         cinema_amount > 0
	and			(@mode = 1 
	or			(@mode = 2
	and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))
--    and        spot_liability.complex_id not in (288,307,308,550,602,604,653,682,816,884)


	select 		@d_other_majors_amount =isnull( sum(cinema_amount),0)
	from		spot_liability,
				campaign_spot
	where 		liability_type = 5
	and			spot_liability.spot_id = campaign_spot.spot_id
	and			spot_liability.complex_id not in (select complex_id from #complexes)
	and			spot_liability.complex_id in (select complex_id from complex where exhibitor_category_code = 'U' and branch_code != 'Z')
	and 		spot_liability.creation_period = @accounting_period
--    and         cinema_amount > 0
	and			(@mode = 1 
	or			(@mode = 2
	and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))
--    and        spot_liability.complex_id not in (288,307,308,550,602,604,653,682,816,884)

	select 		@d_others_amount =isnull( sum(cinema_amount),0)
	from		spot_liability,
				campaign_spot
	where 		liability_type = 5
	and			spot_liability.spot_id = campaign_spot.spot_id
	and			spot_liability.complex_id not in (select complex_id from #complexes)
	and			spot_liability.complex_id in (select complex_id from complex where exhibitor_category_code != 'U' and branch_code != 'Z')
--    and         cinema_amount > 0
--	and			spot_liability.complex_id not in (select complex_id from complex where exhibitor_category_code = 'U' and branch_code != 'Z')
--	and			spot_liability.complex_id in (select complex_id from complex where branch_code != 'Z')
	and 		spot_liability.creation_period = @accounting_period
	and			(@mode = 1 
	or			(@mode = 2
	and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))
--    and        spot_liability.complex_id not in (288,307,308,550,602,604,653,682,816,884)

	insert into #mthly_breakdown values (@accounting_period, @f_agreement_amount, @f_other_majors_amount, @f_others_amount, @d_agreement_amount, @d_other_majors_amount, @d_others_amount)

	fetch accounting_period_csr into @accounting_period
end

select *, @start_date, @end_date, @cinema_agreement_id, @mode from #mthly_breakdown


return 0
GO
