/****** Object:  StoredProcedure [dbo].[p_test_complexes]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_test_complexes]
GO
/****** Object:  StoredProcedure [dbo].[p_test_complexes]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_test_complexes]		@start_date					datetime,
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

create table #complexes
(
	complex_id					int				null
)

create table #complexes_test
(
	complex_id					int				null,
    accounting_period           datetime        null,
    type                        char(1)         null
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

    insert      into #complexes_test
	select 		distinct spot_liability.complex_id,
                @accounting_period,
                'A'
	from		spot_liability,
				campaign_spot
	where 		(liability_type = 1 or liability_type = 5)
	and			spot_liability.spot_id = campaign_spot.spot_id
	and			spot_liability.complex_id in (select complex_id from #complexes)
	and 		spot_liability.creation_period = @accounting_period
	and			(@mode = 1 
	or			(@mode = 2
	and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))

    insert      into #complexes_test
	select 		distinct spot_liability.complex_id,
                @accounting_period,
                'M'
	from		spot_liability,
				campaign_spot
	where 		(liability_type = 1 or liability_type = 5)
	and			spot_liability.spot_id = campaign_spot.spot_id
	and			spot_liability.complex_id not in (select complex_id from #complexes)
	and			spot_liability.complex_id in (select complex_id from complex where exhibitor_category_code = 'U' and branch_code != 'Z')
	and 		spot_liability.creation_period = @accounting_period
	and			(@mode = 1 
	or			(@mode = 2
	and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))

    insert      into #complexes_test
	select 		distinct spot_liability.complex_id,
                @accounting_period,
                'O'
	from		spot_liability,
				campaign_spot
	where 		(liability_type = 1 or liability_type = 5)
	and			spot_liability.spot_id = campaign_spot.spot_id
	and			spot_liability.complex_id not in (select complex_id from #complexes)
	and			spot_liability.complex_id not in (select complex_id from complex where exhibitor_category_code = 'U' and branch_code != 'Z')
	and			spot_liability.complex_id in (select complex_id from complex where branch_code != 'Z')
	and 		spot_liability.creation_period = @accounting_period
	and			(@mode = 1 
	or			(@mode = 2
	and			campaign_spot.campaign_no in (select campaign_no from aaa_camps)))


	fetch accounting_period_csr into @accounting_period
end

select accounting_period, type, complex_name from #complexes_test, complex where #complexes_test.complex_id = complex.complex_id
return 0
GO
