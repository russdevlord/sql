/****** Object:  StoredProcedure [dbo].[p_film_campaign_mthly_audit_creation_diff]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_mthly_audit_creation_diff]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_mthly_audit_creation_diff]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  proc [dbo].[p_film_campaign_mthly_audit_creation_diff]		@accounting_period  		datetime,
											                @cinema_agreement_id		int,
											                @mode						int

as
 
declare		@error						int,
			@f_agreement_amount			money,
			@f_other_majors_amount		money,
			@f_others_amount			money,			
			@d_agreement_amount			money,
			@d_other_majors_amount		money,
			@d_others_amount			money,
			@creation_period			datetime,
			@liability_type				int
			

set nocount on

create table #mthly_breakdown
(
	creation_period					datetime		null,
	spot_id     					int				null,
	campaign_no     				int 			null,
	cinema_amount_sum   			money			null
)

create table #complexes
(
	complex_id					int				null
)

create table #spots
(
    spot_id                     int             null,
    phase                       int             null 
)


truncate table #complexes

insert 		into #complexes
select 		complex_id 
from 		cinema_agreement_policy 
where		cinema_agreement_id = @cinema_agreement_id
and    		processing_start_date <= @accounting_period
and    		isnull(processing_end_date,'1-jan-2050') >= @accounting_period

insert      into #spots
select 		distinct spot_liability.spot_id,
            1
from		spot_liability,
			campaign_spot
where 		liability_type = 1
and			spot_liability.spot_id = campaign_spot.spot_id
and			spot_liability.complex_id in (select complex_id from #complexes)
and 		spot_liability.creation_period = @accounting_period
and			(@mode = 1 
or			(@mode = 2
and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))


insert      into #spots
select 		distinct spot_liability.spot_id,
            2
from		spot_liability,
			campaign_spot
where 		liability_type = 1
and			spot_liability.spot_id = campaign_spot.spot_id
and			spot_liability.complex_id not in (select complex_id from #complexes)
and			spot_liability.complex_id in (select complex_id from complex where exhibitor_category_code = 'U' and branch_code != 'Z')
and 		spot_liability.creation_period = @accounting_period
and			(@mode = 1 
or			(@mode = 2
and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))

insert      into #spots
select 		distinct spot_liability.spot_id,
            3
from		spot_liability,
			campaign_spot
where 		liability_type = 1
and			spot_liability.spot_id = campaign_spot.spot_id
and			spot_liability.complex_id not in (select complex_id from #complexes)
and			spot_liability.complex_id in (select complex_id from complex where exhibitor_category_code != 'U' and branch_code != 'Z')
--	and			spot_liability.complex_id not in (select complex_id from complex where exhibitor_category_code = 'U' and branch_code != 'Z')
--	and			spot_liability.complex_id in (select complex_id from complex where branch_code != 'Z')
and 		spot_liability.creation_period = @accounting_period
and			(@mode = 1 
or			(@mode = 2
and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))

insert      into #spots
select 		distinct spot_liability.spot_id,
            4
from		spot_liability,
			campaign_spot
where 		liability_type = 5
and			spot_liability.spot_id = campaign_spot.spot_id
and			spot_liability.complex_id in (select complex_id from #complexes)
and 		spot_liability.creation_period = @accounting_period
and			(@mode = 1 
or			(@mode = 2
and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))


insert      into #spots
select 		distinct spot_liability.spot_id,
            5
from		spot_liability,
			campaign_spot
where 		liability_type = 5
and			spot_liability.spot_id = campaign_spot.spot_id
and			spot_liability.complex_id not in (select complex_id from #complexes)
and			spot_liability.complex_id in (select complex_id from complex where exhibitor_category_code = 'U' and branch_code != 'Z')
and 		spot_liability.creation_period = @accounting_period
and			(@mode = 1 
or			(@mode = 2
and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))

insert      into #spots
select 		distinct spot_liability.spot_id,
            6
from		spot_liability,
			campaign_spot
where 		liability_type = 5
and			spot_liability.spot_id = campaign_spot.spot_id
and			spot_liability.complex_id not in (select complex_id from #complexes)
and			spot_liability.complex_id in (select complex_id from complex where exhibitor_category_code != 'U' and branch_code != 'Z')
--	and			spot_liability.complex_id not in (select complex_id from complex where exhibitor_category_code = 'U' and branch_code != 'Z')
--	and			spot_liability.complex_id in (select complex_id from complex where branch_code != 'Z')
and 		spot_liability.creation_period = @accounting_period
and			(@mode = 1 
or			(@mode = 2
and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))

insert      into #mthly_breakdown
select		@accounting_period,
            spot_liability.spot_id,
            campaign_no,
            sum(cinema_amount)
from		spot_liability,
            campaign_spot,
            #spots
where		#spots.spot_id = spot_liability.spot_id
and         campaign_spot.spot_id = spot_liability.spot_id
and         campaign_spot.spot_id = #spots.spot_id
group by 	spot_liability.spot_id,
            campaign_no
having      sum(cinema_amount) != 0
order by    campaign_no,
            spot_liability.spot_id
            
select      #mthly_breakdown.campaign_no,
            product_desc,
            creation_period,
            sum(cinema_amount_sum)
from        #mthly_breakdown,
            film_campaign
where       #mthly_breakdown.campaign_no = film_campaign.campaign_no
group by    #mthly_breakdown.campaign_no,
            product_desc,
            creation_period
having      sum(cinema_amount_sum) != 0
order by    #mthly_breakdown.campaign_no
return 0
GO
