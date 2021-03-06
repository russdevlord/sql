/****** Object:  StoredProcedure [dbo].[p_film_campaign_mthly_audit_release_cre]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_mthly_audit_release_cre]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_mthly_audit_release_cre]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  proc [dbo].[p_film_campaign_mthly_audit_release_cre]		@accounting_period  		datetime,
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
	liability_type					int				null,
	f_agreement_amount				money			null,
	f_other_majors_amount			money			null,
	f_others_amount					money			null,
	d_agreement_amount				money			null,
	d_other_majors_amount			money			null,
	d_others_amount					money			null
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
and 		spot_liability.release_period = @accounting_period
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
and 		spot_liability.release_period = @accounting_period
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
and 		spot_liability.release_period = @accounting_period
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
and 		spot_liability.release_period = @accounting_period
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
and 		spot_liability.release_period = @accounting_period
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
and 		spot_liability.release_period = @accounting_period
and			(@mode = 1 
or			(@mode = 2
and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))

declare		accounting_period_csr cursor forward_only static for
select		creation_period,
			liability_type 
from		spot_liability,
            #spots
where		#spots.spot_id = spot_liability.spot_id
--and 		liability_type != 1
--and		liability_type != 5
group by 	creation_period,
			liability_type 
order by 	creation_period,
			liability_type
for			read only

open accounting_period_csr
fetch accounting_period_csr into @creation_period, @liability_type
while(@@fetch_status=0)
begin

	truncate table #complexes

	insert 		into #complexes
	select 		complex_id 
	from 		cinema_agreement_policy 
	where		cinema_agreement_id = @cinema_agreement_id
	and    		processing_start_date <= @accounting_period
	and    		isnull(processing_end_date,'1-jan-2050') >= @accounting_period

	select 		@f_agreement_amount = isnull( sum(cinema_amount),0)
	from		spot_liability
	where 		liability_type = @liability_type
	and 		spot_liability.creation_period = @creation_period
	and			spot_id in (select  spot_id
                            from    #spots
                            where   phase = 1)

	select 		@f_other_majors_amount =isnull( sum(cinema_amount),0)
	from		spot_liability
	where 		liability_type = @liability_type
	and 		spot_liability.creation_period = @creation_period
	and			spot_id in (select  spot_id
                            from    #spots
                            where   phase = 2)

	select 		@f_others_amount =isnull( sum(cinema_amount),0)
	from		spot_liability
	where 		liability_type = @liability_type
	and 		spot_liability.creation_period = @creation_period
	and			spot_id in (select  spot_id
                            from    #spots
                            where   phase = 3)


	select 		@d_agreement_amount = isnull( sum(cinema_amount),0)
	from		spot_liability
	where 		liability_type = @liability_type
	and 		spot_liability.creation_period = @creation_period
	and			spot_id in (select  spot_id
                            from    #spots
                            where   phase = 4)

	select 		@d_other_majors_amount =isnull( sum(cinema_amount),0)
	from		spot_liability
	where 		liability_type = @liability_type
	and 		spot_liability.creation_period = @creation_period
	and			spot_id in (select  spot_id
                            from    #spots
                            where   phase = 5)

	select 		@d_others_amount =isnull( sum(cinema_amount),0)
	from		spot_liability
	where 		liability_type = @liability_type
	and 		spot_liability.creation_period = @creation_period
	and			spot_id in (select  spot_id
                            from    #spots
                            where   phase = 6)

	if @f_agreement_amount != 0 or  @f_other_majors_amount != 0 or  @f_others_amount != 0 or  @d_agreement_amount != 0 or  @d_other_majors_amount != 0 or @d_others_amount != 0
		insert into #mthly_breakdown values (@creation_period, @liability_type, @f_agreement_amount, @f_other_majors_amount, @f_others_amount, @d_agreement_amount, @d_other_majors_amount, @d_others_amount)

	fetch accounting_period_csr into @creation_period, @liability_type
end

select *, 
@accounting_period, 
@cinema_agreement_id, 
@mode 
from #mthly_breakdown 
where liability_type = 1 
union
select *, 
@accounting_period, 
@cinema_agreement_id, 
@mode 
from #mthly_breakdown 
where liability_type = 5
order by liability_type, creation_period
--select * from #spots
return 0
GO
